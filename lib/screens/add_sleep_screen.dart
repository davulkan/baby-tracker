// lib/screens/add_sleep_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/sleep_details.dart';
import 'package:baby_tracker/models/event.dart';

class AddSleepScreen extends StatefulWidget {
  final Event? event;

  const AddSleepScreen({super.key, this.event});

  @override
  State<AddSleepScreen> createState() => _AddSleepScreenState();
}

class _AddSleepScreenState extends State<AddSleepScreen> {
  bool _isManualMode = true;
  bool _isDayMode = true;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now();
  final _notesController = TextEditingController();
  SleepDetails? _existingDetails;

  // Для таймера
  bool _isTimerRunning = false;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.event != null) {
      // Загружаем данные для редактирования
      _startTime = widget.event!.startedAt;
      if (widget.event!.endedAt != null) {
        _endTime = widget.event!.endedAt!;
      }
      if (widget.event!.notes != null) {
        _notesController.text = widget.event!.notes!;
      }

      // Загружаем детали сна
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      _existingDetails = await eventsProvider.getSleepDetails(widget.event!.id);
      if (_existingDetails != null) {
        _isDayMode = _existingDetails!.sleepType == SleepType.day;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _notesController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _elapsedSeconds = 0;
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _endTime = DateTime.now();
    });
  }

  String _formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );

        if (isStart) {
          _startTime = selectedDateTime;
        } else {
          _endTime = selectedDateTime;
        }
      });
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
            Icon(Icons.bed, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text(
              widget.event != null ? 'Редактировать сон' : 'Сон',
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
            // Переключатель режима
            _buildModeSelector(),

            const SizedBox(height: 32),

            // Контент в зависимости от режима
            if (_isManualMode) ...[
              _buildManualMode(),
            ] else ...[
              _buildTimerMode(),
            ],

            const SizedBox(height: 32),

            // Тип сна (только в ручном режиме)
            if (_isManualMode) _buildSleepTypeSelector(),

            const SizedBox(height: 32),

            // Комментарий
            _buildNotesField(),

            const SizedBox(height: 24),

            // Кнопка добавить фото
            _buildAddPhotoButton(),

            const SizedBox(height: 32),

            // Кнопка сохранить
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              'Вручную',
              _isManualMode,
              () => setState(() => _isManualMode = true),
            ),
          ),
          Expanded(
            child: _buildModeButton(
              'Таймер',
              !_isManualMode,
              () => setState(() => _isManualMode = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildManualMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Начало',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectTime(context, true),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1)),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('Сегодня, HH:mm').format(_startTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Окончание',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectTime(context, false),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1)),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('Сегодня, HH:mm').format(_endTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerMode() {
    return Column(
      children: [
        Text(
          _formatDuration(_elapsedSeconds),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _isTimerRunning ? _stopTimer : _startTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: Icon(
            _isTimerRunning ? Icons.stop : Icons.play_arrow,
            color: Colors.white,
          ),
          label: Text(
            _isTimerRunning ? 'Остановить' : 'Заснул',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сон',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSleepTypeButton(
                  '☀️ Дневной',
                  _isDayMode,
                  () => setState(() => _isDayMode = true),
                ),
              ),
              Expanded(
                child: _buildSleepTypeButton(
                  '🌙 Ночной',
                  !_isDayMode,
                  () => setState(() => _isDayMode = false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTypeButton(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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

  Widget _buildAddPhotoButton() {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Добавить фото
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: const BorderSide(color: Color(0xFF6366F1)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
      label: const Text(
        'Добавить фото',
        style: TextStyle(
          color: Color(0xFF6366F1),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer3<AuthProvider, BabyProvider, EventsProvider>(
      builder: (context, authProvider, babyProvider, eventsProvider, child) {
        return ElevatedButton(
          onPressed: eventsProvider.isLoading
              ? null
              : () async {
                  final baby = babyProvider.currentBaby;
                  if (baby == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ошибка: профиль ребенка не найден'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  DateTime start, end;
                  if (_isManualMode) {
                    start = _startTime;
                    end = _endTime;
                  } else {
                    start = _startTime;
                    end = DateTime.now();
                  }

                  // Валидация
                  if (end.isBefore(start)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Окончание должно быть после начала'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  bool success;
                  if (widget.event != null) {
                    // Обновляем существующее событие
                    final updatedEvent = widget.event!.copyWith(
                      startedAt: start,
                      endedAt: end,
                      notes: _notesController.text.trim().isEmpty
                          ? null
                          : _notesController.text.trim(),
                      lastModifiedAt: DateTime.now(),
                    );

                    success = await eventsProvider.updateEvent(updatedEvent);

                    if (success) {
                      // Обновляем детали сна
                      final updatedDetails = SleepDetails(
                        id: '',
                        eventId: widget.event!.id,
                        sleepType: _isDayMode ? SleepType.day : SleepType.night,
                        notes: _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                      );
                      await eventsProvider.updateSleepDetails(
                          widget.event!.id, updatedDetails);
                    }
                  } else {
                    // Создаем новое событие
                    final eventId = await eventsProvider.addSleepEvent(
                      babyId: baby.id,
                      familyId: authProvider.familyId!,
                      startedAt: start,
                      endedAt: end,
                      createdBy: authProvider.currentUser!.uid,
                      createdByName: authProvider.currentUser!.displayName ??
                          'Пользователь',
                      sleepType: _isDayMode ? SleepType.day : SleepType.night,
                      notes: _notesController.text.trim().isEmpty
                          ? null
                          : _notesController.text.trim(),
                    );
                    success = eventId != null;
                  }

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.event != null
                            ? 'Сон обновлен'
                            : 'Сон добавлен'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          eventsProvider.error ??
                              (widget.event != null
                                  ? 'Ошибка обновления сна'
                                  : 'Ошибка добавления сна'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: eventsProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
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
      },
    );
  }
}
