import 'package:vista/supabase_env.dart';

/// Base URL del progetto Supabase (da `--dart-define=SUPABASE_URL=...`).
String get baseUrl => SupabaseEnv.supabaseUrl;

/// Prefisso path delle Edge Functions.
const String functionsApiPath = '/functions/v1/';

/// Anon key (da `--dart-define=SUPABASE_ANON_KEY=...`).
String get anonKey => SupabaseEnv.supabaseAnonKey;
