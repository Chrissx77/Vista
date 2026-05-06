import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/controllers/moderation_controller.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/providers.dart';
import 'package:vista/screens/edit_point_page.dart';
import 'package:vista/services/external_apps.dart';
import 'package:vista/services/location_service.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/widgets/favorite_button.dart';
import 'package:vista/widgets/point_image_carousel.dart';

/// Dettaglio di un punto panoramico, con azioni: preferiti, condividi, apri
/// in Mappe, segnala, blocca utente, edit/delete (solo per il proprietario).
class PointDetailPage extends ConsumerWidget {
  const PointDetailPage({super.key, required this.pointId});

  final int pointId;

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
    final currentUid = ref.watch(currentUserIdProvider);

    return asyncPoint.when(
      data: (Pointview p) {
        final location = _location(p);
        final creator = _creatorLabel(p);
        final isOwner = currentUid != null && p.createdBy == currentUid;
        final hasCoords = p.latitude != null && p.longitude != null;

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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
                child: FavoriteButton(pointviewId: pointId),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: _OverflowMenu(pointview: p, isOwner: isOwner),
              ),
            ],
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
                      const SizedBox(height: 20),
                      _ActionRow(pointview: p, hasCoords: hasCoords),
                      const SizedBox(height: 24),
                      if (p.description != null &&
                          p.description!.trim().isNotEmpty) ...[
                        Text('Descrizione', style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(p.description!, style: textTheme.bodyLarge),
                        const SizedBox(height: 24),
                      ],
                      if (hasCoords) ...[
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
                        const SizedBox(height: 24),
                      ],
                      _ServicesSection(point: p),
                      const SizedBox(height: 24),
                      _NearbyAmenitiesSection(point: p),
                      const SizedBox(height: 24),
                      _ReviewsSection(point: p),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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

class _ServicesSection extends ConsumerWidget {
  const _ServicesSection({required this.point});
  final Pointview point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = point.services;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servizi disponibili',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (services.isEmpty)
          const Text('Nessun servizio ancora indicato.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services
                .map(
                  (s) => InputChip(
                    label: Text('${s.name} (${s.status})'),
                    onPressed: () async {
                      final pointId = point.id;
                      if (pointId == null) return;
                      await ref
                          .read(pointExperienceControllerProvider)
                          .reportServiceChange(
                            pointId: pointId,
                            serviceId: await _serviceIdBySlug(ref, s.slug),
                            suggestedStatus: s.status == 'active'
                                ? 'unavailable'
                                : 'active',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Segnalazione inviata.'),
                          ),
                        );
                      }
                    },
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Future<int> _serviceIdBySlug(WidgetRef ref, String slug) async {
    final list = await ref
        .read(pointExperienceControllerProvider)
        .listCatalogServices();
    final found = list.firstWhere((e) => e['slug'] == slug);
    return (found['id'] as num).toInt();
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.point});
  final Pointview point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avg = point.avgRating?.toStringAsFixed(1) ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recensioni', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text('Media $avg (${point.ratingVotesCount})'),
          ],
        ),
        const SizedBox(height: 8),
        ...point.reviews
            .take(5)
            .map(
              (r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${'★' * r.rating}${'☆' * (5 - r.rating)}'),
                subtitle: Text(
                  (r.reviewText ?? '').isEmpty ? 'Nessun testo' : r.reviewText!,
                ),
              ),
            ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addReview(context, ref),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('Lascia recensione'),
        ),
      ],
    );
  }

  Future<void> _addReview(BuildContext context, WidgetRef ref) async {
    final pointId = point.id;
    if (pointId == null) return;
    final lat = point.latitude;
    final lon = point.longitude;
    if (lat == null || lon == null) return;
    final canReview = await _isNearPoint(lat, lon);
    if (!context.mounted) return;
    if (!canReview) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puoi votare solo quando sei entro 100m dal punto.'),
          ),
        );
      }
      return;
    }
    int rating = 5;
    final textController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nuova recensione'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: rating,
                isExpanded: true,
                items: List.generate(
                  5,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1} stelle'),
                  ),
                ),
                onChanged: (v) => setState(() => rating = v ?? 5),
              ),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Commento (opzionale)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Invia'),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    await ref
        .read(pointExperienceControllerProvider)
        .addOrUpdateReview(
          pointId: pointId,
          rating: rating,
          reviewText: textController.text,
        );
    ref.invalidate(pointviewDetailProvider(pointId));
  }

  Future<bool> _isNearPoint(double latitude, double longitude) async {
    final res = await LocationService.getCurrentPosition();
    if (!res.isOk || res.position == null) return false;
    final p = res.position!;
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLon =
        (40075000 * math.cos(latitude * math.pi / 180) / 360).abs();
    final dLat = (p.latitude - latitude) * metersPerDegreeLat;
    final dLon = (p.longitude - longitude) * metersPerDegreeLon;
    final distance = math.sqrt(dLat * dLat + dLon * dLon);
    return distance <= 100;
  }
}

class _NearbyAmenitiesSection extends ConsumerStatefulWidget {
  const _NearbyAmenitiesSection({required this.point});
  final Pointview point;

  @override
  ConsumerState<_NearbyAmenitiesSection> createState() =>
      _NearbyAmenitiesSectionState();
}

class _NearbyAmenitiesSectionState
    extends ConsumerState<_NearbyAmenitiesSection> {
  late Future<List<NearbyAmenity>> _future;

  @override
  void initState() {
    super.initState();
    final lat = widget.point.latitude;
    final lon = widget.point.longitude;
    if (lat == null || lon == null) {
      _future = Future.value(const []);
      return;
    }
    _future = ref
        .read(pointExperienceControllerProvider)
        .fetchNearbyAmenities(latitude: lat, longitude: lon);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.point.latitude == null || widget.point.longitude == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servizi nelle vicinanze',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<NearbyAmenity>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 3),
              );
            }
            final data = snapshot.data ?? const <NearbyAmenity>[];
            if (data.isEmpty) {
              return const Text(
                'Nessun servizio vicino trovato (entro 2.5 km).',
              );
            }
            return Column(
              children: data
                  .take(8)
                  .map(
                    (a) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.near_me_outlined, size: 18),
                      title: Text(a.name),
                      subtitle: Text(
                        '${_kindLabel(a.kind)} · ${a.distanceMeters.toStringAsFixed(0)} m',
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'toilets':
        return 'WC';
      case 'drinking_water':
        return 'Acqua';
      case 'fuel':
        return 'Carburante';
      case 'camp_site':
        return 'Camping';
      case 'restaurant':
        return 'Ristorazione';
      case 'parking':
        return 'Parcheggio';
      default:
        return kind.replaceAll('_', ' ');
    }
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.pointview, required this.hasCoords});

  final Pointview pointview;
  final bool hasCoords;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final loc = [
      if ((pointview.city ?? '').trim().isNotEmpty) pointview.city!.trim(),
      if ((pointview.region ?? '').trim().isNotEmpty) pointview.region!.trim(),
    ].join(', ');
    await ExternalApps.sharePoint(
      name: pointview.name ?? 'Punto panoramico',
      location: loc.isEmpty ? null : loc,
      latitude: pointview.latitude,
      longitude: pointview.longitude,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _openInMaps(BuildContext context) async {
    if (!hasCoords) return;
    final ok = await ExternalApps.openInMaps(
      latitude: pointview.latitude!,
      longitude: pointview.longitude!,
      label: pointview.name,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna app di mappe disponibile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Condividi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsApp.primarySoft,
              foregroundColor: ColorsApp.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasCoords ? () => _openInMaps(context) : null,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Apri in Mappe'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.pointview, required this.isOwner});

  final Pointview pointview;
  final bool isOwner;

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'edit':
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => EditPointPage(pointview: pointview),
          ),
        );
        if (result == true) {
          ref.invalidate(pointviewsProvider);
          ref.invalidate(myPointviewsProvider);
        }
        break;
      case 'delete':
        await _confirmDelete(context, ref);
        break;
      case 'report':
        await _showReportSheet(context, ref);
        break;
      case 'block':
        await _confirmBlock(context, ref);
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elimina punto'),
        content: const Text(
          'Vuoi eliminare definitivamente questo punto? L\'azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: ColorsApp.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final id = pointview.id;
    if (id == null) return;
    try {
      await ref.read(pointviewControllerProvider).delete(id);
      ref.invalidate(pointviewsProvider);
      ref.invalidate(myPointviewsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Punto eliminato.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showReportSheet(BuildContext context, WidgetRef ref) async {
    final id = pointview.id;
    if (id == null) return;
    final reason = await showModalBottomSheet<ReportReason>(
      context: context,
      backgroundColor: ColorsApp.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorsApp.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Segnala questo punto',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 4),
              for (final r in ReportReason.values)
                ListTile(
                  title: Text(r.label),
                  onTap: () => Navigator.pop(sheetContext, r),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (reason == null) return;
    try {
      await ref
          .read(moderationControllerProvider)
          .reportPointview(pointviewId: id, reason: reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Segnalazione inviata. Grazie per averci aiutato.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmBlock(BuildContext context, WidgetRef ref) async {
    final blockedId = pointview.createdBy;
    if (blockedId == null || blockedId.isEmpty) return;
    final creator = (pointview.creatorDisplayName ?? '').trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Blocca utente'),
        content: Text(
          creator.isEmpty
              ? 'Vuoi bloccare l\'autore di questo punto? I suoi punti non verranno più mostrati.'
              : 'Vuoi bloccare $creator? I suoi punti non verranno più mostrati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: ColorsApp.error),
            child: const Text('Blocca'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(moderationControllerProvider).blockUser(blockedId);
      ref.invalidate(blockedUserIdsProvider);
      ref.invalidate(pointviewsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utente bloccato.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: ColorsApp.surface,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: const Color(0x33000000),
      child: SizedBox(
        width: 40,
        height: 40,
        child: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz,
            size: 18,
            color: ColorsApp.onSurface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (v) => _onSelected(context, ref, v),
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];
            if (isOwner) {
              items.add(
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Modifica'),
                  ),
                ),
              );
              items.add(
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: ColorsApp.error),
                    title: Text(
                      'Elimina',
                      style: TextStyle(color: ColorsApp.error),
                    ),
                  ),
                ),
              );
            } else {
              items.add(
                const PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.flag_outlined),
                    title: Text('Segnala'),
                  ),
                ),
              );
              items.add(
                const PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.block, color: ColorsApp.error),
                    title: Text(
                      'Blocca utente',
                      style: TextStyle(color: ColorsApp.error),
                    ),
                  ),
                ),
              );
            }
            return items;
          },
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
          const Icon(
            Icons.explore_outlined,
            size: 18,
            color: ColorsApp.onSurfaceMuted,
          ),
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
