import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:baby_tracker/models/baby.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/screens/stats/widgets/event_categories_widget.dart';
import 'package:baby_tracker/screens/stats/widgets/day_section_widget.dart';

class PatternViewWidget extends StatelessWidget {
  final Baby? baby;
  final Set<EventType> selectedTypes;
  final Function(EventType) onToggle;

  const PatternViewWidget({
    super.key,
    required this.baby,
    required this.selectedTypes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (baby == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'Добавьте профиль ребенка',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return StreamBuilder<List<Event>>(
          stream: eventsProvider.getEventsStream(baby!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Ошибка загрузки данных',
                  style: TextStyle(color: Colors.red[300]),
                ),
              );
            }

            final allEvents = snapshot.data ?? [];

            if (allEvents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 80, color: Colors.grey[700]),
                    const SizedBox(height: 16),
                    Text(
                      'Нет данных для статистики',
                      style: TextStyle(color: Colors.grey[600], fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добавьте события для отображения паттерна',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Категории событий
                  EventCategoriesWidget(
                    selectedTypes: selectedTypes,
                    onToggle: onToggle,
                  ),

                  const SizedBox(height: 32),

                  // Динамически генерируем секции для всех дней с данными
                  ..._buildAllDaySections(_filterEvents(allEvents)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildAllDaySections(List<Event> filteredEvents) {
    // Группируем события по дням
    final Map<String, List<Event>> eventsByDay = {};

    for (final event in filteredEvents) {
      final dayKey = DateTime(
              event.startedAt.year, event.startedAt.month, event.startedAt.day)
          .toIso8601String()
          .split('T')[0];
      eventsByDay.putIfAbsent(dayKey, () => []).add(event);
    }

    // Сортируем дни по убыванию (новые дни сверху)
    final sortedDayKeys = eventsByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final List<Widget> sections = [];

    for (int i = 0; i < sortedDayKeys.length; i++) {
      final dayKey = sortedDayKeys[i];
      final dayEvents = eventsByDay[dayKey]!;
      final date = DateTime.parse(dayKey);

      // Определяем заголовок дня
      String title;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBeforeYesterday = today.subtract(const Duration(days: 2));

      if (date == today) {
        title = 'Сегодня';
      } else if (date == yesterday) {
        title = 'Вчера';
      } else if (date == dayBeforeYesterday) {
        title = 'Позавчера';
      } else {
        title = _formatDayTitle(date);
      }

      sections.add(DaySectionWidget(
        title: title,
        stats: _calculateDayStats(dayEvents, date),
      ));

      // Добавляем отступ между секциями, кроме последней
      if (i < sortedDayKeys.length - 1) {
        sections.add(const SizedBox(height: 24));
      }
    }

    return sections;
  }

  String _formatDayTitle(DateTime date) {
    return DateFormat('d MMMM', 'ru').format(date);
  }

  List<Event> _filterEvents(List<Event> events) {
    if (selectedTypes.isEmpty) {
      return events; // Показывать все события
    }
    return events
        .where((event) => selectedTypes.contains(event.eventType))
        .toList();
  }

  Map<String, dynamic> _calculateDayStats(
      List<Event> dayEvents, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);

    // События уже отфильтрованы по дню, просто используем их

    // Подсчитываем статистику
    int sleepCount = 0;
    int sleepTotalMinutes = 0;
    int feedingCount = 0;
    int feedingTotalMinutes = 0;
    int diaperCount = 0;
    int bottleCount = 0;
    double totalBottleVolume = 0.0;

    for (final event in dayEvents) {
      switch (event.eventType) {
        case EventType.sleep:
          sleepCount++;
          if (event.duration != null) {
            sleepTotalMinutes += event.duration!.inMinutes;
          }
          break;
        case EventType.feeding:
          feedingCount++;
          if (event.duration != null) {
            feedingTotalMinutes += event.duration!.inMinutes;
          }
          break;
        case EventType.diaper:
          diaperCount++;
          break;
        case EventType.bottle:
          bottleCount++;
          // Пока показываем только количество, объем добавим позже
          // когда обновим структуру данных
          break;
        default:
          break;
      }
    }

    // Создаем данные для графика
    final chartEvents = _createChartEvents(dayEvents, startOfDay);

    return {
      'sleepHours': sleepTotalMinutes ~/ 60,
      'sleepMinutes': sleepTotalMinutes % 60,
      'sleepCount': sleepCount,
      'feedingHours': feedingTotalMinutes ~/ 60,
      'feedingMinutes': feedingTotalMinutes % 60,
      'feedingCount': feedingCount,
      'diaperCount': diaperCount,
      'bottleCount': bottleCount,
      'bottleVolume': totalBottleVolume,
      'chartEvents': chartEvents,
    };
  }

  List<Map<String, dynamic>> _createChartEvents(
      List<Event> events, DateTime startOfDay) {
    final List<Map<String, dynamic>> chartEvents = [];
    final endOfDay = startOfDay.add(const Duration(days: 1));

    for (final event in events) {
      // Определяем цвет по типу события
      Color color;
      switch (event.eventType) {
        case EventType.sleep:
          color = const Color(0xFF6366F1);
          break;
        case EventType.feeding:
          color = const Color(0xFF10B981);
          break;
        case EventType.diaper:
          color = const Color(0xFFF59E0B);
          break;
        case EventType.bottle:
          color = const Color(0xFFEC4899);
          break;
        default:
          color = Colors.grey;
      }

      // Ограничиваем время начала и конца границами дня
      final effectiveStart =
          event.startedAt.isBefore(startOfDay) ? startOfDay : event.startedAt;

      DateTime? effectiveEnd;
      if (event.endedAt != null) {
        if (event.endedAt!.isAfter(endOfDay)) {
          effectiveEnd = endOfDay.subtract(const Duration(seconds: 1));
        } else if (event.endedAt!.isBefore(startOfDay)) {
          // Событие полностью вне этого дня
          continue;
        } else {
          effectiveEnd = event.endedAt;
        }
      }

      // Вычисляем минуты от начала дня
      final startMinuteOfDay = effectiveStart.difference(startOfDay).inMinutes;

      // Если есть конец события
      if (effectiveEnd != null) {
        final endMinuteOfDay = effectiveEnd.difference(startOfDay).inMinutes;

        // Вычисляем длительность в минутах для этого дня
        final durationMinutes = endMinuteOfDay - startMinuteOfDay;

        // Минимальная длительность для видимости
        final displayDuration = durationMinutes.clamp(5, 1440);

        chartEvents.add({
          'startMinuteOfDay': startMinuteOfDay,
          'endMinuteOfDay': startMinuteOfDay + displayDuration,
          'color': color,
          'type': event.eventType,
          'hasEndTime': true,
          'startedAt': event.startedAt,
        });
      } else {
        // Событие без конца - показываем как точку в начале
        chartEvents.add({
          'startMinuteOfDay': startMinuteOfDay,
          'endMinuteOfDay': startMinuteOfDay + 5,
          'color': color,
          'type': event.eventType,
          'hasEndTime': false,
          'startedAt': event.startedAt,
        });
      }
    }

    // Назначаем track (дорожку) каждому событию для избежания перекрытий
    _assignTracks(chartEvents);

    return chartEvents;
  }

  void _assignTracks(List<Map<String, dynamic>> events) {
    // Все события на одном треке - они будут накладываться друг на друга
    for (final event in events) {
      event['track'] = 0;
      event['totalTracks'] = 1;
    }
  }
}