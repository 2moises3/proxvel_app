import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../integration/local/secure_token_storage.dart';
import '../integration/local/local_storage_service.dart';
import '../integration/services/user_service.dart';
import '../integration/services/auth_service.dart';
import '../integration/api/api_client.dart';

class AuthController extends ChangeNotifier {
  final LocalStorageService _storage;
  final SecureTokenStorage _secureStorage;
  final UserService? _userService;
  final AuthService? _authService;

  AuthController(
    this._storage,
    this._secureStorage, [
    this._userService,
    this._authService,
  ]);

  int _sessionRevision = 0;

  bool get isAuthenticated => _storage.isSessionActive;

  /// Returns the currently stored session user, or null if none saved.
  UserModel? get currentUser => _storage.getUser();

  Future<void> saveToken(String token) async =>
      await _secureStorage.saveAccessToken(token);
  Future<void> clearToken() async => await _secureStorage.deleteAccessToken();
  Future<bool> hasToken() async => await _secureStorage.hasAccessToken();

  Future<void> register({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    if (_userService == null) {
      throw Exception('Servicio de usuarios no disponible.');
    }
    if (_authService == null) {
      throw Exception('Servicio de autenticación no disponible.');
    }

    // Concatena nombres antes de enviar si es necesario
    final unifiedName = lastName.isNotEmpty ? '$name $lastName'.trim() : name;

    // Llama al backend
    await _userService.createUser(
      name: unifiedName,
      email: email,
      password: password,
      acceptedTerms: acceptedTerms,
    );

    // Auto-login post-registro
    try {
      final loginResponse = await _authService.login(
        email: email,
        password: password,
      );

      await saveToken(loginResponse.accessToken);
      await _storage.saveUser(loginResponse.user);
      await _storage.setSessionActive(true);
      notifyListeners();
    } catch (e) {
      throw Exception(
        'Tu cuenta fue creada, pero no se pudo iniciar sesión automáticamente. Inicia sesión manualmente.',
      );
    }
  }

  /// Autentica usando JWT y guarda la sesión
  Future<String?> login(String email, String password) async {
    _sessionRevision++;
    if (email.trim().isEmpty || password.isEmpty) {
      return 'Correo y contraseña son requeridos.';
    }

    if (_authService == null) return 'Servicio de autenticación no disponible.';

    try {
      final response = await _authService.login(
        email: email.trim(),
        password: password,
      );

      await saveToken(response.accessToken);
      await _storage.saveUser(response.user);
      await _storage.setSessionActive(true);
      notifyListeners();

      return null; // Null means success (no error)
    } catch (e) {
      if (e is ApiException) {
        return e.message;
      }
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Cambia la contraseña. Devuelve null si salió bien o el mensaje de error para mostrar.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_authService == null) return 'Servicio de autenticación no disponible.';
    try {
      final newToken = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      // El backend cerró las demás sesiones: se reemplaza el token de este dispositivo.
      await saveToken(newToken);
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return 'No pudimos cambiar la contraseña. Verifica tu conexión e intenta nuevamente.';
    }
  }

  /// Pide el código de recuperación. `error` es null si salió bien.
  Future<PasswordResetRequestResult> requestPasswordReset(String email) async {
    if (_authService == null) {
      return const PasswordResetRequestResult(
        error: 'Servicio de autenticación no disponible.',
      );
    }
    try {
      return await _authService.forgotPassword(email.trim());
    } catch (e) {
      if (e is ApiException) {
        return PasswordResetRequestResult(error: e.message);
      }
      return const PasswordResetRequestResult(
        error:
            'No pudimos enviar el código. Verifica tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Cambia la contraseña con el código. Devuelve null si salió bien o el mensaje de error.
  Future<String?> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (_authService == null) return 'Servicio de autenticación no disponible.';
    try {
      await _authService.resetPassword(
        email: email.trim(),
        code: code,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return 'No pudimos cambiar la contraseña. Verifica tu conexión e intenta de nuevo.';
    }
  }

  /// Registra la aceptación de los textos legales vigentes y actualiza el usuario guardado.
  Future<bool> acceptCurrentTerms() async {
    if (_userService == null) return false;
    try {
      final updated = await _userService.acceptTerms();
      await _storage.saveUser(updated);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _sessionRevision++;
    await clearToken();
    await _storage.clearAllUserData(); // Borrado estricto de seguridad
    await _storage.setSessionActive(false);
    notifyListeners();
  }

  /// Restaura la sesión validando el token contra el backend
  Future<bool> restoreSession() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        await _storage.setSessionActive(false);
        notifyListeners();
        return false;
      }

      if (_authService == null) return false;

      final user = await _authService.me();
      await _storage.saveUser(user);
      await _storage.setSessionActive(true);
      notifyListeners();
      return true;
    } catch (e) {
      // Si falla (por ejemplo 401, o error de storage), limpiamos sesión
      try {
        await logout();
      } catch (_) {
        await _storage.setSessionActive(false);
        notifyListeners();
      }
      return false;
    }
  }

  /// Updates the current user's profile info
  Future<void> updateUserProfile({
    required String name,
    required String lastName,
    required String email,
    String? residenceDepartment,
    String? residenceProvince,
    String? residenceCity,
  }) async {
    final currentUser = _storage.getUser();
    final revision = _sessionRevision;
    if (currentUser == null || _userService == null) {
      throw StateError('No hay una sesión disponible para guardar el perfil.');
    }
    final unifiedName = lastName.isNotEmpty ? '$name $lastName'.trim() : name;
    final realUser = await _userService.updateUser(
      userId: currentUser.id,
      name: unifiedName,
      residenceDepartment: residenceDepartment,
      residenceProvince: residenceProvince,
      residenceCity: residenceCity,
    );
    if (_sessionRevision != revision ||
        _storage.getUser()?.id != currentUser.id) {
      throw StateError('La sesión cambió durante la actualización.');
    }
    await _storage.saveUser(realUser);
    notifyListeners();
  }

  /// Sube un nuevo avatar a Cloudinary y actualiza la sesión
  Future<void> uploadAvatar({
    String? filePath,
    List<int>? fileBytes,
    String? filename,
  }) async {
    final owner = _storage.getUser();
    final revision = _sessionRevision;
    if (owner == null || _userService == null) {
      throw StateError('No hay una sesión disponible para cambiar la foto.');
    }
    final newAvatarUrl = await _userService.uploadAvatar(
      userId: owner.id,
      filePath: filePath,
      fileBytes: fileBytes,
      filename: filename,
    );
    final currentUser = _storage.getUser();
    if (_sessionRevision != revision ||
        currentUser == null ||
        currentUser.id != owner.id) {
      throw StateError('La sesión cambió durante la subida.');
    }
    final uri = Uri.tryParse(newAvatarUrl);
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') {
      throw StateError('La foto no devolvió una dirección válida.');
    }
    final updatedUser = UserModel(
      id: currentUser.id,
      name: currentUser.name,
      lastName: currentUser.lastName,
      email: currentUser.email,
      password: currentUser.password,
      role: currentUser.role,
      isActive: currentUser.isActive,
      avatarUrl: newAvatarUrl,
      residenceDepartment: currentUser.residenceDepartment,
      residenceProvince: currentUser.residenceProvince,
      residenceCity: currentUser.residenceCity,
      acceptedTermsVersion: currentUser.acceptedTermsVersion,
    );
    await _storage.saveUser(updatedUser);
    notifyListeners();
  }
}
