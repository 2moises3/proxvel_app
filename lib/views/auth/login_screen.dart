import '../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/core/theme/app_typography.dart';

import '../../controllers/auth_controller.dart';
import '../../core/widgets/legal/legal_links_row.dart';
import '../../integration/services/auth_service.dart';
import 'widgets/auth_backdrop.dart';
import 'widgets/auth_form_page.dart';
import '../../core/widgets/inputs/glass_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final String _background = AuthScenes.current;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberSession = false;

  String? _loginError;
  String? _emailError;
  String? _passwordError;

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

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? context.l10n.uiElCorreoEsRequerido
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? context.l10n.uiLaContrasenaEsRequerida
          : null;
      _loginError = null;
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    final error = await context.read<AuthController>().login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberSession: _rememberSession,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        setState(() => _loginError = _sanitizeAuthError(error));
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
        context.go('/session-ready');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// v1: la recuperación por correo aún no está activa; se muestra cómo recuperar la cuenta.
  /// Si el backend la activa (v2), abre la pantalla del código.
  Future<void> _onForgotPassword() async {
    final info = await context.read<AuthService>().supportContact();
    if (!mounted) return;
    if (info.resetByEmail) {
      context.push('/forgot-password', extra: _emailController.text.trim());
      return;
    }
    final email = info.supportEmail ?? 'soporte@m3biznovatech.com';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF202020),
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
                context.l10n.forgotPassword,
                style: AppTypography.style(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.supportAccess(email),
                style: AppTypography.style(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: email));
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n.uiCorreoDeSoporteCopiado,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(context.l10n.uiCopiarCorreo),
                    ),
                  ),
                  const SizedBox(width: AppSpace.content),
                  Expanded(
                    child: AuthSubmitButton(
                      text: context.l10n.uiEntendido,
                      onPressed: () => Navigator.of(sheetContext).pop(),
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
  Widget build(BuildContext context) => AuthFormPage(
    background: _background,
    onBack: () => context.pop(),
    title: context.l10n.welcomeBack,
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTextField(
            label: context.l10n.email,
            hintText: 'nombre@correo.com',
            controller: _emailController,
            errorText: _emailError,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {
              _emailError = null;
              _loginError = null;
            }),
          ),
          const SizedBox(height: 18),
          GlassTextField(
            label: context.l10n.password,
            hintText: context.l10n.enterPassword,
            controller: _passwordController,
            isPassword: true,
            errorText: _passwordError,
            onChanged: (_) => setState(() {
              _passwordError = null;
              _loginError = null;
            }),
          ),
          if (_loginError != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                context.errorText(_loginError!),
                style: AppTypography.style(
                  color: const Color(0xFFFFADAD),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _onForgotPassword,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(
                context.l10n.forgotPassword,
                style: AppTypography.style(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          MergeSemantics(
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () => setState(() => _rememberSession = !_rememberSession),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Checkbox(
                    value: _rememberSession,
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _rememberSession = value!),
                    checkColor: AppColors.textPrimary,
                    activeColor: AppColors.accent,
                    side: const BorderSide(color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.rememberSession,
                      style: AppTypography.style(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AuthSubmitButton(
            text: context.l10n.signIn,
            onPressed: _handleLogin,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.l10n.firstVisit,
                style: AppTypography.style(color: Colors.white, fontSize: 14),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => context.push('/register'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(
                  context.l10n.registerAction,
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const LegalLinksRow(),
        ],
      ),
    ),
  );
}
