// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:baby_tracker/models/settings.dart';
import 'package:baby_tracker/models/event.dart';

class SettingsProvider with ChangeNotifier {
  static const String _settingsKey = 'user_settings';

  UserSettings _settings = const UserSettings();
  bool _isLoading = false;
  SharedPreferences? _prefs;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;

  List<EventType> get favoriteEventTypes => _settings.favoriteEventTypes;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      _prefs = await SharedPreferences.getInstance();
      final settingsJson = _prefs?.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = UserSettings.fromJson(settingsMap);
      } else {
        // Default favorites
        _settings = const UserSettings(favoriteEventTypes: [
          EventType.sleep,
          EventType.feeding,
          EventType.bottle,
          EventType.diaper,
        ]);
        await _saveSettings();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toJson());
      await _prefs!.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> updateFavoriteEventTypes(List<EventType> favoriteTypes) async {
    _settings = _settings.copyWith(favoriteEventTypes: favoriteTypes);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> addFavoriteEventType(EventType eventType) async {
    if (!favoriteEventTypes.contains(eventType)) {
      final newFavorites = [...favoriteEventTypes, eventType];
      await updateFavoriteEventTypes(newFavorites);
    }
  }

  Future<void> removeFavoriteEventType(EventType eventType) async {
    final newFavorites =
        favoriteEventTypes.where((e) => e != eventType).toList();
    await updateFavoriteEventTypes(newFavorites);
  }

  bool isFavorite(EventType eventType) {
    return favoriteEventTypes.contains(eventType);
  }
}
