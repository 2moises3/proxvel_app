import 'package:flutter/material.dart';
import '../../integration/local/local_storage_service.dart';

enum LanguageChoice { system, es, en }

class AppLanguage extends ChangeNotifier {
  AppLanguage(this._storage)
    : _choice = LanguageChoice.values.firstWhere(
        (value) => value.name == _storage.appLanguage,
        orElse: () => LanguageChoice.system,
      );

  final LocalStorageService _storage;
  LanguageChoice _choice;
  LanguageChoice get choice => _choice;

  Locale? get locale =>
      choice == LanguageChoice.system ? null : Locale(choice.name);

  String get languageCode {
    if (locale case final selected?) return selected.languageCode;
    return resolveSystemLocale(
      WidgetsBinding.instance.platformDispatcher.locales,
    ).languageCode;
  }

  static Locale resolveSystemLocale(List<Locale>? locales) {
    for (final deviceLocale in locales ?? const <Locale>[]) {
      if (deviceLocale.languageCode == 'es' ||
          deviceLocale.languageCode == 'en') {
        return Locale(deviceLocale.languageCode);
      }
    }
    return const Locale('es');
  }

  Future<void> select(LanguageChoice value) async {
    if (choice == value) return;
    _choice = value;
    notifyListeners();
    await _storage.setAppLanguage(value.name);
  }
}
