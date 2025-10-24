// lib/models/event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  feeding,
  sleep,
  diaper,
  health,
  milestone,
  other,
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

  Event({
    required this.id,
    required this.babyId,
    required this.familyId,
    required this.eventType,
    required this.startedAt,
    this.endedAt,
    this.notes,
    this.photoUrls,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.createdBy,
    required this.createdByName,
    this.lastModifiedBy,
    this.version = 1,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      babyId: data['baby_id'] ?? '',
      familyId: data['family_id'] ?? '',
      eventType: _parseEventType(data['event_type']),
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'baby_id': babyId,
      'family_id': familyId,
      'event_type': eventType.name,
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
      case 'health':
        return EventType.health;
      case 'milestone':
        return EventType.milestone;
      default:
        return EventType.other;
    }
  }

  // Продолжительность события
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

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
  }) {
    return Event(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      familyId: familyId ?? this.familyId,
      eventType: eventType ?? this.eventType,
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
    );
  }
}
