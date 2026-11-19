import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../core/ui/splash_style.dart';

class WordmarkSplash extends StatefulWidget {
  const WordmarkSplash({super.key});

  static const duration = Duration(milliseconds: 3600);
  static const background = Color(0xFF0B0B0F);

  @override
  State<WordmarkSplash> createState() => _WordmarkSplashState();
}

class _WordmarkSplashState extends State<WordmarkSplash>
    with TickerProviderStateMixin {
  /// Controls the initial entrance: black delay -> gradient sweep reveal.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1650),
  );

  /// Seamlessly flows the signature multi-stop gradient across the letters.
  late final AnimationController _flowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  /// Infinite breathing loop: pulses glow between extreme bloom and reduced glow.
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    _flowController.repeat();
    _entranceController.forward();
    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _glowController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _flowController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Creates a continuous, perfectly seamless gradient shader that shifts
  /// across the wordmark letters without any seam or discontinuity.
  Shader _createFlowShader(Rect bounds, double flow) {
    // Shifting by exactly one cycle (2.4 units out of total span 4.8)
    // guarantees that flow=0.0 and flow=1.0 are mathematically identical.
    final shift = -flow * 2.4;
    return LinearGradient(
      begin: Alignment(shift - 1.2, -0.15),
      end: Alignment(shift + 3.6, 0.15),
      colors: const [
        Color(0xFF36D99A), // Mint / Emerald Teal
        Color(0xFF39A9FF), // Electric Sky Blue
        Color(0xFF7BE65B), // Neon Lime Green
        Color(0xFF39A9FF), // Electric Sky Blue
        Color(0xFF36D99A), // Mint / Emerald Teal
        Color(0xFF39A9FF), // Electric Sky Blue
        Color(0xFF7BE65B), // Neon Lime Green
        Color(0xFF39A9FF), // Electric Sky Blue
        Color(0xFF36D99A), // Mint / Emerald Teal
      ],
      stops: const [
        0.0,
        0.125,
        0.25,
        0.375,
        0.5,
        0.625,
        0.75,
        0.875,
        1.0,
      ],
    ).createShader(bounds);
  }

  bool get _isSquare {
    final style = SplashStyle.selectedId;
    return style == 'bankai' || style == 'custom';
  }

  double get _aspectRatio {
    return _isSquare ? 1.0 : (2222 / 959);
  }

  Widget _buildLogoImage() {
    final style = SplashStyle.selectedId;
    final customPath = SplashStyle.customImagePath;
    if (style == 'custom' && customPath != null && File(customPath).existsSync()) {
      return Image.file(
        File(customPath),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
    if (style == 'bankai') {
      return Image.asset(
        'assets/icon/app_icon.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
    return Image.asset(
      'assets/icon/wordmark.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }

  /// Wordmark or custom logo colored exclusively with the flowing gradient (no black).
  Widget _gradientWordmark(double flow) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (bounds) => _createFlowShader(bounds, flow),
    child: _buildLogoImage(),
  );

  /// Reveals the flowing gradient from left to right as the gradient enters.
  /// Behind the reveal line: pure vibrant gradient (no black).
  /// Once reveal reaches 1.0: 100% revealed permanently (no mask).
  Widget _revealedWordmark({
    required double flow,
    required double reveal,
  }) {
    final base = _gradientWordmark(flow);
    if (reveal >= 1.0) return base;
    if (reveal <= 0.0) return const SizedBox.shrink();

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        const feather = 0.14;
        final edge = reveal * (1.0 + feather);
        final start = (edge - feather).clamp(0.0, 1.0);
        final end = edge.clamp(0.0, 1.0);

        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.white,
            Colors.white,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [
            0.0,
            start,
            end,
            1.0,
          ],
        ).createShader(bounds);
      },
      child: base,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WordmarkSplash.background,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final isSquare = _isSquare;
        final width = math.min(
          constraints.maxWidth * (isSquare ? 0.62 : 0.82),
          isSquare ? 240.0 : 360.0,
        );
        return Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _flowController,
              _glowController,
            ]),
            builder: (context, _) {
              final entranceProgress = _entranceController.value;

              // Phase 1: Pure black delay (~380ms)
              // Phase 2: Gradient enters from left to right (~380ms to 1650ms)
              final reveal = entranceProgress < 0.23
                  ? 0.0
                  : Curves.easeInOutCubic.transform(
                      ((entranceProgress - 0.23) / 0.77).clamp(0.0, 1.0),
                    );

              final flow = _flowController.value;

              // Breathing pulse:
              // - Starts at 1.0 (extreme bloom) during entrance.
              // - After entrance finishes, breathes between 0.52 and 1.0.
              // - Never drops to 0 ("একবারে নাই হয়ে যাবে না").
              // - Reaches peak extreme ("অনেক এক্সট্রিম হবে") and eases slightly ("আর একটু কমবে").
              final breathing = 0.52 +
                  (0.48 *
                      Curves.easeInOutSine.transform(_glowController.value));
              final glowFactor = entranceProgress < 1.0 ? 1.0 : breathing;

              return SizedBox(
                width: width,
                child: AspectRatio(
                  aspectRatio: _aspectRatio,
                  child: _buildLayers(
                    reveal: reveal,
                    flow: flow,
                    glowFactor: glowFactor,
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );

  Widget _buildLayers({
    required double reveal,
    required double flow,
    required double glowFactor,
  }) {
    if (reveal <= 0.0) {
      return const SizedBox.shrink();
    }

    final wordmark = _revealedWordmark(
      reveal: reveal,
      flow: flow,
    );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // 1. Wide ambient halo (dispersed glow across the background)
        Opacity(
          opacity: (0.65 * glowFactor).clamp(0.0, 1.0),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 52, sigmaY: 52),
            child: wordmark,
          ),
        ),
        // 2. Mid-range vivid aura (neon glow around the letters)
        Opacity(
          opacity: (0.85 * glowFactor).clamp(0.0, 1.0),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: wordmark,
          ),
        ),
        // 3. Tight intense neon core (intense edge bloom)
        Opacity(
          opacity: (0.95 * glowFactor).clamp(0.0, 1.0),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: wordmark,
          ),
        ),
        // 4. Sharp, crisp foreground wordmark
        wordmark,
      ],
    );
  }
}
