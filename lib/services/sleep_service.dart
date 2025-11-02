// lib/services/sleep_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/sleep_details.dart';
import 'package:baby_tracker/services/events_repository.dart';
import 'package:baby_tracker/services/event_details_service.dart';

/// Сервис для работы с событиями сна
class SleepService {
  final EventsRepository _eventsRepo;
  final EventDetailsService _detailsService;

  SleepService({
    EventsRepository? eventsRepository,
    EventDetailsService? detailsService,
  })  : _eventsRepo = eventsRepository ?? EventsRepository(),
        _detailsService = detailsService ?? EventDetailsService();

  /// Добавление завершенного события сна
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
      final event = Event(
        status: EventStatus.completed,
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

      final eventId = await _eventsRepo.createEvent(event);
      if (eventId == null) return null;

      final sleepDetails = SleepDetails(
        id: '',
        eventId: eventId,
        sleepType: sleepType,
        notes: notes,
      );

      await _detailsService.createSleepDetails(sleepDetails);
      return eventId;
    } catch (e) {
      return null;
    }
  }

  /// Запуск события сна (таймер)
  Future<String?> startSleepEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required String createdBy,
    required String createdByName,
    required SleepType sleepType,
    String? notes,
  }) async {
    try {
      final eventData = {
        'baby_id': babyId,
        'family_id': familyId,
        'event_type': 'sleep',
        'started_at': Timestamp.fromDate(startedAt),
        'ended_at': null,
        'notes': notes,
        'created_at': FieldValue.serverTimestamp(),
        'last_modified_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
        'created_by_name': createdByName,
        'status': 'active',
        'version': 1,
        'sleep_type': sleepType.name,
      };

      return await _eventsRepo.createEventFromMap(eventData);
    } catch (e) {
      return null;
    }
  }

  /// Завершение события сна
  Future<bool> stopSleepEvent({
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

  /// Stream активных событий сна
  Stream<List<Event>> getActiveSleepEventsStream(String babyId) {
    return _eventsRepo.getActiveEventsByTypeStream(babyId, EventType.sleep);
  }

  /// Получение активного события сна
  Future<Event?> getActiveSleepEvent(String babyId) async {
    return await _eventsRepo.getActiveEvent(babyId, EventType.sleep);
  }
}
