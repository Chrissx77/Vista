import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bucketId = 'pointview-images';

String _contentTypeForExtension(String ext) {
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
    case 'heif':
      return 'image/heic';
    default:
      return 'image/jpeg';
  }
}

/// Carica 1–3 file sul bucket `pointview-images` (cartella = `auth.uid()`)
/// e restituisce gli URL pubblici da inviare a `sendPointview`.
Future<List<String>> uploadPointviewImages(List<XFile> files) async {
  if (files.isEmpty || files.length > 3) {
    throw ArgumentError('Servono tra 1 e 3 immagini.');
  }

  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null || uid.isEmpty) {
    throw StateError('Accedi per caricare le immagini.');
  }

  final bucket = client.storage.from(_bucketId);
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final urls = <String>[];

  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    final bytes = await file.readAsBytes();
    final name = file.name;
    final dot = name.lastIndexOf('.');
    var ext = dot >= 0 ? name.substring(dot + 1) : 'jpg';
    ext = ext.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
    if (ext.isEmpty) ext = 'jpg';

    final path = '$uid/${stamp}_$i.$ext';
    try {
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: _contentTypeForExtension(ext),
          upsert: false,
        ),
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('bucket not found') ||
          msg.contains('bucket') && msg.contains('404')) {
        throw Exception(
          'Il bucket Storage "$_bucketId" non esiste sul tuo progetto Supabase '
          '(l’errore non dipende dall’API del punto: le immagini si caricano prima su Storage).\n\n'
          'Correzione: apri il dashboard Supabase → SQL Editor → incolla ed esegui il file '
          'supabase/fix_storage_bucket.sql (oppure Storage → New bucket, id esatto: '
          '$_bucketId, pubblico, max ~5 MB, tipi immagine).',
        );
      }
      rethrow;
    }
    urls.add(bucket.getPublicUrl(path));
  }

  return urls;
}
