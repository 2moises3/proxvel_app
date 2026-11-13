import '../../core/localization/l10n.dart';
import '../profile/widgets/profile_page_bar.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/legal/legal_texts.dart';
import '../../core/theme/app_colors.dart';
import '../../integration/api/api_client.dart';
import '../../integration/services/user_service.dart';

/// Eliminar mi cuenta: explica qué pasará y exige la contraseña.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy) return;
    if (_password.text.isEmpty) {
      setState(() => _error = context.l10n.uiEscribeTuContrasenaParaConfirmar);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<UserService>().deleteMyAccount(_password.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 403
            ? context.l10n.uiLaContrasenaNoEsCorrecta
            : e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            context.l10n.uiNoPudimosProcesarTuSolicitudRevisa;
      });
      return;
    }
    if (!mounted) return;
    final confirmation = context.l10n.accountDeletionScheduled(kSupportEmail);
    await auth.logout();
    router.go('/welcome');
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(confirmation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, context.l10n.deleteAccount, busy: _busy),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            20,
            AppSpace.screen,
            32,
          ),
          children: [
            Text(context.l10n.uiEstoEsLoQuePasara, style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpace.content),
            for (final t in [
              context.l10n.uiTuAccesoSeBloqueaDeInmediato,
              context.l10n.accountDeletionGrace(kSupportEmail),
              context.l10n.uiPasadoEsePlazoBorramosTuPerfil,
              context.l10n.uiTusResenasSeConservanSinIdentificarte,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7, right: 10, left: 4),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: AppColors.error,
                      ),
                    ),
                    Expanded(
                      child: Text(t, style: AppTextStyles.bodySecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpace.card),
            TextField(
              controller: _password,
              obscureText: _obscure,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: context.l10n.uiTuContrasena,
                hintText: context.l10n.uiConfirmaConTuContrasenaActual,
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _obscure
                      ? context.l10n.uiMostrarContrasena
                      : context.l10n.uiOcultarContrasena,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _busy ? null : _delete(),
            ),
            const SizedBox(height: AppSpace.card),
            FilledButton(
              onPressed: _busy ? null : _delete,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(50),
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
                  : Text(context.l10n.deleteAccount),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(context.l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
