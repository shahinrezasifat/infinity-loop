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

/// The "Glass" Home banner: frosted acrylic glassmorphism card.
///
/// Features an Apple VisionOS-inspired floating acrylic glass panel
/// with specular highlight borders and subtle glowing aura.
class FeaturedBannerGlass extends StatefulWidget {
  const FeaturedBannerGlass({
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
  State<FeaturedBannerGlass> createState() => _FeaturedBannerGlassState();
}

class _FeaturedBannerGlassState extends State<FeaturedBannerGlass> {
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
  void didUpdateWidget(FeaturedBannerGlass old) {
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

  Widget _cardImage(MediaItem item) {
    final url = _art(item);
    if (url == null || url.isEmpty) {
      return ColoredBox(color: AppColors.surface);
    }
    return Image(
      image: nativeCoverProvider(url, item.coverHeaders),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
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
                // Inset container below top reserve
              Positioned(
                top: topReserve,
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Artwork with transition
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, ?current],
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('glass_art_${item.id}'),
                          child: SizedBox.expand(child: _cardImage(item)),
                        ),
                      ),

                      // Gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x55000000),
                              Colors.transparent,
                              Color(0x99000000),
                            ],
                            stops: [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // Floating Frosted Glass Acrylic Panel at bottom
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.24),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left: Title Logo & Meta
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        BannerTitleLogo(
                                          item: item,
                                          align: TextAlign.left,
                                          maxHeight: 32,
                                          maxWidthFactor: 0.8,
                                          fontSize: 18,
                                          onTap: () => widget.onInfo(item),
                                        ),
                                        const SizedBox(height: 3),
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

                                  // Right: Frosted Action Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Glowing Play button
                                      GestureDetector(
                                        onTap: () => widget.onPlay(item),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 12,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            widget.reading
                                                ? Icons.menu_book_rounded
                                                : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 22,
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
                                      const SizedBox(width: 6),
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
                          ),
                        ),
                      ),
                    ],
                  ),
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
