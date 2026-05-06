import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/base_client.dart';
import 'package:vista/controllers/auth_controller.dart';
import 'package:vista/controllers/favorites_controller.dart';
import 'package:vista/controllers/moderation_controller.dart';
import 'package:vista/controllers/point_experience_controller.dart';
import 'package:vista/controllers/pointview_controller.dart';
import 'package:vista/controllers/profile_controller.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/models/profile.dart';

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(),
);

final pointviewControllerProvider = Provider<PointviewController>(
  (ref) => PointviewController(BaseClient()),
);

final profileControllerProvider = Provider<ProfileController>(
  (ref) => ProfileController(BaseClient()),
);

final favoritesControllerProvider = Provider<FavoritesController>(
  (ref) => FavoritesController(),
);

final moderationControllerProvider = Provider<ModerationController>(
  (ref) => ModerationController(),
);
final pointExperienceControllerProvider = Provider<PointExperienceController>(
  (ref) => PointExperienceController(),
);

/// Tick realtime per aggiornare automaticamente feed/lista/trending.
/// Emette un valore ogni volta che cambiano tabelle che impattano le 3 sezioni:
/// - point_views (nuovi punti / update)
/// - favorites (conteggio preferiti, ranking trend)
/// - point_reviews (rating medio)
final pointsRealtimeTickProvider = StreamProvider.autoDispose<int>((ref) {
  final supabase = Supabase.instance.client;
  var tick = 0;

  final stream = Stream<int>.multi((controller) {
    void emitTick() {
      tick += 1;
      controller.add(tick);
    }

    final channel = supabase.channel('realtime:points-feed');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'point_views',
          callback: (_) => emitTick(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorites',
          callback: (_) => emitTick(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'point_reviews',
          callback: (_) => emitTick(),
        )
        .subscribe();

    controller
      ..add(tick)
      ..onCancel = () async {
        await supabase.removeChannel(channel);
      };
  });

  return stream;
});

/// Lista globale punti, filtrata lato client per escludere utenti bloccati.
final pointviewsProvider = FutureProvider<List<Pointview>>((ref) async {
  ref.watch(pointsRealtimeTickProvider);
  final all = await ref.read(pointviewControllerProvider).getAll();
  final blocked = await ref.watch(blockedUserIdsProvider.future);
  if (blocked.isEmpty) return all;
  return all.where((p) {
    final cb = p.createdBy;
    return cb == null || !blocked.contains(cb);
  }).toList(growable: false);
});

final profileProvider = FutureProvider.autoDispose.family<Profile?, String?>((
  ref,
  userId,
) {
  if (userId == null || userId.isEmpty) return null;
  return ref.read(profileControllerProvider).getMine();
});

final pointviewDetailProvider =
    FutureProvider.autoDispose.family<Pointview, int>((ref, id) {
  return ref.read(pointviewControllerProvider).getById(id);
});

/// Pointview creati dall'utente loggato.
final myPointviewsProvider = FutureProvider.autoDispose<List<Pointview>>((ref) {
  return ref.read(pointviewControllerProvider).getMine();
});

/// Set degli id dei punti preferiti dell'utente loggato.
final myFavoriteIdsProvider = FutureProvider<Set<int>>((ref) {
  ref.watch(pointsRealtimeTickProvider);
  return ref.read(favoritesControllerProvider).myFavoriteIds();
});

/// Lista pointview preferiti completi (per la tab "Salvati").
final myFavoritesProvider = FutureProvider.autoDispose<List<Pointview>>((ref) {
  ref.watch(pointsRealtimeTickProvider);
  return ref.read(favoritesControllerProvider).myFavoritePointviews();
});

/// Set di user id bloccati dall'utente loggato.
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.read(moderationControllerProvider).myBlockedUserIds();
});

/// User id corrente, utile a UI condizionali.
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final trendingPointviewsProvider = FutureProvider.autoDispose<List<Pointview>>((ref) {
  ref.watch(pointsRealtimeTickProvider);
  return ref.read(pointExperienceControllerProvider).getTrending(limit: 10);
});

final recentPointviewsProvider = FutureProvider.autoDispose<List<Pointview>>((ref) {
  ref.watch(pointsRealtimeTickProvider);
  return ref.read(pointExperienceControllerProvider).getRecentlyAdded(limit: 10);
});

final isPremiumProvider = FutureProvider.autoDispose<bool>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  final profile = await ref.watch(profileProvider(uid).future);
  return profile?.isPremium ?? false;
});
