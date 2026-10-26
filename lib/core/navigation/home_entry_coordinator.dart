import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';

class HomeEntryCoordinator {
  static const Duration _homePreparationTimeout = Duration(seconds: 5);

  /// Prepara los datos e imágenes críticas del Home de forma silenciosa.
  /// No realiza validaciones de sesión ni ruteos, solo trabajo pesado.
  static Future<void> prepareHomeForFirstPaint(BuildContext context) async {
    final homeController = context.read<HomeController>();
    if (kDebugMode) {
      debugPrint(
        '[HomeEntryCoordinator] destinations before: ${homeController.destinations.length}',
      );
    }

    try {
      if (homeController.destinations.isEmpty) {
        if (kDebugMode) {
          debugPrint('[HomeEntryCoordinator] loadDestinations start');
        }
        await homeController.loadDestinations();
        if (kDebugMode) {
          debugPrint('[HomeEntryCoordinator] loadDestinations end');
        }
      }

      if (!context.mounted) return;
      final urls = homeController.featuredDestinations
          .map((d) => d.imageUrl.trim())
          .where((url) => url.isNotEmpty)
          .take(5)
          .toSet()
          .toList();

      // Agregar assets estáticos críticos de la UI del Home
      urls.addAll(['assets/images/home_andes_lagoon.webp']);

      if (kDebugMode) debugPrint('[HomeEntryCoordinator] urls selected: $urls');

      await Future.wait(
        urls.map((url) async {
          try {
            final ImageProvider provider = url.startsWith('http')
                ? NetworkImage(url)
                : AssetImage(url) as ImageProvider;
            await precacheImage(provider, context);
            if (kDebugMode) {
              debugPrint('[HomeEntryCoordinator] precache success $url');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[HomeEntryCoordinator] precache failed $url: $e');
            }
          }
        }),
      ).timeout(_homePreparationTimeout);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeEntryCoordinator] prepareHome error: $e');
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
