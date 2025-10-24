// lib/models/bottle_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/models/event.dart';

enum BottleType {
  formula,
  breastMilk,
}

class BottleEvent extends Event {
  final BottleType bottleType;
  final double volumeMl;

  BottleEvent({
    required super.id,
    required super.babyId,
    required super.familyId,
    required super.startedAt,
    super.endedAt,
    super.notes,
    super.photoUrls,
    required super.createdAt,
    required super.lastModifiedAt,
    required super.createdBy,
    required super.createdByName,
    super.lastModifiedBy,
    super.version = 1,
    required this.bottleType,
    required this.volumeMl,
  }) : super(
          eventType: EventType.bottle,
        );

  factory BottleEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BottleEvent(
      id: doc.id,
      babyId: data['baby_id'] ?? '',
      familyId: data['family_id'] ?? '',
      startedAt: (data['started_at'] as Timestamp).toDate(),
      endedAt: data['ended_at'] != null
          ? (data['ended_at'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      photoUrls: data['photo_urls'] != null
          ? List<String>.from(data['photo_urls'])
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      lastModifiedAt: (data['last_modified_at'] as Timestamp).toDate(),
      createdBy: data['created_by'] ?? '',
      createdByName: data['created_by_name'] ?? '',
      lastModifiedBy: data['last_modified_by'],
      version: data['version'] ?? 1,
      bottleType: _parseBottleType(data['bottle_type']),
      volumeMl: (data['volume_ml'] ?? 0.0).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final baseData = super.toFirestore();
    baseData.addAll({
      'bottle_type': bottleType.name,
      'volume_ml': volumeMl,
    });
    return baseData;
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

  String get bottleTypeDisplayName {
    switch (bottleType) {
      case BottleType.formula:
        return 'Смесь';
      case BottleType.breastMilk:
        return 'Грудное молоко';
    }
  }

  @override
  BottleEvent copyWith({
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
    bool? isTimerActive,
    bool? isLeftTimerActive,
    bool? isRightTimerActive,
    int? timerMs,
    int? leftTimerMs,
    int? rightTimerMs,
    BottleType? bottleType,
    double? volumeMl,
  }) {
    return BottleEvent(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      familyId: familyId ?? this.familyId,
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
    );
  }
}
