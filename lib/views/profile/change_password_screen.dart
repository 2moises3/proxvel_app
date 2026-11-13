import '../../core/localization/l10n.dart';
import 'widgets/profile_page_bar.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons/proxvel_button.dart';
import '../../core/widgets/inputs/proxvel_text_field.dart';

/// Mínimo que exige el backend (POST /auth/change-password).
const int kMinPasswordLength = 8;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;
  String?
  _serverError; // error devuelto por el backend (contraseña actual incorrecta, etc.)

  String? get _currentError {
    if (_serverError != null) return context.errorText(_serverError!);
    if (_submitted && _currentController.text.isEmpty) {
      return context.l10n.uiIngresaTuContrasenaActual;
    }
    return null;
  }

  String? get _newError {
    final value = _newController.text;
    if (value.isEmpty) {
      return _submitted ? context.l10n.uiIngresaLaNuevaContrasena : null;
    }
    if (value.length < kMinPasswordLength) {
      return 'Debe tener al menos $kMinPasswordLength caracteres.';
    }
    if (value == _currentController.text) {
      return context.l10n.uiDebeSerDistintaDeLaActual;
    }
    return null;
  }

  String? get _confirmError {
    final value = _confirmController.text;
    if (value.isEmpty) return _submitted ? context.l10n.uiRepiteLaNuevaContrasena : null;
    if (value != _newController.text) return context.l10n.uiLasContrasenasNoCoinciden2;
    return null;
  }

  bool get _isValid =>
      _currentController.text.isNotEmpty &&
      _newController.text.length >= kMinPasswordLength &&
      _newController.text != _currentController.text &&
      _confirmController.text == _newController.text;

  Future<void> _handleSave() async {
    if (_isLoading) return;
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!_isValid) return;

    setState(() => _isLoading = true);
    final error = await context.read<AuthController>().changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _serverError = error;
      });
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.uiContrasenaActualizadaCerramosTusOtrasSesiones),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, context.l10n.changePassword, busy: _isLoading),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.passwordChangeHelp(kMinPasswordLength),
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpace.section),
            ProxvelTextField(
              label: context.l10n.uiContrasenaActual,
              hintText: context.l10n.uiEscribeTuContrasenaActual,
              readOnly: _isLoading,
              controller: _currentController,
              isPassword: true,
              errorText: _currentError,
              onChanged: (_) => setState(() => _serverError = null),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: context.l10n.uiNuevaContrasena,
              hintText: context.l10n.eightCharacters,
              readOnly: _isLoading,
              controller: _newController,
              isPassword: true,
              errorText: _newError,
              helperText: context.l10n.passwordMin(kMinPasswordLength),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: context.l10n.uiRepiteLaNuevaContrasena2,
              hintText: context.l10n.uiVuelveAEscribirla,
              readOnly: _isLoading,
              controller: _confirmController,
              isPassword: true,
              errorText: _confirmError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpace.section),
            ProxvelButton(
              text: context.l10n.changePassword,
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
