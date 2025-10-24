// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/event.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _localeInitialized = false;
  Set<EventType> _selectedEventTypes =
      {}; // Пустой по умолчанию - показывать все

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('ru', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, color: Color(0xFFFF8A80)),
            SizedBox(width: 8),
            Text(
              'Статистика',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF8A80),
          labelColor: const Color(0xFFFF8A80),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Паттерн'),
            Tab(text: 'Вес, рост и прочее'),
          ],
        ),
      ),
      body: !_localeInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPatternView(),
                _buildGrowthView(),
              ],
            ),
    );
  }

  Widget _buildPatternView() {
    final baby = Provider.of<BabyProvider>(context).currentBaby;

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
          stream: eventsProvider.getEventsStream(baby.id),
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
                  _buildEventCategories(),

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

      sections.add(_buildDaySection(title, dayEvents, date));

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
    if (_selectedEventTypes.isEmpty) {
      return events; // Показывать все события
    }
    return events
        .where((event) => _selectedEventTypes.contains(event.eventType))
        .toList();
  }

  void _toggleEventType(EventType type) {
    setState(() {
      if (_selectedEventTypes.contains(type)) {
        _selectedEventTypes.remove(type);
      } else {
        _selectedEventTypes.add(type);
      }
    });
  }

  Widget _buildEventCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryIcon(
            Icons.bed,
            'Сон',
            const Color(0xFF6366F1),
            EventType.sleep,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            Icons.child_care,
            'Кормле...',
            const Color(0xFF10B981),
            EventType.feeding,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            Icons.auto_awesome,
            'Подгузн...',
            const Color(0xFFF59E0B),
            EventType.diaper,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(
      IconData icon, String label, Color color, EventType type) {
    final isSelected = _selectedEventTypes.contains(type);

    return GestureDetector(
      onTap: () => _toggleEventType(type),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[900] : Colors.grey[850],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.grey[700]!,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(String title, List<Event> dayEvents, DateTime date) {
    final stats = _calculateDayStats(dayEvents, date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // График паттерна на 24 часа
        _buildPatternChart(stats['chartEvents'] as List<Map<String, dynamic>>),

        const SizedBox(height: 16),

        // Сводка
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildStatItem(
              Icons.bed,
              '${stats['sleepHours']} ч ${stats['sleepMinutes']} мин',
              '${stats['sleepCount']} раз',
              const Color(0xFF6366F1),
            ),
            _buildStatItem(
              Icons.child_care,
              '${stats['feedingHours']} ч ${stats['feedingMinutes']} мин',
              '${stats['feedingCount']} раз',
              const Color(0xFF10B981),
            ),
            _buildStatItem(
              Icons.auto_awesome,
              '',
              '${stats['diaperCount']} раз',
              const Color(0xFFF59E0B),
            ),
          ],
        ),
      ],
    );
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

  Widget _buildPatternChart(List<Map<String, dynamic>> chartEvents) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: [
            // Часовая шкала
            Row(
              children: List.generate(24, (hour) {
                return Expanded(
                  child: Center(
                    child: hour % 3 == 0
                        ? Text(
                            hour.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          )
                        : const SizedBox(),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),

            // График с событиями
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Сетка
                      Row(
                        children: List.generate(24, (hour) {
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: hour % 3 == 0
                                        ? Colors.white12
                                        : Colors.white.withOpacity(0.03),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // События (сортируем по длительности - длинные рисуются первыми)
                      ...(() {
                        final sortedEvents =
                            List<Map<String, dynamic>>.from(chartEvents);
                        sortedEvents.sort((a, b) {
                          final aDuration = (a['endMinuteOfDay'] as int) -
                              (a['startMinuteOfDay'] as int);
                          final bDuration = (b['endMinuteOfDay'] as int) -
                              (b['startMinuteOfDay'] as int);
                          return bDuration
                              .compareTo(aDuration); // От длинных к коротким
                        });
                        return sortedEvents.map((event) {
                          return _buildEventBar(event, constraints.maxWidth,
                              constraints.maxHeight);
                        }).toList();
                      })(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBar(
      Map<String, dynamic> event, double totalWidth, double totalHeight) {
    final startMinuteOfDay = event['startMinuteOfDay'] as int;
    final endMinuteOfDay = event['endMinuteOfDay'] as int;
    final color = event['color'] as Color;
    final hasEndTime = event['hasEndTime'] as bool;
    final track = event['track'] as int;
    final totalTracks = event['totalTracks'] as int;

    // Общее количество минут в сутках = 24 * 60 = 1440
    final totalMinutes = 24 * 60;

    final left = (startMinuteOfDay / totalMinutes) * totalWidth;
    final width =
        ((endMinuteOfDay - startMinuteOfDay) / totalMinutes) * totalWidth;

    // Минимальная ширина для видимости
    final displayWidth = width.clamp(2.0, totalWidth - left);

    final trackHeight = totalHeight / totalTracks.clamp(1, 10);
    final top = track * trackHeight;

    return Positioned(
      left: left,
      top: top,
      width: displayWidth,
      height: trackHeight - 4, // Отступ между дорожками
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border:
              hasEndTime ? null : Border.all(color: Colors.white30, width: 1),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String duration, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (duration.isNotEmpty)
              Text(
                duration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrowthView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'График роста',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Скоро появится',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
