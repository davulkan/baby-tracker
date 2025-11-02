// lib/services/activities_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/services/events_repository.dart';

/// Сервис для работы с активностями (прогулка, купание, бутылка)
class ActivitiesService {
  final EventsRepository _eventsRepo;

  ActivitiesService({EventsRepository? eventsRepository})
      : _eventsRepo = eventsRepository ?? EventsRepository();

  // ============================================================================
  // Прогулка
  // ============================================================================

  /// Добавление завершенного события прогулки
  Future<String?> addWalkEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required DateTime endedAt,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    try {
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.walk,
        startedAt: startedAt,
        endedAt: endedAt,
        notes: notes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
        status: EventStatus.completed,
      );

      return await _eventsRepo.createEvent(event);
    } catch (e) {
      return null;
    }
  }

  /// Запуск события прогулки (таймер)
  Future<String?> startWalkEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    try {
      final eventData = {
        'baby_id': babyId,
        'family_id': familyId,
        'event_type': 'walk',
        'started_at': Timestamp.fromDate(startedAt),
        'ended_at': null,
        'notes': notes,
        'created_at': FieldValue.serverTimestamp(),
        'last_modified_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
        'created_by_name': createdByName,
        'status': 'active',
        'version': 1,
      };

      return await _eventsRepo.createEventFromMap(eventData);
    } catch (e) {
      return null;
    }
  }

  /// Завершение события прогулки
  Future<bool> stopWalkEvent({
    required String eventId,
    required DateTime endedAt,
    String? lastModifiedBy,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'ended_at': Timestamp.fromDate(endedAt),
      'status': 'completed',
    };

    if (lastModifiedBy != null) updates['last_modified_by'] = lastModifiedBy;
    if (notes != null) updates['notes'] = notes;

    return await _eventsRepo.updateEvent(eventId, updates);
  }

  /// Stream активных событий прогулки
  Stream<List<Event>> getActiveWalkEventsStream(String babyId) {
    return _eventsRepo.getActiveEventsByTypeStream(babyId, EventType.walk);
  }

  // ============================================================================
  // Купание
  // ============================================================================

  /// Добавление события купания
  Future<String?> addBathEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    try {
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.bath,
        startedAt: time,
        notes: notes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
        status: EventStatus.completed,
      );

      return await _eventsRepo.createEvent(event);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // Бутылка
  // ============================================================================

  /// Добавление события бутылки
  Future<String?> addBottleEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required BottleType bottleType,
    required double volumeMl,
    String? notes,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      final eventData = {
        'baby_id': babyId,
        'family_id': familyId,
        'event_type': 'bottle',
        'started_at': Timestamp.fromDate(startedAt),
        'notes': notes,
        'created_at': FieldValue.serverTimestamp(),
        'last_modified_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
        'created_by_name': createdByName,
        'status': 'completed',
        'version': 1,
        'bottle_type': bottleType.name,
        'volume_ml': volumeMl,
      };

      return await _eventsRepo.createEventFromMap(eventData);
    } catch (e) {
      return null;
    }
  }

  /// Обновление события бутылки
  Future<bool> updateBottleEvent({
    required String eventId,
    DateTime? startedAt,
    BottleType? bottleType,
    double? volumeMl,
    String? notes,
    String? lastModifiedBy,
  }) async {
    final updates = <String, dynamic>{};

    if (startedAt != null) {
      updates['started_at'] = Timestamp.fromDate(startedAt);
    }
    if (bottleType != null) {
      updates['bottle_type'] = bottleType.name;
    }
    if (volumeMl != null) {
      updates['volume_ml'] = volumeMl;
    }
    if (notes != null) {
      updates['notes'] = notes;
    }
    if (lastModifiedBy != null) {
      updates['last_modified_by'] = lastModifiedBy;
    }

    return await _eventsRepo.updateEvent(eventId, updates);
  }
}
