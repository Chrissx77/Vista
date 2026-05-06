import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/auth_sync.dart';

const String _passwordResetRedirect = 'vista://reset-password';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    requestAuthGateSessionSync();
  }

  String? currentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: _passwordResetRedirect,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
