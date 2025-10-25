// lib/services/timer_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class TimerStorageService {
  // Префиксы для ключей - теперь каждый eventId имеет свои ключи
  static String _eventTypeKey(String eventId) => 'timer_${eventId}_type';
  static String _startTimeKey(String eventId) => 'timer_${eventId}_start_time';
  static String _leftSecondsKey(String eventId) =>
      'timer_${eventId}_left_seconds';
  static String _rightSecondsKey(String eventId) =>
      'timer_${eventId}_right_seconds';
  static String _isLeftActiveKey(String eventId) =>
      'timer_${eventId}_is_left_active';
  static String _isRightActiveKey(String eventId) =>
      'timer_${eventId}_is_right_active';
  static String _elapsedSecondsKey(String eventId) =>
      'timer_${eventId}_elapsed_seconds';
  static String _isPausedKey(String eventId) => 'timer_${eventId}_is_paused';

  // Ключ для списка активных eventId
  static const String _activeTimersKey = 'active_timers';

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

    // Сохраняем данные для конкретного eventId
    await prefs.setString(_eventTypeKey(eventId), 'feeding');
    await prefs.setInt(
        _startTimeKey(eventId), startTime.millisecondsSinceEpoch);
    await prefs.setInt(_leftSecondsKey(eventId), leftSeconds);
    await prefs.setInt(_rightSecondsKey(eventId), rightSeconds);
    await prefs.setBool(_isLeftActiveKey(eventId), isLeftActive);
    await prefs.setBool(_isRightActiveKey(eventId), isRightActive);

    // Добавляем eventId в список активных таймеров
    await _addToActiveTimers(eventId);
  }

  // Сохранить состояние таймера сна
  Future<void> saveSleepTimerState({
    required String eventId,
    required DateTime startTime,
    required int elapsedSeconds,
    bool isPaused = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Сохраняем данные для конкретного eventId
    await prefs.setString(_eventTypeKey(eventId), 'sleep');
    await prefs.setInt(
        _startTimeKey(eventId), startTime.millisecondsSinceEpoch);
    await prefs.setInt(_elapsedSecondsKey(eventId), elapsedSeconds);
    await prefs.setBool(_isPausedKey(eventId), isPaused);

    // Добавляем eventId в список активных таймеров
    await _addToActiveTimers(eventId);
  }

  // Получить состояние конкретного таймера по eventId
  Future<Map<String, dynamic>?> getTimerState({String? eventId}) async {
    final prefs = await SharedPreferences.getInstance();

    // Если eventId не указан, возвращаем первый найденный таймер (обратная совместимость)
    if (eventId == null) {
      final activeTimers = await getActiveTimers();
      if (activeTimers.isEmpty) return null;
      eventId = activeTimers.first;
    }

    final eventType = prefs.getString(_eventTypeKey(eventId));
    final startTimeMs = prefs.getInt(_startTimeKey(eventId));
    if (eventType == null || startTimeMs == null) return null;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);

    if (eventType == 'feeding') {
      final leftSeconds = prefs.getInt(_leftSecondsKey(eventId)) ?? 0;
      final rightSeconds = prefs.getInt(_rightSecondsKey(eventId)) ?? 0;
      final isLeftActive = prefs.getBool(_isLeftActiveKey(eventId)) ?? false;
      final isRightActive = prefs.getBool(_isRightActiveKey(eventId)) ?? false;

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
      final elapsedSeconds = prefs.getInt(_elapsedSecondsKey(eventId)) ?? 0;
      final isPaused = prefs.getBool(_isPausedKey(eventId)) ?? false;

      return {
        'eventId': eventId,
        'eventType': eventType,
        'startTime': startTime,
        'elapsedSeconds': elapsedSeconds,
        'isPaused': isPaused,
      };
    }

    return null;
  }

  // Получить список всех активных таймеров
  Future<List<String>> getActiveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final activeTimers = prefs.getStringList(_activeTimersKey) ?? [];
    return activeTimers;
  }

  // Очистить состояние конкретного таймера
  Future<void> clearTimerState({String? eventId}) async {
    final prefs = await SharedPreferences.getInstance();

    if (eventId != null) {
      // Очищаем конкретный таймер
      await prefs.remove(_eventTypeKey(eventId));
      await prefs.remove(_startTimeKey(eventId));
      await prefs.remove(_leftSecondsKey(eventId));
      await prefs.remove(_rightSecondsKey(eventId));
      await prefs.remove(_isLeftActiveKey(eventId));
      await prefs.remove(_isRightActiveKey(eventId));
      await prefs.remove(_elapsedSecondsKey(eventId));
      await prefs.remove(_isPausedKey(eventId));

      // Удаляем из списка активных
      await _removeFromActiveTimers(eventId);
    } else {
      // Очищаем все таймеры (обратная совместимость)
      final activeTimers = await getActiveTimers();
      for (final id in activeTimers) {
        await clearTimerState(eventId: id);
      }
      await prefs.remove(_activeTimersKey);
    }
  }

  // Проверить, есть ли активный таймер для конкретного события
  Future<bool> hasActiveTimer({String? eventId}) async {
    if (eventId != null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_eventTypeKey(eventId));
    } else {
      // Проверяем наличие любых активных таймеров
      final activeTimers = await getActiveTimers();
      return activeTimers.isNotEmpty;
    }
  }

  // Добавить eventId в список активных таймеров
  Future<void> _addToActiveTimers(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final activeTimers = prefs.getStringList(_activeTimersKey) ?? [];
    if (!activeTimers.contains(eventId)) {
      activeTimers.add(eventId);
      await prefs.setStringList(_activeTimersKey, activeTimers);
    }
  }

  // Удалить eventId из списка активных таймеров
  Future<void> _removeFromActiveTimers(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final activeTimers = prefs.getStringList(_activeTimersKey) ?? [];
    activeTimers.remove(eventId);
    await prefs.setStringList(_activeTimersKey, activeTimers);
  }
}
