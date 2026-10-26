import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Palette ──
  static const Color primary = Color(0xFF1A1F2E);
  static const Color primaryDark = Color(0xFF141821);
  static const Color primaryLight = Color(0xFF252B3B);

  // ── Brand accent: shared by splash and all yellow UI accents ──
  static const Color accent = Color(0xFFFDBA00);
  static const Color accentPressed = Color(0xFFD99F00);
  static const Color accentLight = Color(0xFFFFCD4D);
  static const Color accentSoft = Color(0xFFFEF3C7);

  // Secondary brand accent for discovery and preference selections.
  static const Color discovery = Color(0xFF7756C5);

  // ── Backgrounds ──
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Colors.white;
  static const Color textOnDarkMuted = Color(0xB3FFFFFF); // 70% white

  // ── UI Elements ──
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color cardShadow = Color(0x14000000);

  // ── Semantic ──
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // ── Navigation ──
  static const Color navActive = Color(0xFF1A1F2E);
  static const Color navInactive = Color(0xFF9CA3AF);

  // ── Legacy aliases (backward compat) ──
  static const Color secondary = accent;
}
