import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'auth_back_button.dart';
import 'auth_backdrop.dart';

/// Shared photo-backed layout for account forms before travel preferences.
class AuthFormPage extends StatelessWidget {
  const AuthFormPage({
    super.key,
    required this.background,
    required this.title,
    this.subtitle,
    required this.child,
    this.onBack,
    this.progress,
    this.topAction,
  });

  final String background;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? progress;
  final Widget? topAction;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackdrop(imagePath: background),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.28, 0.46, 0.72, 1],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x66000000),
                    Color(0x14000000),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Row(
                          children: [
                            if (onBack != null)
                              AuthBackButton(onPressed: onBack!),
                            const Spacer(),
                            ?topAction,
                          ],
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const ClampingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              sliver: SliverFillRemaining(
                                hasScrollBody: false,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Spacer(),
                                    if (progress != null) ...[
                                      progress!,
                                      const SizedBox(height: 20),
                                    ],
                                    Text(
                                      title,
                                      style: AppTypography.style(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w600,
                                        height: 1.12,
                                        letterSpacing: -0.7,
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 14),
                                      Text(
                                        subtitle!,
                                        style: AppTypography.style(
                                          color: Colors.white,
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 28),
                                    child,
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum AuthSubmitButtonSize { regular, large }

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.size = AuthSubmitButtonSize.regular,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AuthSubmitButtonSize size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF202020),
        disabledBackgroundColor: AppColors.accent.withValues(
          alpha: isLoading ? 1 : 0.4,
        ),
        disabledForegroundColor: const Color(0xFF202020),
        minimumSize: Size.fromHeight(
          size == AuthSubmitButtonSize.large ? 64 : 56,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: AppTypography.style(
          fontSize: size == AuthSubmitButtonSize.large ? 18 : 16,
          fontWeight: size == AuthSubmitButtonSize.large
              ? FontWeight.w500
              : FontWeight.w600,
        ),
      ),
      child: isLoading
          ? Semantics(
              label: 'Procesando',
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF202020),
                ),
              ),
            )
          : Text(text, textAlign: TextAlign.center),
    ),
  );
}
