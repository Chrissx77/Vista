import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/screens/point_detail_page.dart';
import 'package:vista/screens/route_planner_page.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/utility/logger.dart';
import 'package:vista/widgets/cached_image.dart';

/// Mappa interattiva con tutti i punti panoramici geolocalizzati.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const _italyCenter = LatLng(41.9, 12.5);
  static const _initialZoom = 5.5;

  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openOsmCopyright() async {
    final uri = Uri.parse('https://www.openstreetmap.org/copyright');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      appLog('osm copyright open failed: ${e.runtimeType}');
    }
  }

  void _showPreview(Pointview pv) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorsApp.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PreviewCard(pointview: pv),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncPoints = ref.watch(pointviewsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: asyncPoints.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (List<Pointview> all) {
            final geo = all
                .where((p) => p.latitude != null && p.longitude != null && p.id != null)
                .toList(growable: false);

            final markers = geo.map((pv) {
              return Marker(
                width: 44,
                height: 44,
                point: LatLng(pv.latitude!, pv.longitude!),
                child: GestureDetector(
                  onTap: () => _showPreview(pv),
                  child: const _MapPin(),
                ),
              );
            }).toList(growable: false);

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _italyCenter,
                    initialZoom: _initialZoom,
                    minZoom: 2,
                    maxZoom: 18,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'app.vista',
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 60,
                        size: const Size(44, 44),
                        padding: const EdgeInsets.all(40),
                        markers: markers,
                        builder: (context, cluster) {
                          return _ClusterChip(count: cluster.length);
                        },
                      ),
                    ),
                    RichAttributionWidget(
                      alignment: AttributionAlignment.bottomRight,
                      showFlutterMapAttribution: false,
                      popupInitialDisplayDuration:
                          const Duration(seconds: 5),
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: _openOsmCopyright,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _MapHeader(
                    count: geo.length,
                    onOpenPlanner: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const RoutePlannerPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.count, required this.onOpenPlanner});

  final int count;
  final VoidCallback onOpenPlanner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ColorsApp.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: ColorsApp.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 18, color: ColorsApp.primary),
          const SizedBox(width: 8),
          Text(
            count == 0 ? 'Nessun punto sulla mappa' : '$count punti sulla mappa',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorsApp.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onOpenPlanner,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text('A→B', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsApp.primary,
        shape: BoxShape.circle,
        boxShadow: ColorsApp.softShadow,
        border: Border.all(color: ColorsApp.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.place,
        size: 22,
        color: ColorsApp.onPrimary,
      ),
    );
  }
}

class _ClusterChip extends StatelessWidget {
  const _ClusterChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsApp.primary,
        shape: BoxShape.circle,
        boxShadow: ColorsApp.softShadow,
        border: Border.all(color: ColorsApp.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: ColorsApp.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.pointview});

  final Pointview pointview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      if ((pointview.city ?? '').trim().isNotEmpty) pointview.city!.trim(),
      if ((pointview.region ?? '').trim().isNotEmpty) pointview.region!.trim(),
    ].join(', ');

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorsApp.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedImage(
                  url: pointview.imageUrls.isEmpty
                      ? null
                      : pointview.imageUrls.first,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              pointview.name ?? '',
              style: textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 16, color: ColorsApp.onSurfaceMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (pointview.id == null) return;
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => PointDetailPage(pointId: pointview.id!),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Apri'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
