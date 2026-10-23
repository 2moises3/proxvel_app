import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

class UserService {
  final ApiClient _api;

  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'accepted_terms': acceptedTerms,
      };
      debugPrint('POST URL: ${ApiConfig.apiBaseUrl}/users');
      final response = await _api.post('/users', body);
      final data = response['data'] as Map<String, dynamic>;
      return UserModel.fromApiJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw Exception('El correo electrónico ya está registrado.');
      } else if (e.statusCode == 422) {
        throw Exception('Error de validación: Revisa los datos ingresados.');
      }
      throw Exception('Error al registrar usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear usuario: $e');
    }
  }

  /// Registra la aceptación de la versión vigente de Términos y Privacidad.
  Future<UserModel> acceptTerms() async {
    final response = await _api.post('/users/me/accept-terms');
    return UserModel.fromApiJson(response['data'] as Map<String, dynamic>);
  }

  /// Pide eliminar la cuenta propia (acceso bloqueado ya; borrado tras 14 días).
  Future<void> deleteMyAccount(String password) async {
    await _api.post('/users/me/delete-account', {'password': password});
  }

  Future<UserModel> getUserById(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('PROFILE LOAD USER ID: $userId');
        debugPrint('GET USER URL: /users/$userId');
      }
      final response = await _api.get('/users/$userId');
      if (kDebugMode) {
        debugPrint('GET USER RESPONSE: $response');
      }
      final data = response['data'] as Map<String, dynamic>;
      return UserModel.fromApiJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Usuario no encontrado.');
      }
      throw Exception('Error al obtener usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al obtener usuario: $e');
    }
  }

  Future<UserModel> updateUser({
    required String userId,
    String? name,
    String? password,
    String? residenceDepartment,
    String? residenceProvince,
    String? residenceCity,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (password != null) body['password'] = password;
      if (residenceDepartment != null) body['residence_department'] = residenceDepartment;
      if (residenceProvince != null) body['residence_province'] = residenceProvince;
      if (residenceCity != null) body['residence_city'] = residenceCity;

      final response = await _api.patch('/users/$userId', body);
      final data = response['data'] as Map<String, dynamic>;
      return UserModel.fromApiJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('Usuario no encontrado.');
      } else if (e.statusCode == 422) {
        throw Exception('Error de validación al actualizar.');
      }
      throw Exception('Error al actualizar usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar usuario: $e');
    }
  }

  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('POST MULTIPART URL: /users/$userId/avatar');
      }
      
      final response = await _api.postMultipart(
        '/users/$userId/avatar',
        filePath: filePath,
        fileField: 'file',
      );
      
      if (kDebugMode) {
        debugPrint('POST AVATAR RESPONSE: $response');
      }
      
      final data = response['data'] as Map<String, dynamic>;
      return data['avatar_url'] as String;
    } on ApiException catch (e) {
      throw Exception('Error al subir avatar: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al subir avatar: $e');
    }
  }
}
