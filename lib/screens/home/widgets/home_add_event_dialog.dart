import 'package:flutter/material.dart';
import 'package:baby_tracker/screens/add_sleep_screen.dart';
import 'package:baby_tracker/screens/add_feeding_screen.dart';
import 'package:baby_tracker/screens/add_diaper_screen.dart';
import 'package:baby_tracker/screens/add_bottle_screen.dart';

class HomeAddEventDialog {
  static void show(BuildContext context) {
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

  static Widget _buildAddEventButton(
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
