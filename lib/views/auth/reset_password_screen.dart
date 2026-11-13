import '../../core/localization/l10n.dart';
import 'dart:async';
import '../../core/theme/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/auth_backdrop.dart';
import '../../core/widgets/inputs/glass_text_field.dart';

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

  final String _background = AuthScenes.current;
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
    if (_serverError != null) return context.errorText(_serverError!);
    final v = _codeController.text;
    if (_submitted && v.length != 6) return context.l10n.uiElCodigoTiene6Digitos;
    return null;
  }

  String? get _newError {
    final v = _newController.text;
    if (v.isEmpty) return _submitted ? context.l10n.uiIngresaLaNuevaContrasena : null;
    if (v.length < _minPassword) {
      return 'Debe tener al menos $_minPassword caracteres.';
    }
    return null;
  }

  String? get _confirmError {
    final v = _confirmController.text;
    if (v.isEmpty) return _submitted ? context.l10n.uiRepiteLaNuevaContrasena : null;
    if (v != _newController.text) return context.l10n.uiLasContrasenasNoCoinciden2;
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
      SnackBar(
        content: Text(context.l10n.uiContrasenaActualizadaYaPuedesIniciarSesion),
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
    final result = await context.read<AuthController>().requestPasswordReset(
      widget.email,
    );
    if (!mounted) return;
    if (result.error != null) {
      setState(() => _resendMessage = result.error);
      return;
    }
    if (result.supportEmail != null) _supportEmail = result.supportEmail;
    setState(
      () => _resendMessage =
          context.l10n.uiTeEnviamosUnCodigoNuevoEl,
    );
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

    return AuthFormPage(
      background: _background,
      onBack: () => context.pop(),
      title: context.l10n.uiRestableceTuContrasena,
      subtitle:
          context.l10n.resetEmailNotice(widget.email, widget.expiresMinutes),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTextField(
            label: context.l10n.uiCodigoDe6Digitos,
            hintText: context.l10n.uiEj123456,
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            errorText: _codeError,
            onChanged: (_) => setState(() => _serverError = null),
          ),
          const SizedBox(height: AppSpace.field),
          GlassTextField(
            label: context.l10n.uiNuevaContrasena,
            hintText: context.l10n.eightCharacters,
            controller: _newController,
            isPassword: true,
            errorText: _newError,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.field),
          GlassTextField(
            label: context.l10n.uiRepiteLaNuevaContrasena2,
            hintText: context.l10n.uiRepiteTuNuevaContrasena,
            controller: _confirmController,
            isPassword: true,
            errorText: _confirmError,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.field),
          AuthSubmitButton(
            text: context.l10n.changePassword,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpace.content),
          Center(
            child: TextButton(
              onPressed: canResend ? _resend : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                disabledForegroundColor: Colors.white60,
              ),
              child: Text(
                canResend
                    ? context.l10n.uiReenviarCodigo
                    : context.l10n.resendCountdown(_secondsLeft),
              ),
            ),
          ),
          if (_resendMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _resendMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          const SizedBox(height: AppSpace.card),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 16),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            textColor: Colors.white,
            collapsedTextColor: Colors.white,
            title: Text(
              context.l10n.uiNoRecibisteElCodigo,
              style: TextStyle(fontSize: 15),
            ),
            children: [
              Text(
                _supportEmail != null && _supportEmail!.isNotEmpty
                    ? context.l10n.supportSpam(_supportEmail!)
                    : context.l10n.uiRevisaSpamOPromocionesSiNecesitas,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
