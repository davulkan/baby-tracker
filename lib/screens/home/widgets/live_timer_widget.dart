import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/feeding_details.dart';

// Виджет для отображения живого таймера
class LiveTimerWidget extends StatefulWidget {
  final Event event;
  final Color color;

  const LiveTimerWidget({
    required this.event,
    required this.color,
  });

  @override
  State<LiveTimerWidget> createState() => _LiveTimerWidgetState();
}

class _LiveTimerWidgetState extends State<LiveTimerWidget> {
  late Stream<String> _timerStream;
  StreamSubscription<DocumentSnapshot>? _eventSubscription;
  StreamSubscription<DocumentSnapshot>? _feedingDetailsSubscription;
  Event? _currentEvent;
  FeedingDetails? _currentFeedingDetails;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;

    // Подписываемся на обновления события в реальном времени
    _eventSubscription = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final updatedEvent = Event.fromFirestore(snapshot);
        setState(() {
          _currentEvent = updatedEvent;
        });
      }
    });

    // Для кормления подписываемся на детали
    if (widget.event.eventType == EventType.feeding) {
      _feedingDetailsSubscription = FirebaseFirestore.instance
          .collection('feeding_details')
          .doc(widget.event.id)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final details = FeedingDetails.fromFirestore(snapshot);
          setState(() {
            _currentFeedingDetails = details;
          });
        }
      });
    }

    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i)
        .map((_) => _formatTimerDisplay());
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _feedingDetailsSubscription?.cancel();
    super.dispose();
  }

  String _formatTimerDisplay() {
    final currentEvent = _currentEvent ?? widget.event;

    // Если событие завершено - не показываем
    if (currentEvent.endedAt != null) {
      return '';
    }

    // Для кормления используем данные из FeedingDetails
    if (currentEvent.eventType == EventType.feeding &&
        _currentFeedingDetails != null) {
      final details = _currentFeedingDetails!.calculateCurrentDuration();
      final totalSeconds = details.totalDurationSeconds;
      return _formatDuration(totalSeconds);
    }

    // Для сна и других событий используем разницу времени
    final now = DateTime.now();
    final diff = now.difference(currentEvent.startedAt);
    final totalSeconds = diff.inSeconds;

    return _formatDuration(totalSeconds);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final currentEvent = _currentEvent ?? widget.event;
        final timeString = snapshot.data ?? '';

        // Если таймер не активен или пустая строка - не показываем виджет
        if (timeString.isEmpty || currentEvent.endedAt != null) {
          return const SizedBox.shrink();
        }

        return Text(
          timeString,
          style: TextStyle(
            color: widget.color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
