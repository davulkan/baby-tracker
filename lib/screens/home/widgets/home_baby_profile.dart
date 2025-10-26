import 'package:baby_tracker/models/baby.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/screens/settings/widgets/baby_profile_screen.dart';

class HomeBabyProfile extends StatelessWidget {
  const HomeBabyProfile({super.key});

  /// Переход к экрану профиля (для создания или редактирования)
  void _navigateToBabyProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BabyProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BabyProvider>(
      builder: (context, babyProvider, child) {
        final baby = babyProvider.currentBaby;

        // Используем общий отступ для обоих состояний
        const cardPadding = EdgeInsets.symmetric(horizontal: 24);

        if (baby == null) {
          return _buildAddBabyCard(
            context,
            padding: cardPadding,
            onTap: () => _navigateToBabyProfile(context),
          );
        }

        return _buildBabyProfileCard(
          context,
          baby: baby,
          padding: cardPadding,
          onTap: () => _navigateToBabyProfile(context),
        );
      },
    );
  }

  /// Виджет-карточка для добавления ребенка
  Widget _buildAddBabyCard(
    BuildContext context, {
    required EdgeInsets padding,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.surfaceVariantColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.child_care_outlined, // Используем outlined иконку
                size: 32,
                color: context.appColors.textSecondaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Добавьте профиль ребенка',
                  style: TextStyle(
                    color: context.appColors.textSecondaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500, // Чище, чем regular
                  ),
                ),
              ),
              // Иконка вместо IconButton, так как вся карточка кликабельна
              Icon(
                Icons.add_circle_outline,
                color: context.appColors.secondaryAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Виджет-карточка с информацией о ребенке
  Widget _buildBabyProfileCard(
    BuildContext context, {
    required Baby baby, // Предполагается, что у вас есть модель Baby
    required EdgeInsets padding,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: padding,
      // Оборачиваем в GestureDetector для возможности редактирования
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Используем тот же стиль контейнера для консистентности
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.surfaceVariantColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildAvatar(context, baby),
              const SizedBox(width: 16),
              _buildNameAndAge(context, baby),
              const SizedBox(width: 12),
              _buildStats(context, baby),
            ],
          ),
        ),
      ),
    );
  }

  /// Аватар ребенка
  Widget _buildAvatar(BuildContext context, Baby baby) {
    final hasPhoto = baby.photoUrl != null && baby.photoUrl!.isNotEmpty;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: context.appColors.surfaceVariantColor,
        shape: BoxShape.circle,
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(baby.photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      // Клиппинг для скругления изображения
      clipBehavior: Clip.antiAlias,
      child: !hasPhoto
          ? Icon(
              Icons.child_care,
              size: 32,
              color: context.appColors.primaryAccent,
            )
          : null,
    );
  }

  /// Имя и возраст
  Widget _buildNameAndAge(BuildContext context, Baby baby) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            baby.name.toUpperCase(),
            style: TextStyle(
              color: context.appColors.textPrimaryColor,
              fontSize: 18, // Немного уменьшил для более "легкого" вида
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4), // Увеличил отступ для "воздуха"
          Text(
            baby.ageText, // У вас должна быть эта логика в модели
            style: TextStyle(
              color: context.appColors.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Статистика (рост и вес)
  Widget _buildStats(BuildContext context, Baby baby) {
    // Используем Column, чтобы динамически добавлять детей
    // Это чище, чем if-условия со SizedBox
    final children = <Widget>[
      if (baby.heightAtBirthCm != null)
        _buildStatItem(
          context,
          '${baby.heightAtBirthCm!.toStringAsFixed(0)} см',
          'Рост',
        ),
      if (baby.heightAtBirthCm != null && baby.weightAtBirthKg != null)
        const SizedBox(height: 8),
      if (baby.weightAtBirthKg != null)
        _buildStatItem(
          context,
          '${baby.weightAtBirthKg!.toStringAsFixed(2)} кг',
          'Вес',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Вспомогательный виджет для отображения одного стата (напр. "80 см" / "Рост")
  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            color: context.appColors.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.appColors.textSecondaryColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/*
Предполагаемая модель Baby (для контекста)

class Baby {
  final String name;
  final String? photoUrl;
  final String ageText; // Напр. "1 год и 2 мес."
  final double? heightAtBirthCm;
  final double? weightAtBirthKg;

  Baby({
    required this.name,
    this.photoUrl,
    required this.ageText,
    this.heightAtBirthCm,
    this.weightAtBirthKg,
  });
}

*/
