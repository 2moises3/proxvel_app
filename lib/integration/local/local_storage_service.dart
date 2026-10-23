import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../models/traveler_profile_model.dart';

class LocalStorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Session ──
  Future<void> setSessionActive(bool isActive) async {
    await _prefs?.setBool('is_session_active', isActive);
  }

  bool get isSessionActive => _prefs?.getBool('is_session_active') ?? false;

  // ── Intro Seen ──
  Future<void> setIntroSeen(bool seen) async {
    await _prefs?.setBool('intro_seen', seen);
  }

  bool get introSeen => _prefs?.getBool('intro_seen') ?? false;

  // ── Current User (active session user) ──
  Future<void> saveUser(UserModel user) async {
    await _prefs?.setString('user', jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final str = _prefs?.getString('user');
    if (str != null) return UserModel.fromJson(jsonDecode(str));
    return null;
  }



  // ── Profile ──
  Future<void> saveProfile(TravelerProfileModel profile) async {
    await _prefs?.setString('profile', jsonEncode(profile.toJson()));
  }

  TravelerProfileModel? getProfile() {
    final str = _prefs?.getString('profile');
    if (str != null) return TravelerProfileModel.fromJson(jsonDecode(str));
    return null;
  }

  // ── Favorites ──
  Future<void> addFavorite(String destinationId) async {
    final list = getFavorites();
    if (!list.contains(destinationId)) {
      list.add(destinationId);
      await _prefs?.setStringList('favorites', list);
    }
  }
  
  Future<void> removeFavorite(String destinationId) async {
    final list = getFavorites();
    if (list.contains(destinationId)) {
      list.remove(destinationId);
      await _prefs?.setStringList('favorites', list);
    }
  }

  List<String> getFavorites() {
    return _prefs?.getStringList('favorites') ?? [];
  }

  // ── Recent Searches ──
  Future<void> addRecentSearch(String query) async {
    final list = getRecentSearches();
    // Remove duplicates, keep most recent first
    list.remove(query);
    list.insert(0, query);
    // Keep only last 10
    final trimmed = list.take(10).toList();
    await _prefs?.setStringList('recent_searches', trimmed);
  }

  List<String> getRecentSearches() {
    return List<String>.from(_prefs?.getStringList('recent_searches') ?? []);
  }

  Future<void> clearRecentSearches() async {
    await _prefs?.setStringList('recent_searches', []);
  }

  // ── Limpieza Total de Sesión (Seguridad) ──
  Future<void> clearAllUserData() async {
    await _prefs?.remove('user');
    await _prefs?.remove('profile');
    // Aislamos estrictamente por usuario:
    await _prefs?.remove('favorites');
    await _prefs?.remove('local_favorites_v1');
    await _prefs?.remove('local_archives_v1');
    // No borramos 'intro_seen' ni 'recent_searches' ya que son de la app, no del usuario específico
  }
}
