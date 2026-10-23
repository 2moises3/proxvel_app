import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import 'widgets/auth_backdrop.dart';
import '../../core/theme/app_colors.dart';
import '../../core/navigation/home_entry_coordinator.dart';
import '../../core/widgets/buttons/shimmer_button.dart';
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

class _ResidenceGateScreenState extends State<ResidenceGateScreen>
    with TickerProviderStateMixin {
  final String _background = AuthScenes.current;
  String? _selectedDepartment;
  String? _selectedProvince;
  String? _selectedCity;

  bool _isLoading = false;
  late final AnimationController _shimmerCtrl;

  static const Color _amber = AppColors.accent;
  static const Color _amberDark = AppColors.accentPressed;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

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
                          alignment: Alignment.centerRight,
                          child: widget.mode == ResidenceGateMode.fallback
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: _handleLogout,
                                  tooltip: 'Cerrar sesión',
                                )
                              : const SizedBox(
                                  height: 48,
                                ), // Spacer to keep layout balanced
                        ),
                      ),

                      const Spacer(),

                      // Eyebrow (Registration only)
                      if (widget.mode == ResidenceGateMode.registration)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Paso 2 de 3',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFDBA00),
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (widget.mode == ResidenceGateMode.registration)
                        const SizedBox(height: AppSpace.related),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          widget.mode == ResidenceGateMode.registration
                              ? 'Tu residencia'
                              : 'Completa tu\nresidencia',
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            height: 1.18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

                      const SizedBox(height: AppSpace.field),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          widget.mode == ResidenceGateMode.registration
                              ? 'La usaremos para personalizar tus recomendaciones. No usamos GPS en este paso.'
                              : 'Necesitamos este dato para adaptar tus recomendaciones y evitar sugerirte siempre lugares de tu propia zona.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
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

                      const SizedBox(height: AppSpace.group),

                      // Form Fields
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.screen,
                        ),
                        child: ResidenceFieldsWidget(
                          isDarkTheme: true,
                          onChanged: (dept, prov, city) {
                            setState(() {
                              _selectedDepartment = dept;
                              _selectedProvince = prov;
                              _selectedCity = city;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Submit Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.screen,
                        ),
                        child: Opacity(
                          opacity: _canSave ? 1.0 : 0.5,
                          child: ShimmerButton(
                            isLoading: _isLoading,
                            shimmer: _shimmerCtrl,
                            baseColor: _amber,
                            hoverColor: _amberDark,
                            text: 'Guardar y continuar',
                            onPressed: _canSave ? _handleSave : () {},
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),
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
