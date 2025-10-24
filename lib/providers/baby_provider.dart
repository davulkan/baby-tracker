// lib/providers/baby_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/models/baby.dart';

class BabyProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Baby? _currentBaby;
  List<Baby> _babies = [];
  bool _isLoading = false;
  String? _error;

  Baby? get currentBaby => _currentBaby;
  List<Baby> get babies => _babies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBaby => _currentBaby != null;

  // Загрузка детей семьи
  Future<void> loadBabies(String familyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('babies')
          .where('family_id', isEqualTo: familyId)
          .where('is_active', isEqualTo: true)
          .get();

      _babies = snapshot.docs.map((doc) => Baby.fromFirestore(doc)).toList();

      if (_babies.isNotEmpty) {
        _currentBaby = _babies.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки профилей детей';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading babies: $e');
    }
  }

  // Stream для реального времени
  Stream<List<Baby>> getBabiesStream(String familyId) {
    return _firestore
        .collection('babies')
        .where('family_id', isEqualTo: familyId)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final babies =
          snapshot.docs.map((doc) => Baby.fromFirestore(doc)).toList();

      if (babies.isNotEmpty && _currentBaby == null) {
        _currentBaby = babies.first;
        notifyListeners();
      }

      return babies;
    });
  }

  // Добавление ребенка
  Future<String?> addBaby({
    required String familyId,
    required String name,
    required DateTime birthDate,
    required String gender,
    required String createdBy,
    String? photoUrl,
    double? weightAtBirthKg,
    double? heightAtBirthCm,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final baby = Baby(
        id: '',
        familyId: familyId,
        name: name,
        birthDate: birthDate,
        gender: gender,
        photoUrl: photoUrl,
        weightAtBirthKg: weightAtBirthKg,
        heightAtBirthCm: heightAtBirthCm,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final docRef =
          await _firestore.collection('babies').add(baby.toFirestore());

      // Обновляем текущего ребенка
      _currentBaby = baby.copyWith(id: docRef.id);

      _isLoading = false;
      notifyListeners();

      return docRef.id;
    } catch (e) {
      _error = 'Ошибка добавления ребенка';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error adding baby: $e');
      return null;
    }
  }

  // Обновление профиля ребенка
  Future<bool> updateBaby({
    required String babyId,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? photoUrl,
    double? weightAtBirthKg,
    double? heightAtBirthCm,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (birthDate != null)
        updates['birth_date'] = Timestamp.fromDate(birthDate);
      if (gender != null) updates['gender'] = gender;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (weightAtBirthKg != null)
        updates['weight_at_birth_kg'] = weightAtBirthKg;
      if (heightAtBirthCm != null)
        updates['height_at_birth_cm'] = heightAtBirthCm;

      await _firestore.collection('babies').doc(babyId).update(updates);

      // Обновляем локальные данные
      if (_currentBaby?.id == babyId) {
        _currentBaby = _currentBaby!.copyWith(
          name: name ?? _currentBaby!.name,
          birthDate: birthDate ?? _currentBaby!.birthDate,
          gender: gender ?? _currentBaby!.gender,
          photoUrl: photoUrl ?? _currentBaby!.photoUrl,
          weightAtBirthKg: weightAtBirthKg ?? _currentBaby!.weightAtBirthKg,
          heightAtBirthCm: heightAtBirthCm ?? _currentBaby!.heightAtBirthCm,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Ошибка обновления профиля';
      debugPrint('Error updating baby: $e');
      return false;
    }
  }

  // Переключение текущего ребенка
  void setCurrentBaby(Baby baby) {
    _currentBaby = baby;
    notifyListeners();
  }

  // Деактивация ребенка (мягкое удаление)
  Future<bool> deactivateBaby(String babyId) async {
    try {
      await _firestore
          .collection('babies')
          .doc(babyId)
          .update({'is_active': false});

      if (_currentBaby?.id == babyId) {
        _currentBaby = null;
        if (_babies.length > 1) {
          _currentBaby = _babies.firstWhere(
            (b) => b.id != babyId,
            orElse: () => _babies.first,
          );
        }
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Ошибка удаления ребенка';
      debugPrint('Error deactivating baby: $e');
      return false;
    }
  }

  // Очистка всех данных (при выходе из семьи)
  void clearData() {
    _currentBaby = null;
    _babies = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
