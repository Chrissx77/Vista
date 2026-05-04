import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/screens/auth_gate.dart';
import 'package:vista/utility/colors_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://iutwiokumxyhvdaqgdwg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1dHdpb2t1bXh5aHZkYXFnZHdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3NDE5NzUsImV4cCI6MjA4MTMxNzk3NX0.OAHaFS22BIN3DPMizy98s9j7dnRvC1u9hmTs7cLZeNw',
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
      home: AuthGate(),
    );
  }
}
