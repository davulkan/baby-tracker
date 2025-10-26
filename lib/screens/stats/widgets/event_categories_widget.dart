import 'package:flutter/material.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/providers/theme_provider.dart';

class EventCategoriesWidget extends StatelessWidget {
  final Set<EventType> selectedTypes;
  final Function(EventType) onToggle;

  const EventCategoriesWidget({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryIcon(
            context,
            Icons.bed,
            'Сон',
            context.appColors.sleepColor,
            EventType.sleep,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            context,
            Icons.child_care,
            'Кормление',
            context.appColors.feedingColor,
            EventType.feeding,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            context,
            Icons.auto_awesome,
            'Подгузник',
            context.appColors.diaperColor,
            EventType.diaper,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            context,
            Icons.local_drink,
            'Бутылка',
            context.appColors.bottleColor,
            EventType.bottle,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context, IconData icon, String label,
      Color color, EventType type) {
    final isSelected = selectedTypes.contains(type);

    return GestureDetector(
      onTap: () => onToggle(type),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.appColors.surfaceVariantColor
                  : context.appColors.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? color : context.appColors.textSecondaryColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? color : context.appColors.textSecondaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? context.appColors.textPrimaryColor
                  : context.appColors.textSecondaryColor,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
