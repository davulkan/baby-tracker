// lib/services/events_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_tracker/models/event.dart';

/// Базовый репозиторий для работы с событиями в Firestore
class EventsRepository {
  final FirebaseFirestore _firestore;

  EventsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // STREAMS - Потоки данных
  // ============================================================================

  /// Stream всех событий для конкретного ребенка
  Stream<List<Event>> getEventsStream(String babyId) {
    return _firestore
        .collection('events')
        .where('baby_id', isEqualTo: babyId)
        .orderBy('started_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('Error in getEventsStream: $error');
      return <Event>[];
    });
  }

  /// Stream событий за сегодня
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
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('Error in getTodayEventsStream: $error');
      return <Event>[];
    });
  }

  /// Stream активных событий (с null endedAt)
  Stream<List<Event>> getActiveEventsStream(String babyId) {
    return _firestore
        .collection('events')
        .where('baby_id', isEqualTo: babyId)
        .where('ended_at', isNull: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('Error in getActiveEventsStream: $error');
      return <Event>[];
    });
  }

  /// Stream активных событий определенного типа
  Stream<List<Event>> getActiveEventsByTypeStream(
      String babyId, EventType eventType) {
    return _firestore
        .collection('events')
        .where('baby_id', isEqualTo: babyId)
        .where('event_type', isEqualTo: eventType.name)
        .where('ended_at', isNull: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('Error in getActiveEventsByTypeStream: $error');
      return <Event>[];
    });
  }

  // ============================================================================
  // CRUD операции
  // ============================================================================

  /// Создание события
  Future<String?> createEvent(Event event) async {
    try {
      final docRef =
          await _firestore.collection('events').add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating event: $e');
      return null;
    }
  }

  /// Создание события с использованием Map (для совместимости)
  Future<String?> createEventFromMap(Map<String, dynamic> eventData) async {
    try {
      final docRef = await _firestore.collection('events').add(eventData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating event from map: $e');
      return null;
    }
  }

  /// Получение события по ID
  Future<Event?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return Event.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting event: $e');
      return null;
    }
  }

  /// Обновление события
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        ...updates,
        'last_modified_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  /// Обновление полного объекта события
  Future<bool> updateEventObject(Event event) async {
    try {
      await _firestore.collection('events').doc(event.id).update({
        ...event.toFirestore(),
        'last_modified_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating event object: $e');
      return false;
    }
  }

  /// Удаление события
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  // ============================================================================
  // Специализированные запросы
  // ============================================================================

  /// Получение активного события определенного типа
  Future<Event?> getActiveEvent(String babyId, EventType eventType) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('baby_id', isEqualTo: babyId)
          .where('event_type', isEqualTo: eventType.name)
          .where('ended_at', isNull: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Event.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting active event: $e');
      return null;
    }
  }

  /// Получение событий за период
  Future<List<Event>> getEventsByPeriod(
      String babyId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('baby_id', isEqualTo: babyId)
          .where('started_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('started_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting events by period: $e');
      return [];
    }
  }

  /// Обновление времени окончания события
  Future<bool> updateEventEndTime(String eventId, DateTime endedAt) async {
    return updateEvent(eventId, {
      'ended_at': Timestamp.fromDate(endedAt),
    });
  }
}
