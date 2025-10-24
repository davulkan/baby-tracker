// lib/models/baby.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Baby {
  final String id;
  final String familyId;
  final String name;
  final DateTime birthDate;
  final String gender; // 'male', 'female', 'other'
  final String? photoUrl;
  final bool isActive;
  final double? weightAtBirthKg;
  final double? heightAtBirthCm;
  final DateTime createdAt;
  final String createdBy;

  Baby({
    required this.id,
    required this.familyId,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.photoUrl,
    this.isActive = true,
    this.weightAtBirthKg,
    this.heightAtBirthCm,
    required this.createdAt,
    required this.createdBy,
  });

  // Преобразование из Firestore
  factory Baby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Baby(
      id: doc.id,
      familyId: data['family_id'] ?? '',
      name: data['name'] ?? '',
      birthDate: (data['birth_date'] as Timestamp).toDate(),
      gender: data['gender'] ?? 'male',
      photoUrl: data['photo_url'],
      isActive: data['is_active'] ?? true,
      weightAtBirthKg: data['weight_at_birth_kg']?.toDouble(),
      heightAtBirthCm: data['height_at_birth_cm']?.toDouble(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      createdBy: data['created_by'] ?? '',
    );
  }

  // Преобразование в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'family_id': familyId,
      'name': name,
      'birth_date': Timestamp.fromDate(birthDate),
      'gender': gender,
      'photo_url': photoUrl,
      'is_active': isActive,
      'weight_at_birth_kg': weightAtBirthKg,
      'height_at_birth_cm': heightAtBirthCm,
      'created_at': Timestamp.fromDate(createdAt),
      'created_by': createdBy,
    };
  }

  // Возраст в месяцах
  int get ageInMonths {
    final now = DateTime.now();
    return ((now.year - birthDate.year) * 12) + (now.month - birthDate.month);
  }

  // Возраст в днях
  int get ageInDays {
    return DateTime.now().difference(birthDate).inDays;
  }

  // Возраст в годах
  int get ageInYears {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  // Текстовое представление возраста
  String get ageText {
    if (ageInDays == 0) {
      return 'Сегодня родился!';
    } else if (ageInDays < 30) {
      return '$ageInDays ${_getDaysWord(ageInDays)}';
    } else if (ageInDays < 365) {
      return '$ageInMonths ${_getMonthsWord(ageInMonths)}';
    } else {
      return '$ageInYears ${_getYearsWord(ageInYears)}';
    }
  }

  String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(days % 10) &&
        ![12, 13, 14].contains(days % 100)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }

  String _getMonthsWord(int months) {
    if (months % 10 == 1 && months % 100 != 11) {
      return 'месяц';
    } else if ([2, 3, 4].contains(months % 10) &&
        ![12, 13, 14].contains(months % 100)) {
      return 'месяца';
    } else {
      return 'месяцев';
    }
  }

  String _getYearsWord(int years) {
    if (years % 10 == 1 && years % 100 != 11) {
      return 'год';
    } else if ([2, 3, 4].contains(years % 10) &&
        ![12, 13, 14].contains(years % 100)) {
      return 'года';
    } else {
      return 'лет';
    }
  }

  Baby copyWith({
    String? id,
    String? familyId,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? photoUrl,
    bool? isActive,
    double? weightAtBirthKg,
    double? heightAtBirthCm,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Baby(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      weightAtBirthKg: weightAtBirthKg ?? this.weightAtBirthKg,
      heightAtBirthCm: heightAtBirthCm ?? this.heightAtBirthCm,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
