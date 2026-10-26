import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';

class HomeEntryCoordinator {
  /// Starts the catalogue in the background and warms only the local hero.
  /// Network photos load in their visible cards instead of delaying navigation.
  static Future<void> prepareHomeForFirstPaint(BuildContext context) async {
    final homeController = context.read<HomeController>();
    if (homeController.destinations.isEmpty && !homeController.isLoading) {
      unawaited(homeController.loadDestinations());
    }
    try {
      await precacheImage(
        const AssetImage('assets/images/home_andes_lagoon.webp'),
        context,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeEntryCoordinator] hero preload failed: $e');
      }
    }
  }

  /// Helper principal para enrutar usuarios de manera segura hacia el Home.
  /// Verifica auth, residencia, prepara data silenciosamente y luego viaja.
  /// No interrumpe visualmente a la pantalla actual (deja que el loading actual continúe).
  static Future<void> goToPreparedHome(BuildContext context) async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;

    if (user == null) {
      if (context.mounted) context.go('/welcome');
      return;
    }

    if (!user.hasCompleteResidence) {
      if (context.mounted) context.go('/residence-gate');
      return;
    }

    // El usuario está validado. Preparamos el Home mientras la pantalla actual
    // sigue mostrando su propio estado de loading (ej. botón de Login cargando).
    await prepareHomeForFirstPaint(context);

    if (context.mounted) {
      context.go('/main');
    }
  }
}
