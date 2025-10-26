// lib/models/medicine.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String familyId;
  final String name;
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.familyId,
    required this.name,
    required this.createdAt,
  });

  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine(
      id: doc.id,
      familyId: data['family_id'] ?? '',
      name: data['name'] ?? '',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'family_id': familyId,
      'name': name,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  Medicine copyWith({
    String? id,
    String? familyId,
    String? name,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}