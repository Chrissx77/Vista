import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/services/location_service.dart';
import 'package:vista/services/pointview_images.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/widgets/cached_image.dart';

class _PickedImage {
  _PickedImage(this.file, this.bytes);
  final XFile file;
  final Uint8List bytes;
}

/// Modifica di un pointview esistente: campi, coordinate, servizi e foto (1–3).
class EditPointPage extends ConsumerStatefulWidget {
  const EditPointPage({super.key, required this.pointview});

  final Pointview pointview;

  @override
  ConsumerState<EditPointPage> createState() => _EditPointPageState();
}

class _EditPointPageState extends ConsumerState<EditPointPage> {
  static const int _maxImages = 3;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _region;
  late final TextEditingController _city;
  late final TextEditingController _description;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;

  bool _saving = false;
  bool _locating = false;
  List<Map<String, dynamic>> _catalogServices = const [];
  final Set<int> _selectedServiceIds = <int>{};

  final List<String> _existingUrls = <String>[];
  final List<_PickedImage> _picked = <_PickedImage>[];
  final ImagePicker _picker = ImagePicker();

  int get _totalImages => _existingUrls.length + _picked.length;

  @override
  void initState() {
    super.initState();
    final p = widget.pointview;
    _name = TextEditingController(text: p.name ?? '');
    _region = TextEditingController(text: p.region ?? '');
    _city = TextEditingController(text: p.city ?? '');
    _description = TextEditingController(text: p.description ?? '');
    _latitude = TextEditingController(
      text: p.latitude == null ? '' : p.latitude.toString(),
    );
    _longitude = TextEditingController(
      text: p.longitude == null ? '' : p.longitude.toString(),
    );
    _existingUrls.addAll(p.imageUrls);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  Future<void> _loadServices() async {
    final list =
        await ref.read(pointExperienceControllerProvider).listCatalogServices();
    final selectedSlugs = widget.pointview.services.map((e) => e.slug).toSet();
    if (!mounted) return;
    setState(() {
      _catalogServices = list;
      _selectedServiceIds
        ..clear()
        ..addAll(
          list
              .where((s) => selectedSlugs.contains(s['slug']?.toString()))
              .map((s) => (s['id'] as num).toInt()),
        );
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _region.dispose();
    _city.dispose();
    _description.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label obbligatorio';
    }
    return null;
  }

  String? _optionalLatitude(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim().replaceAll(',', '.'));
    if (n == null) return 'Latitudine non valida';
    if (n < -90 || n > 90) return 'Latitudine tra -90 e 90';
    return null;
  }

  String? _optionalLongitude(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim().replaceAll(',', '.'));
    if (n == null) return 'Longitudine non valida';
    if (n < -180 || n > 180) return 'Longitudine tra -180 e 180';
    return null;
  }

  Future<bool> _ensureCameraPermission() async {
    if (kIsWeb) return true;
    if (!Platform.isIOS && !Platform.isAndroid) return true;
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Serve il permesso fotocamera per scattare.'),
        action: SnackBarAction(
          label: 'Impostazioni',
          onPressed: openAppSettings,
        ),
      ),
    );
    return false;
  }

  Future<void> _addFromGallery() async {
    if (_totalImages >= _maxImages) return;
    final remaining = _maxImages - _totalImages;
    if (remaining == 1) {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (!mounted || x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => _picked.add(_PickedImage(x, bytes)));
      return;
    }
    final list = await _picker.pickMultiImage(
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (!mounted || list.isEmpty) return;
    final add = <_PickedImage>[];
    for (final x in list) {
      if (_totalImages + add.length >= _maxImages) break;
      add.add(_PickedImage(x, await x.readAsBytes()));
    }
    if (add.isEmpty) return;
    setState(() => _picked.addAll(add));
  }

  Future<void> _addFromCamera() async {
    if (_totalImages >= _maxImages) return;
    if (!await _ensureCameraPermission()) return;
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (!mounted || x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _picked.add(_PickedImage(x, bytes)));
  }

  Future<void> _showImageSourceSheet() async {
    if (_totalImages >= _maxImages || _saving) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galleria'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotocamera'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_locating || _saving) return;
    setState(() => _locating = true);
    try {
      final res = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (!res.isOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Posizione non disponibile.'),
            action: SnackBarAction(
              label: 'Impostazioni',
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }
      final p = res.position!;
      _latitude.text = p.latitude.toStringAsFixed(6);
      _longitude.text = p.longitude.toStringAsFixed(6);
      final names =
          await LocationService.reverseGeocode(p.latitude, p.longitude);
      if (!mounted) return;
      if (_region.text.trim().isEmpty && (names.region ?? '').isNotEmpty) {
        _region.text = names.region!;
      }
      if (_city.text.trim().isEmpty && (names.city ?? '').isNotEmpty) {
        _city.text = names.city!;
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalImages < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Serve almeno un'immagine (massimo 3)."),
        ),
      );
      return;
    }

    final latEmpty = _latitude.text.trim().isEmpty;
    final lngEmpty = _longitude.text.trim().isEmpty;
    if (latEmpty != lngEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inserisci sia latitudine sia longitudine, oppure lascia entrambe vuote.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final originalUrls = widget.pointview.imageUrls;
      final kept = List<String>.from(_existingUrls);
      final uploaded = _picked.isEmpty
          ? const <String>[]
          : await uploadPointviewImages(_picked.map((e) => e.file).toList());
      final finalUrls = [...kept, ...uploaded];

      final updated = Pointview()
        ..id = widget.pointview.id
        ..name = _name.text.trim()
        ..region = _region.text.trim()
        ..city = _city.text.trim()
        ..description = _description.text.trim().isEmpty
            ? null
            : _description.text.trim()
        ..latitude = latEmpty
            ? null
            : double.parse(_latitude.text.trim().replaceAll(',', '.'))
        ..longitude = lngEmpty
            ? null
            : double.parse(_longitude.text.trim().replaceAll(',', '.'))
        ..imageUrls = finalUrls;

      await ref.read(pointviewControllerProvider).update(updated);
      if (widget.pointview.id != null) {
        await ref.read(pointExperienceControllerProvider).upsertPointServices(
              pointId: widget.pointview.id!,
              serviceIds: _selectedServiceIds.toList(),
            );
      }

      final removed = originalUrls.where((u) => !finalUrls.contains(u));
      await deletePointviewImagePaths(storagePathsFromPublicUrls(removed));

      ref.invalidate(pointviewsProvider);
      ref.invalidate(myPointviewsProvider);
      if (widget.pointview.id != null) {
        ref.invalidate(pointviewDetailProvider(widget.pointview.id!));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punto aggiornato.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: TextStyle(color: scheme.onError)),
          backgroundColor: scheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica punto'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Foto', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Da 1 a $_maxImages immagini.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _existingUrls.length; i++)
                  _ExistingImageTile(
                    url: _existingUrls[i],
                    onRemove: _saving
                        ? null
                        : () => setState(() => _existingUrls.removeAt(i)),
                  ),
                for (var i = 0; i < _picked.length; i++)
                  _NewImageTile(
                    bytes: _picked[i].bytes,
                    onRemove: _saving
                        ? null
                        : () => setState(() => _picked.removeAt(i)),
                  ),
                if (_totalImages < _maxImages)
                  _AddImageTile(
                    onTap: _saving ? null : _showImageSourceSheet,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Dettagli', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome del punto',
                prefixIcon: Icon(Icons.landscape_outlined),
              ),
              validator: (v) => _required(v, 'Nome'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _region,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Regione',
                prefixIcon: Icon(Icons.public_outlined),
              ),
              validator: (v) => _required(v, 'Regione'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Città',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              validator: (v) => _required(v, 'Città'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Text('Posizione', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _saving || _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: ColorsApp.primary,
                        ),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: const Text('Usa la mia posizione'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsApp.primary,
                  side: const BorderSide(color: ColorsApp.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitude,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitudine',
                    ),
                    validator: _optionalLatitude,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitude,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitudine',
                    ),
                    validator: _optionalLongitude,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Servizi', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _catalogServices.map((service) {
                final id = (service['id'] as num).toInt();
                final selected = _selectedServiceIds.contains(id);
                return FilterChip(
                  label: Text(service['name']?.toString() ?? ''),
                  selected: selected,
                  onSelected: _saving
                      ? null
                      : (_) {
                          setState(() {
                            if (selected) {
                              _selectedServiceIds.remove(id);
                            } else {
                              _selectedServiceIds.add(id);
                            }
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: ColorsApp.onPrimary,
                      ),
                    )
                  : const Text('Salva modifiche'),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExistingImageTile extends StatelessWidget {
  const _ExistingImageTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 100,
            height: 100,
            child: CachedImage(url: url, fit: BoxFit.cover),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: ColorsApp.onSurface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: ColorsApp.onPrimary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NewImageTile extends StatelessWidget {
  const _NewImageTile({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            bytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: ColorsApp.onSurface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: ColorsApp.onPrimary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: ColorsApp.primarySoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorsApp.primary.withValues(alpha: 0.35)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: ColorsApp.primary, size: 26),
            SizedBox(height: 6),
            Text(
              'Aggiungi',
              style: TextStyle(
                color: ColorsApp.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
