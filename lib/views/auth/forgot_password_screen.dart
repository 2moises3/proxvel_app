import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons/proxvel_button.dart';
import '../../core/widgets/inputs/proxvel_text_field.dart';

/// Paso 1 de recuperar la contraseña: se pide el correo y se envía un código de 6 dígitos.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  String? _serverError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? get _emailError {
    if (_serverError != null) return _serverError;
    final value = _emailController.text.trim();
    if (!_submitted) return null;
    if (value.isEmpty) return 'Ingresa tu correo.';
    if (!_emailRegex.hasMatch(value)) return 'Ingresa un correo válido.';
    return null;
  }

  Future<void> _send() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) return;

    setState(() => _isLoading = true);
    final result = await context.read<AuthController>().requestPasswordReset(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.error != null) {
      setState(() => _serverError = result.error);
      return;
    }
    // Siempre se avanza igual, exista o no el correo (el backend no lo revela).
    context.push('/reset-password', extra: {
      'email': email,
      'supportEmail': result.supportEmail,
      'expiresMinutes': result.expiresMinutes,
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Recuperar contraseña',
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpace.related),
            const Icon(Icons.mark_email_unread_outlined,
                size: 56, color: AppColors.accent),
            const SizedBox(height: AppSpace.card),
            const Text(
              '¿Olvidaste tu contraseña?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Escribe el correo de tu cuenta y te enviaremos un código de 6 dígitos para crear una nueva.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 28),
            ProxvelTextField(
              label: 'Correo electrónico',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              prefixIcon: const Icon(Icons.mail_outline_rounded,
                  color: Color(0xFF9CA3AF), size: 20),
              onChanged: (_) => setState(() => _serverError = null),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelButton(
              text: 'Enviar código',
              isLoading: _isLoading,
              onPressed: _send,
            ),
            const SizedBox(height: AppSpace.field),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
