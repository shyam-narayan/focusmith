import 'package:fluent_ui/fluent_ui.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

/// Fluent UI theme aligned with the FOCUSMITH purple design mock.
class AppTheme {
  static AccentColor get accentColor => AccentColor.swatch({
        'darkest': const Color(0xFF4C1D95),
        'darker': const Color(0xFF5B21B6),
        'dark': const Color(0xFF6D28D9),
        'normal': AppColors.accent,
        'light': AppColors.accentLight,
        'lighter': const Color(0xFFC4B5FD),
        'lightest': const Color(0xFFEDE9FE),
      });

  static FluentThemeData get darkTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      fontFamily: AppFonts.family,
      accentColor: accentColor,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surfaceElevated,
      menuColor: AppColors.surface,
      acrylicBackgroundColor: AppColors.surface.withValues(alpha: 0.92),
      micaBackgroundColor: AppColors.background,
      activeColor: AppColors.accent,
      typography: const Typography.raw(
        body: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
        bodyStrong: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
        caption: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        subtitle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.textPrimary,
        ),
        title: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  static FluentThemeData get lightTheme {
    return FluentThemeData(
      brightness: Brightness.light,
      fontFamily: AppFonts.family,
      accentColor: accentColor,
      scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      cardColor: Colors.white,
      menuColor: const Color(0xFFF1EFF8),
      acrylicBackgroundColor: const Color(0xFFF1EFF8).withValues(alpha: 0.92),
      micaBackgroundColor: const Color(0xFFF8F7FC),
      activeColor: AppColors.accent,
      typography: const Typography.raw(
        body: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: Color(0xFF111827),
        ),
        bodyStrong: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.45,
          color: Color(0xFF111827),
        ),
        caption: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
        subtitle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: Color(0xFF111827),
        ),
        title: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: Color(0xFF111827),
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: Color(0xFF111827),
        ),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.08),
    );
  }
}
