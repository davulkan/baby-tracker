// lib/screens/home/widgets/home_events_sliver_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/screens/home/widgets/event_item.dart';
import 'package:baby_tracker/screens/add_sleep_screen.dart';
import 'package:baby_tracker/screens/add_feeding_screen.dart';
import 'package:baby_tracker/screens/add_diaper_screen.dart';
import 'package:baby_tracker/screens/add_bottle_screen.dart';

class HomeEventsSliverList extends StatelessWidget {
  const HomeEventsSliverList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BabyProvider, EventsProvider>(
      builder: (context, babyProvider, eventsProvider, child) {
        final baby = babyProvider.currentBaby;

        if (baby == null) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: Center(
                child: Text(
                  'Добавьте профиль ребенка',
                  style: TextStyle(color: context.appColors.textSecondaryColor),
                ),
              ),
            ),
          );
        }

        return StreamBuilder<List<Event>>(
          stream: eventsProvider.getEventsStream(baby.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.appColors.primaryAccent,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Ошибка загрузки событий',
                      style: TextStyle(color: context.appColors.errorColor),
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 60,
                          color: context.appColors.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет событий',
                          style: TextStyle(
                            color: context.appColors.textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите "+" чтобы добавить',
                          style: TextStyle(
                            color: context.appColors.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final events = snapshot.data!;
            final groupedEvents = _groupEventsByDate(events);
            final dateKeys = groupedEvents.keys.toList()
              ..sort((a, b) => b.compareTo(a)); // Новые даты сверху

            return SliverMainAxisGroup(
              slivers: dateKeys.map((date) {
                final dateEvents = groupedEvents[date]!;
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _DateHeaderDelegate(date: date),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = dateEvents[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildDismissibleEventItem(
                                    context, event, eventsProvider),
                                if (event != dateEvents.last)
                                  const SizedBox(height: 6),
                              ],
                            ),
                          );
                        },
                        childCount: dateEvents.length,
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildDismissibleEventItem(
    BuildContext context,
    Event event,
    EventsProvider eventsProvider,
  ) {
    return Dismissible(
      key: ValueKey('${event.id}_${event.eventType.name}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Text(
              'Удалить событие?',
              style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color),
            ),
            content: Text(
              'Это действие нельзя отменить',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Удалить',
                  style: TextStyle(color: context.appColors.errorColor),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          final success =
              await eventsProvider.deleteEvent(event.id, event.eventType);

          if (context.mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Событие удалено'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ошибка удаления события'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ошибка удаления события'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: context.appColors.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete,
          color: context.appColors.textPrimaryColor,
          size: 32,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          switch (event.eventType) {
            case EventType.sleep:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSleepScreen(event: event),
                ),
              );
              break;
            case EventType.feeding:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFeedingScreen(event: event),
                ),
              );
              break;
            case EventType.diaper:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDiaperScreen(event: event),
                ),
              );
              break;
            case EventType.bottle:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddBottleScreen(event: event),
                ),
              );
              break;
            default:
              break;
          }
        },
        child: EventItem(event: event),
      ),
    );
  }

  Map<DateTime, List<Event>> _groupEventsByDate(List<Event> events) {
    final grouped = <DateTime, List<Event>>{};

    for (final event in events) {
      final date = DateTime(
          event.startedAt.year, event.startedAt.month, event.startedAt.day);
      grouped.putIfAbsent(date, () => []).add(event);
    }

    return grouped;
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;

  _DateHeaderDelegate({required this.date});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Фон, чтобы прилипал
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      alignment: Alignment.center,
      child: Text(
        _formatDateHeader(date),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.appColors.textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 50; // Высота заголовка

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is _DateHeaderDelegate && oldDelegate.date != date;
  }
}

String _formatDateHeader(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final preYesterday = today.subtract(const Duration(days: 2));
  final eventDate = DateTime(date.year, date.month, date.day);

  if (eventDate == today) {
    return 'Сегодня';
  } else if (eventDate == yesterday) {
    return 'Вчера';
  } else if (eventDate == preYesterday) {
    return 'Позавчера';
  } else {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}
