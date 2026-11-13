import '../../integration/api/api_client.dart';
import '../../core/localization/l10n.dart';
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
  bool _checkedIdentity = false;
  bool _checkedPassword = false;
  String? _emailTaken;
  String? _submitError;

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
    if (_isStep1Valid != isValid || _checkedIdentity) {
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
      return context.l10n.uiNoPudimosCompletarLaAccionIntenta;
    }

    final lower = rawError.toLowerCase();

    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception') ||
        lower.contains('timeout') ||
        lower.contains('handshake')) {
      return context.l10n.uiNoHayConexionConElServidor;
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
      return context.l10n.uiOcurrioUnProblemaInesperadoIntentaNuevamente;
    }

    if (rawError.length > 150) {
      return context.l10n.uiNoPudimosCompletarLaAccionIntenta;
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
        final message = _sanitizeAuthError(e);
        setState(() {
          _isLoading = false;
          if (e is ApiException && e.statusCode == 409) {
            _currentStep = 0;
            _emailTaken = context.l10n.registrationEmailTaken;
          } else {
            _submitError = context.errorText(message);
          }
        });
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
  Widget build(BuildContext context) => PopScope(
    canPop: _currentStep == 0 && !_isLoading,
    onPopInvokedWithResult: (popped, _) {
      if (!popped && !_isLoading && _currentStep == 1) _prevStep();
    },
    child: AuthFormPage(
      background: _background,
      onBack: _isLoading ? null : _prevStep,
      progress: AuthProgressIndicator(step: _currentStep, count: 3),
      title: _currentStep == 0
          ? context.l10n.registerTitle
          : context.l10n.createPassword,
      subtitle: _currentStep == 0 ? null : context.l10n.atLeastEight,
      child: _buildSteps(),
    ),
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
            label: context.l10n.firstName,
            hintText: context.l10n.uiEjMaria,
            controller: _nameController,
            errorText: _checkedIdentity && _nameController.text.trim().isEmpty
                ? context.l10n.registrationFirstName
                : null,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
          ),
          const SizedBox(height: AppSpace.card),
          GlassTextField(
            label: context.l10n.lastName,
            hintText: context.l10n.uiEjGarciaLopez,
            controller: _lastnameController,
            errorText:
                _checkedIdentity && _lastnameController.text.trim().isEmpty
                ? context.l10n.registrationLastName
                : null,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
          ),
          const SizedBox(height: AppSpace.card),
          GlassTextField(
            label: context.l10n.email,
            hintText: 'nombre@correo.com',
            controller: _emailController,
            onChanged: (_) {
              if (_emailTaken != null) setState(() => _emailTaken = null);
            },
            errorText:
                _emailTaken ??
                (_checkedIdentity &&
                        !_emailRegex.hasMatch(_emailController.text.trim())
                    ? context.l10n.uiIngresaUnCorreoValido
                    : null),
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: AppSpace.group),

          // Next Button
          AuthSubmitButton(
            text: context.l10n.continueAction,
            onPressed: () {
              setState(() => _checkedIdentity = true);
              if (_isStep1Valid) _nextStep();
            },
          ),

          const SizedBox(height: AppSpace.group), // Exact space to link
          // Login Link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.l10n.alreadyHaveAccount,
                style: AppTypography.style(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  context.l10n.signInPrompt,
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
            label: context.l10n.password,
            hintText: context.l10n.eightCharacters,
            controller: _passwordController,
            errorText: _checkedPassword && _passwordController.text.length < 8
                ? context.l10n.uiUsaAlMenos8Caracteres
                : null,
            isPassword: true,
          ),

          const SizedBox(height: AppSpace.field),
          GlassTextField(
            label: context.l10n.confirmPassword,
            hintText: context.l10n.repeatPassword,
            controller: _confirmPasswordController,
            errorText:
                (_checkedPassword ||
                        _confirmPasswordController.text.isNotEmpty) &&
                    !_passwordsMatch
                ? context.l10n.uiLasContrasenasNoCoinciden
                : null,
            isPassword: true,
          ),

          const SizedBox(height: AppSpace.content),

          const SizedBox(height: AppSpace.card),

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
                      TextSpan(text: context.l10n.declareAge),
                      _legalLink(context.l10n.terms, '/legal/doc/terminos'),
                      TextSpan(text: context.l10n.legalAnd),
                      _legalLink(
                        context.l10n.privacyPolicy,
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

          if (_submitError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.field),
              child: Text(
                _submitError!,
                style: const TextStyle(color: Color(0xFFFFADAD)),
              ),
            ),
          AuthSubmitButton(
            isLoading: _isLoading,
            text: context.l10n.createMyAccount,
            onPressed: () {
              setState(() {
                _checkedPassword = true;
                _submitError = null;
              });
              if (isReadyToSubmit) {
                _handleRegister();
              } else if (!_acceptTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.uiDebesAceptarLosTerminosYLa),
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
