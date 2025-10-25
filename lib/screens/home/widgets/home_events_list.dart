import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/screens/add_sleep_screen.dart';
import 'package:baby_tracker/screens/add_feeding_screen.dart';
import 'package:baby_tracker/screens/add_diaper_screen.dart';
import 'package:baby_tracker/screens/add_bottle_screen.dart';
import 'package:baby_tracker/screens/home/widgets/live_timer_widget.dart';

class HomeEventsList extends StatelessWidget {
  const HomeEventsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BabyProvider, EventsProvider>(
      builder: (context, babyProvider, eventsProvider, child) {
        final baby = babyProvider.currentBaby;

        if (baby == null) {
          return const Center(
            child: Text(
              'Добавьте профиль ребенка',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }

        return StreamBuilder<List<Event>>(
          stream: eventsProvider.getTodayEventsStream(baby.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Ошибка загрузки событий',
                  style: TextStyle(color: Colors.red[300]),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 60,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет событий за сегодня',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите "+" чтобы добавить',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            final events = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildDismissibleEventItem(
                    context, event, eventsProvider);
              },
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
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Удалить событие?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Это действие нельзя отменить',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Удалить',
                  style: TextStyle(color: Colors.red),
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
                  backgroundColor: Colors.red,
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
                backgroundColor: Colors.red,
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
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
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
        child: _buildEventItemFromEvent(event),
      ),
    );
  }

  Widget _buildEventItemFromEvent(Event event) {
    if (event.eventType == EventType.feeding) {
      return _buildFeedingEventItem(event);
    }

    IconData icon;
    String title;
    String subtitle;
    Color color;
    String? duration;

    switch (event.eventType) {
      case EventType.sleep:
        icon = Icons.bed;
        title = 'Сон';
        color = const Color(0xFF6366F1);
        if (event.endedAt != null) {
          final dur = event.duration!;
          duration = '${dur.inHours}ч ${dur.inMinutes % 60}м';
          subtitle =
              '${_formatTime(event.startedAt)} - ${_formatTime(event.endedAt!)}';
        } else {
          subtitle = '${_formatTime(event.startedAt)} - Сейчас';
          duration = null;
        }
        break;

      case EventType.feeding:
        icon = Icons.child_care;
        title = 'Кормление';
        color = const Color(0xFF10B981);
        if (event.endedAt != null) {
          final dur = event.duration!;
          subtitle = '${_formatTime(event.startedAt)}, ${dur.inMinutes} мин';
        } else {
          subtitle = '${_formatTime(event.startedAt)} - Сейчас';
        }
        break;

      case EventType.diaper:
        icon = Icons.auto_awesome;
        title = 'Подгузник';
        color = const Color(0xFFF59E0B);
        subtitle = _formatTime(event.startedAt);
        break;

      case EventType.bottle:
        icon = Icons.local_drink;
        title = 'Бутылка';
        color = const Color(0xFFEC4899);
        subtitle = _formatTime(event.startedAt);
        break;

      default:
        icon = Icons.event;
        title = 'Событие';
        color = Colors.grey;
        subtitle = _formatTime(event.startedAt);
    }

    return _buildEventItem(
      event: event,
      icon: icon,
      title: title,
      subtitle: subtitle,
      duration: duration,
      color: color,
    );
  }

  Widget _buildFeedingEventItem(Event event) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return FutureBuilder<FeedingDetails?>(
          future: eventsProvider.getFeedingDetails(event.id),
          builder: (context, snapshot) {
            String breastInfo = '';

            if (snapshot.hasData && snapshot.data != null) {
              final details = snapshot.data!;

              if (event.endedAt == null) {
                // Для активных событий показываем активную грудь
                switch (details.activeState) {
                  case FeedingActiveState.left:
                    breastInfo = 'Левая грудь';
                    break;
                  case FeedingActiveState.right:
                    breastInfo = 'Правая грудь';
                    break;
                  case FeedingActiveState.none:
                    break;
                }
              } else {
                // Для завершенных событий показываем порядок груди
                if (details.firstBreast != null &&
                    details.secondBreast != null) {
                  final first =
                      details.firstBreast == BreastSide.left ? 'Л' : 'П';
                  final second =
                      details.secondBreast == BreastSide.left ? 'Л' : 'П';
                  breastInfo = '$first → $second';
                } else if (details.firstBreast != null) {
                  final breast = details.firstBreast == BreastSide.left
                      ? 'Левая'
                      : 'Правая';
                  breastInfo = '$breast грудь';
                }
              }
            }

            String title = 'Кормление грудью';
            String subtitle;

            if (event.endedAt != null) {
              final dur = event.duration!;
              subtitle =
                  '${_formatTime(event.startedAt)}, ${dur.inMinutes} мин';
            } else {
              subtitle = '${_formatTime(event.startedAt)} - Сейчас';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.child_care,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (breastInfo.isNotEmpty)
                          Text(
                            breastInfo,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.endedAt == null) ...[
                    const SizedBox(width: 8),
                    LiveTimerWidget(
                      event: event,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEventItem({
    Event? event,
    required IconData icon,
    required String title,
    required String subtitle,
    String? duration,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (duration != null ||
              (event != null &&
                  event.endedAt == null &&
                  (event.eventType == EventType.sleep)))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: event != null &&
                      event.endedAt == null &&
                      event.eventType == EventType.sleep
                  ? LiveTimerWidget(
                      event: event,
                      color: color,
                    )
                  : Text(
                      duration!,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
