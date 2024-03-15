import 'package:flutter/material.dart' show Brightness;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:score_board_detect/service/localization.dart';

enum Language { en, vi }

extension LanguageExtension on Language {
  String get name {
    switch (this) {
      case Language.en:
        return 'English';
      case Language.vi:
        return 'Tiếng Việt';
      default:
        return 'English';
    }
  }

  String get nameToSave {
    switch (this) {
      case Language.en:
        return 'en';
      default:
        return 'vi';
    }
  }

  static Language mapping(String? name) {
    switch (name) {
      case 'en':
        return Language.en;
      default:
        return Language.vi;
    }
  }
}

class SettingsState extends GetxController {
  final Brightness platformBrightness;
  final _isDarkMode = false.obs;
  final _language = Language.vi.obs;
  final _autoSaveOnCloud = false.obs;
  final _storage = GetStorage();

  //keys
  static const String _isDarkModeKey = 'isDarkMode';
  static const String _languageKey = 'language';
  static const String _autoSaveOnCloudKey = 'autoSaveOnCloud';

  SettingsState(this.platformBrightness);

  @override
  void onInit() {
    super.onInit();
    _loadSettingsFromStorage();
  }

  bool get isDarkMode => _isDarkMode.value;

  Language get language => _language.value;

  bool get autoSaveOnCloud => _autoSaveOnCloud.value;

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _storage.write(_isDarkModeKey, _isDarkMode.value);
    update();
  }

  void toggleLanguage() {
    _language.value =
        (_language.value == Language.en) ? Language.vi : Language.en;
    _storage.write(_languageKey, _language.value.nameToSave);
    LocalizationService.changeLocale(_language.value.nameToSave);
    update();
  }

  void toggleAutoSaveOnCloud() {
    _autoSaveOnCloud.value = !_autoSaveOnCloud.value;
    _storage.write(_autoSaveOnCloudKey, _autoSaveOnCloud.value);
  }

  void _loadSettingsFromStorage() {
    _isDarkMode.value = _storage.read(_isDarkModeKey) ?? false;
    _autoSaveOnCloud.value = _storage.read(_autoSaveOnCloudKey) ?? false;
    _language.value = LanguageExtension.mapping(_storage.read(_languageKey));
  }

  void clear() {
    _storage.remove(_isDarkModeKey);
    _storage.remove(_autoSaveOnCloudKey);
    _storage.remove(_languageKey);
    _isDarkMode.value = platformBrightness == Brightness.dark;
    _language.value = Language.vi;
    Get.updateLocale(LocalizationService.defaultLocale);
    _autoSaveOnCloud.value = false;
    update();
  }
}
