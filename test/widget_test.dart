import 'package:flutter_test/flutter_test.dart';
import 'package:vista/supabase_env.dart';

void main() {
  test('SupabaseEnv compile-time keys are strings', () {
    expect(SupabaseEnv.supabaseUrl, isA<String>());
    expect(SupabaseEnv.supabaseAnonKey, isA<String>());
  });
}
