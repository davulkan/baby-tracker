// lib/screens/add_feeding_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/models/feeding_details.dart';
import 'package:baby_tracker/models/event.dart';

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
        // Завершенное событие - редактирование, таймеры недоступны
        _endTime = widget.event!.endedAt!;
        _isManualMode = true;
      } else {
        // Это активное событие - включаем таймер
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
            backgroundColor: Color(0xFF10B981),
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

  Future<void> _createActiveEvent() async {
    if (_activeEventId != null) return;

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final baby = babyProvider.currentBaby;

    if (baby == null || authProvider.currentUser == null) return;

    final now = DateTime.now();

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
      // Создаем начальный документ FeedingDetails
      final initialDetails = FeedingDetails(
        id: eventId,
        eventId: eventId,
        breastSide: BreastSide.left,
        leftDurationSeconds: 0,
        rightDurationSeconds: 0,
        activeState: FeedingActiveState.none,
        lastActivityAt: now,
        notes: null,
      );
      await eventsProvider.updateFeedingDetails(eventId, initialDetails);
    }

    setState(() {
      _activeEventId = eventId;
      _startTime = now;
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

      // Обновляем детали кормления с текущим состоянием
      final pauseDetails = FeedingDetails(
        id: _activeEventId!,
        eventId: _activeEventId!,
        breastSide: _leftSeconds > 0 && _rightSeconds > 0
            ? BreastSide.both
            : (_leftSeconds > 0 ? BreastSide.left : BreastSide.right),
        leftDurationSeconds: _leftSeconds,
        rightDurationSeconds: _rightSeconds,
        activeState: FeedingActiveState.none, // Ставим на паузу
        lastActivityAt: now,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await eventsProvider.updateFeedingDetails(_activeEventId!, pauseDetails);

      // Делаем промежуточное сохранение - записываем endedAt для сохранения прогресса
      await eventsProvider.stopFeedingEvent(
        eventId: _activeEventId!,
        endedAt: now,
        lastModifiedBy: authProvider.currentUser?.uid,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Сразу создаем новое активное событие для возможности продолжения
      final newEventId = await eventsProvider.startFeedingEvent(
        babyId: (Provider.of<BabyProvider>(context, listen: false)
            .currentBaby
            ?.id)!,
        familyId: (Provider.of<BabyProvider>(context, listen: false)
            .currentBaby
            ?.familyId)!,
        startedAt: now,
        createdBy: authProvider.currentUser!.uid,
        createdByName: authProvider.currentUser!.displayName ?? 'Пользователь',
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (newEventId != null) {
        // Создаем детали для нового события с сохраненным прогрессом
        final continueDetails = FeedingDetails(
          id: newEventId,
          eventId: newEventId,
          breastSide: _leftSeconds > 0 && _rightSeconds > 0
              ? BreastSide.both
              : (_leftSeconds > 0 ? BreastSide.left : BreastSide.right),
          leftDurationSeconds: _leftSeconds,
          rightDurationSeconds: _rightSeconds,
          activeState: FeedingActiveState.none,
          lastActivityAt: now,
          notes: null,
        );
        await eventsProvider.updateFeedingDetails(newEventId, continueDetails);
        _activeEventId = newEventId;
      }
    }

    setState(() {
      _isLeftActive = false;
      _isRightActive = false;
    });
  }

  void _toggleBreast(bool isLeft) async {
    // Если нажали "Пауза" на активной груди - делаем промежуточное сохранение
    if ((isLeft && _isLeftActive) || (!isLeft && _isRightActive)) {
      await _pauseFeeding();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Кормление приостановлено и сохранено'),
            backgroundColor: Color(0xFF10B981),
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
        notes: null,
      );

      await eventsProvider.updateFeedingDetails(
          _activeEventId!, updatedDetails);
    }
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
            Icon(Icons.child_care, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              widget.event != null ? 'Редактировать кормление' : 'Кормление',
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
            ] else ...[
              _buildTimerMode(),
            ],
            const SizedBox(height: 32),
            if (!isTimerModeAvailable || _isManualMode) _buildBreastSelector(),
            const SizedBox(height: 32),
            _buildNotesField(),
            const SizedBox(height: 24),
            _buildAddPhotoButton(),
            const SizedBox(height: 32),
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
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
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
              border: Border.all(color: const Color(0xFF10B981)),
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
              border: Border.all(color: const Color(0xFF10B981)),
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
                backgroundColor:
                    _isLeftActive ? const Color(0xFF10B981) : Colors.grey[800],
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
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLeftActive ? 'Пауза' : 'Левая',
                    style: const TextStyle(
                      color: Colors.white,
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
                backgroundColor:
                    _isRightActive ? const Color(0xFF10B981) : Colors.grey[800],
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
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRightActive ? 'Пауза' : 'Правая',
                    style: const TextStyle(
                      color: Colors.white,
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
              color: isActive ? const Color(0xFF10B981) : Colors.white60,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? const Color(0xFF10B981) : Colors.grey[800]!,
                width: 2,
              ),
            ),
            child: Text(
              _formatDuration(seconds),
              style: TextStyle(
                color: isActive ? const Color(0xFF10B981) : Colors.white60,
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
            color: Colors.grey[900],
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
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
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
        side: const BorderSide(color: Color(0xFF10B981)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
      label: const Text(
        'Добавить фото',
        style: TextStyle(
          color: Color(0xFF10B981),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveToFirestore,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
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
