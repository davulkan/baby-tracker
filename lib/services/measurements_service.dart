// lib/services/measurements_service.dart
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/services/events_repository.dart';

/// Сервис для работы с измерениями (вес, рост, окружность головы)
class MeasurementsService {
  final EventsRepository _eventsRepo;

  MeasurementsService({EventsRepository? eventsRepository})
      : _eventsRepo = eventsRepository ?? EventsRepository();

  /// Добавление события веса
  Future<String?> addWeightEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required double weightKg,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    try {
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.weight,
        startedAt: time,
        notes: notes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
        status: EventStatus.completed,
        weightKg: weightKg,
      );

      return await _eventsRepo.createEvent(event);
    } catch (e) {
      return null;
    }
  }

  /// Добавление события роста
  Future<String?> addHeightEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required double heightCm,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    try {
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.height,
        startedAt: time,
        notes: notes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
        status: EventStatus.completed,
        heightCm: heightCm,
      );

      return await _eventsRepo.createEvent(event);
    } catch (e) {
      return null;
    }
  }

 
}
