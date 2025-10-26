import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:flutter/material.dart';

class StatsSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsSummaryWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          context,
          Icons.bed,
          '${stats['sleepHours']} ч ${stats['sleepMinutes']} мин',
          '${stats['sleepCount']} раз',
          colors.sleepColor,
        ),
        _buildStatItem(
          context,
          Icons.child_care,
          '${stats['feedingHours']} ч ${stats['feedingMinutes']} мин',
          '${stats['feedingCount']} раз',
          colors.feedingColor,
        ),
        _buildStatItem(
          context,
          Icons.auto_awesome,
          '',
          '${stats['diaperCount']} раз',
          colors.diaperColor,
        ),
        _buildStatItem(
          context,
          Icons.local_drink,
          '', // Пока без объема
          '${stats['bottleCount']} раз',
          colors.bottleColor,
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String duration,
      String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 36, // Задаем фиксированную высоту для выравнивания
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
