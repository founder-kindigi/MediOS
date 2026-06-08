import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color onPrimary = Colors.white;

  // Secondary / Accent
  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark = Color(0xFF005B4F);
  static const Color onSecondary = Colors.white;

  // Surface hierarchy
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceContainer = Color(0xFFF0F2F5);
  static const Color surfaceVariant = Color(0xFFE8EAF0);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Color(0xFFF3F4F6);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Neutrals
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF0F0F0);

  // Chart palette
  static const List<Color> chartColors = [
    Color(0xFF1565C0),
    Color(0xFF00897B),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
  ];

  // Overlay
  static Color get scaffoldOverlay => Colors.black.withValues(alpha: 0.05);
  static Color get shimmerBase => const Color(0xFFE5E7EB);
  static Color get shimmerHighlight => const Color(0xFFF3F4F6);
}
