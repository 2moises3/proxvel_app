import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Centralized text styles for consistent typography across the app.
class AppTextStyles {
  AppTextStyles._();

  // ── Headings ──
  static const TextStyle h1 = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Section ──
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Body ──
  static const TextStyle body1 = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ── Labels ──
  static const TextStyle label = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // ── Caption ──
  static const TextStyle caption = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // ── Button ──
  static const TextStyle button = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── On Dark ──
  static const TextStyle headingOnDark = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    height: 1.2,
  );

  static const TextStyle bodyOnDark = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnDarkMuted,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );

  static const TextStyle smallBody = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle smallLabel = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle mutedLabel = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textMuted,
  );

  static const TextStyle cardTitleOnDark = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Colors.white,
  );

  static const TextStyle h2OnDark = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textOnDark,
  );

  static const TextStyle sectionOnDark = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textOnDark,
  );
}
