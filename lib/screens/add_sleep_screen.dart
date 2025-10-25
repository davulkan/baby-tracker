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
import 'package:baby_tracker/widgets/date_time_picker.dart';

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
  String? _activeEventId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    if (widget.event != null) {
      // Загружаем данные для редактирования
      _startTime = widget.event!.startedAt;
      if (widget.event!.endedAt != null) {
        // Завершенное событие
        _endTime = widget.event!.endedAt!;
        _isManualMode = true;
      } else {
        // Активное событие - включаем таймер
        _isManualMode = false;
        _isTimerRunning = true;
        _activeEventId = widget.event!.id;

        // Запускаем локальный таймер для обновления UI
        _startLocalTimer();
      }

      if (widget.event!.notes != null) {
        _notesController.text = widget.event!.notes!;
      }

      // Загружаем детали сна
      _existingDetails = await eventsProvider.getSleepDetails(widget.event!.id);
      if (_existingDetails != null) {
        _isDayMode = _existingDetails!.sleepType == SleepType.day;
      }
    }
    // Убираем логику автоматического переключения в активный таймер
    // Пользователь должен иметь возможность создавать новые события независимо от активных
    setState(() {});
  }

  void _startLocalTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Просто обновляем UI каждую секунду
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final baby = babyProvider.currentBaby;
    final user = authProvider.currentUser;

    if (baby == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ошибка: нет данных о ребенке или пользователе')),
      );
      return;
    }

    setState(() {
      _isTimerRunning = true;
      _startTime = DateTime.now();
    });

    // Создаем событие в Firestore
    final eventId = await eventsProvider.startSleepEvent(
      babyId: baby.id,
      familyId: baby.familyId,
      startedAt: _startTime,
      createdBy: user.uid,
      createdByName: user.displayName ?? 'Пользователь',
      sleepType: _isDayMode ? SleepType.day : SleepType.night,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (eventId != null) {
      _activeEventId = eventId;
      _startLocalTimer();
    } else {
      setState(() {
        _isTimerRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка запуска таймера')),
      );
    }
  }

  void _stopTimer() async {
    if (_activeEventId == null) return;

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _timer?.cancel();
    final endTime = DateTime.now();

    // Завершаем событие в Firestore
    final success = await eventsProvider.stopSleepEvent(
      eventId: _activeEventId!,
      endedAt: endTime,
      lastModifiedBy: authProvider.currentUser?.uid,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() {
      _isTimerRunning = false;
      _endTime = endTime;
      if (success) {
        _activeEventId = null;
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие сна сохранено')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка завершения таймера')),
      );
    }
  }

  String _formatDuration() {
    if (_activeEventId == null) return '00:00:00';

    final elapsed = DateTime.now().difference(_startTime);
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final selected = await showCupertinoDateTimePicker(
        context, isStart ? _startTime : _endTime);
    if (selected != null) {
      setState(() {
        if (isStart) {
          _startTime = selected;
        } else {
          _endTime = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTimerModeAvailable =
        widget.event == null || widget.event!.endedAt == null;

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
            if (isTimerModeAvailable) ...[
              _buildModeSelector(),
              const SizedBox(height: 32),
            ],
            if (!isTimerModeAvailable || _isManualMode) ...[
              _buildManualMode(),
              const SizedBox(height: 32),
              _buildSleepTypeSelector(),
              const SizedBox(height: 32),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ] else ...[
              _buildTimerMode(),
              const SizedBox(height: 32),
              _buildSleepTypeSelector(),
              const SizedBox(height: 32),
              _buildNotesField(),
            ],
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
          _formatDuration(),
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
