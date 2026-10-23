import 'package:flutter/material.dart';
import 'button_content.dart';

/// Acción de formulario. Conserva su tamaño durante la espera y admite texto ampliado.
class ProxvelButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  const ProxvelButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = ButtonContent(text: text, isLoading: isLoading);
    return SizedBox(
      width: double.infinity,
      child: isSecondary
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: label,
            )
          : FilledButton(onPressed: isLoading ? null : onPressed, child: label),
    );
  }
}
