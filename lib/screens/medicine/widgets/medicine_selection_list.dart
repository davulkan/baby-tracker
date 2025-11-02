// lib/widgets/medicine_selection_list.dart
import 'package:flutter/material.dart';
import 'package:baby_tracker/models/medicine.dart';
import 'package:baby_tracker/providers/theme_provider.dart';

class MedicineSelectionList extends StatelessWidget {
  final List<Medicine> medicines;
  final Set<String> selectedMedicineIds;
  final ValueChanged<String> onMedicineToggled;
  final String searchQuery;

  const MedicineSelectionList({
    super.key,
    required this.medicines,
    required this.selectedMedicineIds,
    required this.onMedicineToggled,
    required this.searchQuery,
  });

  List<Medicine> get filteredMedicines {
    if (searchQuery.isEmpty) {
      return medicines;
    }
    return medicines.where((medicine) {
      return medicine.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredMedicines;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: context.appColors.textHintColor,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? 'Нет лекарств' : 'Лекарства не найдены',
              style: TextStyle(
                fontSize: 18,
                color: context.appColors.textHintColor,
              ),
            ),
            if (searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Добавьте лекарства с помощью кнопки в верхней части экрана',
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textHintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Место для FAB
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final medicine = filtered[index];
        final isSelected = selectedMedicineIds.contains(medicine.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? context.appColors.primaryAccent.withOpacity(0.1)
                : context.appColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? context.appColors.primaryAccent
                  : context.appColors.surfaceVariantColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.appColors.primaryAccent
                    : context.appColors.surfaceVariantColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.medical_services,
                color: isSelected
                    ? context.appColors.textPrimaryColor
                    : context.appColors.primaryAccent,
                size: 20,
              ),
            ),
            title: Text(
              medicine.name,
              style: TextStyle(
                color: context.appColors.textPrimaryColor,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: context.appColors.primaryAccent,
                  )
                : null,
            onTap: () => onMedicineToggled(medicine.id),
          ),
        );
      },
    );
  }
}
