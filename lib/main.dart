import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/screens/auth_gate.dart';
import 'package:vista/supabase_env.dart';
import 'package:vista/utility/colors_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: ColorsApp.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  if (!SupabaseEnv.isConfigured) {
    final msg = SupabaseEnv.missingConfigMessage;
    if (kReleaseMode) {
      throw StateError(msg);
    }
    debugPrint(msg);
    runApp(
      MaterialApp(
        theme: ColorsApp.lightTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(msg),
            ),
          ),
        ),
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: SupabaseEnv.supabaseUrl,
    anonKey: SupabaseEnv.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vista',
      theme: ColorsApp.lightTheme(),
      home: const AuthGate(),
    );
  }
}
