import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../models/media_item.dart';
import '../theme/app_colors.dart';
import 'banner_actions.dart';
import 'featured_carousel.dart' show heroHeightFor;
import 'featured_hero.dart' show HeroMeta, heroTopReserve;
import 'image_fade.dart' show imageFadeIn;
import 'native_cover_provider.dart' show nativeCoverProvider;

/// The "Showcase" Home banner: portrait poster + title & synopsis over ambient blur.
///
/// Features a prominent vertical media poster on the left with score badge,
/// detailed metadata and actions on the right, set against a blurred cinematic backdrop.
class FeaturedBannerShowcase extends StatefulWidget {
  const FeaturedBannerShowcase({
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
  State<FeaturedBannerShowcase> createState() => _FeaturedBannerShowcaseState();
}

class _FeaturedBannerShowcaseState extends State<FeaturedBannerShowcase> {
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
  void didUpdateWidget(FeaturedBannerShowcase old) {
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
      _timer = Timer.periodic(const Duration(milliseconds: 5500), (_) => _advance(1));
    }
  }

  void _advance(int delta) {
    if (!mounted || _count <= 1) return;
    setState(() {
      _index = (_index + delta) % _count;
      if (_index < 0) _index += _count;
    });
  }

  static String? _coverArt(MediaItem m) => m.cover ?? m.banner;
  static String? _backdropArt(MediaItem m) => m.banner ?? m.cover;

  Widget _ambientBackdrop(MediaItem item) {
    final url = _backdropArt(item);
    if (url == null || url.isEmpty) {
      return ColoredBox(color: AppColors.bg);
    }
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: AppColors.bg),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Transform.scale(
              scale: 1.25,
              child: Image(
                image: nativeCoverProvider(url, item.coverHeaders),
                fit: BoxFit.cover,
                frameBuilder: imageFadeIn,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.50),
                  Colors.black.withValues(alpha: 0.65),
                  AppColors.bg.withValues(alpha: 0.88),
                  AppColors.bg,
                ],
                stops: const [0.0, 0.48, 0.85, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _poster(MediaItem item) {
    final url = _coverArt(item);
    final score = item.score;

    return GestureDetector(
      onTap: () => widget.onInfo(item),
      child: Container(
        width: 122,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null && url.isNotEmpty)
              Image(
                image: nativeCoverProvider(url, item.coverHeaders),
                fit: BoxFit.cover,
                frameBuilder: imageFadeIn,
              )
            else
              ColoredBox(color: AppColors.surface2),

            // Score badge
            if (score != null && score > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
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
                        (score / 10).toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
                // Ambient blurred backdrop
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 650),
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('showcase_bg_${item.id}'),
                    child: _ambientBackdrop(item),
                  ),
                ),

                // Foreground content: Poster + Details
                Positioned(
                  top: topReserve + 10,
                  left: 18,
                  right: 18,
                  bottom: 26,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: KeyedSubtree(
                      key: ValueKey('showcase_row_${item.id}'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _poster(item),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(alpha: 0.45),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    widget.reading ? 'FEATURED' : 'TRENDING',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Title Logo or Text
                                BannerTitleLogo(
                                  item: item,
                                  align: TextAlign.left,
                                  maxHeight: 38,
                                  maxWidthFactor: 0.95,
                                  fontSize: 20,
                                  onTap: () => widget.onInfo(item),
                                ),
                                const SizedBox(height: 6),

                                // Meta line (genres, year, etc.)
                                BannerMetaLine(
                                  metaFuture: widget.meta?.call(item),
                                  reading: widget.reading,
                                  align: TextAlign.left,
                                  compact: true,
                                ),
                                const SizedBox(height: 14),

                                // Action buttons
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => widget.onPlay(item),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius: BorderRadius.circular(19),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 10,
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
                                              color: Colors.white,
                                              size: 19,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              widget.reading ? 'Read' : 'Play',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    BannerCircleButton(
                                      icon: inList
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      active: inList,
                                      size: 38,
                                      onTap: () => widget.onToggleList(item),
                                    ),
                                    const SizedBox(width: 8),
                                    BannerCircleButton(
                                      icon: Icons.info_outline_rounded,
                                      size: 38,
                                      onTap: () => widget.onInfo(item),
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
                ),

                // Dot indicators at bottom
                if (_count > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_count, (i) {
                        final sel = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: sel ? 18 : 5,
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
