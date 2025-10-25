import 'package:flutter/material.dart';
import 'package:baby_tracker/screens/stats/stats_screen.dart';
import 'package:baby_tracker/screens/settings/settings_screen.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
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
}
