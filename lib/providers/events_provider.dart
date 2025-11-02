// lib/providers/events_provider.dart
import 'package:flutter/material.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/models/sleep_details.dart';
import 'package:baby_tracker/models/diaper_details.dart';
import 'package:baby_tracker/models/medicine.dart';
import 'package:baby_tracker/models/medicine_details.dart';
import 'package:baby_tracker/services/events_repository.dart';
import 'package:baby_tracker/services/event_details_service.dart';
import 'package:baby_tracker/services/sleep_service.dart';
import 'package:baby_tracker/services/feeding_service.dart';
import 'package:baby_tracker/services/diaper_service.dart';
import 'package:baby_tracker/services/medicine_service.dart';
import 'package:baby_tracker/services/measurements_service.dart';
import 'package:baby_tracker/services/activities_service.dart';
import 'package:baby_tracker/services/statistics_service.dart';

/// Provider для управления событиями ребенка
/// 
/// Рефакторенная версия с использованием специализированных сервисов
/// вместо прямой работы с Firestore
class EventsProvider with ChangeNotifier {
  // Сервисы
  final EventsRepository _eventsRepo;
  final EventDetailsService _detailsService;
  final SleepService _sleepService;
  final FeedingService _feedingService;
  final DiaperService _diaperService;
  final MedicineService _medicineService;
  final MeasurementsService _measurementsService;
  final ActivitiesService _activitiesService;
  final StatisticsService _statisticsService;

  // Состояние
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EventsProvider({
    EventsRepository? eventsRepository,
    EventDetailsService? detailsService,
    SleepService? sleepService,
    FeedingService? feedingService,
    DiaperService? diaperService,
    MedicineService? medicineService,
    MeasurementsService? measurementsService,
    ActivitiesService? activitiesService,
    StatisticsService? statisticsService,
  })  : _eventsRepo = eventsRepository ?? EventsRepository(),
        _detailsService = detailsService ?? EventDetailsService(),
        _sleepService = sleepService ?? SleepService(),
        _feedingService = feedingService ?? FeedingService(),
        _diaperService = diaperService ?? DiaperService(),
        _medicineService = medicineService ?? MedicineService(),
        _measurementsService = measurementsService ?? MeasurementsService(),
        _activitiesService = activitiesService ?? ActivitiesService(),
        _statisticsService = statisticsService ?? StatisticsService();

  // ============================================================================
  // STREAMS - Потоки событий
  // ============================================================================

  Stream<List<Event>> getEventsStream(String babyId) {
    return _eventsRepo.getEventsStream(babyId);
  }

  Stream<List<Event>> getTodayEventsStream(String babyId) {
    return _eventsRepo.getTodayEventsStream(babyId);
  }

  Stream<List<Event>> getActiveEventsStream(String babyId) {
    return _eventsRepo.getActiveEventsStream(babyId);
  }

  Stream<List<Event>> getActiveFeedingEventsStream(String babyId) {
    return _feedingService.getActiveFeedingEventsStream(babyId);
  }

  Stream<List<Event>> getActiveSleepEventsStream(String babyId) {
    return _sleepService.getActiveSleepEventsStream(babyId);
  }

  Stream<List<Event>> getActiveWalkEventsStream(String babyId) {
    return _activitiesService.getActiveWalkEventsStream(babyId);
  }

  Stream<FeedingDetails?> getFeedingDetailsStream(String eventId) {
    return _detailsService.getFeedingDetailsStream(eventId);
  }

  // ============================================================================
  // СОН (Sleep Events)
  // ============================================================================

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
    _setLoading(true);
    final result = await _sleepService.addSleepEvent(
      babyId: babyId,
      familyId: familyId,
      startedAt: startedAt,
      endedAt: endedAt,
      createdBy: createdBy,
      createdByName: createdByName,
      sleepType: sleepType,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Future<String?> startSleepEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required String createdBy,
    required String createdByName,
    required SleepType sleepType,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _sleepService.startSleepEvent(
      babyId: babyId,
      familyId: familyId,
      startedAt: startedAt,
      createdBy: createdBy,
      createdByName: createdByName,
      sleepType: sleepType,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Future<bool> stopSleepEvent({
    required String eventId,
    required DateTime endedAt,
    String? lastModifiedBy,
    String? notes,
  }) async {
    return await _sleepService.stopSleepEvent(
      eventId: eventId,
      endedAt: endedAt,
      lastModifiedBy: lastModifiedBy,
      notes: notes,
    );
  }

  Future<Event?> getActiveSleepEvent(String babyId) async {
    return await _sleepService.getActiveSleepEvent(babyId);
  }

  // ============================================================================
  // КОРМЛЕНИЕ (Feeding Events)
  // ============================================================================

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
    _setLoading(true);
    final result = await _feedingService.addFeedingEvent(
      babyId: babyId,
      familyId: familyId,
      startedAt: startedAt,
      endedAt: endedAt,
      createdBy: createdBy,
      createdByName: createdByName,
      breastSide: breastSide,
      leftDurationSeconds: leftDurationSeconds,
      rightDurationSeconds: rightDurationSeconds,
      bottleAmountMl: bottleAmountMl,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Future<String?> startFeedingEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _feedingService.startFeedingEvent(
      babyId: babyId,
      familyId: familyId,
      startedAt: startedAt,
      createdBy: createdBy,
      createdByName: createdByName,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Future<bool> stopFeedingEvent({
    required String eventId,
    required DateTime endedAt,
    String? lastModifiedBy,
    String? notes,
  }) async {
    return await _feedingService.stopFeedingEvent(
      eventId: eventId,
      endedAt: endedAt,
      lastModifiedBy: lastModifiedBy,
      notes: notes,
    );
  }

  Future<Event?> getActiveFeedingEvent(String babyId) async {
    return await _feedingService.getActiveFeedingEvent(babyId);
  }

  Future<bool> updateTimerState({
    required String eventId,
    bool? isTimerActive,
    bool? isLeftTimerActive,
    bool? isRightTimerActive,
    int? timerMs,
    int? leftTimerMs,
    int? rightTimerMs,
  }) async {
    return await _feedingService.updateTimerState(
      eventId: eventId,
      isTimerActive: isTimerActive,
      isLeftTimerActive: isLeftTimerActive,
      isRightTimerActive: isRightTimerActive,
      timerMs: timerMs,
      leftTimerMs: leftTimerMs,
      rightTimerMs: rightTimerMs,
    );
  }

  // ============================================================================
  // ПОДГУЗНИК (Diaper Events)
  // ============================================================================

  Future<String?> addDiaperEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required String createdBy,
    required String createdByName,
    required DiaperType diaperType,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _diaperService.addDiaperEvent(
      babyId: babyId,
      familyId: familyId,
      time: time,
      createdBy: createdBy,
      createdByName: createdByName,
      diaperType: diaperType,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  // ============================================================================
  // ЛЕКАРСТВА (Medicine Events)
  // ============================================================================

  Future<String?> addMedicineEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required String medicineId,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _medicineService.addMedicineEvent(
      babyId: babyId,
      familyId: familyId,
      time: time,
      medicineId: medicineId,
      createdBy: createdBy,
      createdByName: createdByName,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Stream<List<Medicine>> getMedicinesStream(String familyId) {
    return _medicineService.getMedicinesStream(familyId);
  }

  Future<Medicine?> getMedicine(String medicineId) async {
    return await _medicineService.getMedicine(medicineId);
  }

  Future<String?> addMedicine({
    required String familyId,
    required String name,
  }) async {
    return await _medicineService.addMedicine(
      familyId: familyId,
      name: name,
    );
  }

  // ============================================================================
  // ИЗМЕРЕНИЯ (Measurements)
  // ============================================================================

  Future<String?> addWeightEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required double weightKg,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _measurementsService.addWeightEvent(
      babyId: babyId,
      familyId: familyId,
      time: time,
      weightKg: weightKg,
      createdBy: createdBy,
      createdByName: createdByName,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Future<String?> addHeightEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required double heightCm,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _measurementsService.addHeightEvent(
      babyId: babyId,
      familyId: familyId,
      time: time,
      heightCm: heightCm,
      createdBy: createdBy,
      createdByName: createdByName,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  

  // ============================================================================
  // АКТИВНОСТИ (Activities - Walk, Bath, Bottle)
  // ============================================================================

  Future<String?> addWalkEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required DateTime endedAt,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _activitiesService.addWalkEvent(
      babyId: babyId,
      familyId: familyId,
      startedAt: startedAt,
      endedAt: endedAt,
      createdBy: createdBy,
      createdByName: createdByName,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Future<String?> startWalkEvent({
    required String babyId,
    required String familyId,
    required DateTime startedAt,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _activitiesService.startWalkEvent(
      babyId: babyId,
      familyId: familyId,
      startedAt: startedAt,
      createdBy: createdBy,
      createdByName: createdByName,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

  Future<bool> stopWalkEvent({
    required String eventId,
    required DateTime endedAt,
    String? lastModifiedBy,
    String? notes,
  }) async {
    return await _activitiesService.stopWalkEvent(
      eventId: eventId,
      endedAt: endedAt,
      lastModifiedBy: lastModifiedBy,
      notes: notes,
    );
  }

  Future<String?> addBathEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    _setLoading(true);
    final result = await _activitiesService.addBathEvent(
      babyId: babyId,
      familyId: familyId,
      time: time,
      createdBy: createdBy,
      createdByName: createdByName,
      notes: notes,
    );
    _setLoading(false);
    return result;
  }

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
    return await _activitiesService.addBottleEvent(
      babyId: babyId,
      familyId: familyId,
      startedAt: startedAt,
      bottleType: bottleType,
      volumeMl: volumeMl,
      notes: notes,
      createdBy: createdBy,
      createdByName: createdByName,
    );
  }

  Future<bool> updateBottleEvent({
    required String eventId,
    DateTime? startedAt,
    BottleType? bottleType,
    double? volumeMl,
    String? notes,
    String? lastModifiedBy,
  }) async {
    return await _activitiesService.updateBottleEvent(
      eventId: eventId,
      startedAt: startedAt,
      bottleType: bottleType,
      volumeMl: volumeMl,
      notes: notes,
      lastModifiedBy: lastModifiedBy,
    );
  }

  // ============================================================================
  // ОБНОВЛЕНИЕ И УДАЛЕНИЕ
  // ============================================================================

  Future<bool> updateEvent(Event event) async {
    return await _eventsRepo.updateEventObject(event);
  }

  Future<bool> updateEventEndTime(String eventId, DateTime endedAt) async {
    return await _eventsRepo.updateEventEndTime(eventId, endedAt);
  }

  Future<bool> updateSleepDetails(String eventId, SleepDetails details) async {
    return await _detailsService.updateSleepDetails(eventId, details);
  }

  Future<bool> updateFeedingDetails(
      String eventId, FeedingDetails details) async {
    return await _detailsService.updateFeedingDetails(eventId, details);
  }

  Future<bool> updateDiaperDetails(
      String eventId, DiaperDetails details) async {
    return await _detailsService.updateDiaperDetails(eventId, details);
  }

  Future<bool> updateMedicineDetails(
      String eventId, MedicineDetails details) async {
    return await _detailsService.updateMedicineDetails(eventId, details);
  }

  Future<bool> deleteEvent(String eventId, EventType eventType) async {
    try {
      // Удаляем основное событие
      final success = await _eventsRepo.deleteEvent(eventId);
      if (!success) return false;

      // Удаляем детали в зависимости от типа
      switch (eventType) {
        case EventType.sleep:
          await _detailsService.deleteSleepDetails(eventId);
          break;
        case EventType.feeding:
          await _detailsService.deleteFeedingDetails(eventId);
          break;
        case EventType.diaper:
          await _detailsService.deleteDiaperDetails(eventId);
          break;
        case EventType.medicine:
          await _detailsService.deleteMedicineDetails(eventId);
          break;
        case EventType.weight:
        case EventType.height:
        // case EventType.headCircumference:
        case EventType.walk:
        case EventType.bath:
          // Эти события не имеют отдельных деталей
          break;
        default:
          break;
      }

      return true;
    } catch (e) {
      _error = 'Ошибка удаления события';
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // ПОЛУЧЕНИЕ ДЕТАЛЕЙ
  // ============================================================================

  Future<SleepDetails?> getSleepDetails(String eventId) async {
    return await _detailsService.getSleepDetails(eventId);
  }

  Future<FeedingDetails?> getFeedingDetails(String eventId) async {
    return await _detailsService.getFeedingDetails(eventId);
  }

  Future<DiaperDetails?> getDiaperDetails(String eventId) async {
    return await _detailsService.getDiaperDetails(eventId);
  }

  Future<MedicineDetails?> getMedicineDetails(String eventId) async {
    return await _detailsService.getMedicineDetails(eventId);
  }

  // ============================================================================
  // СТАТИСТИКА
  // ============================================================================

  Future<Map<String, int>> getStatistics(
      String babyId, DateTime startDate, DateTime endDate) async {
    return await _statisticsService.getStatistics(babyId, startDate, endDate);
  }

  // ============================================================================
  // АКТИВНЫЕ СОБЫТИЯ (для обратной совместимости)
  // ============================================================================

  Future<Event?> getActiveEvent(String babyId, EventType eventType) async {
    return await _eventsRepo.getActiveEvent(babyId, eventType);
  }

  // ============================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ============================================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
