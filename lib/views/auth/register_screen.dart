import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../core/utils/formatters.dart';
import 'widgets/auth_backdrop.dart';
import 'widgets/auth_back_button.dart';
import '../../core/widgets/buttons/shimmer_button.dart';
import '../../core/widgets/inputs/glass_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
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

  // Password Strength State
  int _passwordStrength = 0; // 0: Weak, 1: Medium, 2: Strong
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;
  bool _passwordsMatch = false;

  static const Color _amber = AppColors.accent;
  static const Color _amberDark = AppColors.accentPressed;

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

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
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    // Calculate strength
    int strength = 0;
    if (pass.length >= 8) strength++; // mínimo que exige el backend
    if (pass.length >= 8 &&
        pass.contains(RegExp(r'[A-Z]')) &&
        pass.contains(RegExp(r'[0-9]'))) {
      strength++;
    }
    if (pass.length >= 10 && pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength++;
    }

    String text = '';
    Color color = Colors.transparent;

    if (pass.isEmpty) {
      strength = 0;
      text = '';
      color = Colors.transparent;
    } else if (strength == 0) {
      text = 'Mínimo 8 caracteres';
      color = const Color(0xFFEF4444); // Red
    } else if (strength == 1) {
      text = 'Débil';
      color = const Color(0xFFEF4444); // Red
    } else if (strength == 2) {
      text = 'Segura';
      color = AppColors.accent; // Amber
    } else {
      text = 'Fuerte';
      color = const Color(0xFF10B981); // Green
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
      _passwordsMatch = pass.isNotEmpty && confirm == pass;
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
    _shimmerCtrl.dispose();
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
          style: GoogleFonts.poppins(
            color: _amber,
            fontSize: 12.5,
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
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: AuthBackdrop(imagePath: _background)),

          // ── Content ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Action Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AuthBackButton(onPressed: _prevStep),
                            ),
                          ),

                          const Spacer(),

                          // Title
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.screen,
                            ),
                            child: Text(
                              'Comienza tu\naventura.',
                              style: GoogleFonts.poppins(
                                textStyle: AppTextStyles.headingOnDark,
                                letterSpacing: -0.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpace.content),

                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.screen,
                            ),
                            child: Text(
                              'Descubre el Perú a tu manera',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpace.section),

                          // Forms AnimatedSwitcher
                          _buildSteps(),

                          const SizedBox(height: AppSpace.section),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Column(
        children: [
          GlassTextField(
            label: 'Nombre',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
          ),
          const SizedBox(height: AppSpace.card),
          GlassTextField(
            label: 'Apellidos',
            controller: _lastnameController,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
          ),
          const SizedBox(height: AppSpace.card),
          GlassTextField(
            label: 'Correo electrónico',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: AppSpace.group),

          // Next Button
          ShimmerButton(
            shimmer: _shimmerCtrl,
            baseColor: _amber,
            hoverColor: _amberDark,
            text: 'Continuar',
            onPressed: () {
              if (_isStep1Valid) {
                _nextStep();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Completa tus datos e ingresa un correo válido.',
                      style: GoogleFonts.poppins(color: Colors.white),
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
                style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
        _acceptTerms && _passwordStrength > 0 && _passwordsMatch;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Column(
        children: [
          GlassTextField(
            label: 'Contraseña',
            controller: _passwordController,
            isPassword: true,
          ),

          // Password Strength Bar
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: AppSpace.content),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: index < _passwordStrength
                                  ? _passwordStrengthColor
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpace.content),
                  Text(
                    _passwordStrengthText,
                    style: GoogleFonts.poppins(
                      color: _passwordStrengthColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpace.field),
          GlassTextField(
            label: 'Confirmar contraseña',
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
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpace.section),

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
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
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
          const SizedBox(height: AppSpace.content),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              'Tu nombre, correo y residencia forman parte de tu cuenta. Tus preferencias de viaje orientan las recomendaciones.',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: AppSpace.group),

          // Submit Button
          ShimmerButton(
            isLoading: _isLoading,
            shimmer: _shimmerCtrl,
            baseColor: _amber,
            hoverColor: _amberDark,
            text: 'Crear mi cuenta',
            onPressed: () {
              if (isReadyToSubmit) {
                _handleRegister();
              } else {
                String msg = 'Completa los datos de contraseña';
                if (!_acceptTerms) {
                  msg =
                      'Debes aceptar los Términos y la Política de Privacidad';
                } else if (!_passwordsMatch) {
                  msg = 'Las contraseñas no coinciden';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      msg,
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          const SizedBox(height: AppSpace.group),

          // Invisible spacer to match step 1 height
          const SizedBox(height: AppSpace.card),
        ],
      ),
    );
  }
}
