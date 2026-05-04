import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/screens/main_shell.dart';
import 'package:vista/screens/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: const CircularProgressIndicator());
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const MainShell(
            pointsListTitle: 'Un nuovo punto di Vista',
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
