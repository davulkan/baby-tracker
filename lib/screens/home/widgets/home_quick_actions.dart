import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/screens/add_sleep_screen.dart';
import 'package:baby_tracker/screens/add_feeding_screen.dart';
import 'package:baby_tracker/screens/add_diaper_screen.dart';
import 'package:baby_tracker/screens/add_bottle_screen.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
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
}
