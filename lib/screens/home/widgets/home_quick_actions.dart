import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/providers/settings_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/screens/add_sleep_screen.dart';
import 'package:baby_tracker/screens/add_feeding_screen.dart';
import 'package:baby_tracker/screens/add_diaper_screen.dart';
import 'package:baby_tracker/screens/add_bottle_screen.dart';
import 'package:baby_tracker/screens/medicine/add_medicament_screen.dart';
import 'package:baby_tracker/screens/add_weight_screen.dart';
import 'package:baby_tracker/screens/add_height_screen.dart';
import 'package:baby_tracker/screens/add_head_circumference_screen.dart';
import 'package:baby_tracker/screens/add_walk_screen.dart';
import 'package:baby_tracker/screens/add_bath_screen.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<BabyProvider, EventsProvider, SettingsProvider>(
      builder:
          (context, babyProvider, eventsProvider, settingsProvider, child) {
        final baby = babyProvider.currentBaby;

        if (baby == null) {
          return const SizedBox();
        }

        return StreamBuilder<List<Event>>(
          stream: eventsProvider.getTodayEventsStream(baby.id),
          builder: (context, snapshot) {
            final favoriteTypes = settingsProvider.favoriteEventTypes;
            final quickActionConfigs = _getQuickActionConfigs(context);
            if (favoriteTypes.isEmpty) {
              return const SizedBox();
            }
            return SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ...favoriteTypes.map((eventType) {
                    final config = quickActionConfigs[eventType];
                    if (config == null) return const SizedBox();
                    return Row(
                      children: [
                        _buildQuickActionButton(
                          context,
                          icon: config['icon'] as IconData,
                          label: config['label'] as String,
                          color: config['color'] as Color,
                          onTap: config['onTap'] as VoidCallback,
                        ),
                        const SizedBox(width: 12),
                      ],
                    );
                  }),
                  const SizedBox(width: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 12,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: context.appColors.textPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Map<EventType, Map<String, dynamic>> _getQuickActionConfigs(
      BuildContext context) {
    return {
      EventType.sleep: {
        'icon': Icons.bed,
        'label': 'Сон',
        'color': context.appColors.secondaryAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSleepScreen()),
          );
        },
      },
      EventType.feeding: {
        'icon': Icons.child_care,
        'label': 'Кормление',
        'color': context.appColors.successColor,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFeedingScreen()),
          );
        },
      },
      EventType.bottle: {
        'icon': Icons.local_drink,
        'label': 'Бутылка',
        'color': context.appColors.errorColor,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBottleScreen()),
          );
        },
      },
      EventType.diaper: {
        'icon': Icons.auto_awesome,
        'label': 'Подгузник',
        'color': context.appColors.primaryAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDiaperScreen()),
          );
        },
      },
      EventType.medicine: {
        'icon': Icons.medical_services,
        'label': 'Лекарство',
        'color': context.appColors.warningColor,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicamentScreen()),
          );
        },
      },
      EventType.weight: {
        'icon': Icons.monitor_weight,
        'label': 'Вес',
        'color': context.appColors.primaryAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWeightScreen()),
          );
        },
      },
      EventType.height: {
        'icon': Icons.height,
        'label': 'Рост',
        'color': context.appColors.secondaryAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHeightScreen()),
          );
        },
      },
      // EventType.headCircumference: {
      //   'icon': Icons.accessibility,
      //   'label': 'Окружность головы',
      //   'color': context.appColors.warningColor,
      //   'onTap': () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //           builder: (_) => const AddHeadCircumferenceScreen()),
      //     );
      //   },
      // },
      EventType.walk: {
        'icon': Icons.directions_walk,
        'label': 'Прогулка',
        'color': context.appColors.secondaryAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWalkScreen()),
          );
        },
      },
      EventType.bath: {
        'icon': Icons.bathtub,
        'label': 'Купание',
        'color': context.appColors.primaryAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBathScreen()),
          );
        },
      },
    };
  }
}
