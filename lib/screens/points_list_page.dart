import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/screens/add_point_page.dart';
import 'package:vista/screens/point_detail_page.dart';

/// Tab principale: elenco punti panoramici.
class PointsListPage extends ConsumerWidget {
  const PointsListPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPoints = ref.watch(pointviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddPointPage(),
                    ),
                  )
                  .then((_) => ref.invalidate(pointviewsProvider));
            },
            icon: const Icon(Icons.add),
            tooltip: 'Aggiungi punto',
          ),
        ],
      ),
      body: asyncPoints.when(
        data: (List<Pointview> list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Nessun punto panoramico ancora.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final pv = list[index];
              final subtitle =
                  '${pv.region ?? ''}${(pv.region ?? '').isNotEmpty && (pv.city ?? '').isNotEmpty ? ', ' : ''}${pv.city ?? ''}';
              final thumb =
                  pv.imageUrls.isNotEmpty ? pv.imageUrls.first : null;
              final scheme = Theme.of(context).colorScheme;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: pv.id == null
                      ? null
                      : () {
                          Navigator.of(context)
                              .push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      PointDetailPage(pointId: pv.id!),
                                ),
                              )
                              .then((_) => ref.invalidate(pointviewsProvider));
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: thumb != null
                            ? Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: scheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.landscape_outlined,
                                    size: 40,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pv.name ?? '',
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Errore: $e',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
