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
import 'package:baby_tracker/services/timer_storage_service.dart';

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
  final _amountController = TextEditingController();
  bool _isSaving = false;
  FeedingDetails? _existingDetails;

  // Для таймера
  bool _isTimerRunning = false;
  Timer? _timer;
  int _leftSeconds = 0;
  int _rightSeconds = 0;
  bool _isLeftActive = false;
  bool _isRightActive = false;
  bool _isPaused = false;
  String? _activeEventId;

  final _timerStorage = TimerStorageService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);

    if (widget.event != null) {
      // Загружаем данные для редактирования
      _startTime = widget.event!.startedAt;
      if (widget.event!.endedAt != null) {
        // Завершенное событие - редактирование, таймеры недоступны
        _endTime = widget.event!.endedAt!;
        _isManualMode = true; // Только ручной режим для завершенных событий
      } else {
        // Это активное событие - включаем таймер
        _isManualMode = false; // Переключаем в режим таймера
        _isTimerRunning = true;
        _activeEventId = widget.event!.id;
        final diff = DateTime.now().difference(widget.event!.startedAt);
        final totalSeconds = diff.inSeconds;

        if (widget.event!.notes != null) {
          _notesController.text = widget.event!.notes!;
        }

        // Пытаемся загрузить состояние из TimerStorage
        final timerState =
            await _timerStorage.getTimerState(eventId: widget.event!.id);
        bool hasTimerState = timerState != null;

        print('DEBUG: Loading event ${widget.event!.id}');
        print('DEBUG: TimerStorage state: $timerState');
        print('DEBUG: Has timer state: $hasTimerState');

        // Приоритет: сначала восстанавливаем из TimerStorage (самое актуальное)
        if (hasTimerState) {
          final savedLeftSeconds = timerState['leftSeconds'] ?? 0;
          final savedRightSeconds = timerState['rightSeconds'] ?? 0;
          _isLeftActive = timerState['isLeftActive'] ?? false;
          _isRightActive = timerState['isRightActive'] ?? false;

          // Рассчитываем прошедшее время с момента сохранения
          final timeSinceSave = DateTime.now().difference(_startTime).inSeconds;

          // Добавляем прошедшее время к активной груди
          if (_isLeftActive) {
            _leftSeconds = savedLeftSeconds + timeSinceSave;
            _rightSeconds = savedRightSeconds;
          } else if (_isRightActive) {
            _rightSeconds = savedRightSeconds + timeSinceSave;
            _leftSeconds = savedLeftSeconds;
          } else {
            // Обе груди на паузе - используем сохраненные значения
            _leftSeconds = savedLeftSeconds;
            _rightSeconds = savedRightSeconds;
          }

          print(
              'DEBUG: Restored from TimerStorage - Left: $_leftSeconds ($_isLeftActive), Right: $_rightSeconds ($_isRightActive), timeSinceSave: $timeSinceSave');

          // Обновляем UI сразу
          setState(() {});
        } else {
          // Если нет TimerStorage, используем totalSeconds
          _isLeftActive = true;
          _isRightActive = false;
          _leftSeconds = totalSeconds;
          print('DEBUG: No TimerStorage, using totalSeconds: $totalSeconds');
        }

        // Загружаем детали кормления для дополнительной информации
        _existingDetails =
            await eventsProvider.getFeedingDetails(widget.event!.id);
        if (_existingDetails != null) {
          _breastSide = _existingDetails!.breastSide!;
        } else {
          print('DEBUG: No feeding details found in Firestore');
        }

        // Запускаем таймер
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_isPaused) {
            setState(() {
              if (_isLeftActive) {
                _leftSeconds++;
              } else if (_isRightActive) {
                _rightSeconds++;
              }
            });
          }

          // Сохраняем состояние каждые 5 секунд
          if ((_leftSeconds + _rightSeconds) % 5 == 0) {
            _timerStorage.saveFeedingTimerState(
              eventId: _activeEventId!,
              startTime: _startTime,
              leftSeconds: _leftSeconds,
              rightSeconds: _rightSeconds,
              isLeftActive: _isLeftActive,
              isRightActive: _isRightActive,
            );
          }
        });
      }
      if (widget.event!.notes != null) {
        _notesController.text = widget.event!.notes!;
      }

      // Для завершенных событий загружаем детали отдельно
      if (widget.event!.endedAt != null && _existingDetails == null) {
        _existingDetails =
            await eventsProvider.getFeedingDetails(widget.event!.id);
        if (_existingDetails != null) {
          // Устанавливаем тип кормления
          _breastSide = _existingDetails!.breastSide!;
        }
      }
    } else {
      // Проверяем, есть ли активное событие кормления
      final baby = babyProvider.currentBaby;
      if (baby != null) {
        final activeEvent = await eventsProvider.getActiveFeedingEvent(baby.id);
        if (activeEvent != null) {
          // Есть активное событие - показываем его
          _isManualMode = false; // Переключаем в режим таймера
          _startTime = activeEvent.startedAt;
          _isTimerRunning = true;
          _activeEventId = activeEvent.id;
          final diff = DateTime.now().difference(activeEvent.startedAt);
          final totalSeconds = diff.inSeconds;

          if (activeEvent.notes != null) {
            _notesController.text = activeEvent.notes!;
          }

          // Пытаемся загрузить состояние из TimerStorage
          final timerState =
              await _timerStorage.getTimerState(eventId: activeEvent.id);
          bool hasTimerState = timerState != null;

          print('DEBUG: Loading active event ${activeEvent.id}');
          print('DEBUG: TimerStorage state: $timerState');
          print('DEBUG: Has timer state: $hasTimerState');

          // Приоритет: сначала восстанавливаем из TimerStorage (самое актуальное)
          if (hasTimerState) {
            final savedLeftSeconds = timerState['leftSeconds'] ?? 0;
            final savedRightSeconds = timerState['rightSeconds'] ?? 0;
            _isLeftActive = timerState['isLeftActive'] ?? false;
            _isRightActive = timerState['isRightActive'] ?? false;

            // Рассчитываем прошедшее время с момента сохранения
            final timeSinceSave =
                DateTime.now().difference(_startTime).inSeconds;

            // Добавляем прошедшее время к активной груди
            if (_isLeftActive) {
              _leftSeconds = savedLeftSeconds + timeSinceSave;
              _rightSeconds = savedRightSeconds;
            } else if (_isRightActive) {
              _rightSeconds = savedRightSeconds + timeSinceSave;
              _leftSeconds = savedLeftSeconds;
            } else {
              // Обе груди на паузе - используем сохраненные значения
              _leftSeconds = savedLeftSeconds;
              _rightSeconds = savedRightSeconds;
            }

            print(
                'DEBUG: Restored from TimerStorage - Left: $_leftSeconds ($_isLeftActive), Right: $_rightSeconds ($_isRightActive), timeSinceSave: $timeSinceSave');

            // Обновляем UI сразу
            setState(() {});
          } else {
            // Если нет TimerStorage, используем totalSeconds
            _isLeftActive = true;
            _isRightActive = false;
            _leftSeconds = totalSeconds;
            print('DEBUG: No TimerStorage, using totalSeconds: $totalSeconds');
          }

          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!_isPaused) {
              setState(() {
                if (_isLeftActive) {
                  _leftSeconds++;
                } else if (_isRightActive) {
                  _rightSeconds++;
                }
              });
            }

            // Сохраняем состояние каждые 5 секунд
            if ((_leftSeconds + _rightSeconds) % 5 == 0) {
              _timerStorage.saveFeedingTimerState(
                eventId: _activeEventId!,
                startTime: _startTime,
                leftSeconds: _leftSeconds,
                rightSeconds: _rightSeconds,
                isLeftActive: _isLeftActive,
                isRightActive: _isRightActive,
              );
            }
          });
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

    // Если есть активное событие (вне зависимости от состояния таймера), завершаем его.
    // Раньше мы завершали только когда _isTimerRunning == true, но если пользователь
    // поставил таймер на паузу (isTimerRunning == false) событие оставалось активным
    // и локальное состояние не очищалось. Всегда вызываем _finishFeeding для чистоты.
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
            breastSide: _breastSide,
            leftDurationSeconds: null,
            rightDurationSeconds: null,
            bottleAmountMl: null,
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
            breastSide: _breastSide,
            leftDurationSeconds: null,
            rightDurationSeconds: null,
            bottleAmountMl: null,
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

  Future<void> _createActiveEvent() async {
    if (_activeEventId != null) return; // Уже создано

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final baby = babyProvider.currentBaby;

    if (baby == null || authProvider.currentUser == null) return;

    final now = DateTime.now();

    // Создаем активное событие в базе данных
    final eventId = await eventsProvider.startFeedingEvent(
      babyId: baby.id,
      familyId: baby.familyId,
      startedAt: now,
      createdBy: authProvider.currentUser!.uid,
      createdByName: authProvider.currentUser!.displayName ?? 'Пользователь',
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

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

      // Завершаем событие кормления
      await eventsProvider.stopFeedingEvent(
        eventId: _activeEventId!,
        endedAt: DateTime.now(),
        lastModifiedBy: authProvider.currentUser?.uid,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    // Очищаем локальное хранилище
    if (_activeEventId != null) {
      await _timerStorage.clearTimerState(eventId: _activeEventId!);
    }

    setState(() {
      _isTimerRunning = false;
      _isLeftActive = false;
      _isRightActive = false;
      _isPaused = false;
      _endTime = DateTime.now();
      _activeEventId = null;
    });
  }

  void _toggleBreast(bool isLeft) async {
    print(
        'DEBUG: Toggle breast - isLeft: $isLeft, current state - Left: $_isLeftActive ($_leftSeconds sec), Right: $_isRightActive ($_rightSeconds sec)');

    if (_activeEventId == null) {
      // Создаем активное событие, если его нет
      await _createActiveEvent();
    }

    print('DEBUG: Before setState - isTimerRunning: $_isTimerRunning');
    setState(() {
      if (isLeft) {
        if (_isLeftActive) {
          // Пауза левой груди - просто останавливаем подсчет секунд, но таймер продолжает работать
          _isLeftActive = false;
          // Не останавливаем таймер - он продолжает обновлять ended_at
        } else {
          // Запускаем левую грудь
          _isLeftActive = true;
          _isRightActive = false; // Останавливаем правую, если была активна
          _isPaused = false;

          if (!_isTimerRunning) {
            _isTimerRunning = true;
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              setState(() {
                if (_isLeftActive) {
                  _leftSeconds++;
                } else if (_isRightActive) {
                  _rightSeconds++;
                }
              });

              // Сохраняем состояние каждые 5 секунд
              if ((_leftSeconds + _rightSeconds) % 5 == 0) {
                _timerStorage.saveFeedingTimerState(
                  eventId: _activeEventId!,
                  startTime: _startTime,
                  leftSeconds: _leftSeconds,
                  rightSeconds: _rightSeconds,
                  isLeftActive: _isLeftActive,
                  isRightActive: _isRightActive,
                );
              }
            });
          }
        }
      } else {
        if (_isRightActive) {
          // Пауза правой груди - просто останавливаем подсчет секунд, но таймер продолжает работать
          _isRightActive = false;
          // Не останавливаем таймер - он продолжает обновлять ended_at
        } else {
          // Запускаем правую грудь
          _isRightActive = true;
          _isLeftActive = false; // Останавливаем левую, если была активна
          _isPaused = false;

          if (!_isTimerRunning) {
            _isTimerRunning = true;
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              setState(() {
                if (_isLeftActive) {
                  _leftSeconds++;
                } else if (_isRightActive) {
                  _rightSeconds++;
                }
              });

              // Сохраняем состояние каждые 5 секунд
              if ((_leftSeconds + _rightSeconds) % 5 == 0) {
                _timerStorage.saveFeedingTimerState(
                  eventId: _activeEventId!,
                  startTime: _startTime,
                  leftSeconds: _leftSeconds,
                  rightSeconds: _rightSeconds,
                  isLeftActive: _isLeftActive,
                  isRightActive: _isRightActive,
                );
              }
            });
          }
        }
      }
    });
    print(
        'DEBUG: After setState - Left: $_isLeftActive ($_leftSeconds sec), Right: $_isRightActive ($_rightSeconds sec), isTimerRunning: $_isTimerRunning');

    // Обновляем детали кормления
    if (_activeEventId != null) {
      BreastSide? currentSide;
      if (_isLeftActive) {
        currentSide = BreastSide.left;
      } else if (_isRightActive) {
        currentSide = BreastSide.right;
      }

      if (currentSide != null) {
        await _updateBreastSide(currentSide);
      } else {
        // Если обе груди остановлены, всё равно обновляем детали
        // Определяем какая была последней активной
        if (_leftSeconds > _rightSeconds) {
          await _updateBreastSide(BreastSide.left);
        } else if (_rightSeconds > 0) {
          await _updateBreastSide(BreastSide.right);
        }
      }

      // Сохраняем состояние в TimerStorage сразу после переключения
      await _timerStorage.saveFeedingTimerState(
        eventId: _activeEventId!,
        startTime: _startTime,
        leftSeconds: _leftSeconds,
        rightSeconds: _rightSeconds,
        isLeftActive: _isLeftActive,
        isRightActive: _isRightActive,
      );
      print(
          'DEBUG: Saved to TimerStorage - EventId: $_activeEventId, Left: $_leftSeconds ($_isLeftActive), Right: $_rightSeconds ($_isRightActive)');
    }
  }

  Future<void> _updateBreastSide(BreastSide breastSide) async {
    if (_activeEventId == null) return;

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    // Создаем или обновляем детали кормления
    final feedingDetails = FeedingDetails(
      id: _activeEventId!, // Используем eventId как id для деталей
      eventId: _activeEventId!,
      breastSide: breastSide,
      leftDurationSeconds: _leftSeconds,
      rightDurationSeconds: _rightSeconds,
      bottleAmountMl: null,
      notes: null,
    );

    await eventsProvider.updateFeedingDetails(_activeEventId!, feedingDetails);
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
    // Определяем, доступен ли режим таймера
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
            // Переключатель режима (только если доступен режим таймера)
            if (isTimerModeAvailable) ...[
              _buildModeSelector(),
              const SizedBox(height: 32),
            ],

            // Контент в зависимости от режима
            if (!isTimerModeAvailable || _isManualMode) ...[
              _buildManualMode(),
            ] else ...[
              _buildTimerMode(),
            ],

            const SizedBox(height: 32),

            // Выбор груди (только в ручном режиме)
            if (!isTimerModeAvailable || _isManualMode) _buildBreastSelector(),

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
    // Показываем режим таймера
    return Column(
      children: [
        // Таймеры для левой и правой груди
        Row(
          children: [
            _buildBreastTimer(
                'Левая', _leftSeconds, _isLeftActive && !_isPaused),
            const SizedBox(width: 16),
            _buildBreastTimer(
                'Правая', _rightSeconds, _isRightActive && !_isPaused),
          ],
        ),

        const SizedBox(height: 32),

        // Кнопки управления
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Кнопка левой груди
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
            // Кнопка правой груди
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
