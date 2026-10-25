/// Configuración central de la API PROXVEL.
///
/// `10.0.2.2` es el alias del host (localhost de tu PC) visto desde
/// el emulador Android. Para dispositivo físico usar la IP LAN de la PC.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get _fallbackUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    if (kReleaseMode && Platform.isAndroid) {
      return 'https://proxback-production.up.railway.app/api/v1';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    // iOS Simulator y Desktop
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// URL base activa de la API.
  /// Lee prioritariamente la variable `API_BASE_URL` definida en `.env`.
  /// Si está presente, se usa de manera global en toda la app sin importar la plataforma.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.trim().isNotEmpty) {
      String url = fromEnv.trim().replaceAll(RegExp(r'/+$'), '');
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      return url;
    }
    return _fallbackUrl;
  }

  /// Alias de compatibilidad: delega siempre a la URL base activa
  static String get webBaseUrl => baseUrl;
  static String get apiBaseUrl => baseUrl;

  static const int timeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static const bool useMockFallback = bool.fromEnvironment(
    'USE_MOCK_FALLBACK',
    defaultValue: false,
  );

  // Endpoints
  static const String favorites = '/favorites';
}
