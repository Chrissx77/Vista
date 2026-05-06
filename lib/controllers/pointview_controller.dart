import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/base_client.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/utility/logger.dart';

const String _imagesBucket = 'pointview-images';
const String _bucketPathSeparator = '/storage/v1/object/public/$_imagesBucket/';

class PointviewController {
  PointviewController(this._client);

  final BaseClient _client;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Pointview>> getAll() => _client.getPointview();

  Future<int> create(Pointview pointview) => _client.sendPointview(pointview);

  Future<Pointview> getById(int id) async {
    final p = await _client.getPointviewById(id);
    if (p == null) {
      throw Exception('Punto non trovato o non accessibile.');
    }
    return p;
  }

  /// Restituisce solo i pointview creati dall'utente loggato.
  /// Le RLS proteggono la lettura, ma filtriamo comunque per `created_by`.
  Future<List<Pointview>> getMine() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await _supabase
        .from('point_views')
        .select()
        .eq('created_by', uid)
        .order('created_at', ascending: false);
    return rows
        .cast<Map<String, dynamic>>()
        .map(Pointview.fromJson)
        .toList(growable: false);
  }

  Future<void> update(Pointview pointview) async {
    final id = pointview.id;
    if (id == null) {
      throw ArgumentError('Impossibile aggiornare: id mancante.');
    }
    final payload = <String, dynamic>{
      'name': pointview.name,
      'region': pointview.region,
      'city': pointview.city,
      'description': pointview.description,
      'latitude': pointview.latitude,
      'longitude': pointview.longitude,
    };
    await _supabase.from('point_views').update(payload).eq('id', id);
  }

  Future<void> delete(int id) async {
    final paths = await _collectStoragePaths(id);
    if (paths.isNotEmpty) {
      try {
        await _supabase.storage.from(_imagesBucket).remove(paths);
      } catch (e) {
        appLog('storage cleanup failed: ${e.runtimeType}');
      }
    }
    await _supabase.from('point_views').delete().eq('id', id);
  }

  Future<List<String>> _collectStoragePaths(int id) async {
    try {
      final row = await _supabase
          .from('point_views')
          .select('image_urls')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return const [];
      final raw = row['image_urls'];
      if (raw is! List) return const [];
      final out = <String>[];
      for (final item in raw) {
        final url = item?.toString() ?? '';
        if (url.isEmpty) continue;
        final idx = url.indexOf(_bucketPathSeparator);
        if (idx < 0) continue;
        final path = url.substring(idx + _bucketPathSeparator.length);
        if (path.isNotEmpty) out.add(path);
      }
      return out;
    } catch (e) {
      appLog('read image_urls before delete failed: ${e.runtimeType}');
      return const [];
    }
  }
}
