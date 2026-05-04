/// Configurazione Supabase letta a **compile-time** (`String.fromEnvironment`).
///
/// Avvio in locale (consigliato):
/// `flutter run --dart-define-from-file=dart_defines.local.json`
///
/// In alternativa:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Copia `dart_defines.example.json` in `dart_defines.local.json` e inserisci i
/// valori da Supabase → Project Settings → API.
abstract final class SupabaseEnv {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get missingConfigMessage =>
      'Manca SUPABASE_URL o SUPABASE_ANON_KEY.\n'
      'Esegui ad esempio:\n'
      '  flutter run --dart-define-from-file=dart_defines.local.json\n'
      'Crea dart_defines.local.json copiando dart_defines.example.json '
      '(il file .local è in .gitignore e non va su Git).';
}
