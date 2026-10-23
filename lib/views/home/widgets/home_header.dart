import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32, // Tamaño similar al de "Bromo Mountain"
            fontWeight: FontWeight.w500, // Fuente más delgada
            height: 1.15,
            letterSpacing: -0.5, // Le da un toque más Premium
          ),
        ),
        const SizedBox(height: AppSpace.related),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              'Usuario',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
