// lib/models/feeding_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedingType {
  breast,
  bottle,
  solid,
}

enum BreastSide {
  left,
  right,
  both,
}

class FeedingDetails {
  final String id;
  final String eventId;
  final FeedingType feedingType;
  final BreastSide? breastSide;
  final int? leftDurationSeconds;
  final int? rightDurationSeconds;
  final double? bottleAmountMl;
  final double? bottleAmountOz;
  final String? formulaType;
  final String? notes;

  FeedingDetails({
    required this.id,
    required this.eventId,
    required this.feedingType,
    this.breastSide,
    this.leftDurationSeconds,
    this.rightDurationSeconds,
    this.bottleAmountMl,
    this.bottleAmountOz,
    this.formulaType,
    this.notes,
  });

  factory FeedingDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedingDetails(
      id: doc.id,
      eventId: data['event_id'] ?? '',
      feedingType: _parseFeedingType(data['feeding_type']),
      breastSide: _parseBreastSide(data['breast_side']),
      leftDurationSeconds: data['left_duration_seconds'],
      rightDurationSeconds: data['right_duration_seconds'],
      bottleAmountMl: data['bottle_amount_ml']?.toDouble(),
      bottleAmountOz: data['bottle_amount_oz']?.toDouble(),
      formulaType: data['formula_type'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'feeding_type': feedingType.name,
      'breast_side': breastSide?.name,
      'left_duration_seconds': leftDurationSeconds,
      'right_duration_seconds': rightDurationSeconds,
      'bottle_amount_ml': bottleAmountMl,
      'bottle_amount_oz': bottleAmountOz,
      'formula_type': formulaType,
      'notes': notes,
    };
  }

  static FeedingType _parseFeedingType(String? type) {
    switch (type) {
      case 'breast':
        return FeedingType.breast;
      case 'bottle':
        return FeedingType.bottle;
      case 'solid':
        return FeedingType.solid;
      default:
        return FeedingType.breast;
    }
  }

  static BreastSide? _parseBreastSide(String? side) {
    switch (side) {
      case 'left':
        return BreastSide.left;
      case 'right':
        return BreastSide.right;
      case 'both':
        return BreastSide.both;
      default:
        return null;
    }
  }

  // Общая продолжительность кормления грудью в минутах
  int? get totalDurationMinutes {
    if (leftDurationSeconds == null && rightDurationSeconds == null) {
      return null;
    }
    final total = (leftDurationSeconds ?? 0) + (rightDurationSeconds ?? 0);
    return (total / 60).round();
  }

  FeedingDetails copyWith({
    String? id,
    String? eventId,
    FeedingType? feedingType,
    BreastSide? breastSide,
    int? leftDurationSeconds,
    int? rightDurationSeconds,
    double? bottleAmountMl,
    double? bottleAmountOz,
    String? formulaType,
    String? notes,
  }) {
    return FeedingDetails(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      feedingType: feedingType ?? this.feedingType,
      breastSide: breastSide ?? this.breastSide,
      leftDurationSeconds: leftDurationSeconds ?? this.leftDurationSeconds,
      rightDurationSeconds: rightDurationSeconds ?? this.rightDurationSeconds,
      bottleAmountMl: bottleAmountMl ?? this.bottleAmountMl,
      bottleAmountOz: bottleAmountOz ?? this.bottleAmountOz,
      formulaType: formulaType ?? this.formulaType,
      notes: notes ?? this.notes,
    );
  }
}
