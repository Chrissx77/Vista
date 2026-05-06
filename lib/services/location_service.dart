import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Esito della richiesta posizione: ok + posizione, oppure errore mappato in
/// messaggio italiano leggibile per l'utente.
class LocationResult {
  const LocationResult.ok(this.position) : message = null;
  const LocationResult.error(this.message) : position = null;

  final Position? position;
  final String? message;

  bool get isOk => position != null;
}

/// Reverse geocoding: prima placemark utile (regione, città).
class GeoNames {
  const GeoNames({this.region, this.city});

  final String? region;
  final String? city;
}

class LocationService {
  /// Acquisisce la posizione corrente gestendo permessi e servizio disattivato.
  /// Tutti i messaggi sono in italiano e adatti a uno snackbar.
  static Future<LocationResult> getCurrentPosition() async {
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      return const LocationResult.error(
        'Servizi di localizzazione disattivati. Attivali dalle impostazioni.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult.error(
        'Permesso posizione negato.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.error(
        'Permesso posizione negato in modo permanente. Apri le impostazioni di sistema per abilitarlo.',
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult.ok(pos);
    } catch (_) {
      return const LocationResult.error(
        'Impossibile ottenere la posizione. Riprova all\u2019aperto.',
      );
    }
  }

  /// Reverse geocoding: prova a estrarre regione amministrativa e località.
  /// Best-effort: in caso di errore restituisce un oggetto vuoto.
  static Future<GeoNames> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return const GeoNames();
      final p = placemarks.first;
      String? region = (p.administrativeArea ?? '').trim();
      if (region.isEmpty) region = (p.subAdministrativeArea ?? '').trim();
      String? city = (p.locality ?? '').trim();
      if (city.isEmpty) city = (p.subLocality ?? '').trim();
      if (city.isEmpty) city = (p.subAdministrativeArea ?? '').trim();
      return GeoNames(
        region: region.isEmpty ? null : region,
        city: city.isEmpty ? null : city,
      );
    } catch (_) {
      return const GeoNames();
    }
  }
}
