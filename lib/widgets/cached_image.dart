import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vista/utility/colors_app.dart';

/// Wrapper su `CachedNetworkImage` con placeholder e errore coerenti col tema.
/// Usare al posto di `Image.network` per ottenere caching su disco.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderIcon = Icons.image_outlined,
    this.errorIcon = Icons.broken_image_outlined,
    this.iconSize = 36,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData placeholderIcon;
  final IconData errorIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _Placeholder(icon: placeholderIcon, size: iconSize);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => Container(color: ColorsApp.surfaceSkeleton),
      errorWidget: (_, __, ___) =>
          _Placeholder(icon: errorIcon, size: iconSize),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorsApp.surfaceSkeleton,
      alignment: Alignment.center,
      child: Icon(icon, color: ColorsApp.iconPlaceholder, size: size),
    );
  }
}
