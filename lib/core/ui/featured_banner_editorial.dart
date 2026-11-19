import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/media_item.dart';
import '../theme/app_colors.dart';
import 'banner_actions.dart';
import 'featured_carousel.dart' show heroHeightFor;
import 'featured_hero.dart' show HeroMeta, heroTopReserve;
import 'image_fade.dart' show imageFadeIn;
import 'native_cover_provider.dart' show nativeCoverProvider;

/// The "Editorial" Home banner: minimalist magazine layout.
///
/// Clean asymmetric framing with trending rank tag, elegant typography,
/// and minimalist glass pill controls.
class FeaturedBannerEditorial extends StatefulWidget {
  const FeaturedBannerEditorial({
    super.key,
    required this.items,
    required this.inList,
    required this.onPlay,
    required this.onInfo,
    required this.onToggleList,
    this.meta,
    this.reading = false,
  });

  final List<MediaItem> items;
  final bool Function(MediaItem) inList;
  final void Function(MediaItem) onPlay;
  final void Function(MediaItem) onInfo;
  final void Function(MediaItem) onToggleList;
  final Future<HeroMeta?> Function(MediaItem)? meta;
  final bool reading;

  @override
  State<FeaturedBannerEditorial> createState() => _FeaturedBannerEditorialState();
}

class _FeaturedBannerEditorialState extends State<FeaturedBannerEditorial> {
  late List<MediaItem> _pages;
  int _index = 0;
  Timer? _timer;

  int get _count => _pages.length;
  MediaItem get _current => _pages[_index];

  @override
  void initState() {
    super.initState();
    _pages = widget.items.take(6).toList();
    _startTimer();
  }

  @override
  void didUpdateWidget(FeaturedBannerEditorial old) {
    super.didUpdateWidget(old);
    final next = widget.items.take(6).toList();
    final changed = next.length != _pages.length ||
        (next.isNotEmpty &&
            _pages.isNotEmpty &&
            next.first.id != _pages.first.id);
    if (changed) {
      setState(() {
        _pages = next;
        _index = 0;
      });
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_count > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _advance(1));
    }
  }

  void _advance(int delta) {
    if (!mounted || _count <= 1) return;
    setState(() {
      _index = (_index + delta) % _count;
      if (_index < 0) _index += _count;
    });
  }

  static String? _art(MediaItem m) => m.banner ?? m.cover;

  Widget _editorialImage(MediaItem item) {
    final url = _art(item);
    if (url == null || url.isEmpty) {
      return ColoredBox(color: AppColors.surface2);
    }
    return Image(
      image: nativeCoverProvider(url, item.coverHeaders),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      frameBuilder: imageFadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = heroHeightFor(context);
    if (_count == 0) return SizedBox(height: height);

    final item = _current;
    final inList = widget.inList(item);
    final topReserve = heroTopReserve(MediaQuery.paddingOf(context).top);

    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -80) {
                _advance(1);
                _startTimer();
              } else if (v > 80) {
                _advance(-1);
                _startTimer();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppColors.bg),
                Positioned(
                top: topReserve,
                left: 16,
                right: 16,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top tag row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '#${_index + 1} TRENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.score != null && item.score! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 11,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  (item.score! / 10).toStringAsFixed(1),
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Main panoramic artwork card
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 550),
                              layoutBuilder: (current, previous) => Stack(
                                fit: StackFit.expand,
                                children: [...previous, ?current],
                              ),
                              child: KeyedSubtree(
                                key: ValueKey('editorial_art_${item.id}'),
                                child: SizedBox.expand(child: _editorialImage(item)),
                              ),
                            ),
                            // Vignette
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x33000000),
                                    Colors.transparent,
                                    Color(0xCC0B0B0F),
                                  ],
                                  stops: [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                            // Tap whole card to open info
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => widget.onInfo(item),
                                ),
                              ),
                            ),
                            // Bottom Title & Actions inside artwork
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 12,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        BannerTitleLogo(
                                          item: item,
                                          align: TextAlign.left,
                                          maxHeight: 34,
                                          maxWidthFactor: 0.85,
                                          fontSize: 20,
                                          onTap: () => widget.onInfo(item),
                                        ),
                                        const SizedBox(height: 4),
                                        BannerMetaLine(
                                          metaFuture: widget.meta?.call(item),
                                          reading: widget.reading,
                                          align: TextAlign.left,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Minimalist actions
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => widget.onPlay(item),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                widget.reading
                                                    ? Icons.menu_book_rounded
                                                    : Icons.play_arrow_rounded,
                                                color: AppColors.bg,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                widget.reading ? 'Read' : 'Play',
                                                style: TextStyle(
                                                  color: AppColors.bg,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      BannerCircleButton(
                                        icon: inList
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                        active: inList,
                                        size: 36,
                                        onTap: () => widget.onToggleList(item),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dot indicators at bottom
              if (_count > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_count, (i) {
                      final sel = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: sel ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
