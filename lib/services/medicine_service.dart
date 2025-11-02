// lib/services/medicine_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/medicine.dart';
import 'package:baby_tracker/models/medicine_details.dart';
import 'package:baby_tracker/services/events_repository.dart';
import 'package:baby_tracker/services/event_details_service.dart';

/// Сервис для работы с лекарствами и событиями приема лекарств
class MedicineService {
  final EventsRepository _eventsRepo;
  final EventDetailsService _detailsService;
  final FirebaseFirestore _firestore;

  MedicineService({
    EventsRepository? eventsRepository,
    EventDetailsService? detailsService,
    FirebaseFirestore? firestore,
  })  : _eventsRepo = eventsRepository ?? EventsRepository(),
        _detailsService = detailsService ?? EventDetailsService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // События приема лекарств
  // ============================================================================

  /// Добавление события приема лекарства
  Future<String?> addMedicineEvent({
    required String babyId,
    required String familyId,
    required DateTime time,
    required String medicineId,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    try {
      final event = Event(
        id: '',
        babyId: babyId,
        familyId: familyId,
        eventType: EventType.medicine,
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

      final medicineDetails = MedicineDetails(
        id: '',
        eventId: eventId,
        medicineId: medicineId,
        notes: notes,
      );

      await _detailsService.createMedicineDetails(medicineDetails);
      return eventId;
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // Управление справочником лекарств
  // ============================================================================

  /// Stream списка лекарств для семьи
  Stream<List<Medicine>> getMedicinesStream(String familyId) {
    return _firestore
        .collection('medicines')
        .where('family_id', isEqualTo: familyId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('Error in getMedicinesStream: $error');
      return <Medicine>[];
    });
  }

  /// Получение популярных лекарств (часто используемых)
  Future<List<Medicine>> getPopularMedicines({
    required String familyId,
    required String babyId,
    int limit = 5,
  }) async {
    try {
      // Получаем последние события
      final allEvents = await _eventsRepo.getEventsStream(babyId).first;

      // Фильтруем только события с лекарствами
      final medicineEvents = allEvents
          .where((event) => event.eventType == EventType.medicine)
          .take(50)
          .toList();

      // Считаем частоту использования каждого лекарства
      final Map<String, int> medicineFrequency = {};
      for (final event in medicineEvents) {
        final details = await _detailsService.getMedicineDetails(event.id);
        if (details != null) {
          medicineFrequency[details.medicineId] =
              (medicineFrequency[details.medicineId] ?? 0) + 1;
        }
      }

      // Сортируем по частоте использования
      final sortedMedicineIds = medicineFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Получаем объекты Medicine для популярных ID
      final List<Medicine> popularMedicines = [];
      for (final entry in sortedMedicineIds.take(limit)) {
        final medicine = await getMedicine(entry.key);
        if (medicine != null) {
          popularMedicines.add(medicine);
        }
      }

      return popularMedicines;
    } catch (e) {
      debugPrint('Error getting popular medicines: $e');
      return [];
    }
  }

  /// Получение лекарства по ID
  Future<Medicine?> getMedicine(String medicineId) async {
    try {
      final doc =
          await _firestore.collection('medicines').doc(medicineId).get();
      if (doc.exists) {
        return Medicine.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting medicine: $e');
      return null;
    }
  }

  /// Добавление нового лекарства
  Future<String?> addMedicine({
    required String familyId,
    required String name,
  }) async {
    try {
      final medicine = Medicine(
        id: '',
        familyId: familyId,
        name: name,
        createdAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('medicines').add(medicine.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding medicine: $e');
      return null;
    }
  }
}
