import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/auth_sync.dart';
import 'package:vista/const.dart';

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

  /// Elimina account e contenuti collegati tramite Edge Function `delete_account`.
  Future<void> deleteAccount() async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sessione non valida. Accedi di nuovo.');
    }

    final url = Uri.parse('$baseUrl${functionsApiPath}delete_account');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      var message = 'Eliminazione account non riuscita (${response.statusCode}).';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

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
