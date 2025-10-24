// lib/services/timer_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class TimerStorageService {
  static const String _activeEventIdKey = 'active_event_id';
  static const String _eventTypeKey = 'event_type';
  static const String _startTimeKey = 'start_time';
  static const String _leftSecondsKey = 'left_seconds';
  static const String _rightSecondsKey = 'right_seconds';
  static const String _isLeftActiveKey = 'is_left_active';
  static const String _isRightActiveKey = 'is_right_active';

  // Сохранить состояние таймера кормления
  Future<void> saveFeedingTimerState({
    required String eventId,
    required DateTime startTime,
    required int leftSeconds,
    required int rightSeconds,
    required bool isLeftActive,
    required bool isRightActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeEventIdKey, eventId);
    await prefs.setString(_eventTypeKey, 'feeding');
    await prefs.setInt(_startTimeKey, startTime.millisecondsSinceEpoch);
    await prefs.setInt(_leftSecondsKey, leftSeconds);
    await prefs.setInt(_rightSecondsKey, rightSeconds);
    await prefs.setBool(_isLeftActiveKey, isLeftActive);
    await prefs.setBool(_isRightActiveKey, isRightActive);
  }

  // Сохранить состояние таймера сна
  Future<void> saveSleepTimerState({
    required String eventId,
    required DateTime startTime,
    required int elapsedSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeEventIdKey, eventId);
    await prefs.setString(_eventTypeKey, 'sleep');
    await prefs.setInt(_startTimeKey, startTime.millisecondsSinceEpoch);
    await prefs.setInt(
        _leftSecondsKey, elapsedSeconds); // Используем leftSeconds для elapsed
  }

  // Получить сохраненное состояние таймера
  Future<Map<String, dynamic>?> getTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final eventId = prefs.getString(_activeEventIdKey);
    if (eventId == null) return null;

    final eventType = prefs.getString(_eventTypeKey);
    final startTimeMs = prefs.getInt(_startTimeKey);
    if (eventType == null || startTimeMs == null) return null;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);

    if (eventType == 'feeding') {
      final leftSeconds = prefs.getInt(_leftSecondsKey) ?? 0;
      final rightSeconds = prefs.getInt(_rightSecondsKey) ?? 0;
      final isLeftActive = prefs.getBool(_isLeftActiveKey) ?? false;
      final isRightActive = prefs.getBool(_isRightActiveKey) ?? false;

      return {
        'eventId': eventId,
        'eventType': eventType,
        'startTime': startTime,
        'leftSeconds': leftSeconds,
        'rightSeconds': rightSeconds,
        'isLeftActive': isLeftActive,
        'isRightActive': isRightActive,
      };
    } else if (eventType == 'sleep') {
      final elapsedSeconds = prefs.getInt(_leftSecondsKey) ?? 0;

      return {
        'eventId': eventId,
        'eventType': eventType,
        'startTime': startTime,
        'elapsedSeconds': elapsedSeconds,
      };
    }

    return null;
  }

  // Очистить сохраненное состояние таймера
  Future<void> clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeEventIdKey);
    await prefs.remove(_eventTypeKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_leftSecondsKey);
    await prefs.remove(_rightSecondsKey);
    await prefs.remove(_isLeftActiveKey);
    await prefs.remove(_isRightActiveKey);
  }

  // Проверить, есть ли активный таймер
  Future<bool> hasActiveTimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_activeEventIdKey);
  }
}
