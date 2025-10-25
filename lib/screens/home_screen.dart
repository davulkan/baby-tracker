// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/screens/add_sleep_screen.dart';
import 'package:baby_tracker/screens/add_feeding_screen.dart';
import 'package:baby_tracker/screens/add_diaper_screen.dart';
import 'package:baby_tracker/screens/add_bottle_screen.dart';
import 'package:baby_tracker/screens/stats_screen.dart';
import 'package:baby_tracker/screens/settings_screen.dart';
import 'package:baby_tracker/screens/baby_profile_screen.dart';

class HomeScreenFull extends StatelessWidget {
  const HomeScreenFull({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 16),
            _buildBabyProfile(),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Сегодня',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Журнал',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildEventsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog(context);
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart,
                color: Color(0xFFFF8A80),
                size: 24,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings,
                color: Color(0xFFFF8A80),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBabyProfile() {
    return Consumer<BabyProvider>(
      builder: (context, babyProvider, child) {
        final baby = babyProvider.currentBaby;

        if (baby == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.child_care,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Добавьте профиль ребенка',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BabyProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                  image: baby.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(baby.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: baby.photoUrl == null
                    ? const Icon(
                        Icons.child_care,
                        size: 32,
                        color: Color(0xFFFF8A80),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      baby.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      baby.ageText,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (baby.heightAtBirthCm != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${baby.heightAtBirthCm!.toStringAsFixed(0)} см',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Рост',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  if (baby.heightAtBirthCm != null &&
                      baby.weightAtBirthKg != null)
                    const SizedBox(height: 8),
                  if (baby.weightAtBirthKg != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${baby.weightAtBirthKg!.toStringAsFixed(2)} кг',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Вес',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Consumer2<BabyProvider, EventsProvider>(
      builder: (context, babyProvider, eventsProvider, child) {
        final baby = babyProvider.currentBaby;

        if (baby == null) {
          return const SizedBox();
        }

        return StreamBuilder<List<Event>>(
          stream: eventsProvider.getTodayEventsStream(baby.id),
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];

            final sleepCount =
                events.where((e) => e.eventType == EventType.sleep).length;
            final feedingCount =
                events.where((e) => e.eventType == EventType.feeding).length;
            final diaperCount =
                events.where((e) => e.eventType == EventType.diaper).length;
            final bottleCount =
                events.where((e) => e.eventType == EventType.bottle).length;

            final lastSleep =
                events.where((e) => e.eventType == EventType.sleep).firstOrNull;
            final lastFeeding = events
                .where((e) => e.eventType == EventType.feeding)
                .firstOrNull;
            final lastDiaper = events
                .where((e) => e.eventType == EventType.diaper)
                .firstOrNull;
            final lastBottle = events
                .where((e) => e.eventType == EventType.bottle)
                .firstOrNull;

            return SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildQuickActionButton(
                    context,
                    icon: Icons.bed,
                    label: 'Сон',
                    sublabel: _getTimeSinceLabel(lastSleep),
                    count: sleepCount.toString(),
                    color: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddSleepScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.child_care,
                    label: 'Кормление',
                    sublabel: _getTimeSinceLabel(lastFeeding),
                    count: feedingCount.toString(),
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddFeedingScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.local_drink,
                    label: 'Бутылка',
                    sublabel: _getTimeSinceLabel(lastBottle),
                    count: bottleCount.toString(),
                    color: const Color(0xFFEC4899),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddBottleScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.auto_awesome,
                    label: 'Подгузник',
                    sublabel: _getTimeSinceLabel(lastDiaper),
                    count: diaperCount.toString(),
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddDiaperScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getTimeSinceLabel(Event? event) {
    if (event == null) return 'Нет данных';

    final now = DateTime.now();
    final diff = now.difference(event.startedAt);

    if (event.endedAt == null) {
      return 'Сейчас';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч назад';
    } else {
      return '${diff.inDays} дн назад';
    }
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: color,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
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
      key: Key(event.id),
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
        await eventsProvider.deleteEvent(event.id, event.eventType);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Событие удалено'),
              duration: Duration(seconds: 2),
            ),
          );
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
              if (details.breastSide != null) {
                breastInfo = details.breastSide == BreastSide.left
                    ? 'Левая грудь'
                    : 'Правая грудь';
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
                    _LiveTimerWidget(
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
                  ? _LiveTimerWidget(
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

  void _showAddEventDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Добавить событие',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildAddEventButton(
              context,
              icon: Icons.bed,
              label: 'Сон',
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSleepScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddEventButton(
              context,
              icon: Icons.child_care,
              label: 'Кормление',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFeedingScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddEventButton(
              context,
              icon: Icons.local_drink,
              label: 'Бутылка',
              color: const Color(0xFFEC4899),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddBottleScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddEventButton(
              context,
              icon: Icons.auto_awesome,
              label: 'Подгузник',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDiaperScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEventButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет для отображения живого таймера
class _LiveTimerWidget extends StatefulWidget {
  final Event event;
  final Color color;

  const _LiveTimerWidget({
    required this.event,
    required this.color,
  });

  @override
  State<_LiveTimerWidget> createState() => _LiveTimerWidgetState();
}

class _LiveTimerWidgetState extends State<_LiveTimerWidget> {
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
