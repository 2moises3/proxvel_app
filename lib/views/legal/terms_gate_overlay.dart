import '../../core/localization/l10n.dart';
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
        _error =
            context.l10n.uiNoPudimosRegistrarTuAceptacionRevisa;
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
    if (user == null || user.acceptedTermsVersion == kLegalVersion) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.uiActualizamosNuestrosTextosLegales,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.uiParaSeguirUsandoProxvelNecesitamosQue,
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: Text(context.l10n.terms),
                      onPressed: () => context.push('/legal/doc/terminos'),
                    ),
                    ActionChip(
                      label: Text(context.l10n.privacyPolicy),
                      onPressed: () => context.push('/legal/doc/privacidad'),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.field),
                FilledButton(
                  onPressed: _busy ? null : _accept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.l10n.uiSoyMayorDe18AnosY),
                ),
                TextButton(
                  onPressed: _busy ? null : _decline,
                  child: Text(context.l10n.uiNoAceptoCerrarSesion),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
