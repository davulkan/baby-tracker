// lib/services/diaper_service.dart
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/diaper_details.dart';
import 'package:baby_tracker/services/events_repository.dart';
import 'package:baby_tracker/services/event_details_service.dart';

/// Сервис для работы с событиями подгузника
class DiaperService {
  final EventsRepository _eventsRepo;
  final EventDetailsService _detailsService;

  DiaperService({
    EventsRepository? eventsRepository,
    EventDetailsService? detailsService,
  })  : _eventsRepo = eventsRepository ?? EventsRepository(),
        _detailsService = detailsService ?? EventDetailsService();

  /// Добавление события подгузника
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
        status: EventStatus.completed,
      );

      final eventId = await _eventsRepo.createEvent(event);
      if (eventId == null) return null;

      final diaperDetails = DiaperDetails(
        id: '',
        eventId: eventId,
        diaperType: diaperType,
        notes: notes,
      );

      await _detailsService.createDiaperDetails(diaperDetails);
      return eventId;
    } catch (e) {
      return null;
    }
  }
}
