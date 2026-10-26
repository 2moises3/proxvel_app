import 'widgets/profile_avatar.dart';
import 'widgets/profile_page_bar.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/inputs/proxvel_text_field.dart';
import '../../core/widgets/buttons/proxvel_button.dart';
import '../../core/utils/avatar_picker_helper.dart';
import '../../core/widgets/forms/residence_fields_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedProvince;
  String? _selectedCity;

  String? _initialDepartment;
  String? _initialProvince;
  String? _initialCity;

  bool _isLoading = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        final fullName = user.fullName.trim();
        final parts = fullName.split(RegExp(r'\s+'));

        if (parts.length == 1) {
          _nameController.text = parts[0];
          _lastNameController.text = '';
        } else if (parts.length == 2) {
          _nameController.text = parts[0];
          _lastNameController.text = parts[1];
        } else if (parts.length > 2) {
          _nameController.text = parts[0];
          _lastNameController.text = parts.skip(1).join(' ');
        }

        _emailController.text = user.email;
        setState(() {
          _initialDepartment = user.residenceDepartment;
          _initialProvince = user.residenceProvince;
          _initialCity = user.residenceCity;
          _selectedDepartment = user.residenceDepartment;
          _selectedProvince = user.residenceProvince;
          _selectedCity = user.residenceCity;
          _isInit = true;
        });
      } else {
        setState(() => _isInit = true);
      }
    });
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu nombre para continuar.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthController>().updateUserProfile(
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        residenceDepartment: _selectedDepartment,
        residenceProvince: _selectedProvince,
        residenceCity: _selectedCity,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos guardar tu perfil. Revisa tu conexión e intenta de nuevo.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, 'Datos personales', busy: _isLoading),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Selector<AuthController, ({String name, String? avatar})>(
                selector: (_, auth) => (
                  name: auth.currentUser?.fullName ?? '',
                  avatar: auth.currentUser?.avatarUrl,
                ),
                builder: (context, user, _) => ProfileAvatar(
                  name: user.name,
                  url: user.avatar,
                  size: 100,
                  onEdit: _isLoading
                      ? null
                      : () => pickAndUploadAvatar(context),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.group),
            ProxvelTextField(
              label: 'Nombre',
              hintText: 'Tu nombre',
              controller: _nameController,
              readOnly: _isLoading,
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Apellidos',
              hintText: 'Tus apellidos',
              readOnly: _isLoading,
              controller: _lastNameController,
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Correo electrónico',
              controller: _emailController,
              readOnly: true,
              fillColor: const Color(0xFFF3F4F6),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
              helperText: 'El correo no se puede modificar',
            ),
            const SizedBox(height: AppSpace.group),
            const Text('Residencia', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpace.field),
            ResidenceFieldsWidget(
              initialDepartment: _initialDepartment,
              initialProvince: _initialProvince,
              initialCity: _initialCity,
              onChanged: (dept, prov, city) {
                _selectedDepartment = dept;
                _selectedProvince = prov;
                _selectedCity = city;
              },
            ),
            const SizedBox(height: 48),
            ProxvelButton(
              text: 'Guardar cambios',
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
