import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/app_navigation.dart';
import 'package:vista/auth_sync.dart';
import 'package:vista/screens/login_page.dart';
import 'package:vista/screens/main_shell.dart';
import 'package:vista/screens/reset_password_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSub;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  /// Sessione dall’ultimo [AuthState] dello stream (fonte aggiornata prima di `currentSession`).
  Session? _sessionState;

  @override
  void initState() {
    super.initState();
    _sessionState = Supabase.instance.client.auth.currentSession;
    registerAuthGateSessionSync(_pullSessionFromClientAndRebuild);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      AuthState state,
    ) {
      if (!mounted) return;
      _sessionState = state.session;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final nested = _navKey.currentState;
          final root = vistaRootNavigatorKey.currentState;
          (nested ?? root)?.push(
            MaterialPageRoute<void>(builder: (_) => const ResetPasswordPage()),
          );
        });
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sessionState = Supabase.instance.client.auth.currentSession;
      setState(() {});
    });
  }

  void _pullSessionFromClientAndRebuild() {
    if (!mounted) return;
    final offered = takeOfferedAuthSession();
    final fromClient = Supabase.instance.client.auth.currentSession;
    _sessionState = offered ?? fromClient;
    setState(() {});
  }

  @override
  void dispose() {
    unregisterAuthGateSessionSync();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _sessionState;

    if (session != null) {
      return const MainShell(pointsListTitle: 'Esplora');
    }

    return Navigator(
      key: _navKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginPage(),
        );
      },
    );
  }
}
