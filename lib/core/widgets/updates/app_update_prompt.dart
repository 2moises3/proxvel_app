import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../integration/services/app_update_service.dart';
import '../../localization/app_language.dart';
import '../../router/app_router.dart';

/// Comprueba al abrir y al volver a primer plano. Muestra un aviso por versión.
class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({super.key, required this.child});
  final Widget child;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt>
    with WidgetsBindingObserver {
  bool _checking = false;
  DateTime? _lastCheck;
  Timer? _startupCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startupCheck = Timer(const Duration(seconds: 4), _check);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startupCheck?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (!mounted || kIsWeb || !Platform.isAndroid || _checking) return;
    if (_lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < const Duration(hours: 1)) {
      return;
    }
    _checking = true;
    _lastCheck = DateTime.now();
    try {
      final release = await AppUpdateService().latestAvailable();
      if (release == null || !mounted) return;
      final preferences = await SharedPreferences.getInstance();
      if ((preferences.getInt('update_prompted_code') ?? 0) >=
          release.versionCode) {
        return;
      }
      if (!mounted) return;
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext == null || !navigatorContext.mounted) return;
      final english = context.read<AppLanguage>().languageCode == 'en';
      await preferences.setInt('update_prompted_code', release.versionCode);
      if (!navigatorContext.mounted) return;
      await showDialog<void>(
        context: navigatorContext,
        builder: (dialogContext) => AlertDialog(
          title: Text(english
              ? 'PROXVEL ${release.versionName} is available'
              : 'PROXVEL ${release.versionName} está disponible'),
          content: Text(release.changelog?.trim().isNotEmpty == true
              ? release.changelog!
              : english
                  ? 'See what changed and choose when to install the update.'
                  : 'Mira qué cambió y elige cuándo instalar la actualización.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(english ? 'Later' : 'Más tarde'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                navigatorContext.go('/profile/updates');
              },
              child: Text(english ? 'View update' : 'Ver actualización'),
            ),
          ],
        ),
      );
    } catch (_) {
      // La conectividad no debe interrumpir el uso de la app.
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
