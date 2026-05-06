import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/services/location_service.dart';
import 'package:vista/utility/colors_app.dart';

/// Modifica di un pointview esistente: campi testuali + coordinate.
/// Le immagini esistenti restano invariate (gestione media via creazione).
class EditPointPage extends ConsumerStatefulWidget {
  const EditPointPage({super.key, required this.pointview});

  final Pointview pointview;

  @override
  ConsumerState<EditPointPage> createState() => _EditPointPageState();
}

class _EditPointPageState extends ConsumerState<EditPointPage> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  Future<void> _loadServices() async {
    final list = await ref.read(pointExperienceControllerProvider).listCatalogServices();
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
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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
            : double.parse(_longitude.text.trim().replaceAll(',', '.'));

      await ref.read(pointviewControllerProvider).update(updated);
      if (widget.pointview.id != null) {
        await ref.read(pointExperienceControllerProvider).upsertPointServices(
              pointId: widget.pointview.id!,
              serviceIds: _selectedServiceIds.toList(),
            );
      }

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
            Text('Dettagli', style: textTheme.titleMedium),
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
