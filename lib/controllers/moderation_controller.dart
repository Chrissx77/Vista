import 'package:supabase_flutter/supabase_flutter.dart';

enum ReportReason {
  spam('spam', 'Spam'),
  inappropriate('inappropriate', 'Contenuto inappropriato'),
  wrongInfo('wrong_info', 'Informazione errata'),
  other('other', 'Altro');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;
}

class ModerationController {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<Set<String>> myBlockedUserIds() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    try {
      final rows = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', uid);
      return rows
          .cast<Map<String, dynamic>>()
          .map((r) => (r['blocked_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> blockUser(String userId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Devi essere loggato per bloccare un utente.');
    }
    if (uid == userId) {
      throw ArgumentError('Non puoi bloccare te stesso.');
    }
    await _supabase.from('blocks').upsert(
      {'blocker_id': uid, 'blocked_id': userId},
      onConflict: 'blocker_id,blocked_id',
    );
  }

  Future<void> unblockUser(String userId) async {
    final uid = _uid;
    if (uid == null) return;
    await _supabase
        .from('blocks')
        .delete()
        .eq('blocker_id', uid)
        .eq('blocked_id', userId);
  }

  Future<void> reportPointview({
    required int pointviewId,
    required ReportReason reason,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Devi essere loggato per segnalare un punto.');
    }
    final payload = <String, dynamic>{
      'reporter_id': uid,
      'point_view_id': pointviewId,
      'reason': reason.code,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    await _supabase.from('reports').insert(payload);
  }
}
