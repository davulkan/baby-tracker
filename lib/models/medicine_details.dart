// lib/models/medicine_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineDetails {
  final String id;
  final String eventId;
  final String medicineId;
  final String? notes;

  MedicineDetails({
    required this.id,
    required this.eventId,
    required this.medicineId,
    this.notes,
  });

  factory MedicineDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicineDetails(
      id: doc.id,
      eventId: data['event_id'] ?? '',
      medicineId: data['medicine_id'] ?? '',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'medicine_id': medicineId,
      'notes': notes,
    };
  }

  MedicineDetails copyWith({
    String? id,
    String? eventId,
    String? medicineId,
    String? notes,
  }) {
    return MedicineDetails(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      medicineId: medicineId ?? this.medicineId,
      notes: notes ?? this.notes,
    );
  }
}
