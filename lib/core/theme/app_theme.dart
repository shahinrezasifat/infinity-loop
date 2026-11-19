import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';
import 'app_text.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.dark(
    surface: AppColors.bg,
    primary: AppColors.accent,
    secondary: AppColors.accent,
    onPrimary: AppColors.textPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: AppText.fontFamily,
    fontFamilyFallback: AppText.fontFamilyFallback,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 0.5,
      space: 0.5,
    ),
  );
}
