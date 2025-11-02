// lib/widgets/medicine_search_field.dart
import 'package:flutter/material.dart';
import 'package:baby_tracker/providers/theme_provider.dart';

class MedicineSearchField extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const MedicineSearchField({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appColors.primaryAccent.withOpacity(0.3),
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: TextStyle(color: context.appColors.textPrimaryColor),
        decoration: InputDecoration(
          hintText: 'Поиск лекарств...',
          hintStyle: TextStyle(color: context.appColors.textHintColor),
          prefixIcon: Icon(
            Icons.search,
            color: context.appColors.primaryAccent,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
