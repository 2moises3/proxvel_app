import 'package:flutter/material.dart';

/// Same translucent return control as the welcome pages.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: 'Volver',
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0x73202020),
      foregroundColor: Colors.white,
      minimumSize: const Size(44, 44),
    ),
    icon: const Icon(Icons.arrow_back_rounded, size: 20),
  );
}
