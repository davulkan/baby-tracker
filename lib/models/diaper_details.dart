// lib/models/diaper_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum DiaperType {
  wet, // Мокрый
  dirty, // Грязный
  mixed, // Смешанный
}

class DiaperDetails {
  final String id;
  final String eventId;
  final DiaperType diaperType;
  final String? notes;

  DiaperDetails({
    required this.id,
    required this.eventId,
    required this.diaperType,
    this.notes,
  });

  factory DiaperDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaperDetails(
      id: doc.id,
      eventId: data['event_id'] ?? '',
      diaperType: _parseDiaperType(data['diaper_type']),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'diaper_type': diaperType.name,
      'notes': notes,
    };
  }

  static DiaperType _parseDiaperType(String? type) {
    switch (type) {
      case 'wet':
        return DiaperType.wet;
      case 'dirty':
        return DiaperType.dirty;
      case 'mixed':
        return DiaperType.mixed;
      default:
        return DiaperType.wet;
    }
  }

  String get displayName {
    switch (diaperType) {
      case DiaperType.wet:
        return 'Мокрый';
      case DiaperType.dirty:
        return 'Грязный';
      case DiaperType.mixed:
        return 'Смешанный';
    }
  }

  DiaperDetails copyWith({
    String? id,
    String? eventId,
    DiaperType? diaperType,
    String? notes,
  }) {
    return DiaperDetails(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      diaperType: diaperType ?? this.diaperType,
      notes: notes ?? this.notes,
    );
  }
}
