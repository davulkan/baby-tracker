// lib/screens/add_diaper_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/models/diaper_details.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/widgets/date_time_picker.dart';

class AddDiaperScreen extends StatefulWidget {
  final Event? event;

  const AddDiaperScreen({super.key, this.event});

  @override
  State<AddDiaperScreen> createState() => _AddDiaperScreenState();
}

class _AddDiaperScreenState extends State<AddDiaperScreen> {
  DiaperType _diaperType = DiaperType.mixed;
  DateTime _time = DateTime.now();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  DiaperDetails? _existingDetails;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.event != null) {
      // Загружаем данные для редактирования
      _time = widget.event!.startedAt;
      if (widget.event!.notes != null) {
        _notesController.text = widget.event!.notes!;
      }

      // Загружаем детали подгузника
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      _existingDetails =
          await eventsProvider.getDiaperDetails(widget.event!.id);
      if (_existingDetails != null) {
        _diaperType = _existingDetails!.diaperType;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirestore() async {
    if (_isSaving) return;

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

      bool success;
      if (widget.event != null) {
        // Обновляем существующее событие
        final updatedEvent = widget.event!.copyWith(
          startedAt: _time,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          lastModifiedAt: DateTime.now(),
        );

        success = await eventsProvider.updateEvent(updatedEvent);

        if (success) {
          // Обновляем детали подгузника
          final updatedDetails = DiaperDetails(
            id: '',
            eventId: widget.event!.id,
            diaperType: _diaperType,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          await eventsProvider.updateDiaperDetails(
              widget.event!.id, updatedDetails);
        }
      } else {
        // Создаем новое событие подгузника
        final eventId = await eventsProvider.addDiaperEvent(
          babyId: baby.id,
          familyId: baby.familyId,
          time: _time,
          createdBy: user.uid,
          createdByName: user.displayName ?? 'Родитель',
          diaperType: _diaperType,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        success = eventId != null;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null
                ? 'Подгузник обновлен'
                : 'Подгузник добавлен'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка сохранения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
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

  String _getDiaperTypeLabel(DiaperType type) {
    switch (type) {
      case DiaperType.wet:
        return 'Мокрый 💧';
      case DiaperType.dirty:
        return 'Грязный 💩';
      case DiaperType.mixed:
        return 'Смешанный 💧💩';
    }
  }

  Color _getDiaperTypeColor(DiaperType type) {
    switch (type) {
      case DiaperType.wet:
        return const Color(0xFF3B82F6);
      case DiaperType.dirty:
        return const Color(0xFF8B5CF6);
      case DiaperType.mixed:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text(
              widget.event != null ? 'Редактировать подгузник' : 'Подгузник',
              style: TextStyle(color: Colors.white),
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
            const Text(
              'Время',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('Сегодня, HH:mm').format(_time),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Тип подгузника
            const Text(
              'Тип',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildDiaperTypeSelector(),

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

  Widget _buildDiaperTypeSelector() {
    return Column(
      children: [
        _buildDiaperTypeButton(DiaperType.wet),
        const SizedBox(height: 12),
        _buildDiaperTypeButton(DiaperType.dirty),
        const SizedBox(height: 12),
        _buildDiaperTypeButton(DiaperType.mixed),
      ],
    );
  }

  Widget _buildDiaperTypeButton(DiaperType type) {
    final isSelected = _diaperType == type;
    final color = _getDiaperTypeColor(type);

    return GestureDetector(
      onTap: () => setState(() => _diaperType = type),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _getDiaperTypeLabel(type),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Комментарий',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ваш комментарий',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveToFirestore,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF59E0B),
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey[700],
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              widget.event != null ? 'Обновить' : 'Сохранить',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
