import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/screens/point_detail_page.dart';
import 'package:vista/services/location_service.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/utility/logger.dart';
import 'package:vista/widgets/cached_image.dart';

/// Mappa interattiva con tutti i punti panoramici geolocalizzati.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with AutomaticKeepAliveClientMixin {
  static const _italyCenter = LatLng(41.9, 12.5);
  static const _initialZoom = 5.5;
  static const _minZoom = 2.0;
  static const _maxZoom = 18.0;

  final MapController _mapController = MapController();
  bool _locating = false;
  List<Marker> _markers = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _syncMarkers(List<Pointview> all) {
    final next = all
        .where((p) => p.latitude != null && p.longitude != null && p.id != null)
        .map(
          (pv) => Marker(
            width: 44,
            height: 44,
            point: LatLng(pv.latitude!, pv.longitude!),
            child: GestureDetector(
              onTap: () => _showPreview(pv),
              child: const _MapPin(),
            ),
          ),
        )
        .toList(growable: false);

    // Evita setState inutili se gli id non sono cambiati.
    if (_sameMarkerIds(_markers, next)) return;
    setState(() => _markers = next);
  }

  bool _sameMarkerIds(List<Marker> a, List<Marker> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].point != b[i].point) return false;
    }
    return true;
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

  void _zoomBy(double delta) {
    try {
      final cam = _mapController.camera;
      final next = (cam.zoom + delta).clamp(_minZoom, _maxZoom);
      _mapController.move(cam.center, next);
    } catch (e) {
      appLog('map zoom failed: ${e.runtimeType}');
    }
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final res = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (!res.isOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Posizione non disponibile.')),
        );
        return;
      }
      final p = res.position!;
      try {
        _mapController.move(LatLng(p.latitude, p.longitude), 14);
      } catch (e) {
        appLog('map move failed: ${e.runtimeType}');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen<AsyncValue<List<Pointview>>>(pointviewsProvider, (_, next) {
      next.whenData(_syncMarkers);
    });

    final asyncPoints = ref.watch(pointviewsProvider);
    final seed = asyncPoints.valueOrNull;
    if (seed != null && _markers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _markers.isNotEmpty) return;
        _syncMarkers(seed);
      });
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Sopra BottomAppBar (68) + notch FAB.
    final controlsBottom = bottomInset + 96;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF2),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _italyCenter,
              initialZoom: _initialZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.vista',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 60,
                  size: const Size(44, 44),
                  padding: const EdgeInsets.all(40),
                  markers: _markers,
                  builder: (context, cluster) {
                    return _ClusterChip(count: cluster.length);
                  },
                ),
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: _openOsmCopyright,
                  ),
                ],
              ),
            ],
          ),
          if (asyncPoints.isLoading && _markers.isEmpty)
            const ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (asyncPoints.hasError && _markers.isEmpty)
            ColoredBox(
              color: ColorsApp.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    asyncPoints.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: controlsBottom,
            child: _MapZoomControls(
              locating: _locating,
              onZoomIn: () => _zoomBy(1),
              onZoomOut: () => _zoomBy(-1),
              onMyLocation: _goToMyLocation,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.locating,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
  });

  final bool locating;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(
          icon: Icons.add,
          tooltip: 'Zoom avanti',
          onPressed: onZoomIn,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: Icons.remove,
          tooltip: 'Zoom indietro',
          onPressed: onZoomOut,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: locating ? null : Icons.my_location,
          tooltip: 'La mia posizione',
          onPressed: locating ? null : onMyLocation,
          child: locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: ColorsApp.primary,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorsApp.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: child ??
                  Icon(icon, size: 22, color: ColorsApp.onSurface),
            ),
          ),
        ),
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
