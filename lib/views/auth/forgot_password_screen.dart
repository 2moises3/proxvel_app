import 'widgets/auth_form_page.dart';
import 'widgets/auth_backdrop.dart';
import '../../core/widgets/inputs/glass_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

/// Paso 1 de recuperar la contraseña: se pide el correo y se envía un código de 6 dígitos.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final String _background = AuthScenes.current;
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
    final result = await context.read<AuthController>().requestPasswordReset(
      email,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.error != null) {
      setState(() => _serverError = result.error);
      return;
    }
    // Siempre se avanza igual, exista o no el correo (el backend no lo revela).
    context.push(
      '/reset-password',
      extra: {
        'email': email,
        'supportEmail': result.supportEmail,
        'expiresMinutes': result.expiresMinutes,
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormPage(
    background: _background,
    onBack: () => context.pop(),
    title: 'Recupera\ntu acceso.',
    subtitle: 'Ingresa el correo de tu cuenta para solicitar un código.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassTextField(
          label: 'Correo electrónico',
          hintText: 'nombre@correo.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          onChanged: (_) => setState(() => _serverError = null),
        ),
        const SizedBox(height: 28),
        AuthSubmitButton(
          text: 'Enviar código',
          isLoading: _isLoading,
          onPressed: _send,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Volver a iniciar sesión'),
        ),
      ],
    ),
  );
}
