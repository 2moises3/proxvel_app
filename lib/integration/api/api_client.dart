import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../local/secure_token_storage.dart';

/// Error de la API PROXVEL (4xx/5xx o respuesta inválida).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP del backend PROXVEL.
///
/// Todos los servicios lo usan con el patrón API-first + fallback mock:
/// si la petición falla (backend apagado, timeout, error), el servicio
/// captura la excepción y continúa con datos locales.
class ApiClient {
  static Function()? onUnauthorized;
  static Function(String)? onForbidden;

  final http.Client _http;
  final SecureTokenStorage _secureStorage;

  ApiClient({http.Client? httpClient, SecureTokenStorage? secureStorage}) 
      : _http = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? SecureTokenStorage();

  Future<Map<String, String>> _getHeaders({bool isGet = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isGet) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _withErrorHandling(Future<http.Response> Function() action) async {
    try {
      final response = await action();
      return _decode(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'No pudimos conectar con el servidor. Verifica tu conexión e intenta nuevamente.');
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    debugPrint('[API] GET $uri');
    final headers = await _getHeaders(isGet: true);
    return _withErrorHandling(() => _http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: ApiConfig.timeoutSeconds)));
  }

  Future<dynamic> post(String endpoint, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
    debugPrint('[API] POST $uri');
    final headers = await _getHeaders();
    return _withErrorHandling(() => _http
        .post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: ApiConfig.timeoutSeconds)));
  }

  Future<dynamic> put(String endpoint, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
    debugPrint('[API] PUT $uri');
    final headers = await _getHeaders();
    return _withErrorHandling(() => _http
        .put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: ApiConfig.timeoutSeconds)));
  }

  Future<dynamic> patch(String endpoint, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
    debugPrint('[API] PATCH $uri');
    final headers = await _getHeaders();
    return _withErrorHandling(() => _http
        .patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: ApiConfig.timeoutSeconds)));
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
    debugPrint('[API] DELETE $uri');
    final headers = await _getHeaders();
    return _withErrorHandling(() => _http
        .delete(
          uri,
          headers: headers,
        )
        .timeout(const Duration(seconds: ApiConfig.timeoutSeconds)));
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    required String filePath,
    required String fileField,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
    debugPrint('[API] POST MULTIPART $uri');
    
    return _withErrorHandling(() async {
      final request = http.MultipartRequest('POST', uri);
      
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      
      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds * 2));
          
      return await http.Response.fromStream(streamedResponse);
    });
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map<String, dynamic> && json.containsKey('success') && json['success'] == false) {
        throw ApiException(response.statusCode, json['message'] ?? 'Error desconocido de la API');
      }
      return json;
    }

    String errorMsg = 'Error inesperado del servidor.';
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map) {
        if (json['detail'] != null) {
          final detail = json['detail'];
          errorMsg = detail is Map ? (detail['message'] as String? ?? 'Revisa los datos e intenta nuevamente.') : detail is String ? detail : 'Revisa los datos e intenta nuevamente.';
        } else if (json['message'] != null) {
          errorMsg = json['message'].toString();
        } else if (json['error'] != null) {
          errorMsg = json['error'].toString();
        }
      }
    } catch (_) {
      errorMsg = response.statusCode >= 500 ? 'Ocurrió un problema inesperado. Intenta nuevamente.' : 'Error del servidor.';
    }

    final lower = errorMsg.toLowerCase();

    if (response.statusCode == 400 || response.statusCode == 409) {
      if (lower.contains('profile incomplete') || lower.contains('perfil incompleto')) {
        errorMsg = 'Completa tu perfil viajero para desbloquear recomendaciones personalizadas.';
      }
    } else if (response.statusCode == 401) {
      final url = response.request?.url.toString().toLowerCase() ?? '';
      final isAuthEndpoint = url.contains('/auth/login') || url.contains('login');
      if (!isAuthEndpoint) {
        onUnauthorized?.call();
        errorMsg = 'Tu sesión expiró. Inicia sesión nuevamente.';
      } else {
        errorMsg = 'Correo o contraseña incorrectos. Verifica tus datos.';
      }
    } else if (response.statusCode == 403) {
      if (lower.contains('desactivada') || lower.contains('eliminación') || lower.contains('deleted') || lower.contains('inactive')) {
        errorMsg = 'Tu cuenta ha sido desactivada o se encuentra en proceso de eliminación.';
      } else if (lower.contains('permiso')) {
        // Usa el mensaje del backend o fallback
        errorMsg = errorMsg != 'Error inesperado del servidor.' ? errorMsg : 'No tienes permiso para realizar esta acción.';
      } else {
        errorMsg = 'No tienes permiso para realizar esta acción.';
      }
      onForbidden?.call(errorMsg);
    } else if (response.statusCode == 404) {
      errorMsg = 'El recurso solicitado ya no está disponible.';
    } else if (response.statusCode >= 500) {
      errorMsg = 'Ocurrió un problema inesperado. Intenta nuevamente.';
    }

    throw ApiException(response.statusCode, errorMsg);
  }
}
