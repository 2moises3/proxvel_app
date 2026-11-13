import 'package:flutter/material.dart';
import 'core/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'integration/local/local_storage_service.dart';
import 'integration/api/api_client.dart';
import 'core/router/app_router.dart';
import 'controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

bool _isHandlingUnauthorized = false;
DateTime? _lastForbiddenTime;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = LocalStorageService();
  await storageService.init();

  ApiClient.onUnauthorized = () {
    if (_isHandlingUnauthorized) return;
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      _isHandlingUnauthorized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final auth = context.read<AuthController>();
        await auth.logout();
        if (context.mounted) {
          context.go('/welcome');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.errorText('Tu sesión expiró. Inicia sesión nuevamente.')),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        Future.delayed(const Duration(seconds: 2), () {
          _isHandlingUnauthorized = false;
        });
      });
    }
  };

  ApiClient.onForbidden = (String message) {
    // Evitar múltiples snackbars si hay varias peticiones concurrentes
    final now = DateTime.now();
    if (_lastForbiddenTime != null && now.difference(_lastForbiddenTime!).inSeconds < 2) return;
    _lastForbiddenTime = now;

    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.errorText(message)),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      });
    }
  };

  runApp(ProxvelApp(storageService: storageService));
}
