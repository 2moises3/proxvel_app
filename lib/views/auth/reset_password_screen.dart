import 'dart:async';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons/proxvel_button.dart';
import '../../core/widgets/inputs/proxvel_text_field.dart';

/// Paso 2: se ingresa el código recibido por correo y la nueva contraseña.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String? supportEmail;
  final int expiresMinutes;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.supportEmail,
    this.expiresMinutes = 15,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const int _minPassword = 8;
  static const int _resendSeconds = 60;

  final _codeController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;
  String? _serverError;
  String? _resendMessage;
  late String? _supportEmail = widget.supportEmail;

  Timer? _timer;
  int _secondsLeft = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
      }
      setState(() => _secondsLeft = _secondsLeft - 1);
    });
  }

  String? get _codeError {
    if (_serverError != null) return _serverError;
    final v = _codeController.text;
    if (_submitted && v.length != 6) return 'El código tiene 6 dígitos.';
    return null;
  }

  String? get _newError {
    final v = _newController.text;
    if (v.isEmpty) return _submitted ? 'Ingresa la nueva contraseña.' : null;
    if (v.length < _minPassword) return 'Debe tener al menos $_minPassword caracteres.';
    return null;
  }

  String? get _confirmError {
    final v = _confirmController.text;
    if (v.isEmpty) return _submitted ? 'Repite la nueva contraseña.' : null;
    if (v != _newController.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  bool get _isValid =>
      _codeController.text.length == 6 &&
      _newController.text.length >= _minPassword &&
      _confirmController.text == _newController.text;

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!_isValid) return;

    setState(() => _isLoading = true);
    final error = await context.read<AuthController>().resetPasswordWithCode(
          email: widget.email,
          code: _codeController.text,
          newPassword: _newController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _serverError = error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/login');
  }

  Future<void> _resend() async {
    setState(() {
      _resendMessage = null;
      _serverError = null;
    });
    final result =
        await context.read<AuthController>().requestPasswordReset(widget.email);
    if (!mounted) return;
    if (result.error != null) {
      setState(() => _resendMessage = result.error);
      return;
    }
    if (result.supportEmail != null) _supportEmail = result.supportEmail;
    setState(() => _resendMessage = 'Te enviamos un código nuevo. El anterior ya no sirve.');
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 0;

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
          'Nueva contraseña',
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Si ${widget.email} tiene una cuenta, te enviamos un código de 6 dígitos. '
              'Vence en ${widget.expiresMinutes} minutos.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpace.section),
            ProxvelTextField(
              label: 'Código de 6 dígitos',
              controller: _codeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              errorText: _codeError,
              prefixIcon: const Icon(Icons.pin_outlined,
                  color: Color(0xFF9CA3AF), size: 20),
              onChanged: (_) => setState(() => _serverError = null),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Nueva contraseña',
              controller: _newController,
              isPassword: true,
              errorText: _newError,
              helperText: 'Mínimo $_minPassword caracteres',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Repite la nueva contraseña',
              controller: _confirmController,
              isPassword: true,
              errorText: _confirmError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelButton(
              text: 'Cambiar contraseña',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpace.content),
            Center(
              child: TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  canResend
                      ? 'Reenviar código'
                      : 'Reenviar código en ${_secondsLeft}s',
                ),
              ),
            ),
            if (_resendMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _resendMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: AppSpace.card),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: AppColors.accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _supportEmail != null && _supportEmail!.isNotEmpty
                          ? '¿No te llega el correo? Revisa spam o promociones. Si sigue sin llegar, '
                              'escríbenos a $_supportEmail y un administrador restablecerá tu acceso.'
                          : '¿No te llega el correo? Revisa spam o promociones. Si sigue sin llegar, '
                              'contacta a un administrador de PROXVEL para restablecer tu acceso.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
