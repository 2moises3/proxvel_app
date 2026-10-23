import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text_styles.dart';

// ──────────────────────────────────────────────────────────
//  PROXVEL — Sistema tipográfico
//
//  Todo → Poppins (geométrica, redondeada, premium)
//
//  USO:
//   • No hace falta especificar fontFamily en ningún widget.
//   • Para un texto con parámetros custom: AppTheme.text(...)
// ──────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  /// Acceso rápido a Poppins con parámetros custom.
  static TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacing = 0,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  // ── TextTheme completo en Poppins ──
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    TextStyle on(TextStyle style) => style.copyWith(color: primaryColor);
    return GoogleFonts.poppinsTextTheme(
      TextTheme(
        displayLarge: on(AppTextStyles.headingOnDark),
        displayMedium: on(AppTextStyles.headingOnDark),
        displaySmall: on(AppTextStyles.headingOnDark),
        headlineLarge: on(AppTextStyles.h1),
        headlineMedium: on(AppTextStyles.h1),
        headlineSmall: on(AppTextStyles.h2),
        titleLarge: on(AppTextStyles.sectionTitle),
        titleMedium: on(AppTextStyles.cardTitle),
        titleSmall: on(AppTextStyles.label),
        bodyLarge: on(AppTextStyles.body1),
        bodyMedium: on(AppTextStyles.body1),
        bodySmall: AppTextStyles.body2.copyWith(color: secondaryColor),
        labelLarge: on(AppTextStyles.button),
        labelMedium: on(AppTextStyles.labelSmall),
        labelSmall: AppTextStyles.caption.copyWith(color: secondaryColor),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Tema claro
  // ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      AppColors.textPrimary,
      AppColors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textOnDark,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(AppSizing.touchTarget, AppSizing.button),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.card,
            vertical: AppSpace.field,
          ),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizing.touchTarget, AppSizing.touchTarget),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(AppSizing.touchTarget, AppSizing.button),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.card,
            vertical: AppSpace.field,
          ),
          side: const BorderSide(color: AppColors.border),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.error,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpace.field),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(AppSizing.touchTarget, AppSizing.button),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.card,
            vertical: AppSpace.field,
          ),
          textStyle: GoogleFonts.poppins(textStyle: AppTextStyles.button),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: GoogleFonts.poppins(
          textStyle: AppTextStyles.sectionTitle,
        ),
        contentTextStyle: GoogleFonts.poppins(textStyle: AppTextStyles.body1),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        shape: Border(),
        collapsedShape: Border(),
        childrenPadding: EdgeInsets.only(bottom: AppSpace.field),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.accentSoft,
        labelStyle: GoogleFonts.poppins(textStyle: AppTextStyles.labelSmall),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      cardTheme: CardThemeData(
        surfaceTintColor: Colors.transparent,
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Tema oscuro
  // ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
      AppColors.textOnDark,
      AppColors.textOnDarkMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.primaryDark,
      textTheme: textTheme,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),

      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.primaryLight,
        error: AppColors.error,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textOnDark,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(AppSizing.touchTarget, AppSizing.button),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.card,
            vertical: AppSpace.field,
          ),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        surfaceTintColor: Colors.transparent,
        color: AppColors.primaryLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
