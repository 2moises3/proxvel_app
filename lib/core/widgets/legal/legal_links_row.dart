import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_layout.dart';

/// «Términos · Privacidad» discreto para pantallas previas al inicio de sesión (fondo oscuro).
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.poppins(
      fontSize: 12,
      color: Colors.white.withValues(alpha: 0.75),
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withValues(alpha: 0.4),
    );
    Widget link(String label, String route) => TextButton(
      onPressed: () => context.push(route),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(AppSizing.touchTarget, AppSizing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.related),
      ),
      child: Text(label, style: style),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        link('Términos y Condiciones', '/legal/doc/terminos'),
        Text('·', style: style.copyWith(decoration: TextDecoration.none)),
        link('Privacidad', '/legal/doc/privacidad'),
      ],
    );
  }
}
