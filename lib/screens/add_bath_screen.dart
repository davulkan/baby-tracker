import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/widgets/date_time_picker.dart';

class AddBathScreen extends StatefulWidget {
  final Event? event;

  const AddBathScreen({super.key, this.event});

  @override
  State<AddBathScreen> createState() => _AddBathScreenState();
}

class _AddBathScreenState extends State<AddBathScreen> {
  DateTime _dateTime = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    if (widget.event != null) {
      _dateTime = widget.event!.startedAt;
      if (widget.event!.notes != null) {
        _notesController.text = widget.event!.notes!;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final selected = await showCupertinoDateTimePicker(context, _dateTime);
    if (selected != null) {
      setState(() {
        _dateTime = selected;
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
              Icon(Icons.bathtub, color: context.appColors.primaryAccent),
              SizedBox(width: 8),
              Text(
                widget.event != null ? 'Редактировать купание' : 'Купание',
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
            Icon(Icons.bathtub, color: context.appColors.primaryAccent),
            SizedBox(width: 8),
            Text(
              widget.event != null ? 'Редактировать купание' : 'Купание',
              style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _selectDateTime(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: context.appColors.primaryAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_dateTime.day.toString().padLeft(2, '0')}.'
                        '${_dateTime.month.toString().padLeft(2, '0')}.'
                        '${_dateTime.year} в '
                        '${_dateTime.hour.toString().padLeft(2, '0')}:'
                        '${_dateTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Температура воды, продолжительность...',
              ),
              maxLines: 3,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBath,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBath() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (babyProvider.currentBaby == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не выбран ребенок')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = false;

    try {
      if (widget.event != null) {
        // Редактируем существующее событие
        final updatedEvent = widget.event!.copyWith(
          startedAt: _dateTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          lastModifiedAt: DateTime.now(),
        );
        success = await eventsProvider.updateEvent(updatedEvent);
      } else {
        // Создаем новое событие купания
        final result = await eventsProvider.addBathEvent(
          babyId: babyProvider.currentBaby!.id,
          familyId: authProvider.familyId!,
          time: _dateTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdBy: authProvider.currentUser!.uid,
          createdByName:
              authProvider.currentUser!.displayName ?? 'Пользователь',
        );
        success = result != null;
      }

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null
                ? 'Купание обновлено'
                : 'Купание добавлено'),
            backgroundColor: context.appColors.successColor,
          ),
        );
        Navigator.of(context).pop();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null
                ? 'Ошибка обновления купания'
                : 'Ошибка добавления купания'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Произошла ошибка: $e'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
