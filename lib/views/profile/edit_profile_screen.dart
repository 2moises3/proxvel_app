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
          _isInit = true;
        });
      } else {
        setState(() => _isInit = true);
      }
    });
  }

  Future<void> _handleSave() async {
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
            content: Text('No pudimos guardar tu perfil. Revisa tu conexión e intenta de nuevo.'),
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Editar perfil',
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => pickAndUploadAvatar(context),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 2),
                        image: context.watch<AuthController>().currentUser?.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(context.watch<AuthController>().currentUser!.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: context.watch<AuthController>().currentUser?.avatarUrl == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: AppColors.accent,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.group),
            ProxvelTextField(label: 'Nombre', controller: _nameController),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Apellidos',
              controller: _lastNameController,
            ),
            const SizedBox(height: AppSpace.field),
            ProxvelTextField(
              label: 'Email',
              controller: _emailController,
              readOnly: true,
              fillColor: const Color(0xFFF3F4F6),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 20),
              helperText: 'El correo no se puede modificar',
            ),
            const SizedBox(height: AppSpace.group),
            const Text(
              'Residencia',
              style: AppTextStyles.sectionTitle,
            ),
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
