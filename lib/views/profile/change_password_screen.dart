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
    if (_serverError != null) return _serverError;
    if (_submitted && _currentController.text.isEmpty) {
      return 'Ingresa tu contraseña actual.';
    }
    return null;
  }

  String? get _newError {
    final value = _newController.text;
    if (value.isEmpty) {
      return _submitted ? 'Ingresa la nueva contraseña.' : null;
    }
    if (value.length < kMinPasswordLength) {
      return 'Debe tener al menos $kMinPasswordLength caracteres.';
    }
    if (value == _currentController.text) {
      return 'Debe ser distinta de la actual.';
    }
    return null;
  }

  String? get _confirmError {
    final value = _confirmController.text;
    if (value.isEmpty) return _submitted ? 'Repite la nueva contraseña.' : null;
    if (value != _newController.text) return 'Las contraseñas no coinciden.';
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
      const SnackBar(
        content: Text('Contraseña actualizada. Cerramos tus otras sesiones.'),
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
      appBar: profilePageBar(context, 'Cambiar contraseña', busy: _isLoading),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Por seguridad, ingresa tu contraseña actual y elige una nueva de al menos $kMinPasswordLength caracteres.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpace.section),
            ProxvelTextField(
              label: 'Contraseña actual',
              hintText: 'Escribe tu contraseña actual',
              readOnly: _isLoading,
              controller: _currentController,
              isPassword: true,
              errorText: _currentError,
              onChanged: (_) => setState(() => _serverError = null),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Nueva contraseña',
              hintText: 'Al menos 8 caracteres',
              readOnly: _isLoading,
              controller: _newController,
              isPassword: true,
              errorText: _newError,
              helperText: 'Mínimo $kMinPasswordLength caracteres',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Repite la nueva contraseña',
              hintText: 'Vuelve a escribirla',
              readOnly: _isLoading,
              controller: _confirmController,
              isPassword: true,
              errorText: _confirmError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpace.section),
            ProxvelButton(
              text: 'Cambiar contraseña',
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
