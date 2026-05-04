import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/widgets/point_image_carousel.dart';

/// Dettaglio di un punto panoramico (T4).
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPoint = ref.watch(pointviewDetailProvider(pointId));
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    return asyncPoint.when(
      data: (Pointview p) {
        final subtitle =
            '${p.region ?? ''}${(p.region ?? '').isNotEmpty && (p.city ?? '').isNotEmpty ? ', ' : ''}${p.city ?? ''}';

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name ?? 'Punto panoramico'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (p.imageUrls.isNotEmpty) ...[
                PointImageCarousel(urls: p.imageUrls),
                const SizedBox(height: 20),
              ],
              if (subtitle.trim().isNotEmpty) ...[
                Text('Località', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: textTheme.bodyLarge),
                const SizedBox(height: 20),
              ],
              if (p.description != null && p.description!.trim().isNotEmpty) ...[
                Text('Descrizione', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(p.description!, style: textTheme.bodyLarge),
                const SizedBox(height: 20),
              ],
              if (p.latitude != null && p.longitude != null) ...[
                Text('Coordinate', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                SelectableText(
                  '${p.latitude}, ${p.longitude}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_creatorLabel(p) != null) ...[
                Text('Creato da', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  _creatorLabel(p)!,
                  style: textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Dettaglio'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: AppBar(
          title: const Text('Dettaglio'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: scheme.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
