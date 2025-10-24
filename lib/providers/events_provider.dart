// lib/providers/events_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/models/sleep_details.dart';
import 'package:baby_tracker/models/diaper_details.dart';

class EventsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream событий для конкретного ребенка
  Stream<List<Event>> getEventsStream(String babyId) {
    return _firestore
        .collection('events')
        .where('baby_id', isEqualTo: babyId)
        .orderBy('started_at', descending: true)
        .limit(50) // Ограничиваем для производительности
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  // Stream событий за сегодня
  Stream<List<Event>> getTodayEventsStream(String babyId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection('events')
        .where('baby_id', isEqualTo: babyId)
        .where('started_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('started_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  // Добавление события сна
  Future<String?> addSleepEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required DateTime endedAt,
    required String createdBy,
    required String createdByName,
    required SleepType sleepType,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Создаем основное событие
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.sleep,
        startedAt: startedAt,
        endedAt: endedAt,
        notes: notes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
      );

      final eventDoc =
          await _firestore.collection('events').add(event.toFirestore());

      // Создаем детали сна
      final sleepDetails = SleepDetails(
        id: '',
        eventId: eventDoc.id,
        sleepType: sleepType,
        notes: notes,
      );

      await _firestore
          .collection('sleep_details')
          .doc(eventDoc.id)
          .set(sleepDetails.toFirestore());

      _isLoading = false;
      notifyListeners();

      return eventDoc.id;
    } catch (e) {
      _error = 'Ошибка добавления сна';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error adding sleep event: $e');
      return null;
    }
  }

  // Добавление события кормления
  Future<String?> addFeedingEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    DateTime? endedAt,
    required String createdBy,
    required String createdByName,
    required FeedingType feedingType,
    BreastSide? breastSide,
    int? leftDurationSeconds,
    int? rightDurationSeconds,
    double? bottleAmountMl,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Создаем основное событие
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.feeding,
        startedAt: startedAt,
        endedAt: endedAt,
        notes: notes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
      );

      final eventDoc =
          await _firestore.collection('events').add(event.toFirestore());

      // Создаем детали кормления
      final feedingDetails = FeedingDetails(
        id: '',
        eventId: eventDoc.id,
        feedingType: feedingType,
        breastSide: breastSide,
        leftDurationSeconds: leftDurationSeconds,
        rightDurationSeconds: rightDurationSeconds,
        bottleAmountMl: bottleAmountMl,
        notes: notes,
      );

      await _firestore
          .collection('feeding_details')
          .doc(eventDoc.id)
          .set(feedingDetails.toFirestore());

      _isLoading = false;
      notifyListeners();

      return eventDoc.id;
    } catch (e) {
      _error = 'Ошибка добавления кормления';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error adding feeding event: $e');
      return null;
    }
  }

  // Добавление события подгузника
  Future<String?> addDiaperEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required String createdBy,
    required String createdByName,
    required DiaperType diaperType,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Создаем основное событие
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.diaper,
        startedAt: time,
        notes: notes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
      );

      final eventDoc =
          await _firestore.collection('events').add(event.toFirestore());

      // Создаем детали подгузника
      final diaperDetails = DiaperDetails(
        id: '',
        eventId: eventDoc.id,
        diaperType: diaperType,
        notes: notes,
      );

      await _firestore
          .collection('diaper_details')
          .doc(eventDoc.id)
          .set(diaperDetails.toFirestore());

      _isLoading = false;
      notifyListeners();

      return eventDoc.id;
    } catch (e) {
      _error = 'Ошибка добавления подгузника';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error adding diaper event: $e');
      return null;
    }
  }

  // Обновление события
  Future<bool> updateEvent(Event event) async {
    try {
      await _firestore.collection('events').doc(event.id).update({
        ...event.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления события';
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  // Обновление деталей сна
  Future<bool> updateSleepDetails(String eventId, SleepDetails details) async {
    try {
      await _firestore.collection('sleep_details').doc(eventId).update({
        ...details.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления деталей сна';
      debugPrint('Error updating sleep details: $e');
      return false;
    }
  }

  // Обновление деталей кормления
  Future<bool> updateFeedingDetails(
      String eventId, FeedingDetails details) async {
    try {
      await _firestore.collection('feeding_details').doc(eventId).update({
        ...details.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления деталей кормления';
      debugPrint('Error updating feeding details: $e');
      return false;
    }
  }

  // Обновление деталей подгузника
  Future<bool> updateDiaperDetails(
      String eventId, DiaperDetails details) async {
    try {
      await _firestore.collection('diaper_details').doc(eventId).update({
        ...details.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления деталей подгузника';
      debugPrint('Error updating diaper details: $e');
      return false;
    }
  }

  // Удаление события
  Future<bool> deleteEvent(String eventId, EventType eventType) async {
    try {
      // Удаляем основное событие
      await _firestore.collection('events').doc(eventId).delete();

      // Удаляем детали в зависимости от типа
      switch (eventType) {
        case EventType.sleep:
          await _firestore.collection('sleep_details').doc(eventId).delete();
          break;
        case EventType.feeding:
          await _firestore.collection('feeding_details').doc(eventId).delete();
          break;
        case EventType.diaper:
          await _firestore.collection('diaper_details').doc(eventId).delete();
          break;
        default:
          break;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления события';
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  // Получение деталей сна
  Future<SleepDetails?> getSleepDetails(String eventId) async {
    try {
      final doc =
          await _firestore.collection('sleep_details').doc(eventId).get();

      if (doc.exists) {
        return SleepDetails.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting sleep details: $e');
      return null;
    }
  }

  // Получение деталей кормления
  Future<FeedingDetails?> getFeedingDetails(String eventId) async {
    try {
      final doc =
          await _firestore.collection('feeding_details').doc(eventId).get();

      if (doc.exists) {
        return FeedingDetails.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting feeding details: $e');
      return null;
    }
  }

  // Получение деталей подгузника
  Future<DiaperDetails?> getDiaperDetails(String eventId) async {
    try {
      final doc =
          await _firestore.collection('diaper_details').doc(eventId).get();

      if (doc.exists) {
        return DiaperDetails.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting diaper details: $e');
      return null;
    }
  }

  // Статистика за период
  Future<Map<String, int>> getStatistics(
      String babyId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('baby_id', isEqualTo: babyId)
          .where('started_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('started_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final events =
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      // Подсчитываем статистику
      final stats = <String, int>{
        'sleep_count': 0,
        'sleep_minutes': 0,
        'feeding_count': 0,
        'feeding_minutes': 0,
        'diaper_count': 0,
      };

      for (final event in events) {
        switch (event.eventType) {
          case EventType.sleep:
            stats['sleep_count'] = stats['sleep_count']! + 1;
            if (event.duration != null) {
              stats['sleep_minutes'] =
                  stats['sleep_minutes']! + event.duration!.inMinutes;
            }
            break;
          case EventType.feeding:
            stats['feeding_count'] = stats['feeding_count']! + 1;
            if (event.duration != null) {
              stats['feeding_minutes'] =
                  stats['feeding_minutes']! + event.duration!.inMinutes;
            }
            break;
          case EventType.diaper:
            stats['diaper_count'] = stats['diaper_count']! + 1;
            break;
          default:
            break;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
