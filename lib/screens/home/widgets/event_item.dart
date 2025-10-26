// lib/widgets/event_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/models/sleep_details.dart';
import 'package:baby_tracker/models/diaper_details.dart';
import 'package:baby_tracker/models/medicine.dart';
import 'package:baby_tracker/models/medicine_details.dart';
import 'package:baby_tracker/screens/home/widgets/live_timer_widget.dart';

class EventItem extends StatelessWidget {
  final Event event;

  const EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    switch (event.eventType) {
      case EventType.feeding:
        return _buildFeedingEventItem(context);
      case EventType.sleep:
        return _buildSleepEventItem(context);
      case EventType.diaper:
        return _buildDiaperEventItem(context);
      case EventType.bottle:
        return _buildBottleEventItem(context);
      case EventType.medicine:
        return _buildMedicineEventItem(context);
      default:
        return _buildGenericEventItem(context);
    }
  }

  Widget _buildGenericEventItem(BuildContext context) {
    IconData icon;
    String title;
    String subtitle;
    Color color;
    String? duration;

    switch (event.eventType) {
      case EventType.sleep:
        icon = Icons.bed;
        title = 'Сон';
        color = context.appColors.secondaryAccent;
        break;
      case EventType.diaper:
        icon = Icons.auto_awesome;
        title = 'Подгузник';
        color = context.appColors.primaryAccent;
        break;
      case EventType.bottle:
        icon = Icons.local_drink;
        title = 'Бутылка';
        color = context.appColors.errorColor;
        break;
      default:
        icon = Icons.event;
        title = 'Событие';
        color = context.appColors.textSecondaryColor;
    }

    if (event.endedAt != null) {
      final dur = event.duration!;
      duration = '${dur.inHours}ч ${dur.inMinutes % 60}м';
      subtitle =
          '${_formatTime(event.startedAt)} - ${_formatTime(event.endedAt!)}';
    } else {
      subtitle = '${_formatTime(event.startedAt)} - Сейчас';
      duration = null;
    }

    return _buildEventItem(
      context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      duration: duration,
      color: color,
      showLiveTimer:
          event.endedAt == null && event.eventType == EventType.sleep,
    );
  }

  Widget _buildFeedingEventItem(BuildContext context) {
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
              // Показываем только время начала и конца без длительности
              subtitle =
                  '${_formatTime(event.startedAt)} - ${_formatTime(event.endedAt!)}';
            } else {
              subtitle = '${_formatTime(event.startedAt)} - Сейчас';
            }

            return _buildEventItem(
              context,
              icon: Icons.child_care,
              title: title,
              subtitle: subtitle,
              color: context.appColors.successColor,
              additionalInfo: breastInfo.isNotEmpty ? breastInfo : null,
              showLiveTimer: event.endedAt == null,
            );
          },
        );
      },
    );
  }

  Widget _buildSleepEventItem(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return FutureBuilder<SleepDetails?>(
          future: eventsProvider.getSleepDetails(event.id),
          builder: (context, snapshot) {
            String? sleepTypeInfo;

            if (snapshot.hasData && snapshot.data != null) {
              final details = snapshot.data!;
              switch (details.sleepType) {
                case SleepType.day:
                  sleepTypeInfo = 'Дневной сон';
                  break;
                case SleepType.night:
                  sleepTypeInfo = 'Ночной сон';
                  break;
              }
            }

            String title = 'Сон';
            String subtitle;
            String? duration;

            if (event.endedAt != null) {
              duration =
                  null; // Не показывать длительность для завершенных событий сна
              subtitle =
                  '${_formatTime(event.startedAt)} - ${_formatTime(event.endedAt!)}';
            } else {
              subtitle = '${_formatTime(event.startedAt)} - Сейчас';
              duration = null;
            }

            return _buildEventItem(
              context,
              icon: Icons.bed,
              title: title,
              subtitle: subtitle,
              duration: duration,
              color: context.appColors.secondaryAccent,
              additionalInfo: sleepTypeInfo,
              showLiveTimer: event.endedAt == null,
            );
          },
        );
      },
    );
  }

  Widget _buildDiaperEventItem(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return FutureBuilder<DiaperDetails?>(
          future: eventsProvider.getDiaperDetails(event.id),
          builder: (context, snapshot) {
            String? diaperTypeInfo;

            if (snapshot.hasData && snapshot.data != null) {
              final details = snapshot.data!;
              switch (details.diaperType) {
                case DiaperType.wet:
                  diaperTypeInfo = 'Мокрый';
                  break;
                case DiaperType.dirty:
                  diaperTypeInfo = 'Грязный';
                  break;
                case DiaperType.mixed:
                  diaperTypeInfo = 'Смешанный';
                  break;
              }
            }

            return _buildEventItem(
              context,
              icon: Icons.auto_awesome,
              title: 'Подгузник',
              subtitle: _formatTime(event.startedAt),
              color: context.appColors.primaryAccent,
              additionalInfo: diaperTypeInfo,
            );
          },
        );
      },
    );
  }

  Widget _buildBottleEventItem(BuildContext context) {
    String? volumeInfo = event.volumeMl != null ? '${event.volumeMl} мл' : null;

    return _buildEventItem(
      context,
      icon: Icons.local_drink,
      title: 'Бутылка',
      subtitle: _formatTime(event.startedAt),
      color: context.appColors.errorColor,
      additionalInfo: volumeInfo,
    );
  }

  Widget _buildMedicineEventItem(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return FutureBuilder<MedicineDetails?>(
          future: eventsProvider.getMedicineDetails(event.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return _buildEventItem(
                context,
                icon: Icons.medical_services,
                title: 'Лекарство',
                subtitle: _formatTime(event.startedAt),
                color: context.appColors.warningColor,
              );
            }

            final details = snapshot.data!;
            return FutureBuilder<Medicine?>(
              future: eventsProvider.getMedicine(details.medicineId),
              builder: (context, medicineSnapshot) {
                String? medicineName = 'Неизвестное лекарство';

                if (medicineSnapshot.hasData && medicineSnapshot.data != null) {
                  medicineName = medicineSnapshot.data!.name;
                }

                return _buildEventItem(
                  context,
                  icon: Icons.medical_services,
                  title: 'Лекарство',
                  subtitle: _formatTime(event.startedAt),
                  color: context.appColors.warningColor,
                  additionalInfo: medicineName,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEventItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? duration,
    required Color color,
    String? additionalInfo,
    bool showLiveTimer = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.appColors.surfaceColor,
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
                  style: TextStyle(
                    color: context.appColors.textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (additionalInfo != null)
                  Text(
                    additionalInfo,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.appColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (duration != null || showLiveTimer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: showLiveTimer
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
