import 'package:flutter/material.dart';
import 'package:baby_tracker/models/event.dart';

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
            Icons.bed,
            'Сон',
            const Color(0xFF6366F1),
            EventType.sleep,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            Icons.child_care,
            'Кормле...',
            const Color(0xFF10B981),
            EventType.feeding,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            Icons.auto_awesome,
            'Подгузн...',
            const Color(0xFFF59E0B),
            EventType.diaper,
          ),
          const SizedBox(width: 16),
          _buildCategoryIcon(
            Icons.local_drink,
            'Бутылка',
            const Color(0xFFEC4899),
            EventType.bottle,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(
      IconData icon, String label, Color color, EventType type) {
    final isSelected = selectedTypes.contains(type);

    return GestureDetector(
      onTap: () => onToggle(type),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[900] : Colors.grey[850],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.grey[700]!,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}