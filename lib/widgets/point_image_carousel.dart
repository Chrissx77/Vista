import 'package:flutter/material.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/widgets/cached_image.dart';

/// Carosello hero per il dettaglio: immagine grande, counter, indicatori.
class PointImageCarousel extends StatefulWidget {
  const PointImageCarousel({
    super.key,
    required this.urls,
    this.height = 380,
  });

  final List<String> urls;
  final double height;

  @override
  State<PointImageCarousel> createState() => _PointImageCarouselState();
}

class _PointImageCarouselState extends State<PointImageCarousel> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();

    final hasMultiple = widget.urls.length > 1;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              return CachedImage(
                url: widget.urls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                iconSize: 48,
              );
            },
          ),
          if (hasMultiple)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_page + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: ColorsApp.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (hasMultiple)
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
                  final selected = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: selected ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected
                          ? ColorsApp.surface
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
