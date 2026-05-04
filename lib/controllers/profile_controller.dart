import 'package:vista/base_client.dart';
import 'package:vista/models/profile.dart';

class ProfileController {
  final BaseClient _client;

  ProfileController(this._client);

  Future<Profile?> getMine() => _client.getProfile();
}
