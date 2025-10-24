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

enum FeedingMode {
  breast,
  bottle,
  solid,
}

class AddFeedingScreen extends StatefulWidget {
  final Event? event;

  const AddFeedingScreen({super.key, this.event});

  @override
  State<AddFeedingScreen> createState() => _AddFeedingScreenState();
}

class _AddFeedingScreenState extends State<AddFeedingScreen> {
  bool _isManualMode = true;
  FeedingMode _feedingMode = FeedingMode.breast;
  BreastSide _breastSide = BreastSide.left;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSaving = false;
  FeedingDetails? _existingDetails;

  // Для таймера
  bool _isTimerRunning = false;
  Timer? _timer;
  int _leftSeconds = 0;
  int _rightSeconds = 0;
  bool _isTimingLeft = true;

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

      // Загружаем детали кормления
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      _existingDetails =
          await eventsProvider.getFeedingDetails(widget.event!.id);
      if (_existingDetails != null) {
        // Устанавливаем тип кормления
        switch (_existingDetails!.feedingType) {
          case FeedingType.breast:
            _feedingMode = FeedingMode.breast;
            if (_existingDetails!.breastSide != null) {
              _breastSide = _existingDetails!.breastSide!;
            }
            break;
          case FeedingType.bottle:
            _feedingMode = FeedingMode.bottle;
            if (_existingDetails!.bottleAmountMl != null) {
              _amountController.text =
                  _existingDetails!.bottleAmountMl!.toString();
            }
            break;
          case FeedingType.solid:
            _feedingMode = FeedingMode.solid;
            break;
        }
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveToFirestore() async {
    if (_isSaving) return;

    // Валидация
    if (_feedingMode == FeedingMode.bottle) {
      if (_amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Укажите объем бутылочки'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
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

      // Конвертируем FeedingMode в FeedingType
      FeedingType feedingType;
      switch (_feedingMode) {
        case FeedingMode.breast:
          feedingType = FeedingType.breast;
          break;
        case FeedingMode.bottle:
          feedingType = FeedingType.bottle;
          break;
        case FeedingMode.solid:
          feedingType = FeedingType.solid;
          break;
      }

      bool success;
      if (widget.event != null) {
        // Обновляем существующее событие
        final updatedEvent = widget.event!.copyWith(
          startedAt: _startTime,
          endedAt: _endTime,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          lastModifiedAt: DateTime.now(),
        );

        success = await eventsProvider.updateEvent(updatedEvent);

        if (success) {
          // Обновляем детали кормления
          final updatedDetails = FeedingDetails(
            id: '',
            eventId: widget.event!.id,
            feedingType: feedingType,
            breastSide: _feedingMode == FeedingMode.breast ? _breastSide : null,
            leftDurationSeconds: null,
            rightDurationSeconds: null,
            bottleAmountMl: _feedingMode == FeedingMode.bottle
                ? double.tryParse(_amountController.text)
                : null,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          await eventsProvider.updateFeedingDetails(
              widget.event!.id, updatedDetails);
        }
      } else {
        // Создаем новое событие кормления
        if (_isManualMode) {
          // Ручной режим
          final eventId = await eventsProvider.addFeedingEvent(
            babyId: baby.id,
            familyId: baby.familyId,
            startedAt: _startTime,
            endedAt: _endTime,
            createdBy: user.uid,
            createdByName: user.displayName ?? 'Родитель',
            feedingType: feedingType,
            breastSide: _feedingMode == FeedingMode.breast ? _breastSide : null,
            leftDurationSeconds: null,
            rightDurationSeconds: null,
            bottleAmountMl: _feedingMode == FeedingMode.bottle
                ? double.tryParse(_amountController.text)
                : null,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          success = eventId != null;
        } else {
          // Режим таймера
          final now = DateTime.now();
          final totalSeconds = _leftSeconds + _rightSeconds;

          final eventId = await eventsProvider.addFeedingEvent(
            babyId: baby.id,
            familyId: baby.familyId,
            startedAt: now.subtract(Duration(seconds: totalSeconds)),
            endedAt: now,
            createdBy: user.uid,
            createdByName: user.displayName ?? 'Родитель',
            feedingType: feedingType,
            breastSide: _leftSeconds > 0 && _rightSeconds > 0
                ? BreastSide.both
                : (_leftSeconds > 0 ? BreastSide.left : BreastSide.right),
            leftDurationSeconds: _leftSeconds > 0 ? _leftSeconds : null,
            rightDurationSeconds: _rightSeconds > 0 ? _rightSeconds : null,
            bottleAmountMl: null,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          success = eventId != null;
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

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isTimingLeft) {
          _leftSeconds++;
        } else {
          _rightSeconds++;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _switchBreast() {
    setState(() {
      _isTimingLeft = !_isTimingLeft;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
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

            // Выбор груди (только для грудного кормления и в ручном режиме)
            if (_feedingMode == FeedingMode.breast && _isManualMode)
              _buildBreastSelector(),

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
        // Таймеры для левой и правой груди
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBreastTimer(
                'Левая', _leftSeconds, _isTimingLeft && _isTimerRunning),
            _buildBreastTimer(
                'Правая', _rightSeconds, !_isTimingLeft && _isTimerRunning),
          ],
        ),

        const SizedBox(height: 32),

        // Кнопки управления
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isTimerRunning) ...[
              ElevatedButton.icon(
                onPressed: _switchBreast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                label: const Text(
                  'Сменить',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            ElevatedButton.icon(
              onPressed: _isTimerRunning ? _stopTimer : _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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
                _isTimerRunning ? 'Завершить' : 'Начать',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreastTimer(String label, int seconds, bool isActive) {
    return Column(
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
          padding: const EdgeInsets.all(20),
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
              color: isActive ? const Color(0xFF10B981) : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
