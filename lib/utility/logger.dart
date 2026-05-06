import 'package:flutter/foundation.dart';

/// Logger leggero gated su `kDebugMode`: niente body Supabase / payload sensibili
/// in build di release, niente leak su crashlytics di terze parti.
///
/// Usare per messaggi di alto livello ("getProfile failed: 401"), MAI per
/// dump interi di response.
void appLog(String message) {
  if (kDebugMode) {
    debugPrint('[vista] $message');
  }
}
