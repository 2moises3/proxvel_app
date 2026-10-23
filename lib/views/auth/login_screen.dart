import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../core/widgets/legal/legal_links_row.dart';
import '../../integration/services/auth_service.dart';
import '../../core/navigation/home_entry_coordinator.dart';
import 'widgets/auth_backdrop.dart';
import 'widgets/auth_back_button.dart';
import '../../core/widgets/buttons/shimmer_button.dart';
import '../../core/widgets/inputs/glass_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final String _background = AuthScenes.current;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _loginError;
  String? _emailError;
  String? _passwordError;

  // Reusing the amber color from welcome screen
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

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? 'El correo es requerido'
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? 'La contraseña es requerida'
          : null;
      _loginError = null;
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    final error = await context.read<AuthController>().login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        setState(() => _loginError = _sanitizeAuthError(error));
      } else {
        await HomeEntryCoordinator.goToPreparedHome(context);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  /// v1: la recuperación por correo aún no está activa; se muestra cómo recuperar la cuenta.
  /// Si el backend la activa (v2), abre la pantalla del código.
  Future<void> _onForgotPassword() async {
    final info = await context.read<AuthService>().supportContact();
    if (!mounted) return;
    if (info.resetByEmail) {
      context.push('/forgot-password');
      return;
    }
    final email = info.supportEmail ?? 'soporte@m3biznovatech.com';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            20,
            AppSpace.screen,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Escríbenos a $email desde el correo de tu cuenta y te enviaremos una contraseña temporal. Muy pronto podrás recuperarla tú mismo desde aquí.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: email));
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Correo de soporte copiado'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar correo'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.content),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Entendido'),
                    ),
                  ),
                ],
              ),
            ],
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
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
                          child: AuthBackButton(onPressed: () => context.pop()),
                        ),
                      ),

                      const Spacer(),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.screen,
                        ),
                        child: Text(
                          '¡Bienvenido de\nnuevo!',
                          style: GoogleFonts.poppins(
                            textStyle: AppTextStyles.headingOnDark,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
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
                          'Continúa tu aventura',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.85),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpace.group),

                      // Form Fields
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.screen,
                        ),
                        child: Column(
                          children: [
                            GlassTextField(
                              label: 'Correo electrónico',
                              controller: _emailController,
                              errorText: _emailError,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (val) {
                                if (_emailError != null) {
                                  setState(() => _emailError = null);
                                }
                                if (_loginError != null) {
                                  setState(() => _loginError = null);
                                }
                              },
                            ),
                            const SizedBox(height: AppSpace.card),
                            GlassTextField(
                              label: 'Contraseña',
                              controller: _passwordController,
                              isPassword: true,
                              errorText: _passwordError,
                              onChanged: (val) {
                                if (_passwordError != null) {
                                  setState(() => _passwordError = null);
                                }
                                if (_loginError != null) {
                                  setState(() => _loginError = null);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Error Message
                      if (_loginError != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.screen,
                          ).copyWith(top: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFFF6B6B),
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpace.content),
                                Expanded(
                                  child: Text(
                                    _loginError!,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFFF6B6B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // «Recordar sesión» no existe: la sesión siempre se conserva (token seguro).
                      const SizedBox(height: AppSpace.content),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.screen,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _onForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              minimumSize: const Size(0, 44),
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.field),

                      // Login Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.screen,
                        ),
                        child: ShimmerButton(
                          isLoading: _isLoading,
                          shimmer: _shimmerCtrl,
                          baseColor: _amber,
                          hoverColor: _amberDark,
                          text: 'Iniciar sesión',
                          onPressed: _handleLogin,
                        ),
                      ),

                      const SizedBox(height: AppSpace.group),

                      // Register Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '¿No tienes una cuenta? ',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                            child: Text(
                              'Regístrate',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const LegalLinksRow(),

                      const SizedBox(height: AppSpace.section),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
