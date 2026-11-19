import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/media_item.dart';
import '../theme/app_colors.dart';
import 'banner_actions.dart';
import 'featured_carousel.dart' show heroHeightFor;
import 'featured_hero.dart' show HeroMeta;
import 'image_fade.dart' show imageFadeIn;
import 'native_cover_provider.dart' show nativeCoverProvider;

/// The "Cinema" Home banner: full-bleed edge-to-edge cinematic canvas.
///
/// Artwork stretches across the entire screen width with gentle Ken-Burns zoom,
/// deep bottom vignette melting into the page, and floating minimalist actions.
class FeaturedBannerCinema extends StatefulWidget {
  const FeaturedBannerCinema({
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
  State<FeaturedBannerCinema> createState() => _FeaturedBannerCinemaState();
}

class _FeaturedBannerCinemaState extends State<FeaturedBannerCinema>
    with SingleTickerProviderStateMixin {
  late List<MediaItem> _pages;
  int _index = 0;
  Timer? _timer;

  late final AnimationController _zoomCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..forward();

  int get _count => _pages.length;
  MediaItem get _current => _pages[_index];

  @override
  void initState() {
    super.initState();
    _pages = widget.items.take(6).toList();
    _startTimer();
  }

  @override
  void didUpdateWidget(FeaturedBannerCinema old) {
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
    _zoomCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_count > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) => _advance(1));
    }
  }

  void _advance(int delta) {
    if (!mounted || _count <= 1) return;
    setState(() {
      _index = (_index + delta) % _count;
      if (_index < 0) _index += _count;
    });
    _zoomCtrl.forward(from: 0.0);
  }

  static String? _art(MediaItem m) => m.banner ?? m.cover;

  Widget _cinemaImage(MediaItem item) {
    final url = _art(item);
    if (url == null || url.isEmpty) {
      return ColoredBox(color: AppColors.surface);
    }
    return AnimatedBuilder(
      animation: _zoomCtrl,
      builder: (context, _) {
        final scale = 1.0 + (_zoomCtrl.value * 0.06);
        return Transform.scale(
          scale: scale,
          child: Image(
            image: nativeCoverProvider(url, item.coverHeaders),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            frameBuilder: imageFadeIn,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = heroHeightFor(context);
    if (_count == 0) return SizedBox(height: height);

    final item = _current;
    final inList = widget.inList(item);

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
                // Full-bleed artwork with crossfade
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('cinema_art_${item.id}'),
                    child: SizedBox.expand(child: _cinemaImage(item)),
                  ),
                ),

              // Deep cinematic multi-stop vignette
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x88000000),
                      Colors.transparent,
                      Color(0x550B0B0F),
                      Color(0xDF0B0B0F),
                      Color(0xFF0B0B0F),
                    ],
                    stops: [0.0, 0.28, 0.58, 0.85, 1.0],
                  ),
                ),
              ),

              // Side vignettes for widescreen immersion
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x44000000),
                      Colors.transparent,
                      Color(0x44000000),
                    ],
                    stops: [0.0, 0.25, 1.0],
                  ),
                ),
              ),

              // Tap whole hero to open info
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onInfo(item),
                  ),
                ),
              ),

              // Bottom details and actions
              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    key: ValueKey('cinema_details_${item.id}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BannerTitleLogo(
                        item: item,
                        align: TextAlign.left,
                        maxHeight: 44,
                        maxWidthFactor: 0.85,
                        fontSize: 24,
                        onTap: () => widget.onInfo(item),
                      ),
                      const SizedBox(height: 6),
                      BannerMetaLine(
                        metaFuture: widget.meta?.call(item),
                        reading: widget.reading,
                        align: TextAlign.left,
                      ),
                      const SizedBox(height: 14),

                      // Minimalist actions
                      Row(
                        children: [
                          // Primary Play Button
                          GestureDetector(
                            onTap: () => widget.onPlay(item),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(19),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
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
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.reading ? 'Read' : 'Play',
                                    style: TextStyle(
                                      color: AppColors.bg,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          BannerCircleButton(
                            icon: inList ? Icons.check_rounded : Icons.add_rounded,
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
              ),

              // Sleek progress bar indicator at bottom
              if (_count > 1)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 6,
                  child: Row(
                    children: List.generate(_count, (i) {
                      final sel = i == _index;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
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
