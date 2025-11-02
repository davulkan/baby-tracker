import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/sleep_details.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/models/diaper_details.dart';

class StatsSummaryWidget extends StatefulWidget {
  final Map<String, dynamic> stats;
  final Set<EventType> selectedTypes;
  final List<Event> events;

  const StatsSummaryWidget({
    super.key,
    required this.stats,
    required this.selectedTypes,
    required this.events,
  });

  @override
  State<StatsSummaryWidget> createState() => _StatsSummaryWidgetState();
}

class _StatsSummaryWidgetState extends State<StatsSummaryWidget> {
  Map<String, dynamic>? _detailedStats;

  @override
  void initState() {
    super.initState();
    _loadDetailedStats();
  }

  @override
  void didUpdateWidget(StatsSummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTypes != widget.selectedTypes ||
        oldWidget.events != widget.events) {
      _loadDetailedStats();
    }
  }

  Future<void> _loadDetailedStats() async {
    if (widget.selectedTypes.length == 1) {
      final eventType = widget.selectedTypes.first;
      final detailedStats = await _calculateDetailedStats(eventType);
      if (mounted) {
        setState(() {
          _detailedStats = detailedStats;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _detailedStats = null;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _calculateDetailedStats(
      EventType eventType) async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final Map<String, dynamic> detailedStats = {};

    switch (eventType) {
      case EventType.sleep:
        int nightHours = 0, nightMinutes = 0, dayHours = 0, dayMinutes = 0;
        for (final event in widget.events) {
          if (event.eventType == EventType.sleep) {
            final details = await eventsProvider.getSleepDetails(event.id);
            if (details != null && event.duration != null) {
              final duration = event.duration!;
              if (details.sleepType == SleepType.night) {
                nightHours += duration.inHours;
                nightMinutes += duration.inMinutes % 60;
              } else {
                dayHours += duration.inHours;
                dayMinutes += duration.inMinutes % 60;
              }
            }
          }
        }
        // Нормализуем минуты
        nightHours += nightMinutes ~/ 60;
        nightMinutes %= 60;
        dayHours += dayMinutes ~/ 60;
        dayMinutes %= 60;

        final totalSleepMinutes =
            (nightHours * 60 + nightMinutes) + (dayHours * 60 + dayMinutes);
        final awakeTotalMinutes = 24 * 60 - totalSleepMinutes;
        final awakeHours = awakeTotalMinutes ~/ 60;
        final awakeMinutes = awakeTotalMinutes % 60;
        final awakeDisplay = '$awakeHours ч $awakeMinutes мин';

        detailedStats['sleep'] = {
          'night': '$nightHours ч $nightMinutes мин',
          'day': '$dayHours ч $dayMinutes мин',
          'awake': awakeDisplay,
        };
        break;

      case EventType.diaper:
        int wet = 0, dirty = 0, mixed = 0;
        for (final event in widget.events) {
          if (event.eventType == EventType.diaper) {
            final details = await eventsProvider.getDiaperDetails(event.id);
            if (details != null) {
              switch (details.diaperType) {
                case DiaperType.wet:
                  wet++;
                  break;
                case DiaperType.dirty:
                  dirty++;
                  break;
                case DiaperType.mixed:
                  mixed++;
                  break;
              }
            }
          }
        }
        detailedStats['diaper'] = {
          'wet': '$wet раз',
          'dirty': '$dirty раз',
          'mixed': '$mixed раз',
        };
        break;

      case EventType.feeding:
        int left = 0, right = 0, both = 0;
        for (final event in widget.events) {
          if (event.eventType == EventType.feeding) {
            final details = await eventsProvider.getFeedingDetails(event.id);
            if (details != null && details.breastSide != null) {
              switch (details.breastSide!) {
                case BreastSide.left:
                  left++;
                  break;
                case BreastSide.right:
                  right++;
                  break;
                case BreastSide.both:
                  both++;
                  break;
              }
            }
          }
        }
        detailedStats['feeding'] = {
          'left': '$left раз',
          'right': '$right раз',
          'both': '$both раз',
        };
        break;

      case EventType.bottle:
        int formula = 0, breastMilk = 0;
        for (final event in widget.events) {
          if (event.eventType == EventType.bottle && event.bottleType != null) {
            switch (event.bottleType!) {
              case BottleType.formula:
                formula++;
                break;
              case BottleType.breastMilk:
                breastMilk++;
                break;
            }
          }
        }
        detailedStats['bottle'] = {
          'formula': '$formula раз',
          'breastMilk': '$breastMilk раз',
        };
        break;

      default:
        break;
    }

    return detailedStats;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_detailedStats != null) {
      return _buildDetailedView(context, colors);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          context,
          Icons.bed,
          '${widget.stats['sleepHours']} ч ${widget.stats['sleepMinutes']} мин',
          '${widget.stats['sleepCount']} раз',
          colors.sleepColor,
        ),
        _buildStatItem(
          context,
          Icons.child_care,
          '${widget.stats['feedingHours']} ч ${widget.stats['feedingMinutes']} мин',
          '${widget.stats['feedingCount']} раз',
          colors.feedingColor,
        ),
        _buildStatItem(
          context,
          Icons.auto_awesome,
          '',
          '${widget.stats['diaperCount']} раз',
          colors.diaperColor,
        ),
        _buildStatItem(
          context,
          Icons.local_drink,
          '',
          '${widget.stats['bottleCount']} раз',
          colors.bottleColor,
        ),
      ],
    );
  }

  Widget _buildDetailedView(BuildContext context, dynamic colors) {
    if (widget.selectedTypes.length != 1) return Container();

    final eventType = widget.selectedTypes.first;
    final details = _detailedStats![eventType.name];

    if (details == null) return Container();

    switch (eventType) {
      case EventType.sleep:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(context, Icons.nightlight_round, details['night'],
                'Ночь', colors.sleepColor),
            _buildStatItem(context, Icons.wb_sunny, details['day'], 'День',
                colors.sleepColor),
            _buildStatItem(context, Icons.access_time, details['awake'],
                'Бодрствование', colors.sleepColor),
          ],
        );

      case EventType.diaper:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(context, Icons.water_drop, details['wet'], 'Мокрый',
                colors.diaperColor),
            _buildStatItem(context, Icons.cleaning_services, details['dirty'],
                'Грязный', colors.diaperColor),
            _buildStatItem(context, Icons.shuffle, details['mixed'],
                'Смешанный', colors.diaperColor),
          ],
        );

      case EventType.feeding:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(context, Icons.arrow_left, details['left'], 'Левая',
                colors.feedingColor),
            _buildStatItem(context, Icons.arrow_right, details['right'],
                'Правая', colors.feedingColor),
            _buildStatItem(context, Icons.compare_arrows, details['both'],
                'Обе', colors.feedingColor),
          ],
        );

      case EventType.bottle:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(context, Icons.restaurant, details['formula'],
                'Смесь', colors.bottleColor),
            _buildStatItem(context, Icons.child_friendly, details['breastMilk'],
                'Грудное молоко', colors.bottleColor),
            Container(), // Empty space for alignment
          ],
        );

      default:
        return Container();
    }
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String duration,
      String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 36,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (duration.isNotEmpty)
              Text(
                duration,
                style: TextStyle(
                  color: context.appColors.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              count,
              style: TextStyle(
                color: context.appColors.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
