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

class _PickedImage {
  _PickedImage(this.file, this.bytes);
  final XFile file;
  final Uint8List bytes;
}

/// Creazione di un nuovo punto panoramico.
class AddPointPage extends ConsumerStatefulWidget {
  const AddPointPage({super.key});

  @override
  ConsumerState<AddPointPage> createState() => _AddPointPageState();
}

class _AddPointPageState extends ConsumerState<AddPointPage> {
  static const int _maxImages = 3;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _region = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  final List<_PickedImage> _picked = [];
  final ImagePicker _picker = ImagePicker();

  bool _saving = false;
  bool _locating = false;
  final Set<int> _selectedServiceIds = <int>{};
  List<Map<String, dynamic>> _catalogServices = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPicks());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  Future<void> _loadServices() async {
    final list = await ref.read(pointExperienceControllerProvider).listCatalogServices();
    if (!mounted) return;
    setState(() => _catalogServices = list);
  }

  /// Su Android, se il sistema chiude l'app con la galleria aperta, qui si recuperano le foto.
  /// Su web / iOS / desktop `retrieveLostData` può non essere implementato: ignoriamo.
  Future<void> _recoverLostPicks() async {
    if (kIsWeb) return;

    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;
      final files = response.files;
      if (files == null || files.isEmpty) return;
      await _appendFromXFiles(files);
    } on UnimplementedError {
      return;
    }
  }

  Future<void> _appendFromXFiles(List<XFile> files) async {
    final add = <_PickedImage>[];
    for (final x in files) {
      if (_picked.length + add.length >= _maxImages) break;
      final bytes = await x.readAsBytes();
      add.add(_PickedImage(x, bytes));
    }
    if (add.isEmpty) return;
    setState(() => _picked.addAll(add));
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
    final normalized = value.trim().replaceAll(',', '.');
    final n = double.tryParse(normalized);
    if (n == null) return 'Latitudine non valida';
    if (n < -90 || n > 90) return 'Latitudine tra -90 e 90';
    return null;
  }

  String? _optionalLongitude(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    final n = double.tryParse(normalized);
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

  Future<void> _addOneFromGallery() async {
    if (_picked.length >= _maxImages) return;
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (!mounted || x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _picked.add(_PickedImage(x, bytes)));
  }

  Future<void> _addMultipleFromGallery() async {
    if (_picked.length >= _maxImages) return;
    final list = await _picker.pickMultiImage(
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (!mounted || list.isEmpty) return;
    await _appendFromXFiles(list);
  }

  Future<void> _addFromCamera() async {
    if (_picked.length >= _maxImages) return;
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

  void _removeAt(int index) {
    setState(() => _picked.removeAt(index));
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

      final names = await LocationService.reverseGeocode(p.latitude, p.longitude);
      if (!mounted) return;
      if (_region.text.trim().isEmpty && (names.region ?? '').isNotEmpty) {
        _region.text = names.region!;
      }
      if (_city.text.trim().isEmpty && (names.city ?? '').isNotEmpty) {
        _city.text = names.city!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posizione aggiornata.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (_picked.length >= _maxImages) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorsApp.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ColorsApp.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: ColorsApp.primary),
                  title: const Text('Scegli dalla galleria'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _addOneFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.collections_outlined,
                      color: ColorsApp.primary),
                  title: const Text('Scegli più foto insieme'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _addMultipleFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: ColorsApp.primary),
                  title: const Text('Scatta una foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _addFromCamera();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aggiungi almeno un'immagine (massimo 3)."),
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
      final urls = await uploadPointviewImages(
        _picked.map((e) => e.file).toList(),
      );

      final pv = Pointview()
        ..name = _name.text.trim()
        ..region = _region.text.trim()
        ..city = _city.text.trim()
        ..description = _description.text.trim().isEmpty
            ? null
            : _description.text.trim()
        ..imageUrls = urls;

      final latText = _latitude.text.trim();
      final lngText = _longitude.text.trim();
      if (latText.isNotEmpty) {
        pv.latitude = double.parse(latText.replaceAll(',', '.'));
      }
      if (lngText.isNotEmpty) {
        pv.longitude = double.parse(lngText.replaceAll(',', '.'));
      }

      final pointId = await ref.read(pointviewControllerProvider).create(pv);
      if (pointId > 0) {
        await ref.read(pointExperienceControllerProvider).upsertPointServices(
              pointId: pointId,
              serviceIds: _selectedServiceIds.toList(),
            );
      }
      ref.invalidate(pointviewsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Punto creato.')));
      Navigator.of(context).pop();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isLegacyMissingIdError =
          msg.contains('id non restituito') ||
          msg.contains('creazione punto riuscita ma id non restituito');
      if (isLegacyMissingIdError) {
        ref.invalidate(pointviewsProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Punto creato.')));
        Navigator.of(context).pop();
        return;
      }
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: TextStyle(color: scheme.onError)),
          backgroundColor: scheme.error,
          behavior: SnackBarBehavior.floating,
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
        title: const Text('Nuovo punto'),
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
            _SectionLabel('Foto', subtitle: 'Da 1 a $_maxImages immagini.'),
            const SizedBox(height: 12),
            _ImagesRow(
              picked: _picked,
              maxImages: _maxImages,
              onRemove: _saving ? null : _removeAt,
              onAdd: _saving ? null : _showImageSourceSheet,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Dettagli'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome del punto',
                prefixIcon: Icon(Icons.tour_outlined),
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
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 28),
            _SectionLabel(
              'Posizione',
              subtitle: 'Lascia vuoto se non vuoi condividere le coordinate.',
            ),
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
                      hintText: 'es. 37.5',
                    ),
                    validator: _optionalLatitude,
                    textInputAction: TextInputAction.next,
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
                      hintText: 'es. 15.08',
                    ),
                    validator: _optionalLongitude,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Le coordinate aiutano gli altri a raggiungere il punto.',
                style: textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Servizi disponibili'),
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
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: ColorsApp.onPrimary,
                      ),
                    )
                  : const Text('Salva punto'),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _ImagesRow extends StatelessWidget {
  const _ImagesRow({
    required this.picked,
    required this.maxImages,
    required this.onRemove,
    required this.onAdd,
  });

  final List<_PickedImage> picked;
  final int maxImages;
  final ValueChanged<int>? onRemove;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (var i = 0; i < picked.length; i++) {
      tiles.add(_ImageTile(bytes: picked[i].bytes, onRemove: () => onRemove?.call(i)));
    }
    if (picked.length < maxImages) {
      tiles.add(_AddImageTile(onTap: onAdd));
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiles,
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

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
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: ColorsApp.onPrimary,
                ),
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
      child: DottedBorderBox(
        size: 100,
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

/// Box "tratteggiato" sintetizzato con bordo solido + sfondo soft.
/// Evita dipendenze esterne mantenendo un look minimal.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ColorsApp.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorsApp.primary.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}
