import 'package:flutter/material.dart';

/// Brand and story accent colors aligned with the FOCUSMITH design mock.
abstract final class AppColors {
  static const Color background = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF14141A);
  static const Color surfaceElevated = Color(0xFF1C1C24);
  static const Color border = Color(0xFF2A2A35);
  static const Color borderActive = Color(0xFF7C3AED);
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color info = Color(0xFF3B82F6);

  static const int purple = 0xFF8B5CF6;
  static const int green = 0xFF22C55E;
  static const int yellow = 0xFFEAB308;
  static const int blue = 0xFF3B82F6;

  static Color fromInt(int value) => Color(value);

  static const List<int> storyPalette = [purple, green, yellow, blue, purple];
}
