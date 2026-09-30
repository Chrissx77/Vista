import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/screens/point_detail_page.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/widgets/cached_image.dart';
import 'package:vista/widgets/favorite_button.dart';

/// Tab principale: ricerca + lista di tutti i punti panoramici.
class PointsListPage extends ConsumerStatefulWidget {
  const PointsListPage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<PointsListPage> createState() => _PointsListPageState();
}

class _PointsListPageState extends ConsumerState<PointsListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _subtitleOf(Pointview pv) {
    final parts = <String>[
      if ((pv.city ?? '').trim().isNotEmpty) pv.city!.trim(),
      if ((pv.region ?? '').trim().isNotEmpty) pv.region!.trim(),
    ];
    return parts.join(', ');
  }

  bool _matches(Pointview pv, String q) {
    if (q.isEmpty) return true;
    final hay = [
      pv.name ?? '',
      pv.region ?? '',
      pv.city ?? '',
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  void _openDetail(Pointview pv) {
    if (pv.id == null) return;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PointDetailPage(pointId: pv.id!),
          ),
        )
        .then((_) {
          ref.invalidate(pointviewsProvider);
          ref.invalidate(myFavoritesProvider);
          ref.invalidate(myFavoriteIdsProvider);
        });
  }

  @override
  Widget build(BuildContext context) {
    final asyncPoints = ref.watch(pointviewsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pointviewsProvider);
            await ref.read(pointviewsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: textTheme.displaySmall),
                      const SizedBox(height: 4),
                      Text(
                        'Un nuovo punto di Vista, ogni giorno.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      _SearchField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                      ),
                    ],
                  ),
                ),
              ),
              ...asyncPoints.when(
                data: (List<Pointview> all) {
                  final filtered = all
                      .where((p) => _matches(p, _query))
                      .toList(growable: false);

                  if (all.isEmpty) {
                    return [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          icon: Icons.landscape_outlined,
                          title: 'Nessun punto panoramico',
                          subtitle:
                              'Tocca «Aggiungi» nella barra in basso per\ncondividere il tuo primo punto.',
                        ),
                      ),
                    ];
                  }

                  if (filtered.isEmpty) {
                    return [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 32, 20, 32),
                          child: _EmptyState(
                            icon: Icons.search_off,
                            title: 'Nessun risultato',
                            subtitle: 'Prova a cambiare i termini di ricerca.',
                          ),
                        ),
                      ),
                    ];
                  }

                  return [
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: 'Tutti i punti panoramici'),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.74,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final pv = filtered[i];
                          return _PointCard(
                            pointId: pv.id,
                            title: pv.name ?? '',
                            subtitle: _subtitleOf(pv),
                            favoriteCount: pv.favoriteCount,
                            avgRating: pv.avgRating,
                            imageUrl: pv.imageUrls.isNotEmpty
                                ? pv.imageUrls.first
                                : null,
                            onTap: () => _openDetail(pv),
                          );
                        },
                      ),
                    ),
                  ];
                },
                loading: () => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (Object e, StackTrace _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Errore di caricamento',
                      subtitle: e.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsApp.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: ColorsApp.softShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          hintText: 'Cerca un punto panoramico',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search, color: ColorsApp.onSurfaceMuted),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                splashRadius: 18,
                icon: const Icon(Icons.close, color: ColorsApp.onSurfaceMuted),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.pointId,
    required this.title,
    required this.subtitle,
    required this.favoriteCount,
    required this.avgRating,
    required this.imageUrl,
    required this.onTap,
  });

  final int? pointId;
  final String title;
  final String subtitle;
  final int favoriteCount;
  final double? avgRating;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: ColorsApp.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ColorsApp.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      if (pointId != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: FavoriteButton(pointviewId: pointId!),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          avgRating == null
                              ? 'Nuovo'
                              : avgRating!.toStringAsFixed(1),
                          style: textTheme.bodySmall?.copyWith(
                            color: ColorsApp.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: ColorsApp.accentRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$favoriteCount',
                          style: textTheme.bodySmall?.copyWith(
                            color: ColorsApp.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: ColorsApp.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ColorsApp.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: ColorsApp.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
