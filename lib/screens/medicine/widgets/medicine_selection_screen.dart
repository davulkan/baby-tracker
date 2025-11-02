// lib/screens/medicine_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/medicine.dart';
import 'package:baby_tracker/screens/medicine/widgets/medicine_search_field.dart';
import 'package:baby_tracker/screens/medicine/widgets/medicine_selection_list.dart';

class MedicineSelectionScreen extends StatefulWidget {
  final Set<String> initialSelectedIds;

  const MedicineSelectionScreen({
    super.key,
    this.initialSelectedIds = const {},
  });

  @override
  State<MedicineSelectionScreen> createState() =>
      _MedicineSelectionScreenState();
}

class _MedicineSelectionScreenState extends State<MedicineSelectionScreen> {
  String _searchQuery = '';
  late Set<String> _selectedMedicineIds;
  List<Medicine> _medicines = [];

  @override
  void initState() {
    super.initState();
    _selectedMedicineIds = Set.from(widget.initialSelectedIds);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onMedicineToggled(String medicineId) {
    setState(() {
      if (_selectedMedicineIds.contains(medicineId)) {
        _selectedMedicineIds.remove(medicineId);
      } else {
        _selectedMedicineIds.add(medicineId);
      }
    });
  }

  Future<void> _addNewMedicine() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surfaceColor,
        title: Text(
          'Добавить лекарство',
          style: TextStyle(color: context.appColors.textPrimaryColor),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.appColors.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'Название лекарства',
            hintStyle: TextStyle(color: context.appColors.textHintColor),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(color: context.appColors.textHintColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(
              'Добавить',
              style: TextStyle(color: context.appColors.primaryAccent),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);

      final baby = babyProvider.currentBaby;
      if (baby != null) {
        final medicineId = await eventsProvider.addMedicine(
          familyId: baby.familyId,
          name: result,
        );
        if (medicineId != null) {
          setState(() {
            _selectedMedicineIds.add(medicineId);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Лекарство "$result" добавлено'),
                backgroundColor: context.appColors.successColor,
              ),
            );
          }
        }
      }
    }
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedMedicineIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services,
              color: context.appColors.primaryAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'Выбор лекарств',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _addNewMedicine,
            icon: Icon(
              Icons.add,
              color: context.appColors.primaryAccent,
            ),
            tooltip: 'Добавить лекарство',
          ),
        ],
      ),
      body: Consumer<BabyProvider>(
        builder: (context, babyProvider, child) {
          final baby = babyProvider.currentBaby;
          if (baby == null) {
            return Center(
              child: Text(
                'Ребенок не выбран',
                style: TextStyle(
                  color: context.appColors.textHintColor,
                  fontSize: 16,
                ),
              ),
            );
          }

          return StreamBuilder<List<Medicine>>(
            stream: Provider.of<EventsProvider>(context, listen: false)
                .getMedicinesStream(baby.familyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.appColors.primaryAccent,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: context.appColors.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки лекарств',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.appColors.errorColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              _medicines = snapshot.data ?? [];

              return Column(
                children: [
                  MedicineSearchField(
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                  ),
                  Expanded(
                    child: MedicineSelectionList(
                      medicines: _medicines,
                      selectedMedicineIds: _selectedMedicineIds,
                      onMedicineToggled: _onMedicineToggled,
                      searchQuery: _searchQuery,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: _selectedMedicineIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _confirmSelection,
              backgroundColor: context.appColors.primaryAccent,
              foregroundColor: context.appColors.textPrimaryColor,
              icon: const Icon(Icons.check),
              label: Text(
                'Выбрано: ${_selectedMedicineIds.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
