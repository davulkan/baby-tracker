// lib/models/sleep_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SleepType {
  day, // Дневной
  night, // Ночной
}

class SleepDetails {
  final String id;
  final String eventId;
  final SleepType sleepType;
  final String? notes;
  final String? quality; // 'poor', 'good', 'excellent'

  SleepDetails({
    required this.id,
    required this.eventId,
    required this.sleepType,
    this.notes,
    this.quality,
  });

  factory SleepDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SleepDetails(
      id: doc.id,
      eventId: data['event_id'] ?? '',
      sleepType: _parseSleepType(data['sleep_type']),
      notes: data['notes'],
      quality: data['quality'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'sleep_type': sleepType.name,
      'notes': notes,
      'quality': quality,
    };
  }

  static SleepType _parseSleepType(String? type) {
    switch (type) {
      case 'day':
        return SleepType.day;
      case 'night':
        return SleepType.night;
      default:
        return SleepType.day;
    }
  }

  SleepDetails copyWith({
    String? id,
    String? eventId,
    SleepType? sleepType,
    String? notes,
    String? quality,
  }) {
    return SleepDetails(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      sleepType: sleepType ?? this.sleepType,
      notes: notes ?? this.notes,
      quality: quality ?? this.quality,
    );
  }
}
