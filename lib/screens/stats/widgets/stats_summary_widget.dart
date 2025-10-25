import 'package:flutter/material.dart';

class StatsSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsSummaryWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        _buildStatItem(
          Icons.bed,
          '${stats['sleepHours']} ч ${stats['sleepMinutes']} мин',
          '${stats['sleepCount']} раз',
          const Color(0xFF6366F1),
        ),
        _buildStatItem(
          Icons.child_care,
          '${stats['feedingHours']} ч ${stats['feedingMinutes']} мин',
          '${stats['feedingCount']} раз',
          const Color(0xFF10B981),
        ),
        _buildStatItem(
          Icons.auto_awesome,
          '',
          '${stats['diaperCount']} раз',
          const Color(0xFFF59E0B),
        ),
        _buildStatItem(
          Icons.local_drink,
          '', // Пока без объема
          '${stats['bottleCount']} раз',
          const Color(0xFFEC4899),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      IconData icon, String duration, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (duration.isNotEmpty)
              Text(
                duration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}