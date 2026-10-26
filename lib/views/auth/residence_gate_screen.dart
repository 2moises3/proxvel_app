import 'widgets/auth_progress_indicator.dart';
import 'widgets/auth_form_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import 'widgets/auth_backdrop.dart';
import '../../core/navigation/home_entry_coordinator.dart';
import '../../core/widgets/forms/residence_fields_widget.dart';

enum ResidenceGateMode { registration, fallback }

class ResidenceGateScreen extends StatefulWidget {
  final ResidenceGateMode mode;

  const ResidenceGateScreen({
    super.key,
    this.mode = ResidenceGateMode.fallback,
  });

  @override
  State<ResidenceGateScreen> createState() => _ResidenceGateScreenState();
}

class _ResidenceGateScreenState extends State<ResidenceGateScreen> {
  final String _background = AuthScenes.current;
  String? _selectedDepartment;
  String? _selectedProvince;
  String? _selectedCity;

  bool _isLoading = false;
  bool get _canSave =>
      _selectedDepartment != null &&
      _selectedProvince != null &&
      _selectedCity != null;

  Future<void> _handleSave() async {
    if (!_canSave) return;

    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthController>().currentUser;
      if (user == null) throw Exception('No session');

      await context.read<AuthController>().updateUserProfile(
        name: user.name,
        lastName: user.lastName,
        email: user.email,
        residenceDepartment: _selectedDepartment,
        residenceProvince: _selectedProvince,
        residenceCity: _selectedCity,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.mode == ResidenceGateMode.registration) {
          context.go('/onboarding');
        } else {
          await HomeEntryCoordinator.goToPreparedHome(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos guardar tu residencia. Intenta nuevamente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await context.read<AuthController>().logout();
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) => AuthFormPage(
    background: _background,
    progress: widget.mode == ResidenceGateMode.registration
        ? const AuthProgressIndicator(step: 2, count: 3)
        : null,
    title: '¿Dónde vives?',
    subtitle: 'Selecciona tu departamento, provincia y distrito.',
    topAction: widget.mode == ResidenceGateMode.fallback
        ? IconButton.filledTonal(
            onPressed: _isLoading ? null : _handleLogout,
            tooltip: 'Cerrar sesión',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x73202020),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResidenceFieldsWidget(
          isDarkTheme: true,
          accountStyle: true,
          onChanged: (dept, prov, city) => setState(() {
            _selectedDepartment = dept;
            _selectedProvince = prov;
            _selectedCity = city;
          }),
        ),
        const SizedBox(height: 28),
        AuthSubmitButton(
          text: 'Guardar y continuar',
          onPressed: _canSave ? _handleSave : null,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
