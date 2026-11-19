import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/media_item.dart';
import '../theme/app_colors.dart';
import 'banner_actions.dart';
import 'featured_carousel.dart' show heroHeightFor;
import 'featured_hero.dart' show HeroMeta, heroTopReserve;
import 'image_fade.dart' show imageFadeIn;
import 'native_cover_provider.dart' show nativeCoverProvider;

/// The "Spotlight" Home banner: modern streaming cards with peek sides.
///
/// The centre card is elevated and featured, while the neighbouring cards
/// peek in from the edges at a scaled-down depth.
class FeaturedBannerSpotlight extends StatefulWidget {
  const FeaturedBannerSpotlight({
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
  State<FeaturedBannerSpotlight> createState() => _FeaturedBannerSpotlightState();
}

class _FeaturedBannerSpotlightState extends State<FeaturedBannerSpotlight> {
  static const int _virtualBase = 600;

  late List<MediaItem> _pages;
  late final PageController _pc;
  int _index = 0;
  Timer? _timer;

  int get _count => _pages.length;
  int get _startIndex =>
      _count > 1 ? _virtualBase - (_virtualBase % _count) : 0;
  int get _realIndex => _count > 0 ? _index % _count : 0;

  @override
  void initState() {
    super.initState();
    _pages = widget.items.take(6).toList();
    _index = _startIndex;
    _pc = PageController(
      initialPage: _index,
      viewportFraction: 0.86,
    );
    _startTimer();
  }

  @override
  void didUpdateWidget(FeaturedBannerSpotlight old) {
    super.didUpdateWidget(old);
    final next = widget.items.take(6).toList();
    final changed = next.length != _pages.length ||
        (next.isNotEmpty &&
            _pages.isNotEmpty &&
            next.first.id != _pages.first.id);
    if (changed) {
      setState(() {
        _pages = next;
        _index = _count > 1 ? _startIndex : 0;
      });
      if (_pc.hasClients) _pc.jumpToPage(_index);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_count > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _advance());
    }
  }

  void _advance() {
    if (!mounted || !_pc.hasClients) return;
    _pc.nextPage(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
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
      frameBuilder: imageFadeIn,
    );
  }

  Widget _buildCard(MediaItem item, double off) {
    final scale = (1.0 - off.abs() * 0.08).clamp(0.90, 1.0);
    final opacity = (1.0 - off.abs() * 0.35).clamp(0.65, 1.0);
    final inList = widget.inList(item);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Artwork
              _cardImage(item),

              // Gradient Scrim
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Color(0xDD0B0B0F),
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Tap whole card to view info
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
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BannerTitleLogo(
                      item: item,
                      maxHeight: 38,
                      maxWidthFactor: 0.85,
                      fontSize: 22,
                      onTap: () => widget.onInfo(item),
                    ),
                    const SizedBox(height: 5),
                    BannerMetaLine(
                      metaFuture: widget.meta?.call(item),
                      reading: widget.reading,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Primary Play / Read button
                        GestureDetector(
                          onTap: () => widget.onPlay(item),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
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
                                  color: AppColors.bg,
                                  size: 19,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.reading ? 'Read' : 'Play',
                                  style: TextStyle(
                                    color: AppColors.bg,
                                    fontSize: 13.5,
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
                          size: 36,
                          onTap: () => widget.onToggleList(item),
                        ),
                        const SizedBox(width: 8),
                        BannerCircleButton(
                          icon: Icons.info_outline_rounded,
                          size: 36,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = heroHeightFor(context);
    if (_count == 0) return SizedBox(height: height);

    final topReserve = heroTopReserve(MediaQuery.paddingOf(context).top);

    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              ColoredBox(color: AppColors.bg),
              // Pager positioned below header room
            Positioned(
              top: topReserve,
              left: 0,
              right: 0,
              bottom: 22,
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return AnimatedBuilder(
                    animation: _pc,
                    builder: (context, _) {
                      var off = 0.0;
                      if (_pc.hasClients && _pc.position.haveDimensions) {
                        off = (_pc.page ?? _index.toDouble()) - i;
                      }
                      return _buildCard(_pages[i % _count], off.clamp(-1.0, 1.0));
                    },
                  );
                },
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
                    final sel = i == _realIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: sel ? 18 : 6,
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
  );
}
}
