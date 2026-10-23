import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../../models/auth_response_model.dart';
import '../../models/user_model.dart';

/// Resultado de pedir el código de recuperación.
class PasswordResetRequestResult {
  final String? error;
  final String? supportEmail;
  final int expiresMinutes;
  const PasswordResetRequestResult({this.error, this.supportEmail, this.expiresMinutes = 15});
}

class AuthService {
  final ApiClient apiClient;

  AuthService({required this.apiClient});

  Future<AuthLoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      debugPrint('[AuthService] Login success response received.');

      if (response['success'] == true && response['data'] != null) {
        try {
          return AuthLoginResponse.fromJson(response['data']);
        } catch (parseError) {
          debugPrint('[AuthService] Error parsing login response: $parseError');
          throw Exception('Error al procesar respuesta del servidor.');
        }
      }
      throw Exception(response['message'] ?? 'Error desconocido en login');
    } catch (e) {
      if (e is ApiException) {
        if (e.statusCode == 422) {
          throw ApiException(422, 'Correo inválido o formato incorrecto.');
        }
        rethrow;
      }
      if (e.toString().contains('Error al procesar respuesta')) {
        rethrow;
      }
      throw ApiException(0, 'No pudimos conectar con el servidor. Verifica tu conexión e intenta nuevamente.');
    }
  }

  /// Cambia la contraseña del usuario autenticado. El backend exige la actual,
  /// cierra las demás sesiones y devuelve un token nuevo (hay que guardarlo).
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await apiClient.post('/auth/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    final token = response['data']?['access_token'];
    if (response['success'] == true && token is String && token.isNotEmpty) {
      return token;
    }
    throw ApiException(500, 'No pudimos cambiar la contraseña. Intenta nuevamente.');
  }

  /// Cierra la sesión en todos los dispositivos (invalida todos los tokens emitidos).
  Future<void> logoutAll() async {
    await apiClient.post('/auth/logout-all');
  }

  /// Correo de soporte y si la recuperación por correo está activa (en la v1 no lo está).
  /// Si el backend no responde, se asume apagada.
  Future<({String? supportEmail, bool resetByEmail})> supportContact() async {
    try {
      final response = await apiClient.get('/auth/support-contact');
      final data = response['data'] as Map<String, dynamic>? ?? const {};
      return (
        supportEmail: data['support_email'] as String?,
        resetByEmail: data['password_reset_by_email'] == true,
      );
    } catch (_) {
      return (supportEmail: null, resetByEmail: false);
    }
  }

  /// Pide un código de 6 dígitos por correo. El backend responde igual exista o no la cuenta.
  Future<PasswordResetRequestResult> forgotPassword(String email) async {
    final response = await apiClient.post('/auth/forgot-password', {'email': email});
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    return PasswordResetRequestResult(
      supportEmail: data['support_email'] as String?,
      expiresMinutes: (data['expires_minutes'] as num?)?.toInt() ?? 15,
    );
  }

  /// Cambia la contraseña con el código recibido. Lanza ApiException con un mensaje legible si falla.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await apiClient.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  Future<UserModel> me() async {
    try {
      final response = await apiClient.get('/auth/me');
      if (response['success'] == true && response['data'] != null) {
        return UserModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Error desconocido al validar sesión');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      rethrow;
    }
  }
}
