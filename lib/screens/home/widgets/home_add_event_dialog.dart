import 'package:flutter/material.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/screens/add_sleep_screen.dart';
import 'package:baby_tracker/screens/add_feeding_screen.dart';
import 'package:baby_tracker/screens/add_diaper_screen.dart';
import 'package:baby_tracker/screens/add_bottle_screen.dart';
import 'package:baby_tracker/screens/add_weight_screen.dart';
import 'package:baby_tracker/screens/add_height_screen.dart';
import 'package:baby_tracker/screens/add_walk_screen.dart';
import 'package:baby_tracker/screens/add_bath_screen.dart';
import 'package:baby_tracker/screens/medicine/add_medicament_screen.dart';

class HomeAddEventDialog {
  static void show(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Добавить событие',
              style: TextStyle(
                color: appColors.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAddEventButton(
                      context,
                      icon: Icons.bed,
                      label: 'Сон',
                      color: appColors.sleepColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddSleepScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.child_care,
                      label: 'Кормление',
                      color: appColors.feedingColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddFeedingScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.local_drink,
                      label: 'Бутылка',
                      color: appColors.bottleColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddBottleScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.auto_awesome,
                      label: 'Подгузник',
                      color: appColors.diaperColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddDiaperScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.monitor_weight,
                      label: 'Вес',
                      color: appColors.primaryAccent,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddWeightScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.height,
                      label: 'Рост',
                      color: appColors.secondaryAccent,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddHeightScreen()),
                        );
                      },
                    ),
                    // const SizedBox(height: 12),
                    // _buildAddEventButton(
                    //   context,
                    //   icon: Icons.child_care,
                    //   label: 'Окружность головы',
                    //   color: appColors.warningColor,
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (_) =>
                    //               const AddHeadCircumferenceScreen()),
                    //     );
                    //   },
                    // ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.directions_walk,
                      label: 'Прогулка',
                      color: appColors.successColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddWalkScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.bathtub,
                      label: 'Купание',
                      color: appColors.secondaryAccent,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddBathScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddEventButton(
                      context,
                      icon: Icons.medical_services,
                      label: 'Лекарства',
                      color: appColors.errorColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddMedicamentScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
    final appColors = context.appColors;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appColors.surfaceVariantColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
              style: TextStyle(
                color: appColors.textPrimaryColor,
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
