import 'package:supabase_flutter/supabase_flutter.dart';

/// Callback registrato da [AuthGate] per forzare un rebuild dopo login
/// senza dipendere solo da `onAuthStateChange` (timing / piattaforma).
void Function()? _authGateSyncSession;

/// Sessione offerta subito dopo [signInWithPassword] (stesso oggetto della risposta),
/// prima che `currentSession` sia garantito nel client.
Session? _sessionHydrate;

void registerAuthGateSessionSync(void Function() fn) {
  _authGateSyncSession = fn;
}

void unregisterAuthGateSessionSync() {
  _authGateSyncSession = null;
  _sessionHydrate = null;
}

Session? takeOfferedAuthSession() {
  final s = _sessionHydrate;
  _sessionHydrate = null;
  return s;
}

void offerAuthSessionForGateSync(Session session) {
  _sessionHydrate = session;
}

/// Chiamare dopo un login riuscito (es. da [LoginPage]).
void requestAuthGateSessionSync() {
  _authGateSyncSession?.call();
}

/// Dopo [signInWithPassword] con sessione non null: evita race su `currentSession`.
void syncAuthGateAfterSignIn(Session session) {
  offerAuthSessionForGateSync(session);
  requestAuthGateSessionSync();
}
