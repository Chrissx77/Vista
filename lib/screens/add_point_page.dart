import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/services/pointview_images.dart';

class _PickedImage {
  _PickedImage(this.file, this.bytes);
  final XFile file;
  final Uint8List bytes;
}

/// Creazione di un nuovo punto panoramico (T5).
class AddPointPage extends ConsumerStatefulWidget {
  const AddPointPage({super.key});

  @override
  ConsumerState<AddPointPage> createState() => _AddPointPageState();
}

class _AddPointPageState extends ConsumerState<AddPointPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _region = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  final List<_PickedImage> _picked = [];

  bool _saving = false;

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

  Future<void> _addFromGallery() async {
    final remaining = 3 - _picked.length;
    if (remaining <= 0) return;
    final list = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted || list.isEmpty) return;
    final add = <_PickedImage>[];
    for (final x in list) {
      if (_picked.length + add.length >= 3) break;
      final bytes = await x.readAsBytes();
      add.add(_PickedImage(x, bytes));
    }
    setState(() => _picked.addAll(add));
  }

  Future<void> _addFromCamera() async {
    if (_picked.length >= 3) return;
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted || x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _picked.add(_PickedImage(x, bytes)));
  }

  void _removeAt(int index) {
    setState(() => _picked.removeAt(index));
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

      await ref.read(pointviewControllerProvider).create(pv);
      ref.invalidate(pointviewsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punto creato.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: TextStyle(color: scheme.onError),
          ),
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo punto panoramico'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Immagini', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Da 1 a 3 foto del punto.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < _picked.length; i++)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _picked[i].bytes,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Material(
                          color: scheme.errorContainer,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _saving ? null : () => _removeAt(i),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_picked.length < 3) ...[
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _addFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(_picked.isEmpty ? 'Scegli foto' : 'Aggiungi foto'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Scatta'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome del punto',
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitudine (opzionale)',
                hintText: 'es. 37.5',
              ),
              validator: _optionalLatitude,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitudine (opzionale)',
                hintText: 'es. 15.08',
              ),
              validator: _optionalLongitude,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Text('Salva punto'),
          ),
        ),
      ),
    );
  }
}
