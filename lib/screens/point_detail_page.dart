import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/widgets/point_image_carousel.dart';

/// Dettaglio di un punto panoramico.
class PointDetailPage extends ConsumerWidget {
  const PointDetailPage({super.key, required this.pointId});

  final int pointId;

  /// Nome da mostrare (mai l'UUID): display_name del profilo se disponibile.
  static String? _creatorLabel(Pointview p) {
    final name = p.creatorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final hasCreator = p.createdBy != null && p.createdBy!.isNotEmpty;
    if (hasCreator) return 'Profilo senza nome';
    return null;
  }

  static String _location(Pointview p) {
    final parts = <String>[
      if ((p.city ?? '').trim().isNotEmpty) p.city!.trim(),
      if ((p.region ?? '').trim().isNotEmpty) p.region!.trim(),
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPoint = ref.watch(pointviewDetailProvider(pointId));
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return asyncPoint.when(
      data: (Pointview p) {
        final location = _location(p);
        final creator = _creatorLabel(p);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: ColorsApp.transparent,
            surfaceTintColor: ColorsApp.transparent,
            elevation: 0,
            leading: const _GlassIconButton(
              icon: Icons.arrow_back_ios_new,
              isBack: true,
            ),
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (p.imageUrls.isNotEmpty)
                PointImageCarousel(urls: p.imageUrls)
              else
                Container(
                  height: 280,
                  color: ColorsApp.surfaceSkeleton,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.landscape_outlined,
                    size: 56,
                    color: ColorsApp.iconPlaceholder,
                  ),
                ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: ColorsApp.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name ?? 'Punto panoramico',
                        style: textTheme.headlineMedium,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: ColorsApp.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: ColorsApp.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (p.description != null &&
                          p.description!.trim().isNotEmpty) ...[
                        Text('Descrizione', style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(p.description!, style: textTheme.bodyLarge),
                        const SizedBox(height: 24),
                      ],
                      if (p.latitude != null && p.longitude != null) ...[
                        Text('Coordinate', style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        _CoordinatesPill(
                          latitude: p.latitude!,
                          longitude: p.longitude!,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (creator != null) ...[
                        Text('Creato da', style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: ColorsApp.primarySoft,
                              child: Text(
                                creator.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: ColorsApp.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(creator, style: textTheme.bodyLarge),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: ColorsApp.error,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: ColorsApp.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, this.isBack = false});

  final IconData icon;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: ColorsApp.surface,
        shape: const CircleBorder(),
        elevation: 1,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isBack ? () => Navigator.of(context).maybePop() : null,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: ColorsApp.onSurface),
          ),
        ),
      ),
    );
  }
}

class _CoordinatesPill extends StatelessWidget {
  const _CoordinatesPill({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ColorsApp.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsApp.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.explore_outlined,
              size: 18, color: ColorsApp.onSurfaceMuted),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              '$latitude, $longitude',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorsApp.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
