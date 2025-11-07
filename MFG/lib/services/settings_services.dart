// lib/services/settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static SettingsService? _instance;
  
  // Singleton pattern
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }
  
  SettingsService._();
  
  // Current settings (cached in memory)
  AppSettings? _currentSettings;
  
  // Get current settings
  AppSettings get currentSettings => _currentSettings ?? AppSettings();
  
  // Load settings from storage
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = prefs.getString(_settingsKey);
      
      if (settingsString != null) {
        _currentSettings = AppSettings.decode(settingsString);
      } else {
        _currentSettings = AppSettings();
      }
      
      return _currentSettings!;
    } catch (e) {
      print('Error loading settings: $e');
      _currentSettings = AppSettings();
      return _currentSettings!;
    }
  }
  
  // Save settings to storage
  Future<bool> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_settingsKey, settings.encode());
      
      if (success) {
        _currentSettings = settings;
      }
      
      return success;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }
  
  // Update a specific setting
  Future<bool> updateSetting<T>({
    required String key,
    required T value,
  }) async {
    final current = _currentSettings ?? AppSettings();
    AppSettings updated;
    
    switch (key) {
      case 'productionLines':
        updated = current.copyWith(productionLines: value as List<String>);
        break;
      case 'showProductionNumbers':
        updated = current.copyWith(showProductionNumbers: value as bool);
        break;
      case 'cardsPerRow':
        updated = current.copyWith(cardsPerRow: value as int);
        break;
      case 'fetchIntervalSeconds':
        updated = current.copyWith(fetchIntervalSeconds: value as int);
        break;
      case 'showStaleDataWarning':
        updated = current.copyWith(showStaleDataWarning: value as bool);
        break;
      case 'dataExpiryMinutes':
        updated = current.copyWith(dataExpiryMinutes: value as int);
        break;
      case 'darkMode':
        updated = current.copyWith(darkMode: value as bool);
        break;
      case 'showCommunicationsPanel':
        updated = current.copyWith(showCommunicationsPanel: value as bool);
        break;
      case 'cardScale':
        updated = current.copyWith(cardScale: value as double);
        break;
      case 'autoScroll':
        updated = current.copyWith(autoScroll: value as bool);
        break;
      case 'scrollIntervalSeconds':
        updated = current.copyWith(scrollIntervalSeconds: value as int);
        break;
      default:
        return false;
    }
    
    return await saveSettings(updated);
  }
  
  // Reset to default settings
  Future<bool> resetToDefaults() async {
    return await saveSettings(AppSettings());
  }
  
  // Export settings as JSON string
  String exportSettings() {
    return (_currentSettings ?? AppSettings()).encode();
  }
  
  // Import settings from JSON string
  Future<bool> importSettings(String jsonString) async {
    try {
      final settings = AppSettings.decode(jsonString);
      return await saveSettings(settings);
    } catch (e) {
      print('Error importing settings: $e');
      return false;
    }
  }
}