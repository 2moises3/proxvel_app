import 'package:flutter/material.dart';

/// The single text family used throughout PROXVEL, bundled for offline use.
abstract final class AppTypography {
  static const family = 'Outfit';

  static TextTheme textTheme(TextTheme theme) =>
      theme.apply(fontFamily: family);

  static TextStyle style({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    List<Shadow>? shadows,
  }) => (textStyle ?? const TextStyle()).copyWith(
    fontFamily: family,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
    shadows: shadows,
  );
}
