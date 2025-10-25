import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/screens/settings/widgets/baby_profile_screen.dart';

class HomeBabyProfile extends StatelessWidget {
  const HomeBabyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BabyProvider>(
      builder: (context, babyProvider, child) {
        final baby = babyProvider.currentBaby;

        if (baby == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.child_care,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Добавьте профиль ребенка',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BabyProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                  image: baby.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(baby.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: baby.photoUrl == null
                    ? const Icon(
                        Icons.child_care,
                        size: 32,
                        color: Color(0xFFFF8A80),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      baby.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      baby.ageText,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (baby.heightAtBirthCm != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${baby.heightAtBirthCm!.toStringAsFixed(0)} см',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Рост',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  if (baby.heightAtBirthCm != null &&
                      baby.weightAtBirthKg != null)
                    const SizedBox(height: 8),
                  if (baby.weightAtBirthKg != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${baby.weightAtBirthKg!.toStringAsFixed(2)} кг',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Вес',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
