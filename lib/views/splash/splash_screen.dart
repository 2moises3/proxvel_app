import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/navigation/home_entry_coordinator.dart';
import '../../core/widgets/loading/proxvel_branded_loading.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/states/proxvel_empty_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _retry = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (_retry) setState(() => _retry = false);

    try {
      if (!mounted) return;

      final authController = context.read<AuthController>();
      final restored = await authController.restoreSession();

      if (!mounted) return;

      if (!restored) {
        context.go('/welcome');
      } else {
        final user = authController.currentUser;
        if (user != null && !user.hasCompleteResidence) {
          context.go('/residence-gate');
          return;
        }
        await HomeEntryCoordinator.prepareHomeForFirstPaint(context);
        if (mounted) context.go('/main');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _retry = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_retry) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ProxvelEmptyState(
            icon: Icons.cloud_off_rounded,
            title: context.l10n.sessionCheckFailed,
            subtitle: context.l10n.sessionCheckHelp,
            actionLabel: context.l10n.retry,
            onAction: _checkSession,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: const ProxvelBrandedLoading(variant: ProxvelLoadingVariant.splash),
    );
  }
}
