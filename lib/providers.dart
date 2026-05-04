import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/base_client.dart';
import 'package:vista/controllers/auth_controller.dart';
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

final pointviewsProvider = FutureProvider<List<Pointview>>((ref) {
  return ref.read(pointviewControllerProvider).getAll();
});

final profileProvider = FutureProvider<Profile?>((ref) {
  return ref.read(profileControllerProvider).getMine();
});

final pointviewDetailProvider =
    FutureProvider.family<Pointview, int>((ref, id) {
  return ref.read(pointviewControllerProvider).getById(id);
});
