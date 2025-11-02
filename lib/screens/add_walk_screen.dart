import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/widgets/date_time_picker.dart';

class AddWalkScreen extends StatefulWidget {
  final Event? event;

  const AddWalkScreen({super.key, this.event});

  @override
  State<AddWalkScreen> createState() => _AddWalkScreenState();
}

class _AddWalkScreenState extends State<AddWalkScreen> {
  bool _isManualMode = true;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  // Для таймера
  bool _isTimerRunning = false;
  Timer? _timer;
  String? _activeEventId;

  // Для подписок на изменения
  StreamSubscription<List<Event>>? _activeEventsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSubscriptions();
    _initializeData();
  }

  void _initializeSubscriptions() {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final baby = babyProvider.currentBaby;
    if (baby != null) {
      _activeEventsSubscription =
          Provider.of<EventsProvider>(context, listen: false)
              .getActiveWalkEventsStream(baby.id)
              .listen(_onActiveEventsChanged);
    }
  }

  void _onActiveEventsChanged(List<Event> events) {
    if (!mounted) return;

    if (events.isNotEmpty && _activeEventId == null && widget.event == null) {
      // Есть активное событие, переключиться на него
      final event = events.first;
      setState(() {
        _activeEventId = event.id;
        _startTime = event.startedAt;
        _notesController.text = event.notes ?? '';
        _isTimerRunning = true;
        _isManualMode = false;
      });
      _startLocalTimer();
    } else if (events.isEmpty &&
        _activeEventId != null &&
        widget.event == null) {
      // Активное событие завершено другим пользователем
      _timer?.cancel();
      setState(() {
        _isTimerRunning = false;
        _endTime = DateTime.now();
        _activeEventId = null;
        _isManualMode = true;
      });
    }
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

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
    } else {
      // Для нового события, проверить активные
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final baby = babyProvider.currentBaby;
      if (baby != null) {
        final activeEvent =
            await eventsProvider.getActiveEvent(baby.id, EventType.walk);
        if (activeEvent != null) {
          _activeEventId = activeEvent.id;
          _startTime = activeEvent.startedAt;
          _notesController.text = activeEvent.notes ?? '';
          _isTimerRunning = true;
          _isManualMode = false;
          _startLocalTimer();
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _startLocalTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        // Просто обновляем UI каждую секунду
      });
    });
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
    final eventId = await eventsProvider.startWalkEvent(
      babyId: baby.id,
      familyId: baby.familyId,
      startedAt: _startTime,
      createdBy: user.uid,
      createdByName: user.displayName ?? 'Пользователь',
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
    final success = await eventsProvider.stopWalkEvent(
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
        const SnackBar(content: Text('Событие прогулки сохранено')),
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

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceVariantColor,
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
          color: isSelected
              ? context.appColors.secondaryAccent
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? context.appColors.textPrimaryColor
                : context.appColors.textSecondaryColor,
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
        Text(
          'Начало',
          style: TextStyle(
            color: context.appColors.textPrimaryColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectTime(context, true),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appColors.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.secondaryAccent),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('Сегодня, HH:mm').format(_startTime),
                  style: TextStyle(
                    color: context.appColors.textPrimaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Окончание',
          style: TextStyle(
            color: context.appColors.textPrimaryColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectTime(context, false),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appColors.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.secondaryAccent),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('Сегодня, HH:mm').format(_endTime),
                  style: TextStyle(
                    color: context.appColors.textPrimaryColor,
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
          style: TextStyle(
            color: context.appColors.textPrimaryColor,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _isTimerRunning ? _stopTimer : _startTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.secondaryAccent,
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
            color: context.appColors.textPrimaryColor,
          ),
          label: Text(
            _isTimerRunning ? 'Остановить' : 'Гуляем',
            style: TextStyle(
              color: context.appColors.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
            fillColor: context.appColors.surfaceVariantColor,
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
                      SnackBar(
                        content:
                            const Text('Ошибка: профиль ребенка не найден'),
                        backgroundColor: context.appColors.errorColor,
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
                  } else {
                    // Создаем новое событие
                    final eventId = await eventsProvider.addWalkEvent(
                      babyId: baby.id,
                      familyId: authProvider.familyId!,
                      startedAt: start,
                      endedAt: end,
                      createdBy: authProvider.currentUser!.uid,
                      createdByName: authProvider.currentUser!.displayName ??
                          'Пользователь',
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
                            ? 'Прогулка обновлена'
                            : 'Прогулка добавлена'),
                        backgroundColor: context.appColors.successColor,
                      ),
                    );
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          eventsProvider.error ??
                              (widget.event != null
                                  ? 'Ошибка обновления прогулки'
                                  : 'Ошибка добавления прогулки'),
                        ),
                        backgroundColor: context.appColors.errorColor,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.secondaryAccent,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: eventsProvider.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.appColors.textPrimaryColor,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTimerModeAvailable =
        widget.event == null || widget.event!.endedAt == null;

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
              Icon(Icons.directions_walk,
                  color: context.appColors.secondaryAccent),
              SizedBox(width: 8),
              Text(
                widget.event != null ? 'Редактировать прогулку' : 'Прогулка',
                style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.appColors.secondaryAccent,
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
            Icon(Icons.directions_walk,
                color: context.appColors.secondaryAccent),
            SizedBox(width: 8),
            Text(
              widget.event != null ? 'Редактировать прогулку' : 'Прогулка',
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
            if (isTimerModeAvailable) ...[
              _buildModeSelector(),
              const SizedBox(height: 32),
            ],
            if (!isTimerModeAvailable || _isManualMode) ...[
              _buildManualMode(),
              const SizedBox(height: 32),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ] else ...[
              _buildTimerMode(),
              const SizedBox(height: 32),
              _buildNotesField(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _timer?.cancel();
    _activeEventsSubscription?.cancel();
    super.dispose();
  }
}
