import 'dart:io' show Platform;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Apertura "esterna" delle coordinate nelle app di mappe del sistema.
class ExternalApps {
  /// Tenta in ordine: Apple Maps su iOS (`maps://`), poi Google Maps,
  /// con fallback su web Google Maps. Restituisce true se almeno una apre.
  static Future<bool> openInMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label ?? '');
    final candidates = <Uri>[];

    if (!kIsWeb && Platform.isIOS) {
      candidates.add(
        Uri.parse(
          'maps://?q=$encodedLabel&ll=$latitude,$longitude',
        ),
      );
      candidates.add(
        Uri.parse('comgooglemaps://?q=$latitude,$longitude'),
      );
    } else if (!kIsWeb && Platform.isAndroid) {
      candidates.add(
        Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)',
        ),
      );
    }

    candidates.add(
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      ),
    );

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (ok) return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  /// Condivide testo + link. `subject` è usato dove supportato (es. email).
  static Future<void> sharePoint({
    required String name,
    String? location,
    double? latitude,
    double? longitude,
    Rect? sharePositionOrigin,
  }) async {
    final lines = <String>[name];
    if ((location ?? '').trim().isNotEmpty) lines.add(location!.trim());
    if (latitude != null && longitude != null) {
      lines.add(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    }
    final params = ShareParams(
      text: lines.join('\n'),
      subject: 'Vista — $name',
      sharePositionOrigin: sharePositionOrigin,
    );
    await SharePlus.instance.share(params);
  }
}
