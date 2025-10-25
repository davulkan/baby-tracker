// lib/screens/add_bottle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';

import 'package:baby_tracker/models/event.dart';

class AddBottleScreen extends StatefulWidget {
  final Event? event; // null = новое событие, иначе редактирование

  const AddBottleScreen({super.key, this.event});

  @override
  State<AddBottleScreen> createState() => _AddBottleScreenState();
}

class _AddBottleScreenState extends State<AddBottleScreen> {
  final _volumeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedTime = DateTime.now();
  BottleType _selectedBottleType = BottleType.formula;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    
      final bottleEvent = widget.event;
      if(bottleEvent != null){
      _selectedTime = bottleEvent.startedAt;
      _selectedBottleType = bottleEvent.bottleType ?? BottleType.formula;
      _volumeController.text = bottleEvent.volumeMl.toString();
      _notesController.text = bottleEvent.notes ?? '';
      }

    
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.event != null ? 'Редактировать бутылку' : 'Добавить бутылку',
          style:
              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        actions: [
          if (widget.event != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteEvent,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Тип содержимого бутылки
                  _buildSectionTitle('Тип содержимого'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBottleTypeCard(
                          type: BottleType.formula,
                          title: 'Смесь',
                          icon: Icons.local_drink,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBottleTypeCard(
                          type: BottleType.breastMilk,
                          title: 'Грудное молоко',
                          icon: Icons.favorite,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Объем
                  _buildSectionTitle('Объем'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _volumeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Введите объем',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                        suffixText: 'мл',
                        suffixStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Время
                  _buildSectionTitle('Время'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: const Color(0xFF6366F1),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTime(_selectedTime),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDate(_selectedTime),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color
                                ?.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Заметки
                  _buildSectionTitle('Заметки (необязательно)'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Добавьте заметку...',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Кнопка сохранения
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.event != null ? 'Сохранить' : 'Добавить',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBottleTypeCard({
    required BottleType type,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedBottleType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottleType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? color
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (time != null) {
      final DatePicker = await showDatePicker(
        context: context,
        initialDate: _selectedTime,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now(),
      );

      if (DatePicker != null) {
        setState(() {
          _selectedTime = DateTime(
            DatePicker.year,
            DatePicker.month,
            DatePicker.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Января',
      'Февраля',
      'Марта',
      'Апреля',
      'Мая',
      'Июня',
      'Июля',
      'Августа',
      'Сентября',
      'Октября',
      'Ноября',
      'Декабря'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _saveEvent() async {
    if (_volumeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите объем')),
      );
      return;
    }

    final volume = double.tryParse(_volumeController.text.trim());
    if (volume == null || volume <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный объем')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final eventsProvider =
          Provider.of<EventsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final baby = babyProvider.currentBaby;
      final user = authProvider.currentUser;

      if (baby == null || user == null) {
        throw Exception('Нет данных о ребенке или пользователе');
      }

      final notes = _notesController.text.trim();

      if (widget.event != null) {
        // Редактирование существующего события
        await eventsProvider.updateBottleEvent(
          eventId: widget.event!.id,
          startedAt: _selectedTime,
          bottleType: _selectedBottleType,
          volumeMl: volume,
          notes: notes.isEmpty ? null : notes,
          lastModifiedBy: user.uid,
        );
      } else {
        // Создание нового события
        await eventsProvider.addBottleEvent(
          babyId: baby.id,
          familyId: baby.familyId,
          startedAt: _selectedTime,
          bottleType: _selectedBottleType,
          volumeMl: volume,
          notes: notes.isEmpty ? null : notes,
          createdBy: user.uid,
          createdByName: user.displayName ?? 'Пользователь',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null
                ? 'Событие обновлено'
                : 'Событие добавлено'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Удалить событие?',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Это действие нельзя отменить',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final eventsProvider =
            Provider.of<EventsProvider>(context, listen: false);
        await eventsProvider.deleteEvent(widget.event!.id, EventType.bottle);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Событие удалено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
