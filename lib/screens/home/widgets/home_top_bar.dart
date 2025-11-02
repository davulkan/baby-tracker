import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/screens/stats/stats_screen.dart';
import 'package:baby_tracker/screens/settings/settings_screen.dart';
import 'package:baby_tracker/screens/settings/widgets/baby_profile_screen.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.appColors.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart,
              color: context.appColors.primaryAccent,
              size: 20,
            ),
          ),
        ),
        // Три чипа: вес - фото+имя+возраст - рост
        Consumer<BabyProvider>(
          builder: (context, babyProvider, child) {
            final baby = babyProvider.currentBaby;
            if (baby == null) {
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BabyProfileScreen(),
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: context.appColors.primaryAccent,
                    size: 20,
                  ),
                ),
              );
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Чип с весом
                if (baby.weightAtBirthKg != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: context.appColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.appColors.primaryAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${baby.weightAtBirthKg!.toStringAsFixed(1)} кг',
                      style: TextStyle(
                        color: context.appColors.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Чип с фото и именем
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              context.appColors.primaryAccent
                                  .withOpacity(0.2),
                              context.appColors.secondaryAccent
                                  .withOpacity(0.2),
                            ],
                          ),
                          image: baby.photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(baby.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: baby.photoUrl == null
                            ? Icon(
                                Icons.child_care,
                                size: 20,
                                color: context.appColors.primaryAccent,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            baby.name,
                            style: TextStyle(
                              color: context.appColors.textPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            baby.ageText,
                            style: TextStyle(
                              color: context.appColors.textSecondaryColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Чип с ростом
                if (baby.heightAtBirthCm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.appColors.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.appColors.successColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${baby.heightAtBirthCm!.toStringAsFixed(0)} см',
                      style: TextStyle(
                        color: context.appColors.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.appColors.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings,
              color: context.appColors.primaryAccent,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
