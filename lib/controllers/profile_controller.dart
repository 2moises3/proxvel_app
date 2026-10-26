import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/traveler_profile_model.dart';
import '../integration/services/profile_service.dart';
import '../integration/services/user_service.dart';
import '../integration/local/local_storage_service.dart';
import '../integration/api/api_client.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _profileService;
  final UserService? _userService;
  final LocalStorageService _storageService;
  bool isLoading = false;
  UserModel? user;
  TravelerProfileModel? profile;
  String? error;
  bool isShowingCachedProfile = false;

  int _mutationGeneration = 0;

  bool _isCurrent(int generation, String userId) =>
      generation == _mutationGeneration &&
      _storageService.getUser()?.id == userId;

  @override
  void dispose() {
    _mutationGeneration++;
    super.dispose();
  }

  ProfileController(
    this._profileService,
    this._storageService, {
    UserService? userService,
    // Keep the public named argument while storing the dependency privately.
    // ignore: prefer_initializing_formals
  }) : _userService = userService;

  Future<void> loadProfileData() async {
    final currentGeneration = ++_mutationGeneration;
    isLoading = true;
    error = null;
    isShowingCachedProfile = false;
    notifyListeners();

    try {
      // 1. Obtener usuario actual desde caché local (id real)
      final localUser = _storageService.getUser();
      final userId = localUser?.id;

      if (userId != null) {
        // 2. Consultar backend
        if (_userService != null) {
          // Bloque protegido 1: Cargar User Base
          try {
            final fetchedUser = await _userService.getUserById(userId);
            if (!_isCurrent(currentGeneration, userId)) return;
            user = fetchedUser;
            await _storageService.saveUser(fetchedUser);
          } catch (e) {
            if (!_isCurrent(currentGeneration, userId)) return;
            user = localUser;
            // Si el user base falla, sí mostramos error global
            if (currentGeneration == _mutationGeneration) {
              error =
                  'No pudimos cargar tu información de usuario. Intenta nuevamente.';
            }
          }

          if (!_isCurrent(currentGeneration, userId)) return;

          // Bloque protegido 2: Cargar Traveler Profile
          try {
            final fetchedProfile = await _profileService.getTravelerProfile(
              userId,
            );
            if (_isCurrent(currentGeneration, userId)) {
              profile = fetchedProfile;
              await _storageService.saveProfile(profile!);
            }
          } catch (profileError) {
            if (_isCurrent(currentGeneration, userId)) {
              final isProfileNotFound =
                  profileError is ApiException &&
                  profileError.statusCode == 404;
              if (isProfileNotFound) {
                profile = null; // Normal para un usuario nuevo sin perfil
              } else {
                // Fallo por timeout/500/etc.
                // Degradación elegante: leemos de local pero NO bloqueamos el UI
                final localProfile = _storageService.getProfile();
                profile = localProfile;
                isShowingCachedProfile = localProfile != null;
                if (localProfile == null) {
                  error =
                      'No pudimos cargar tu perfil viajero. Intenta nuevamente.';
                }
              }
            }
          }
        } else {
          // Si no hay UserService inyectado
          user = localUser;
        }
      } else {
        // No hay usuario activo
        if (currentGeneration == _mutationGeneration) {
          user = null;
          profile = null;
          error =
              'No se encontró un usuario activo. Regístrate o inicia sesión para continuar.';
        }
      }
    } catch (e) {
      if (currentGeneration == _mutationGeneration) {
        error =
            'No pudimos cargar tu perfil. Revisa tu conexión e intenta de nuevo.';
      }
    }

    if (currentGeneration == _mutationGeneration) {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearState() {
    _mutationGeneration++;
    user = null;
    profile = null;
    error = null;
    isShowingCachedProfile = false;
    isLoading = false;
    notifyListeners();
  }

  Future<void> updatePreferences(TravelerProfileModel updatedProfile) async {
    // Sin el usuario en memoria (recarga o enlace directo) se carga antes de guardar.
    // Nunca se guarda solo en el teléfono: el viajero creería que se guardó y el motor
    // seguiría usando las preferencias anteriores.
    if (user?.id == null) await loadProfileData();
    final userId = user?.id;
    if (userId == null) {
      throw Exception(
        'No pudimos identificar tu cuenta. Vuelve a iniciar sesión.',
      );
    }
    final generation = ++_mutationGeneration;
    if (!_isCurrent(generation, userId)) throw StateError('Session changed');

    error = null;
    isLoading = false;

    final realProfile = await _profileService.putTravelerProfile(
      userId: userId,
      profile: updatedProfile,
    );
    if (!_isCurrent(generation, userId)) throw StateError('Session changed');
    profile = realProfile;
    isShowingCachedProfile = false;
    await _storageService.saveProfile(realProfile);
    if (_isCurrent(generation, userId)) notifyListeners();
  }

  /// Cambia la preferencia "Aplicar IA en toda la app".
  /// Usa PATCH parcial (no recalcula pesos en backend). Optimista con reversión.
  Future<void> setApplyAiGlobally(bool value) async {
    if (user?.id == null) await loadProfileData();
    final userId = user?.id;
    final current = profile;
    if (current == null) return; // Sin perfil no hay preferencia que aplicar.
    if (userId == null) {
      // Nunca solo en el teléfono: el backend es quien aplica la IA en Explorar y Búsqueda.
      throw Exception(
        'No pudimos identificar tu cuenta. Vuelve a iniciar sesión.',
      );
    }

    final generation = ++_mutationGeneration;
    if (!_isCurrent(generation, userId)) throw StateError('Session changed');
    final previous = current;
    profile = current.copyWithAi(value);
    notifyListeners();

    try {
      final updated = await _profileService.patchTravelerProfile(
        userId: userId,
        updates: {'apply_ai_globally': value},
      );
      if (!_isCurrent(generation, userId)) throw StateError('Session changed');
      profile = updated;
      await _storageService.saveProfile(updated);
      if (_isCurrent(generation, userId)) notifyListeners();
    } catch (e) {
      // Revertir si falla la persistencia.
      if (_isCurrent(generation, userId)) {
        profile = previous;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _mutationGeneration++;
    user = null;
    profile = null;
    error = null;
    await _storageService.clearAllUserData();
    await _storageService.setSessionActive(false);
    notifyListeners();
  }
}
