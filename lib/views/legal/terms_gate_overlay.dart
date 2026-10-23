import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/legal/legal_texts.dart';
import '../../core/theme/app_colors.dart';

/// Se muestra una sola vez a quien ya tenía cuenta cuando aún no aceptó la versión vigente de los
/// Términos y la Política de Privacidad. Va dentro del árbol del Home (no como diálogo) para que
/// los refrescos del router no lo descarten.
class TermsGateOverlay extends StatefulWidget {
  const TermsGateOverlay({super.key});

  @override
  State<TermsGateOverlay> createState() => _TermsGateOverlayState();
}

class _TermsGateOverlayState extends State<TermsGateOverlay> {
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await context.read<AuthController>().acceptCurrentTerms();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'No pudimos registrar tu aceptación. Revisa tu conexión e intenta de nuevo.';
      });
    }
  }

  Future<void> _decline() async {
    final auth = context.read<AuthController>();
    final router = GoRouter.of(context);
    await auth.logout();
    router.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    if (user == null || user.acceptedTermsVersion == kLegalVersion) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Actualizamos nuestros textos legales',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 10),
                const Text(
                  'Para seguir usando PROXVEL necesitamos que leas y aceptes los Términos y Condiciones y la Política de Privacidad, y que confirmes que eres mayor de 18 años.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Términos y Condiciones'),
                      onPressed: () => context.push('/legal/doc/terminos'),
                    ),
                    ActionChip(
                      label: const Text('Política de Privacidad'),
                      onPressed: () => context.push('/legal/doc/privacidad'),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
                ],
                const SizedBox(height: AppSpace.field),
                FilledButton(
                  onPressed: _busy ? null : _accept,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Soy mayor de 18 años y acepto'),
                ),
                TextButton(
                  onPressed: _busy ? null : _decline,
                  child: const Text('No acepto (cerrar sesión)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
