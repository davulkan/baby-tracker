import 'package:flutter/cupertino.dart';

/// Показывает купертиновский барабан для выбора даты и времени
/// Возвращает выбранное DateTime или null, если отменено
Future<DateTime?> showCupertinoDateTimePicker(
  BuildContext context,
  DateTime initialDateTime,
) async {
  DateTime tempDateTime = initialDateTime;

  final result = await showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (_) => Container(
      height: 300,
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: const Text('Отмена'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoButton(
                child: const Text('Готово'),
                onPressed: () {
                  Navigator.of(context).pop(tempDateTime);
                },
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: initialDateTime,
              minimumDate: DateTime.now().subtract(const Duration(days: 365)),
              maximumDate: DateTime.now().add(const Duration(days: 1)),
              onDateTimeChanged: (DateTime newDateTime) {
                tempDateTime = newDateTime;
              },
            ),
          ),
        ],
      ),
    ),
  );

  return result;
}
