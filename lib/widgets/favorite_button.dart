import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/providers.dart';
import 'package:vista/utility/colors_app.dart';

/// Cuore tap-to-toggle per i preferiti. Si appoggia a `myFavoriteIdsProvider`
/// e applica un update ottimistico per restare reattivo.
class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({
    super.key,
    required this.pointviewId,
    this.iconSize = 22,
    this.color,
    this.background,
  });

  final int pointviewId;
  final double iconSize;
  final Color? color;
  final Color? background;

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _busy = false;

  Future<void> _toggle(bool current) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(favoritesControllerProvider).toggle(
            widget.pointviewId,
            isFavorite: current,
          );
      ref.invalidate(myFavoriteIdsProvider);
      ref.invalidate(myFavoritesProvider);
      // Aggiorna subito ranking e numeri "preferiti" nelle sezioni home.
      ref.invalidate(trendingPointviewsProvider);
      ref.invalidate(recentPointviewsProvider);
      ref.invalidate(pointviewsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncIds = ref.watch(myFavoriteIdsProvider);
    final isFav = asyncIds.maybeWhen(
      data: (ids) => ids.contains(widget.pointviewId),
      orElse: () => false,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _toggle(isFav),
      child: Container(
        decoration: BoxDecoration(
          color: widget.background ?? ColorsApp.surface,
          shape: BoxShape.circle,
          boxShadow: ColorsApp.hairlineShadow,
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: widget.iconSize,
          color: isFav ? ColorsApp.accentRed : (widget.color ?? ColorsApp.onSurface),
        ),
      ),
    );
  }
}
