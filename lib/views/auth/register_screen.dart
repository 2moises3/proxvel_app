import 'widgets/auth_progress_indicator.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/core/theme/app_typography.dart';

import '../../controllers/auth_controller.dart';
import '../../core/utils/formatters.dart';
import 'widgets/auth_backdrop.dart';
import 'widgets/auth_form_page.dart';
import '../../core/widgets/inputs/glass_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Animación manual para evitar PageView rígido
  int _currentStep = 0;

  // Step 1 Controllers
  final String _background = AuthScenes.current;
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 2 Controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;

  bool _isStep1Valid = false;
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _passwordsMatch = false;

  static const Color _amber = AppColors.accent;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateStep1);
    _lastnameController.addListener(_validateStep1);
    _emailController.addListener(_validateStep1);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  void _validateStep1() {
    final isValid =
        _nameController.text.trim().isNotEmpty &&
        _lastnameController.text.trim().isNotEmpty &&
        _emailRegex.hasMatch(_emailController.text.trim());
    if (_isStep1Valid != isValid) {
      setState(() => _isStep1Valid = isValid);
    }
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text;
      _passwordsMatch =
          password.isNotEmpty && _confirmPasswordController.text == password;
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    }
  }

  void _prevStep() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
    } else {
      context.pop();
    }
  }

  String _sanitizeAuthError(Object error) {
    String rawError = error.toString();
    rawError = rawError
        .replaceAll('Exception: ', '')
        .replaceAll('ApiException: ', '')
        .trim();

    if (rawError.isEmpty) {
      return 'No pudimos completar la acción. Intenta nuevamente.';
    }

    final lower = rawError.toLowerCase();

    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception') ||
        lower.contains('timeout') ||
        lower.contains('handshake')) {
      return 'No hay conexión con el servidor. Verifica tu internet e intenta nuevamente.';
    }

    if (lower.contains('typeerror') ||
        lower.contains('formatexception') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('null is not a subtype') ||
        lower.contains('stack trace') ||
        lower.contains('traceback') ||
        lower.contains('sql') ||
        lower.contains('database') ||
        lower.contains('internal server error')) {
      return 'Ocurrió un problema inesperado. Intenta nuevamente.';
    }

    if (rawError.length > 150) {
      return 'No pudimos completar la acción. Intenta nuevamente.';
    }

    return rawError;
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthController>().register(
        name: _nameController.text.trim(),
        lastName: _lastnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        acceptedTerms: _acceptTerms,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/register-residence');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final message = _sanitizeAuthError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Enlace dentro del texto de la casilla: abre el documento sin marcar ni desmarcar la casilla.
  InlineSpan _legalLink(String label, String route) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Text(
          label,
          style: AppTypography.style(
            color: _amber,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: _amber,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthFormPage(
    background: _background,
    onBack: _prevStep,
    progress: AuthProgressIndicator(step: _currentStep, count: 3),
    title: _currentStep == 0 ? 'Crea tu cuenta' : 'Crea tu contraseña',
    subtitle: _currentStep == 0 ? null : 'Usa al menos 8 caracteres.',
    child: _buildSteps(),
  );

  Widget _buildSteps() {
    final child = _currentStep == 0
        ? KeyedSubtree(key: const ValueKey(0), child: _buildStep1())
        : KeyedSubtree(key: const ValueKey(1), child: _buildStep2());
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(duration: AppMotion.standard, child: child),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GlassTextField(
            label: 'Nombre',
            hintText: 'Ej. María',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
          ),
          const SizedBox(height: AppSpace.card),
          GlassTextField(
            label: 'Apellidos',
            hintText: 'Ej. García López',
            controller: _lastnameController,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
          ),
          const SizedBox(height: AppSpace.card),
          GlassTextField(
            label: 'Correo electrónico',
            hintText: 'nombre@correo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: AppSpace.group),

          // Next Button
          AuthSubmitButton(
            text: 'Continuar',
            onPressed: () {
              if (_isStep1Valid) {
                _nextStep();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Completa tus datos e ingresa un correo válido.',
                      style: AppTypography.style(color: Colors.white),
                    ),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          const SizedBox(height: AppSpace.group), // Exact space to link
          // Login Link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '¿Ya tienes una cuenta? ',
                style: AppTypography.style(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  'Inicia sesión',
                  style: AppTypography.style(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final bool isReadyToSubmit =
        _acceptTerms && _passwordController.text.length >= 8 && _passwordsMatch;

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GlassTextField(
            label: 'Contraseña',
            hintText: 'Al menos 8 caracteres',
            controller: _passwordController,
            isPassword: true,
          ),

          const SizedBox(height: AppSpace.field),
          GlassTextField(
            label: 'Confirmar contraseña',
            hintText: 'Repite tu contraseña',
            controller: _confirmPasswordController,
            isPassword: true,
          ),

          const SizedBox(height: AppSpace.content),

          // Password match indicator
          if (_confirmPasswordController.text.isNotEmpty && !_passwordsMatch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Las contraseñas no coinciden',
                  style: AppTypography.style(
                    color: const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Términos, Privacidad y declaración de mayoría de edad (casilla sin marcar de forma predeterminada)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (val) {
                    setState(() => _acceptTerms = val ?? false);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  activeColor: _amber,
                  checkColor: Colors.black,
                ),
              ),
              const SizedBox(width: AppSpace.related),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Declaro ser mayor de 18 años y acepto los ',
                      ),
                      _legalLink(
                        'Términos y Condiciones',
                        '/legal/doc/terminos',
                      ),
                      const TextSpan(text: ' y la '),
                      _legalLink(
                        'Política de Privacidad',
                        '/legal/doc/privacidad',
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.group),

          // Submit Button
          AuthSubmitButton(
            isLoading: _isLoading,
            text: 'Crear mi cuenta',
            onPressed: () {
              if (isReadyToSubmit) {
                _handleRegister();
              } else {
                String msg = 'Completa los datos de contraseña';
                if (!_acceptTerms) {
                  msg =
                      'Debes aceptar los Términos y la Política de Privacidad';
                } else if (_passwordController.text.length < 8) {
                  msg = 'Usa al menos 8 caracteres';
                } else if (!_passwordsMatch) {
                  msg = 'Las contraseñas no coinciden';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      msg,
                      style: AppTypography.style(color: Colors.white),
                    ),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          const SizedBox(height: AppSpace.group),
        ],
      ),
    );
  }
}
