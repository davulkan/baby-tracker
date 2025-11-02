# Добавление новых типов событий в Baby Tracker

Этот документ описывает пошаговый процесс добавления новых типов событий в приложение Baby Tracker.

## Обзор архитектуры

Приложение использует следующие компоненты для работы с событиями:
- **Event** - основная модель события
- **Детальные модели** - дополнительные данные для специфических типов (feeding_details, weight_details и т.д.)
- **EventsProvider** - провайдер для работы с событиями
- **UI компоненты** - отображение и взаимодействие

## Шаг 1: Добавление типа события в модель Event

### 1.1 Обновление enum EventType
Файл: `lib/models/event.dart`

```dart
enum EventType {
  feeding,
  sleep,
  diaper,
  bottle,
  medicine,
  weight,
  height,
  headCircumference,
  // ДОБАВИТЬ НОВЫЙ ТИП ЗДЕСЬ
  newEventType,
  other,
}
```

### 1.1.1 Обновление функции парсинга типов событий
После добавления нового типа в enum, необходимо обновить функцию `_parseEventType` в том же файле, чтобы она могла правильно распознавать новый тип при чтении из Firestore:

```dart
static EventType _parseEventType(String? type) {
  switch (type) {
    case 'feeding':
      return EventType.feeding;
    case 'sleep':
      return EventType.sleep;
    case 'diaper':
      return EventType.diaper;
    case 'bottle':
      return EventType.bottle;
    case 'medicine':
      return EventType.medicine;
    case 'weight':
      return EventType.weight;
    case 'height':
      return EventType.height;
    case 'headCircumference':
      return EventType.headCircumference;
    // ДОБАВИТЬ CASE ДЛЯ НОВОГО ТИПА ЗДЕСЬ
    case 'newEventType':
      return EventType.newEventType;
    default:
      return EventType.other;
  }
}
```

### 1.2 Добавление полей в класс Event (если нужны)
Если новый тип требует хранения дополнительных данных в основной коллекции events:

```dart
class Event {
  // Существующие поля...

  // ДОБАВИТЬ НОВЫЕ ПОЛЯ ЗДЕСЬ
  final double? newField;

  Event({
    // Существующие параметры...
    this.newField,
  });

  // ОБНОВИТЬ fromFirestore
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      // Существующие поля...
      newField: data['new_field'] != null
          ? (data['new_field'] as num).toDouble()
          : null,
    );
  }

  // ОБНОВИТЬ toFirestore
  Map<String, dynamic> toFirestore() {
    return {
      // Существующие поля...
      'status': status.name,  // Убедитесь, что статус сохраняется
      if (newField != null) 'new_field': newField,
    };
  }

  // ОБНОВИТЬ copyWith
  Event copyWith({
    // Существующие параметры...
    double? newField,
  }) {
    return Event(
      // Существующие поля...
      newField: newField ?? this.newField,
    );
  }
}
```

## Шаг 2: Создание детальной модели (если нужны дополнительные данные)

Если тип события требует хранения дополнительных данных в отдельной коллекции:

### 2.1 Создание модели деталей
Файл: `lib/models/new_event_details.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NewEventDetails {
  final String id;
  final String eventId;
  final double value; // Пример поля
  final String? notes;

  NewEventDetails({
    required this.id,
    required this.eventId,
    required this.value,
    this.notes,
  });

  factory NewEventDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewEventDetails(
      id: doc.id,
      eventId: data['event_id'],
      value: (data['value'] as num).toDouble(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'value': value,
      'notes': notes,
    };
  }
}
```

### 2.2 Добавление методов в EventsProvider
Файл: `lib/providers/events_provider.dart`

```dart
// ДОБАВИТЬ ИМПОРТ
import 'package:baby_tracker/models/new_event_details.dart';

// ДОБАВИТЬ МЕТОД ПОЛУЧЕНИЯ ДЕТАЛЕЙ
Future<NewEventDetails?> getNewEventDetails(String eventId) async {
  try {
    final doc = await _firestore.collection('new_event_details').doc(eventId).get();
    if (doc.exists) {
      return NewEventDetails.fromFirestore(doc);
    }
    return null;
  } catch (e) {
    debugPrint('Error getting new event details: $e');
    return null;
  }
}

// ДОБАВИТЬ МЕТОД ДОБАВЛЕНИЯ СОБЫТИЯ
Future<String?> addNewEvent({
  required String babyId,
  required String familyId,
  required DateTime time,
  required double value,
  required String createdBy,
  required String createdByName,
  String? notes,
}) async {
  try {
    _isLoading = true;
    notifyListeners();

    // Создаем основное событие
    final event = Event(
      id: '',
      babyId: babyId,
      familyId: familyId,
      eventType: EventType.newEventType,
      startedAt: time,
      notes: notes,
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      createdBy: createdBy,
      createdByName: createdByName,
      status: EventStatus.completed,
    );

    final eventDoc = await _firestore.collection('events').add(event.toFirestore());

    // Создаем детали
    final details = NewEventDetails(
      id: '',
      eventId: eventDoc.id,
      value: value,
      notes: notes,
    );

    await _firestore.collection('new_event_details').doc(eventDoc.id).set(details.toFirestore());

    _isLoading = false;
    notifyListeners();
    return eventDoc.id;
  } catch (e) {
    _error = 'Ошибка добавления нового события';
    _isLoading = false;
    notifyListeners();
    debugPrint('Error adding new event: $e');
    return null;
  }
}
```

## Шаг 3: Обновление отображения событий

### 3.1 Добавление case в EventItem
Файл: `lib/screens/home/widgets/event_item.dart`

```dart
// ДОБАВИТЬ ИМПОРТ ДЕТАЛЕЙ
import 'package:baby_tracker/models/new_event_details.dart';

// ДОБАВИТЬ CASE В BUILD
case EventType.newEventType:
  return _buildNewEventItem(context);

// ДОБАВИТЬ МЕТОД ОТОБРАЖЕНИЯ
Widget _buildNewEventItem(BuildContext context) {
  return Consumer<EventsProvider>(
    builder: (context, eventsProvider, child) {
      return FutureBuilder<NewEventDetails?>(
        future: eventsProvider.getNewEventDetails(event.id),
        builder: (context, snapshot) {
          String? valueInfo;

          if (snapshot.hasData && snapshot.data != null) {
            final details = snapshot.data!;
            valueInfo = '${details.value} ед.'; // Форматирование значения
          }

          return _buildEventItem(
            context,
            icon: Icons.new_icon, // Выбрать подходящую иконку
            title: 'Новое событие',
            subtitle: _formatTime(event.startedAt),
            color: context.appColors.primaryAccent, // Выбрать цвет
            additionalInfo: valueInfo,
          );
        },
      );
    },
  );
}
```

### 3.2 Обновление конфигураций для простых типов (опционально)
Если новый тип не требует дополнительных данных, добавить в `_eventTypeConfigs`:

```dart
final Map<EventType, EventTypeConfig> _eventTypeConfigs = {
  // Существующие...
  EventType.newEventType: EventTypeConfig(
    icon: Icons.new_icon,
    title: 'Новое событие',
    colorGetter: (context) => context.appColors.primaryAccent,
    additionalInfoGetter: (event) => null,
  ),
};
```

## Шаг 4: Обновление настроек избранных событий

Файл: `lib/screens/settings/favorite_events_settings_screen.dart`

```dart
final Map<EventType, Map<String, dynamic>> _eventConfigs = {
  // Существующие конфигурации...
  EventType.newEventType: {
    'icon': Icons.new_icon,
    'label': 'Новое событие',
    'color': const Color(0xFF123456), // Выбрать цвет
  },
};
```

## Шаг 5: Обновление быстрых действий

Файл: `lib/screens/home/widgets/home_quick_actions.dart`

```dart
// ДОБАВИТЬ ИМПОРТ ЭКРАНА
import 'package:baby_tracker/screens/add_new_event_screen.dart';

// ДОБАВИТЬ В _getQuickActionConfigs
EventType.newEventType: {
  'icon': Icons.new_icon,
  'label': 'Новое событие',
  'color': context.appColors.primaryAccent,
  'onTap': () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddNewEventScreen()),
    );
  },
},
```

## Шаг 6: Обновление диалога добавления событий

Файл: `lib/screens/home/widgets/home_add_event_dialog.dart`

```dart
// ДОБАВИТЬ ИМПОРТ ЭКРАНА
import 'package:baby_tracker/screens/add_new_event_screen.dart';

// ДОБАВИТЬ КНОПКУ В СПИСОК
_buildAddEventButton(
  context,
  icon: Icons.new_icon,
  label: 'Новое событие',
  color: const Color(0xFF123456),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddNewEventScreen()),
    );
  },
),
```

## Шаг 7: Создание экрана добавления/редактирования

Создать новый файл: `lib/screens/add_new_event_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/models/event.dart';

class AddNewEventScreen extends StatefulWidget {
  final Event? event;

  const AddNewEventScreen({super.key, this.event});

  @override
  State<AddNewEventScreen> createState() => _AddNewEventScreenState();
}

class _AddNewEventScreenState extends State<AddNewEventScreen> {
  // Реализовать логику экрана аналогично add_weight_screen.dart
  // - Поля для ввода данных
  // - Загрузка существующих данных при редактировании
  // - Сохранение через EventsProvider
}
```

## Шаг 8: Обновление навигации в списке событий

Файл: `lib/screens/home/widgets/home_events_sliver_list.dart`

```dart
// ДОБАВИТЬ ИМПОРТ ЭКРАНА
import 'package:baby_tracker/screens/add_new_event_screen.dart';

// ДОБАВИТЬ CASE В onTap
case EventType.newEventType:
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddNewEventScreen(event: event),
    ),
  );
  break;
```

## Шаг 9: Тестирование

1. Проверить компиляцию: `flutter build apk --debug`
2. Проверить анализ кода: `flutter analyze`
3. Тестировать функциональность:
   - Добавление нового события
   - Отображение в списке
   - Редактирование существующего события
   - Настройки избранных событий
   - Быстрые действия

## Примеры реализации

### Для простого типа без дополнительных данных:
- Пропустить шаги 2, 3.1 (метод с FutureBuilder)
- Использовать конфигурацию в `_eventTypeConfigs`

### Для типа с дополнительными данными:
- Выполнить все шаги
- Создать детальную модель и методы в провайдере
- Использовать FutureBuilder в EventItem

### Для типа с таймером:
- Дополнительно реализовать логику старта/остановки в EventsProvider
- Добавить обработку активных состояний в UI

## Полезные советы

1. **Иконки**: Использовать Material Design иконки из `Icons.`
2. **Цвета**: Следовать существующей цветовой схеме приложения
3. **Валидация**: Добавлять проверку данных перед сохранением
4. **Обработка ошибок**: Реализовывать корректную обработку ошибок
5. **Локализация**: Добавлять ключи для переводов если необходимо
6. **Тестирование**: Проверять все сценарии использования

## Чек-лист перед коммитом

- [ ] Тип добавлен в EventType enum
- [ ] Функция _parseEventType обновлена для нового типа
- [ ] Модель Event обновлена (если нужны поля)
- [ ] Детальная модель создана (если нужна)
- [ ] EventsProvider обновлен
- [ ] EventItem обновлен
- [ ] Настройки избранных событий обновлены
- [ ] Быстрые действия обновлены
- [ ] Диалог добавления обновлен
- [ ] Экран добавления/редактирования создан
- [ ] Навигация в списке обновлена
- [ ] Код компилируется без ошибок
- [ ] Функциональность протестирована</content>
<parameter name="filePath">/home/dts/development/baby_tracker/ADD_NEW_EVENT_TYPE.md