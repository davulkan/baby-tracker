// lib/models/event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  feeding,
  sleep,
  diaper,
  bottle,
  medicine,
  weight,
  height,
  // headCircumference,
  walk,
  bath,
  other,
}

enum EventStatus {
  active, // Событие идет прямо сейчас (таймер)
  completed, // Событие завершено
}

enum BottleType {
  formula,
  breastMilk,
}

class Event {
  final String id;
  final String babyId;
  final String familyId;
  final EventType eventType;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final String createdBy;
  final String createdByName;
  final String? lastModifiedBy;
  final int version;
  final EventStatus status; // ← НОВОЕ ПОЛЕ

  // Поля для бутылочки
  final BottleType? bottleType;
  final double? volumeMl;

  // Поля для измерений
  final double? weightKg;
  final double? heightCm;
  final double? headCircumferenceCm;

  bool get isActive => status == EventStatus.active;
  Duration get currentDuration => DateTime.now().difference(startedAt);
  // Поля для таймеров
  // Убраны из Firestore, теперь только локально

  Event({
    required this.id,
    required this.babyId,
    required this.familyId,
    required this.eventType,
    required this.startedAt,
    required this.status,
    this.endedAt,
    this.notes,
    this.photoUrls,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.createdBy,
    required this.createdByName,
    this.lastModifiedBy,
    this.version = 1,
    this.bottleType,
    this.volumeMl,
    this.weightKg,
    this.heightCm,
    this.headCircumferenceCm,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      babyId: data['baby_id'] ?? '',
      familyId: data['family_id'] ?? '',
      eventType: _parseEventType(data['event_type']),
      startedAt: (data['started_at'] as Timestamp).toDate(),
      status: _parseEventStatus(data['status']),
      endedAt: data['ended_at'] != null
          ? (data['ended_at'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      photoUrls: data['photo_urls'] != null
          ? List<String>.from(data['photo_urls'])
          : null,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      lastModifiedAt: data['last_modified_at'] != null
          ? (data['last_modified_at'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['created_by'] ?? '',
      createdByName: data['created_by_name'] ?? '',
      lastModifiedBy: data['last_modified_by'],
      version: data['version'] ?? 1,
      bottleType: data['bottle_type'] != null
          ? _parseBottleType(data['bottle_type'])
          : null,
      volumeMl: data['volume_ml'] != null
          ? (data['volume_ml'] as num).toDouble()
          : null,
      weightKg: data['weight_kg'] != null
          ? (data['weight_kg'] as num).toDouble()
          : null,
      heightCm: data['height_cm'] != null
          ? (data['height_cm'] as num).toDouble()
          : null,
      headCircumferenceCm: data['head_circumference_cm'] != null
          ? (data['head_circumference_cm'] as num).toDouble()
          : null,
    );
  }
  static EventStatus _parseEventStatus(String? status) {
    switch (status) {
      case 'active':
        return EventStatus.active;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.completed;
    }
  }

  static BottleType _parseBottleType(String? type) {
    switch (type) {
      case 'formula':
        return BottleType.formula;
      case 'breastMilk':
        return BottleType.breastMilk;
      default:
        return BottleType.formula;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'baby_id': babyId,
      'family_id': familyId,
      'event_type': eventType.name,
      'status': status.name,
      'started_at': Timestamp.fromDate(startedAt),
      'ended_at': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'notes': notes,
      'photo_urls': photoUrls,
      'created_at': Timestamp.fromDate(createdAt),
      'last_modified_at': Timestamp.fromDate(lastModifiedAt),
      'created_by': createdBy,
      'created_by_name': createdByName,
      'last_modified_by': lastModifiedBy,
      'version': version,
      if (bottleType != null) 'bottle_type': bottleType!.name,
      if (volumeMl != null) 'volume_ml': volumeMl,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (headCircumferenceCm != null)
        'head_circumference_cm': headCircumferenceCm,
    };
  }

  static EventType _parseEventType(String? type) {
    switch (type) {
      case 'feeding':
        return EventType.feeding;
      case 'sleep':
        return EventType.sleep;
      case 'diaper':
        return EventType.diaper;
      case 'bottle':
        return EventType.bottle;
      case 'medicine':
        return EventType.medicine;
      case 'weight':
        return EventType.weight;
      case 'height':
        return EventType.height;
      // case 'headCircumference':
      //   return EventType.headCircumference;
      case 'walk':
        return EventType.walk;
      case 'bath':
        return EventType.bath;
      default:
        return EventType.other;
    }
  }

  // Продолжительность события
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  // Проверка, должен ли отображаться таймер в списке событий
  // Убрана, так как таймеры теперь локально

  Event copyWith({
    String? id,
    String? babyId,
    String? familyId,
    EventType? eventType,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    String? createdBy,
    String? createdByName,
    String? lastModifiedBy,
    int? version,
    EventStatus? status,
    BottleType? bottleType,
    double? volumeMl,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
  }) {
    return Event(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      familyId: familyId ?? this.familyId,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      version: version ?? this.version,
      bottleType: bottleType ?? this.bottleType,
      volumeMl: volumeMl ?? this.volumeMl,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
    );
  }
}
