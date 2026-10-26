import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/navigation/home_entry_coordinator.dart';
import '../../core/widgets/loading/proxvel_branded_loading.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final startTime = DateTime.now();
    
    try {
      if (!mounted) return;
      
      final authController = context.read<AuthController>();
      final restored = await authController.restoreSession();
      
      if (!mounted) return;
      
      if (restored) {
        final user = authController.currentUser;
        if (user != null && !user.hasCompleteResidence) {
          context.go('/residence-gate');
          return;
        }

        // Si tiene sesión y residencia completa, preparamos Home
        await HomeEntryCoordinator.prepareHomeForFirstPaint(context);
        
        if (!mounted) return;
        
        // Ensure at least 900ms minimum duration for the splash loop animation to look premium
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 900) {
          await Future.delayed(Duration(milliseconds: 900 - elapsed));
        }
        
        setState(() {
          _isReady = true;
        });

        // Salida rápida y elegante de la animación final de ProxvelBrandedLoading
        await Future.delayed(const Duration(milliseconds: 400));
        
        if (mounted) {
          context.go('/main');
        }
      } else {
        // Fallback rápido si no hay sesión
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 900) {
          await Future.delayed(Duration(milliseconds: 900 - elapsed));
        }
        
        setState(() {
          _isReady = true;
        });
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: ProxvelBrandedLoading(
        variant: ProxvelLoadingVariant.splash,
        isReady: _isReady,
      ),
    );
  }
}
