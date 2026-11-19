import 'package:material_ui/material_ui.dart';

/// Jungle theme color palette with forest greens and earthy tones.
class JungleColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32); // Forest Green
  static const Color primaryLight = Color(0xFF4CAF50); // Light Green
  static const Color primaryDark = Color(0xFF1B5E20); // Dark Forest Green
  static const Color secondary = Color(0xFF795548); // Earth Brown

  // Accent Colors
  static const Color accent = Color(0xFFFFC107); // Warm Amber
  static const Color accentLight = Color(0xFFFFE082);
  static const Color accentDark = Color(0xFFFFB300);

  // Background Colors
  static const Color background = Color(0xFFF1F8E9); // Light Mint
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color cardBackground = Color(0xFFE8F5E9); // Very Light Green

  // Text Colors
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF6B9C6D);
  static const Color textLight = Color(0xFF9E9E9E);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Gradient Colors
  static const Color gradientStart = Color(0xFF1B5E20);
  static const Color gradientMiddle = Color(0xFF2E7D32);
  static const Color gradientEnd = Color(0xFF4CAF50);
}

/// Jungle theme typography configuration.
class JungleTypography {
  // Display Text
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: JungleColors.textPrimary,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: JungleColors.textPrimary,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: JungleColors.textPrimary,
    height: 1.22,
  );

  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: JungleColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: JungleColors.textPrimary,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: JungleColors.textPrimary,
    height: 1.33,
  );

  // Title Text
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: JungleColors.textPrimary,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: JungleColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: JungleColors.textPrimary,
    height: 1.43,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: JungleColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: JungleColors.textPrimary,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: JungleColors.textSecondary,
    height: 1.33,
  );

  // Label Text
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: JungleColors.textPrimary,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: JungleColors.textPrimary,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: JungleColors.textPrimary,
    height: 1.45,
  );
}

/// Jungle theme configuration.
class JungleThemeConfig {
  final bool isDark;
  final double scaleFactor;
  final double textScaleFactor;

  const JungleThemeConfig({
    this.isDark = false,
    this.scaleFactor = 1.0,
    this.textScaleFactor = 1.0,
  });

  /// Create jungle theme config.
  static JungleThemeConfig light() {
    return const JungleThemeConfig(
      isDark: false,
      scaleFactor: 1.0,
      textScaleFactor: 1.0,
    );
  }

  /// Create jungle theme config dark mode.
  static JungleThemeConfig dark() {
    return const JungleThemeConfig(
      isDark: true,
      scaleFactor: 1.0,
      textScaleFactor: 1.0,
    );
  }

  /// Copy with updated values.
  JungleThemeConfig copyWith({
    bool? isDark,
    double? scaleFactor,
    double? textScaleFactor,
  }) {
    return JungleThemeConfig(
      isDark: isDark ?? this.isDark,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }

  /// Convert to boolean.
  bool get isDarkMode => isDark;

  /// Get theme mode name.
  String get modeName => isDark ? 'Dark' : 'Light';
}
