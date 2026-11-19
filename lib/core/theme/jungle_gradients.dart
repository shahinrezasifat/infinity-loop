import 'package:material_ui/material_ui.dart';

/// Jungle theme gradient definitions.
class JungleGradients {
  // Primary Gradient (Forest Green)
  static const LinearGradient primary = LinearGradient(
    colors: [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
      Color(0xFF4CAF50),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary Gradient (Earth Brown)
  static const LinearGradient secondary = LinearGradient(
    colors: [
      Color(0xFF5D4037),
      Color(0xFF795548),
      Color(0xFF8D6E63),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background Gradient (Light Mint)
  static const LinearGradient background = LinearGradient(
    colors: [
      Color(0xFFF1F8E9),
      Color(0xFFE8F5E9),
      Color(0xFFDCEDC8),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Card Gradient
  static const LinearGradient card = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF1F8E9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Button Gradient
  static const LinearGradient button = LinearGradient(
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Button Dark Gradient
  static const LinearGradient buttonDark = LinearGradient(
    colors: [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Gradient (Primary)
  static final TextStyle textPrimary = TextStyle(
    foreground: Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF1B5E20),
          Color(0xFF2E7D32),
        ],
      ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 50.0)),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // Text Gradient (Secondary)
  static final TextStyle textSecondary = TextStyle(
    foreground: Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF4CAF50),
          Color(0xFF81C784),
        ],
      ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 50.0)),
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
  );

  // Accented Gradient (Amber)
  static const LinearGradient accented = LinearGradient(
    colors: [
      Color(0xFFFFC107),
      Color(0xFFFFB300),
      Color(0xFFFF9800),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Gradient (Surface)
  static const LinearGradient darkBackground = LinearGradient(
    colors: [
      Color(0xFF121212),
      Color(0xFF1E1E1E),
      Color(0xFF2D2D2D),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark Card Gradient
  static const LinearGradient darkCard = LinearGradient(
    colors: [
      Color(0xFF1E1E1E),
      Color(0xFF2D2D2D),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Organic Gradient (Leaf Shape)
  static const LinearGradient organic = LinearGradient(
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF4CAF50),
      Color(0xFF81C784),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Organic Dark Gradient
  static const LinearGradient organicDark = LinearGradient(
    colors: [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
      Color(0xFF4CAF50),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Helper class for applying gradients.
class GradientHelper {
  /// Get a box decoration with a gradient.
  static BoxDecoration gradientBox({
    required Gradient gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: boxShadow,
    );
  }

  /// Get a container with a gradient background.
  static Container gradientContainer({
    required Widget child,
    required Gradient gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? padding,
    double? height,
    double? width,
  }) {
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }

  /// Get a linear gradient shader.
  static Shader? getLinearShader(
    List<Color> colors,
    Rect bounds,
  ) {
    return LinearGradient(colors: colors).createShader(bounds);
  }
}
