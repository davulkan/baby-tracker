// lib/services/family_data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Сервис для управления данными семьи
class FamilyDataService {
  final FirebaseFirestore _firestore;

  FamilyDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Удаление всех событий и деталей по семье
  Future<bool> deleteAllFamilyData(String familyId) async {
    try {
      debugPrint('Начинаем удаление всех данных для семьи: $familyId');

      // Получаем всех детей семьи
      final babiesSnapshot = await _firestore
          .collection('babies')
          .where('family_id', isEqualTo: familyId)
          .get();

      final List<String> babyIds =
          babiesSnapshot.docs.map((doc) => doc.id).toList();
      debugPrint('Найдено детей: ${babyIds.length}');

      // Batch для группировки операций удаления
      WriteBatch batch = _firestore.batch();
      int operationsCount = 0;

      // Удаляем события для каждого ребенка
      for (String babyId in babyIds) {
        debugPrint('Удаляем события для ребенка: $babyId');

        // Получаем все события ребенка
        final eventsSnapshot = await _firestore
            .collection('events')
            .where('baby_id', isEqualTo: babyId)
            .get();

        debugPrint(
            'Найдено событий для ребенка $babyId: ${eventsSnapshot.docs.length}');

        for (var eventDoc in eventsSnapshot.docs) {
          final eventId = eventDoc.id;

          // Удаляем основное событие
          batch.delete(_firestore.collection('events').doc(eventId));
          operationsCount++;

          // Удаляем детали событий из всех коллекций деталей
          await _deleteEventDetails(eventId, batch);
          operationsCount += 6; // 6 коллекций деталей

          // Если достигли лимита операций в batch, выполняем его
          if (operationsCount >= 450) {
            // Оставляем запас до лимита 500
            await batch.commit();
            batch = _firestore.batch();
            operationsCount = 0;
            debugPrint('Выполнен промежуточный batch');
          }
        }
      }

      // Удаляем лекарства семьи
      debugPrint('Удаляем лекарства семьи');
      final medicinesSnapshot = await _firestore
          .collection('medicines')
          .where('family_id', isEqualTo: familyId)
          .get();

      for (var medicineDoc in medicinesSnapshot.docs) {
        batch.delete(medicineDoc.reference);
        operationsCount++;

        if (operationsCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationsCount = 0;
          debugPrint('Выполнен промежуточный batch для лекарств');
        }
      }

      // Удаляем профили детей
      debugPrint('Удаляем профили детей');
      for (var babyDoc in babiesSnapshot.docs) {
        batch.delete(babyDoc.reference);
        operationsCount++;

        if (operationsCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationsCount = 0;
          debugPrint('Выполнен промежуточный batch для детей');
        }
      }

      // Выполняем оставшиеся операции
      if (operationsCount > 0) {
        await batch.commit();
        debugPrint('Выполнен финальный batch');
      }

      debugPrint('Успешно удалены все данные семьи: $familyId');
      return true;
    } catch (e) {
      debugPrint('Ошибка при удалении данных семьи: $e');
      return false;
    }
  }

  /// Удаление деталей события из всех коллекций
  Future<void> _deleteEventDetails(String eventId, WriteBatch batch) async {
    // Список всех коллекций с деталями событий
    final detailCollections = [
      'sleep_details',
      'feeding_details',
      'diaper_details',
      'medicine_details',
      'weight_details',
      'height_details',
    ];

    for (String collection in detailCollections) {
      final docRef = _firestore.collection(collection).doc(eventId);
      batch.delete(docRef);
    }
  }

  /// Подсчет общего количества записей для семьи (для информации пользователя)
  Future<Map<String, int>> getFamilyDataCount(String familyId) async {
    try {
      int eventsCount = 0;
      int babiesCount = 0;
      int medicinesCount = 0;

      // Считаем детей
      final babiesSnapshot = await _firestore
          .collection('babies')
          .where('family_id', isEqualTo: familyId)
          .get();

      babiesCount = babiesSnapshot.docs.length;
      final List<String> babyIds =
          babiesSnapshot.docs.map((doc) => doc.id).toList();

      // Считаем события для каждого ребенка
      for (String babyId in babyIds) {
        final eventsSnapshot = await _firestore
            .collection('events')
            .where('baby_id', isEqualTo: babyId)
            .get();
        eventsCount += eventsSnapshot.docs.length;
      }

      // Считаем лекарства
      final medicinesSnapshot = await _firestore
          .collection('medicines')
          .where('family_id', isEqualTo: familyId)
          .get();
      medicinesCount = medicinesSnapshot.docs.length;

      return {
        'events': eventsCount,
        'babies': babiesCount,
        'medicines': medicinesCount,
      };
    } catch (e) {
      debugPrint('Ошибка при подсчете данных семьи: $e');
      return {
        'events': 0,
        'babies': 0,
        'medicines': 0,
      };
    }
  }

  /// Удаление данных конкретного ребенка
  Future<bool> deleteBabyData(String babyId) async {
    try {
      debugPrint('Начинаем удаление данных для ребенка: $babyId');

      WriteBatch batch = _firestore.batch();
      int operationsCount = 0;

      // Удаляем все события ребенка
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('baby_id', isEqualTo: babyId)
          .get();

      debugPrint('Найдено событий для ребенка: ${eventsSnapshot.docs.length}');

      for (var eventDoc in eventsSnapshot.docs) {
        final eventId = eventDoc.id;

        // Удаляем основное событие
        batch.delete(_firestore.collection('events').doc(eventId));
        operationsCount++;

        // Удаляем детали событий
        await _deleteEventDetails(eventId, batch);
        operationsCount += 6;

        if (operationsCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationsCount = 0;
        }
      }

      // Выполняем оставшиеся операции
      if (operationsCount > 0) {
        await batch.commit();
      }

      debugPrint('Успешно удалены данные ребенка: $babyId');
      return true;
    } catch (e) {
      debugPrint('Ошибка при удалении данных ребенка: $e');
      return false;
    }
  }
}
