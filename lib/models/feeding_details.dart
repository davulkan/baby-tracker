// lib/models/feeding_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum BreastSide {
  left,
  right,
  both,
}

enum FeedingActiveState {
  none, // Обе груди на паузе
  left, // Активна левая грудь
  right, // Активна правая грудь
}

class FeedingDetails {
  final String id;
  final String eventId;
  final BreastSide? breastSide;
  final int? leftDurationSeconds;
  final int? rightDurationSeconds;
  final FeedingActiveState activeState; // Какая грудь активна сейчас
  final DateTime? lastActivityAt; // Когда последний раз была активность
  final BreastSide? firstBreast; // Какая грудь была первой
  final BreastSide? secondBreast; // Какая грудь была второй
  final String? notes;

  FeedingDetails({
    required this.id,
    required this.eventId,
    this.breastSide,
    this.leftDurationSeconds,
    this.rightDurationSeconds,
    this.activeState = FeedingActiveState.none,
    this.lastActivityAt,
    this.firstBreast,
    this.secondBreast,
    this.notes,
  });

  factory FeedingDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedingDetails(
      id: doc.id,
      eventId: data['event_id'] ?? '',
      breastSide: _parseBreastSide(data['breast_side']),
      leftDurationSeconds: data['left_duration_seconds'],
      rightDurationSeconds: data['right_duration_seconds'],
      activeState: _parseActiveState(data['active_state']),
      lastActivityAt: data['last_activity_at'] != null
          ? (data['last_activity_at'] as Timestamp).toDate()
          : null,
      firstBreast: _parseBreastSide(data['first_breast']),
      secondBreast: _parseBreastSide(data['second_breast']),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'breast_side': breastSide?.name,
      'left_duration_seconds': leftDurationSeconds,
      'right_duration_seconds': rightDurationSeconds,
      'active_state': activeState.name,
      'last_activity_at':
          lastActivityAt != null ? Timestamp.fromDate(lastActivityAt!) : null,
      'first_breast': firstBreast?.name,
      'second_breast': secondBreast?.name,
      'notes': notes,
    };
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

  static FeedingActiveState _parseActiveState(String? state) {
    switch (state) {
      case 'left':
        return FeedingActiveState.left;
      case 'right':
        return FeedingActiveState.right;
      case 'none':
        return FeedingActiveState.none;
      default:
        return FeedingActiveState.none;
    }
  }

  // Общая продолжительность кормления грудью в секундах
  int get totalDurationSeconds {
    return (leftDurationSeconds ?? 0) + (rightDurationSeconds ?? 0);
  }

  // Общая продолжительность в минутах
  int get totalDurationMinutes {
    return (totalDurationSeconds / 60).round();
  }

  // Вычислить актуальную длительность с учетом текущего времени
  FeedingDetails calculateCurrentDuration() {
    if (activeState == FeedingActiveState.none || lastActivityAt == null) {
      return this;
    }

    final now = DateTime.now();
    final elapsedSeconds = now.difference(lastActivityAt!).inSeconds;

    if (activeState == FeedingActiveState.left) {
      return copyWith(
        leftDurationSeconds: (leftDurationSeconds ?? 0) + elapsedSeconds,
        lastActivityAt: now,
      );
    } else if (activeState == FeedingActiveState.right) {
      return copyWith(
        rightDurationSeconds: (rightDurationSeconds ?? 0) + elapsedSeconds,
        lastActivityAt: now,
      );
    }

    return this;
  }

  FeedingDetails copyWith({
    String? id,
    String? eventId,
    BreastSide? breastSide,
    int? leftDurationSeconds,
    int? rightDurationSeconds,
    FeedingActiveState? activeState,
    DateTime? lastActivityAt,
    BreastSide? firstBreast,
    BreastSide? secondBreast,
    double? bottleAmountMl,
    double? bottleAmountOz,
    String? formulaType,
    String? notes,
  }) {
    return FeedingDetails(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      breastSide: breastSide ?? this.breastSide,
      leftDurationSeconds: leftDurationSeconds ?? this.leftDurationSeconds,
      rightDurationSeconds: rightDurationSeconds ?? this.rightDurationSeconds,
      activeState: activeState ?? this.activeState,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      firstBreast: firstBreast ?? this.firstBreast,
      secondBreast: secondBreast ?? this.secondBreast,
      notes: notes ?? this.notes,
    );
  }
}
