// lib/screens/add_medicament_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/models/medicine.dart';
import 'package:baby_tracker/models/medicine_details.dart';
import 'package:baby_tracker/services/medicine_service.dart';
import 'package:baby_tracker/widgets/date_time_picker.dart';
import 'package:baby_tracker/screens/medicine/widgets/medicine_selection_screen.dart';

class AddMedicamentScreen extends StatefulWidget {
  final Event? event;

  const AddMedicamentScreen({super.key, this.event});

  @override
  State<AddMedicamentScreen> createState() => _AddMedicamentScreenState();
}

class _AddMedicamentScreenState extends State<AddMedicamentScreen> {
  DateTime _time = DateTime.now();
  Set<String> _selectedMedicineIds = {};
  final _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = false;
  MedicineDetails? _existingDetails;
  List<Medicine> _popularMedicines = [];
  final MedicineService _medicineService = MedicineService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    if (widget.event != null) {
      // Загружаем данные для редактирования
      _time = widget.event!.startedAt;
      if (widget.event!.notes != null) {
        _notesController.text = widget.event!.notes!;
      }

      // Загружаем детали лекарства
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      _existingDetails =
          await eventsProvider.getMedicineDetails(widget.event!.id);
      if (_existingDetails != null) {
        _selectedMedicineIds = {_existingDetails!.medicineId};
      }
    }

    // Загружаем популярные лекарства
    await _loadPopularMedicines();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPopularMedicines() async {
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final baby = babyProvider.currentBaby;

      if (baby != null) {
        final popularMedicines = await _medicineService.getPopularMedicines(
          familyId: baby.familyId,
          babyId: baby.id,
          limit: 4,
        );

        if (mounted) {
          setState(() {
            _popularMedicines = popularMedicines;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading popular medicines: $e');
    }
  }

  Future<void> _selectMedicines() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineSelectionScreen(
          initialSelectedIds: _selectedMedicineIds,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMedicineIds = result;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirestore() async {
    if (_isSaving || _selectedMedicineIds.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final baby = babyProvider.currentBaby;
      final user = authProvider.currentUser;

      if (baby == null || user == null) {
        throw Exception('Ребенок или пользователь не найдены');
      }

      bool success = false;
      if (widget.event != null) {
        // Обновляем существующее событие (только одно лекарство)
        final selectedMedicineId = _selectedMedicineIds.first;
        final updatedEvent = widget.event!.copyWith(
          startedAt: _time,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          lastModifiedAt: DateTime.now(),
        );

        success = await eventsProvider.updateEvent(updatedEvent);

        if (success) {
          // Обновляем детали лекарства
          final updatedDetails = MedicineDetails(
            id: '',
            eventId: widget.event!.id,
            medicineId: selectedMedicineId,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          await eventsProvider.updateMedicineDetails(
              widget.event!.id, updatedDetails);
        }
      } else {
        // Создаем события для всех выбранных лекарств
        int successCount = 0;
        for (String medicineId in _selectedMedicineIds) {
          final eventId = await eventsProvider.addMedicineEvent(
            babyId: baby.id,
            familyId: baby.familyId,
            time: _time,
            medicineId: medicineId,
            createdBy: user.uid,
            createdByName: user.displayName ?? 'Родитель',
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          if (eventId != null) {
            successCount++;
          }
        }
        success = successCount == _selectedMedicineIds.length;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null
                ? 'Лекарство обновлено'
                : _selectedMedicineIds.length > 1
                    ? 'Добавлено ${_selectedMedicineIds.length} лекарств'
                    : 'Лекарство добавлено'),
            backgroundColor: context.appColors.successColor,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка сохранения'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final selected = await showCupertinoDateTimePicker(context, _time);
    if (selected != null) {
      setState(() {
        _time = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services,
                  color: context.appColors.primaryAccent),
              SizedBox(width: 8),
              Text(
                widget.event != null ? 'Редактировать лекарство' : 'Лекарство',
                style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.appColors.primaryAccent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services,
                color: context.appColors.primaryAccent),
            SizedBox(width: 8),
            Text(
              widget.event != null ? 'Редактировать лекарство' : 'Лекарство',
              style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Время
            Text(
              'Время',
              style: TextStyle(
                color: context.appColors.textPrimaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.primaryAccent),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('Сегодня, HH:mm').format(_time),
                      style: TextStyle(
                        color: context.appColors.textPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Выбор лекарств
            Text(
              'Лекарства',
              style: TextStyle(
                color: context.appColors.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMedicineSelectionButton(),

            // Быстрый выбор популярных лекарств
            if (_popularMedicines.isNotEmpty && widget.event == null) ...[
              const SizedBox(height: 16),
              Text(
                'Часто используемые',
                style: TextStyle(
                  color: context.appColors.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildPopularMedicinesGrid(),
            ],

            const SizedBox(height: 32),

            // Комментарий
            _buildNotesField(),

            const SizedBox(height: 32),

            // Кнопка сохранить
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Комментарий',
          style: TextStyle(
            color: context.appColors.textPrimaryColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: TextStyle(color: context.appColors.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'Ваш комментарий',
            hintStyle: TextStyle(color: context.appColors.textHintColor),
            filled: true,
            fillColor: context.appColors.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineSelectionButton() {
    return GestureDetector(
      onTap: widget.event != null && _selectedMedicineIds.length > 1
          ? null
          : _selectMedicines,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedMedicineIds.isEmpty
                ? context.appColors.primaryAccent.withOpacity(0.3)
                : context.appColors.primaryAccent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedMedicineIds.isEmpty
                  ? Icons.medical_services_outlined
                  : Icons.medical_services,
              color: _selectedMedicineIds.isEmpty
                  ? context.appColors.textHintColor
                  : context.appColors.primaryAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedMedicineIds.isEmpty
                    ? 'Выберите лекарства'
                    : widget.event != null
                        ? 'Одно лекарство выбрано'
                        : '${_selectedMedicineIds.length} лекарств выбрано',
                style: TextStyle(
                  color: _selectedMedicineIds.isEmpty
                      ? context.appColors.textHintColor
                      : context.appColors.textPrimaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            if (widget.event == null || _selectedMedicineIds.length == 1) ...[
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.appColors.textHintColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed:
          _selectedMedicineIds.isEmpty || _isSaving ? null : _saveToFirestore,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.appColors.primaryAccent,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: context.appColors.surfaceVariantColor,
      ),
      child: _isSaving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: context.appColors.textPrimaryColor,
                strokeWidth: 2,
              ),
            )
          : Text(
              widget.event != null ? 'Обновить' : 'Сохранить',
              style: TextStyle(
                color: context.appColors.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildPopularMedicinesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _popularMedicines.map((medicine) {
        final isSelected = _selectedMedicineIds.contains(medicine.id);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedMedicineIds.remove(medicine.id);
              } else {
                _selectedMedicineIds.add(medicine.id);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.appColors.primaryAccent.withOpacity(0.15)
                  : context.appColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? context.appColors.primaryAccent
                    : context.appColors.textHintColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.medication_outlined,
                  size: 18,
                  color: isSelected
                      ? context.appColors.primaryAccent
                      : context.appColors.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  medicine.name,
                  style: TextStyle(
                    color: isSelected
                        ? context.appColors.primaryAccent
                        : context.appColors.textPrimaryColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
