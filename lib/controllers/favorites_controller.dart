import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/models/pointview.dart';

class FavoritesController {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<Set<int>> myFavoriteIds() async {
    final uid = _uid;
    if (uid == null) return <int>{};
    final rows = await _supabase
        .from('favorites')
        .select('point_view_id')
        .eq('user_id', uid);
    return rows
        .cast<Map<String, dynamic>>()
        .map((r) => (r['point_view_id'] as num).toInt())
        .toSet();
  }

  /// Restituisce i pointview marcati come preferiti, ordinati dal più recente.
  Future<List<Pointview>> myFavoritePointviews() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _supabase
        .from('favorites')
        .select('point_view_id, created_at, point_views(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final list = <Pointview>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final raw = row['point_views'];
      if (raw is Map<String, dynamic>) {
        list.add(Pointview.fromJson(raw));
      } else if (raw is List && raw.isNotEmpty) {
        list.add(Pointview.fromJson(raw.first as Map<String, dynamic>));
      }
    }
    return list;
  }

  Future<void> add(int pointviewId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Devi essere loggato per salvare un punto.');
    }
    await _supabase.from('favorites').upsert(
      {'user_id': uid, 'point_view_id': pointviewId},
      onConflict: 'user_id,point_view_id',
    );
  }

  Future<void> remove(int pointviewId) async {
    final uid = _uid;
    if (uid == null) return;
    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', uid)
        .eq('point_view_id', pointviewId);
  }

  /// Toggle atomico: se presente rimuove, altrimenti aggiunge.
  /// Restituisce lo stato finale (true = preferito).
  Future<bool> toggle(int pointviewId, {required bool isFavorite}) async {
    if (isFavorite) {
      await remove(pointviewId);
      return false;
    }
    await add(pointviewId);
    return true;
  }
}
