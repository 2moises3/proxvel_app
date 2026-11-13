import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Servicio para el manejo seguro del JWT u otros tokens confidenciales.
/// Emplea flutter_secure_storage (Keychain en iOS, EncryptedSharedPreferences en Android).
class SecureTokenStorage {
  final _storage = const FlutterSecureStorage();
  
  static const _tokenKey = 'jwt_access_token';
  String? _memoryToken;
  bool _memoryOnly = false;

  Future<void> setPersistence(bool persist) async {
    if (!persist) await _storage.delete(key: _tokenKey);
    _memoryOnly = !persist;
    _memoryToken = null;
  }

  /// Guarda el Access Token.
  Future<void> saveAccessToken(String token) async {
    if (_memoryOnly) {
      _memoryToken = token;
      return;
    }
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Error writing secure storage: $e');
    }
  }

  /// Recupera el Access Token. Retorna null si no existe.
  Future<String?> getAccessToken() async {
    if (_memoryOnly) return _memoryToken;
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error reading secure storage: $e');
      try {
        await _storage.delete(key: _tokenKey);
      } catch (_) {}
      return null;
    }
  }

  /// Elimina el Access Token, cerrando la sesión de forma efectiva a nivel de auth.
  Future<void> deleteAccessToken() async {
    _memoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('Error deleting secure storage: $e');
    }
  }

  /// Retorna true si hay un token guardado.
  Future<bool> hasAccessToken() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
