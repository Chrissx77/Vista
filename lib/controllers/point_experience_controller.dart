import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/services/location_service.dart';

class PointExperienceController {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _defaultHttpTimeout = Duration(seconds: 12);

  Future<List<Pointview>> getTrending({int limit = 10}) async {
    final rows = await _supabase
        .from('point_view_metrics')
        .select()
        .order('favorite_count', ascending: false)
        .order('avg_rating', ascending: false)
        .limit(limit);
    return rows.cast<Map<String, dynamic>>().map(Pointview.fromJson).toList();
  }

  Future<List<Pointview>> getRecentlyAdded({int limit = 10}) async {
    final rows = await _supabase
        .from('point_view_metrics')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.cast<Map<String, dynamic>>().map(Pointview.fromJson).toList();
  }

  Future<List<Pointview>> getByServiceSlugs(List<String> slugs) async {
    if (slugs.isEmpty) return const [];
    final serviceRows = await _supabase
        .from('point_services_catalog')
        .select('id')
        .inFilter('slug', slugs);
    final ids = serviceRows
        .cast<Map<String, dynamic>>()
        .map((e) => (e['id'] as num).toInt())
        .toList();
    if (ids.isEmpty) return const [];
    final pvServiceRows = await _supabase
        .from('point_view_services')
        .select('point_view_id')
        .inFilter('service_id', ids)
        .eq('status', 'active');
    final pointIds = pvServiceRows
        .cast<Map<String, dynamic>>()
        .map((e) => (e['point_view_id'] as num).toInt())
        .toSet()
        .toList();
    if (pointIds.isEmpty) return const [];
    final rows = await _supabase
        .from('point_view_metrics')
        .select()
        .inFilter('id', pointIds)
        .order('favorite_count', ascending: false);
    return rows.cast<Map<String, dynamic>>().map(Pointview.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> listCatalogServices() async {
    final rows = await _supabase
        .from('point_services_catalog')
        .select('id, slug, name, icon, category')
        .eq('is_active', true)
        .order('name');
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> upsertPointServices({
    required int pointId,
    required List<int> serviceIds,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase
        .from('point_view_services')
        .delete()
        .eq('point_view_id', pointId);
    if (serviceIds.isEmpty) return;
    await _supabase
        .from('point_view_services')
        .insert(
          serviceIds
              .map(
                (serviceId) => {
                  'point_view_id': pointId,
                  'service_id': serviceId,
                  'status': 'active',
                  'updated_by': uid,
                },
              )
              .toList(),
        );
  }

  Future<void> reportServiceChange({
    required int pointId,
    required int serviceId,
    required String suggestedStatus,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw StateError('Devi essere loggato.');
    await _supabase.from('point_service_change_reports').insert({
      'point_view_id': pointId,
      'service_id': serviceId,
      'suggested_status': suggestedStatus,
      'reporter_id': uid,
    });
  }

  Future<void> addOrUpdateReview({
    required int pointId,
    required int rating,
    String? reviewText,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw StateError('Devi essere loggato.');
    final location = await LocationService.getCurrentPosition();
    if (!location.isOk || location.position == null) {
      throw StateError(
        location.message ?? 'Posizione richiesta per inviare una recensione.',
      );
    }
    final p = location.position!;
    await _supabase.from('point_reviews').upsert({
      'point_view_id': pointId,
      'user_id': uid,
      'rating': rating,
      'review_text': reviewText?.trim().isEmpty == true
          ? null
          : reviewText?.trim(),
      'reviewer_latitude': p.latitude,
      'reviewer_longitude': p.longitude,
    }, onConflict: 'point_view_id,user_id');
  }

  Future<List<LatLng>> computeRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final response = await http.get(uri).timeout(_defaultHttpTimeout);
      if (response.statusCode != 200) return [start, end];
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = decoded['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) return [start, end];
      final coords =
          (routes.first as Map<String, dynamic>)['geometry']['coordinates']
              as List<dynamic>? ??
          const [];
      final route = coords
          .whereType<List<dynamic>>()
          .where((c) => c.length >= 2)
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
      return route.isEmpty ? [start, end] : route;
    } catch (_) {
      return [start, end];
    }
  }

  Future<List<NearbyAmenity>> fetchNearbyAmenities({
    required double latitude,
    required double longitude,
    int radiusMeters = 2500,
    int limit = 20,
  }) async {
    final query =
        '''
[out:json][timeout:20];
(
  node(around:$radiusMeters,$latitude,$longitude)["amenity"];
  node(around:$radiusMeters,$latitude,$longitude)["tourism"];
  node(around:$radiusMeters,$latitude,$longitude)["leisure"];
);
out body ${limit * 2};
''';
    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: query,
          )
          .timeout(_defaultHttpTimeout);
      if (response.statusCode != 200) return const [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      final origin = LatLng(latitude, longitude);
      final distance = const Distance();
      final out = <NearbyAmenity>[];
      for (final row in elements) {
        final lat = row['lat'];
        final lon = row['lon'];
        if (lat is! num || lon is! num) continue;
        final tags = (row['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
        final kind =
            tags['amenity']?.toString() ??
            tags['tourism']?.toString() ??
            tags['leisure']?.toString() ??
            'service';
        final rawName = tags['name']?.toString().trim() ?? '';
        final name = rawName.isNotEmpty ? rawName : _labelForKind(kind);
        final point = LatLng(lat.toDouble(), lon.toDouble());
        out.add(
          NearbyAmenity(
            name: name,
            kind: kind,
            latitude: point.latitude,
            longitude: point.longitude,
            distanceMeters: distance.as(LengthUnit.Meter, origin, point),
          ),
        );
      }
      out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      final unique = <NearbyAmenity>[];
      final keys = <String>{};
      for (final item in out) {
        final key = '${item.name.toLowerCase()}|${item.kind.toLowerCase()}';
        if (keys.add(key)) unique.add(item);
        if (unique.length >= limit) break;
      }
      return unique;
    } catch (_) {
      return const [];
    }
  }

  String _labelForKind(String kind) {
    switch (kind) {
      case 'parking':
        return 'Parcheggio';
      case 'toilets':
        return 'WC';
      case 'drinking_water':
        return 'Acqua potabile';
      case 'fuel':
        return 'Carburante';
      case 'restaurant':
        return 'Ristorante';
      case 'camp_site':
        return 'Camping';
      case 'viewpoint':
        return 'Belvedere';
      default:
        return kind.replaceAll('_', ' ');
    }
  }

  Future<List<Pointview>> scenicAlongRoute({
    required List<LatLng> route,
    required double minRating,
    double maxDistanceMeters = 3000,
  }) async {
    if (route.isEmpty) return const [];
    final rows = await _supabase
        .from('point_view_metrics')
        .select()
        .gte('avg_rating', minRating)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('avg_rating', ascending: false);
    final candidates = rows
        .cast<Map<String, dynamic>>()
        .map(Pointview.fromJson)
        .toList();
    final dist = const Distance();
    final out = <Pointview>[];
    for (final point in candidates) {
      final lat = point.latitude;
      final lon = point.longitude;
      if (lat == null || lon == null) continue;
      final p = LatLng(lat, lon);
      var min = double.infinity;
      for (final node in route) {
        final d = dist.as(LengthUnit.Meter, p, node);
        if (d < min) min = d;
      }
      if (min <= maxDistanceMeters) out.add(point);
    }
    return out.take(15).toList();
  }
}
