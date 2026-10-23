import 'package:flutter/material.dart';

/// Ritmo compartido. El espacio expresa relación, no el tamaño del dispositivo.
abstract final class AppSpace {
  static const double micro = 4;
  static const double related = 8;
  static const double content = 12;
  static const double field = 16;
  static const double card = 20;
  static const double section = 24;
  static const double group = 32;
  static const double hero = 40;
  static const double screen = 24;
  static const pageInsets = EdgeInsets.symmetric(horizontal: screen);
}

abstract final class AppRadius {
  static const double chip = 12;
  static const double control = 16;
  static const double image = 16;
  static const double card = 20;
  static const double sheet = 28;
  static const double pill = 100;
}

abstract final class AppSizing {
  static const double touchTarget = 48;
  static const double button = 56;
  static const double icon = 20;
}

/// Movimiento discreto para estados locales. La navegación no añade efectos.
abstract final class AppMotion {
  static const short = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 260);
  static const curve = Curves.easeOutCubic;

  static Duration duration(BuildContext context, [bool brief = false]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : (brief ? short : standard);
}
