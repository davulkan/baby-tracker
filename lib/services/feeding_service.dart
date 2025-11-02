// lib/services/feeding_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/services/events_repository.dart';
import 'package:baby_tracker/services/event_details_service.dart';

/// Сервис для работы с событиями кормления
class FeedingService {
  final EventsRepository _eventsRepo;
  final EventDetailsService _detailsService;

  FeedingService({
    EventsRepository? eventsRepository,
    EventDetailsService? detailsService,
  })  : _eventsRepo = eventsRepository ?? EventsRepository(),
        _detailsService = detailsService ?? EventDetailsService();

  /// Добавление завершенного события кормления
  Future<String?> addFeedingEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    DateTime? endedAt,
    required String createdBy,
    required String createdByName,
    BreastSide? breastSide,
    int? leftDurationSeconds,
    int? rightDurationSeconds,
    double? bottleAmountMl,
    String? notes,
  }) async {
    try {
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
        status: endedAt != null ? EventStatus.completed : EventStatus.active,
      );

      final eventId = await _eventsRepo.createEvent(event);
      if (eventId == null) return null;

      final feedingDetails = FeedingDetails(
        id: '',
        eventId: eventId,
        breastSide: breastSide,
        leftDurationSeconds: leftDurationSeconds,
        rightDurationSeconds: rightDurationSeconds,
        notes: notes,
      );

      await _detailsService.createFeedingDetails(feedingDetails);
      return eventId;
    } catch (e) {
      return null;
    }
  }

  /// Запуск события кормления (таймер)
  Future<String?> startFeedingEvent({
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
        'event_type': 'feeding',
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

  /// Завершение события кормления
  Future<bool> stopFeedingEvent({
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

  /// Stream активных событий кормления
  Stream<List<Event>> getActiveFeedingEventsStream(String babyId) {
    return _eventsRepo.getActiveEventsByTypeStream(babyId, EventType.feeding);
  }

  /// Получение активного события кормления
  Future<Event?> getActiveFeedingEvent(String babyId) async {
    return await _eventsRepo.getActiveEvent(babyId, EventType.feeding);
  }

  /// Обновление состояния таймера
  Future<bool> updateTimerState({
    required String eventId,
    bool? isTimerActive,
    bool? isLeftTimerActive,
    bool? isRightTimerActive,
    int? timerMs,
    int? leftTimerMs,
    int? rightTimerMs,
  }) async {
    final updates = <String, dynamic>{};

    if (isTimerActive != null) updates['is_timer_active'] = isTimerActive;
    if (isLeftTimerActive != null)
      updates['is_left_timer_active'] = isLeftTimerActive;
    if (isRightTimerActive != null)
      updates['is_right_timer_active'] = isRightTimerActive;
    if (timerMs != null) updates['timer_ms'] = timerMs;
    if (leftTimerMs != null) updates['left_timer_ms'] = leftTimerMs;
    if (rightTimerMs != null) updates['right_timer_ms'] = rightTimerMs;

    return await _eventsRepo.updateEvent(eventId, updates);
  }
}
