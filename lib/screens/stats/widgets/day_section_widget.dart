import 'package:flutter/material.dart';
import 'package:baby_tracker/screens/stats/widgets/pattern_chart_widget.dart';
import 'package:baby_tracker/screens/stats/widgets/stats_summary_widget.dart';

class DaySectionWidget extends StatelessWidget {
  final String title;
  final Map<String, dynamic> stats;

  const DaySectionWidget({
    super.key,
    required this.title,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
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
        PatternChartWidget(chartEvents: stats['chartEvents']),

        const SizedBox(height: 16),

        // Сводка
        StatsSummaryWidget(stats: stats),
      ],
    );
  }
}