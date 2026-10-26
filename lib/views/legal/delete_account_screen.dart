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
      setState(() => _error = 'Escribe tu contraseña para confirmar.');
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
            ? 'La contraseña no es correcta.'
            : e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'No pudimos procesar tu solicitud. Revisa tu conexión e intenta de nuevo.';
      });
      return;
    }
    await auth.logout();
    router.go('/welcome');
    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 6),
        content: Text(
          'Tu cuenta se eliminará en 14 días. Si cambias de opinión, escribe a $kSupportEmail.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, 'Eliminar mi cuenta', busy: _busy),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            20,
            AppSpace.screen,
            32,
          ),
          children: [
            const Text('Esto es lo que pasará', style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpace.content),
            for (final t in const [
              'Tu acceso se bloquea de inmediato.',
              'Tienes 14 días para arrepentirte escribiendo a $kSupportEmail.',
              'Pasado ese plazo borramos tu perfil, favoritos, archivados, notificaciones, foto y datos de residencia, y anonimizamos tu nombre y correo.',
              'Tus reseñas se conservan sin identificarte, para mejorar las recomendaciones.',
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
                labelText: 'Tu contraseña',
                hintText: 'Confirma con tu contraseña actual',
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
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
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
                  : const Text('Eliminar mi cuenta'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
