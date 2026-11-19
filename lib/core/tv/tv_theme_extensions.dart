import 'package:material_ui/material_ui.dart';
import '../theme/jungle_theme.dart';
import '../theme/jungle_gradients.dart';

/// TV-focused theme extensions.
class TVTheme {
  /// Get TV-focused theme data.
  static ThemeData get tv {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: JungleColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.black,
        elevation: 0,
        shape: CircularNotchedRectangle(),
      ),
      cardTheme: CardThemeData(
        color: JungleColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: JungleColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 4,
          textStyle: JungleTypography.labelLarge.copyWith(fontSize: 20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: JungleColors.primaryLight,
          textStyle: JungleTypography.labelLarge.copyWith(fontSize: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black87,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: JungleColors.primary, width: 4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: JungleTypography.bodyMedium.copyWith(color: Colors.white60),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.black87,
        selectedColor: JungleColors.primary,
        labelStyle: JungleTypography.labelLarge.copyWith(fontSize: 18),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        titleTextStyle: JungleTypography.titleLarge.copyWith(fontSize: 22),
        subtitleTextStyle: JungleTypography.bodyMedium.copyWith(fontSize: 18),
        iconColor: JungleColors.primary,
        textColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: JungleColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: JungleTypography.displayLarge.copyWith(fontSize: 57),
        displayMedium: JungleTypography.displayMedium.copyWith(fontSize: 45),
        displaySmall: JungleTypography.displaySmall.copyWith(fontSize: 36),
        headlineLarge: JungleTypography.headlineLarge.copyWith(fontSize: 32),
        headlineMedium: JungleTypography.headlineMedium.copyWith(fontSize: 28),
        headlineSmall: JungleTypography.headlineSmall.copyWith(fontSize: 24),
        titleLarge: JungleTypography.titleLarge.copyWith(fontSize: 22),
        titleMedium: JungleTypography.titleMedium.copyWith(fontSize: 16),
        titleSmall: JungleTypography.titleSmall.copyWith(fontSize: 14),
        bodyLarge: JungleTypography.bodyLarge.copyWith(fontSize: 18),
        bodyMedium: JungleTypography.bodyMedium.copyWith(fontSize: 16),
        bodySmall: JungleTypography.bodySmall.copyWith(fontSize: 14),
        labelLarge: JungleTypography.labelLarge.copyWith(fontSize: 18),
        labelMedium: JungleTypography.labelMedium.copyWith(fontSize: 16),
        labelSmall: JungleTypography.labelSmall.copyWith(fontSize: 14),
      ),
    );
  }

  /// Get TV-focused focus state.
  static BoxDecoration focusState(Color focusColor) {
    return BoxDecoration(
      border: Border.all(
        color: focusColor,
        width: 4,
      ),
      boxShadow: [
        BoxShadow(
          color: focusColor.withValues(alpha: 0.3),
          blurRadius: 16,
          spreadRadius: 8,
        ),
      ],
    );
  }

  /// Get TV-focused card style.
  static BoxDecoration cardStyle() {
    return BoxDecoration(
      gradient: JungleGradients.card,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Get TV-focused button style.
  static ElevatedButtonThemeData buttonStyle() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: JungleColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 4,
        textStyle: JungleTypography.labelLarge.copyWith(fontSize: 20),
      ),
    );
  }

  /// Get TV-focused text style.
  static TextStyle textStyle(
    String text, {
    double fontSize = 18,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      color: color ?? Colors.white,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.2,
    );
  }
}

/// TV screen size constants.
class TVScreenSize {
  static const double minWidth = 1280;
  static const double minHeight = 720;
  static const double optimalWidth = 1920;
  static const double optimalHeight = 1080;
  static const double padding = 48;
  static const double spacing = 32;
}

/// TV focus animation constants.
class TVFocusAnimation {
  static const Duration focusDuration = Duration(milliseconds: 200);
  static const Duration pressDuration = Duration(milliseconds: 100);
  static const Curve focusCurve = Curves.easeOut;
  static const Curve pressCurve = Curves.easeInOut;
}
