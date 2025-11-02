import 'package:flutter/material.dart';
import 'package:baby_tracker/screens/stats/widgets/pattern_chart_widget.dart';
import 'package:baby_tracker/screens/stats/widgets/stats_summary_widget.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/event.dart';

class DaySectionWidget extends StatelessWidget {
  final String title;
  final Map<String, dynamic> stats;
  final Set<EventType> selectedTypes;
  final List<Event> events;

  const DaySectionWidget({
    super.key,
    required this.title,
    required this.stats,
    required this.selectedTypes,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.appColors.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // График паттерна на 24 часа
        PatternChartWidget(chartEvents: stats['chartEvents']),

        const SizedBox(height: 16),

        // Сводка
        StatsSummaryWidget(
          stats: stats,
          selectedTypes: selectedTypes,
          events: events,
        ),
      ],
    );
  }
}
