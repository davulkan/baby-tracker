// lib/screens/add_feeding_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/widgets/date_time_picker.dart';

class AddFeedingScreen extends StatefulWidget {
  final Event? event;

  const AddFeedingScreen({super.key, this.event});

  @override
  State<AddFeedingScreen> createState() => _AddFeedingScreenState();
}

class _AddFeedingScreenState extends State<AddFeedingScreen> {
  bool _isManualMode = true;
  BreastSide _breastSide = BreastSide.left;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  FeedingDetails? _existingDetails;

  // Для таймера
  Timer? _timer;
  int _leftSeconds = 0;
  int _rightSeconds = 0;
  bool _isLeftActive = false;
  bool _isRightActive = false;
  String? _activeEventId;

  // Для отслеживания порядка груди
  BreastSide? _firstBreast;
  BreastSide? _secondBreast;

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
        _endTime = widget.event!.endedAt!;
      }

      // Всегда можем использовать таймер, независимо от статуса события
      if (widget.event!.endedAt == null) {
        // Активное событие - переключаемся на режим таймера
        _isManualMode = false;
        _activeEventId = widget.event!.id;

        if (widget.event!.notes != null) {
          _notesController.text = widget.event!.notes!;
        }

        // Загружаем детали кормления из Firestore
        _existingDetails =
            await eventsProvider.getFeedingDetails(widget.event!.id);
        if (_existingDetails != null) {
          _breastSide = _existingDetails!.breastSide ?? BreastSide.left;
          _leftSeconds = _existingDetails!.leftDurationSeconds ?? 0;
          _rightSeconds = _existingDetails!.rightDurationSeconds ?? 0;
          _firstBreast = _existingDetails!.firstBreast;
          _secondBreast = _existingDetails!.secondBreast;

          // Определяем активное состояние из FeedingDetails
          _isLeftActive =
              _existingDetails!.activeState == FeedingActiveState.left;
          _isRightActive =
              _existingDetails!.activeState == FeedingActiveState.right;

          // Если есть активность и lastActivityAt, добавляем прошедшее время
          if ((_isLeftActive || _isRightActive) &&
              _existingDetails!.lastActivityAt != null) {
            final timeSinceLast = DateTime.now()
                .difference(_existingDetails!.lastActivityAt!)
                .inSeconds;
            if (_isLeftActive) {
              _leftSeconds += timeSinceLast;
            } else if (_isRightActive) {
              _rightSeconds += timeSinceLast;
            }
          }
        }

        // Запускаем таймер для обновления UI
        _startLocalTimer();
      }
      if (widget.event!.notes != null) {
        _notesController.text = widget.event!.notes!;
      }
    }
    // Убираем логику автоматического переключения в активный таймер
    // Пользователь должен иметь возможность создавать новые события независимо от активных
    setState(() {});
  }

  void _startLocalTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isLeftActive) {
          _leftSeconds++;
        } else if (_isRightActive) {
          _rightSeconds++;
        }
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveToFirestore() async {
    if (_isSaving) return;

    // Если есть активное событие, завершаем его
    if (_activeEventId != null) {
      await _finishFeeding();
    }

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
      if (widget.event != null && widget.event!.endedAt != null) {
        // Обновляем существующее завершенное событие
        final updatedEvent = widget.event!.copyWith(
          startedAt: _startTime,
          endedAt: _endTime,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          lastModifiedAt: DateTime.now(),
        );

        success = await eventsProvider.updateEvent(updatedEvent);

        if (success) {
          final updatedDetails = FeedingDetails(
            id: '',
            eventId: widget.event!.id,
            breastSide: _breastSide,
            leftDurationSeconds: null,
            rightDurationSeconds: null,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          await eventsProvider.updateFeedingDetails(
              widget.event!.id, updatedDetails);
        }
      } else {
        // Создаем новое завершенное событие кормления
        if (_isManualMode) {
          final eventId = await eventsProvider.addFeedingEvent(
            babyId: baby.id,
            familyId: baby.familyId,
            startedAt: _startTime,
            endedAt: _endTime,
            createdBy: user.uid,
            createdByName: user.displayName ?? 'Родитель',
            breastSide: _breastSide,
            leftDurationSeconds: null,
            rightDurationSeconds: null,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          success = eventId != null;
        } else {
          // Режим таймера - событие уже завершено в _finishFeeding
          success = true;
        }
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null
                ? 'Кормление обновлено'
                : 'Кормление добавлено'),
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

  Future<void> _createActiveEvent() async {
    if (_activeEventId != null) return;

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final baby = babyProvider.currentBaby;

    if (baby == null || authProvider.currentUser == null) return;

    final now = DateTime.now();
    final isResuming = _leftSeconds > 0 ||
        _rightSeconds > 0; // Проверяем, возобновляем ли кормление

    // Создаем активное событие в Firestore
    final eventId = await eventsProvider.startFeedingEvent(
      babyId: baby.id,
      familyId: baby.familyId,
      startedAt: now,
      createdBy: authProvider.currentUser!.uid,
      createdByName: authProvider.currentUser!.displayName ?? 'Пользователь',
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (eventId != null) {
      // Создаем документ FeedingDetails с сохраненным прогрессом
      final initialDetails = FeedingDetails(
        id: eventId,
        eventId: eventId,
        breastSide: _leftSeconds > 0 && _rightSeconds > 0
            ? BreastSide.both
            : (_leftSeconds > 0 ? BreastSide.left : BreastSide.right),
        leftDurationSeconds: _leftSeconds,
        rightDurationSeconds: _rightSeconds,
        activeState: FeedingActiveState.none,
        lastActivityAt: now,
        firstBreast: _firstBreast,
        secondBreast: _secondBreast,
        notes: null,
      );
      await eventsProvider.updateFeedingDetails(eventId, initialDetails);
    }

    setState(() {
      _activeEventId = eventId;
      if (!isResuming) {
        _startTime = now;
      }
    });
  }

  Future<void> _finishFeeding() async {
    _timer?.cancel();

    if (_activeEventId != null) {
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final now = DateTime.now();

      // Обновляем детали кормления перед завершением
      final finalDetails = FeedingDetails(
        id: _activeEventId!,
        eventId: _activeEventId!,
        breastSide: _leftSeconds > 0 && _rightSeconds > 0
            ? BreastSide.both
            : (_leftSeconds > 0 ? BreastSide.left : BreastSide.right),
        leftDurationSeconds: _leftSeconds,
        rightDurationSeconds: _rightSeconds,
        activeState: FeedingActiveState.none,
        lastActivityAt: now,
        firstBreast: _firstBreast,
        secondBreast: _secondBreast,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await eventsProvider.updateFeedingDetails(_activeEventId!, finalDetails);

      // Завершаем событие
      await eventsProvider.stopFeedingEvent(
        eventId: _activeEventId!,
        endedAt: now,
        lastModifiedBy: authProvider.currentUser?.uid,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    setState(() {
      _isLeftActive = false;
      _isRightActive = false;
      _endTime = DateTime.now();
      _activeEventId = null;
    });
  }

  Future<void> _pauseFeeding() async {
    if (_activeEventId != null) {
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final now = DateTime.now();

      // Обновляем детали кормления перед завершением
      final pauseDetails = FeedingDetails(
        id: _activeEventId!,
        eventId: _activeEventId!,
        breastSide: _leftSeconds > 0 && _rightSeconds > 0
            ? BreastSide.both
            : (_leftSeconds > 0 ? BreastSide.left : BreastSide.right),
        leftDurationSeconds: _leftSeconds,
        rightDurationSeconds: _rightSeconds,
        activeState: FeedingActiveState.none,
        lastActivityAt: now,
        firstBreast: _firstBreast,
        secondBreast: _secondBreast,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await eventsProvider.updateFeedingDetails(_activeEventId!, pauseDetails);

      // Завершаем текущее событие
      await eventsProvider.stopFeedingEvent(
        eventId: _activeEventId!,
        endedAt: now,
        lastModifiedBy: authProvider.currentUser?.uid,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    setState(() {
      _isLeftActive = false;
      _isRightActive = false;
      _activeEventId = null; // Сбрасываем ID активного события
    });
  }

  void _toggleBreast(bool isLeft) async {
    // Если нажали "Пауза" на активной груди - завершаем текущее событие
    if ((isLeft && _isLeftActive) || (!isLeft && _isRightActive)) {
      await _pauseFeeding();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Кормление завершено'),
            backgroundColor: context.appColors.successColor,
          ),
        );
      }
      return;
    }

    // Если событие не создано - создаем его
    if (_activeEventId == null) {
      await _createActiveEvent();
      // Запускаем таймер после создания активного события
      if (_timer == null && _activeEventId != null) {
        _startLocalTimer();
      }
    }

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final now = DateTime.now();
    final selectedBreast = isLeft ? BreastSide.left : BreastSide.right;

    // Обновляем порядок груди
    if (_firstBreast == null) {
      _firstBreast = selectedBreast;
    } else if (_firstBreast != selectedBreast && _secondBreast == null) {
      _secondBreast = selectedBreast;
    }

    setState(() {
      if (isLeft) {
        _isLeftActive = true;
        _isRightActive = false;
      } else {
        _isRightActive = true;
        _isLeftActive = false;
      }
    });

    // Определяем текущее активное состояние
    FeedingActiveState activeState = FeedingActiveState.none;
    if (_isLeftActive) {
      activeState = FeedingActiveState.left;
    } else if (_isRightActive) {
      activeState = FeedingActiveState.right;
    }

    // Обновляем детали кормления в Firestore
    if (_activeEventId != null) {
      final updatedDetails = FeedingDetails(
        id: _activeEventId!,
        eventId: _activeEventId!,
        breastSide: _leftSeconds > 0 && _rightSeconds > 0
            ? BreastSide.both
            : (_isLeftActive ? BreastSide.left : BreastSide.right),
        leftDurationSeconds: _leftSeconds,
        rightDurationSeconds: _rightSeconds,
        activeState: activeState,
        lastActivityAt: now,
        firstBreast: _firstBreast,
        secondBreast: _secondBreast,
        notes: null,
      );

      await eventsProvider.updateFeedingDetails(
          _activeEventId!, updatedDetails);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
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
            Icon(Icons.child_care, color: context.appColors.successColor),
            SizedBox(width: 8),
            Text(
              widget.event != null ? 'Редактировать кормление' : 'Кормление',
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
            _buildModeSelector(),
            const SizedBox(height: 32),
            if (_isManualMode) ...[
              _buildManualMode(),
              const SizedBox(height: 32),
              _buildBreastSelector(),
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
          color:
              isSelected ? context.appColors.successColor : Colors.transparent,
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
              border: Border.all(color: context.appColors.successColor),
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
              border: Border.all(color: context.appColors.successColor),
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
        Row(
          children: [
            _buildBreastTimer('Левая', _leftSeconds, _isLeftActive),
            const SizedBox(width: 16),
            _buildBreastTimer('Правая', _rightSeconds, _isRightActive),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => _toggleBreast(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLeftActive
                    ? context.appColors.successColor
                    : context.appColors.surfaceVariantColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLeftActive ? Icons.pause : Icons.timer,
                    color: context.appColors.textPrimaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLeftActive ? 'Пауза' : 'Левая',
                    style: TextStyle(
                      color: context.appColors.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _toggleBreast(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRightActive
                    ? context.appColors.successColor
                    : context.appColors.surfaceVariantColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRightActive ? Icons.pause : Icons.timer,
                    color: context.appColors.textPrimaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRightActive ? 'Пауза' : 'Правая',
                    style: TextStyle(
                      color: context.appColors.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreastTimer(String label, int seconds, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? context.appColors.successColor
                  : context.appColors.textSecondaryColor,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? context.appColors.successColor.withOpacity(0.2)
                  : context.appColors.surfaceVariantColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? context.appColors.successColor
                    : context.appColors.surfaceVariantColor,
                width: 2,
              ),
            ),
            child: Text(
              _formatDuration(seconds),
              style: TextStyle(
                color: isActive
                    ? context.appColors.successColor
                    : context.appColors.textSecondaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreastSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Грудь',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.appColors.surfaceVariantColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBreastButton(
                  'Левая',
                  _breastSide == BreastSide.left,
                  () => setState(() => _breastSide = BreastSide.left),
                ),
              ),
              Expanded(
                child: _buildBreastButton(
                  'Правая',
                  _breastSide == BreastSide.right,
                  () => setState(() => _breastSide = BreastSide.right),
                ),
              ),
              Expanded(
                child: _buildBreastButton(
                  'Обе',
                  _breastSide == BreastSide.both,
                  () => setState(() => _breastSide = BreastSide.both),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreastButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? context.appColors.successColor : Colors.transparent,
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
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveToFirestore,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.appColors.successColor,
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
}
