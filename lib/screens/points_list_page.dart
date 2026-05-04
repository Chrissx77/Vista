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
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final pv = list[index];
              return ListTile(
                title: Text(pv.name ?? ''),
                subtitle: Text(
                  '${pv.region ?? ''}${(pv.region ?? '').isNotEmpty && (pv.city ?? '').isNotEmpty ? ', ' : ''}${pv.city ?? ''}',
                ),
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
