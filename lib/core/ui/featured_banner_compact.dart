import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/media_item.dart';
import '../theme/app_colors.dart';
import 'banner_actions.dart';
import 'featured_hero.dart' show HeroMeta, heroTopReserve;
import 'image_fade.dart' show imageFadeIn;
import 'native_cover_provider.dart' show nativeCoverProvider;

/// The "Compact" Home banner: low-profile widescreen hero strip.
///
/// Designed for users who prefer faster access to Home rows without a massive
/// banner dominating the screen.
class FeaturedBannerCompact extends StatefulWidget {
  const FeaturedBannerCompact({
    super.key,
    required this.items,
    required this.onPlay,
    required this.onInfo,
    this.meta,
    this.reading = false,
  });

  final List<MediaItem> items;
  final void Function(MediaItem) onPlay;
  final void Function(MediaItem) onInfo;
  final Future<HeroMeta?> Function(MediaItem)? meta;
  final bool reading;

  @override
  State<FeaturedBannerCompact> createState() => _FeaturedBannerCompactState();
}

class _FeaturedBannerCompactState extends State<FeaturedBannerCompact> {
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
  void didUpdateWidget(FeaturedBannerCompact old) {
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

  Widget _bannerImage(MediaItem item) {
    final url = _art(item);
    if (url == null || url.isEmpty) {
      return ColoredBox(color: AppColors.surface2);
    }
    return Image(
      image: nativeCoverProvider(url, item.coverHeaders),
      fit: BoxFit.cover,
      frameBuilder: imageFadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();

    final item = _current;
    final topReserve = heroTopReserve(MediaQuery.paddingOf(context).top);

    return RepaintBoundary(
      child: ClipRect(
        child: Container(
          padding: EdgeInsets.fromLTRB(16, topReserve + 4, 16, 12),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Artwork with transition
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: KeyedSubtree(
                        key: ValueKey('compact_art_${item.id}'),
                        child: _bannerImage(item),
                      ),
                    ),

                    // Left-to-right fade scrim
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xF00B0B0F),
                            Color(0xCC0B0B0F),
                            Color(0x330B0B0F),
                          ],
                          stops: [0.0, 0.55, 1.0],
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

                    // Content
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 14,
                      bottom: 14,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Featured tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                BannerTitleLogo(
                                  item: item,
                                  align: TextAlign.left,
                                  maxHeight: 28,
                                  maxWidthFactor: 0.7,
                                  fontSize: 17,
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
                          // Big Play Button
                          GestureDetector(
                            onTap: () => widget.onPlay(item),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.45),
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
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mini Dots
              if (_count > 1) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_count, (i) {
                    final sel = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: sel ? 14 : 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent
                            : Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
}
