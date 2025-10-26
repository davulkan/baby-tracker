import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:baby_tracker/firebase_options.dart';
import 'package:baby_tracker/realm/app.dart';
import 'package:realm_dart/realm.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Tracker Migration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MigrationScreen(),
    );
  }
}

class MigrationScreen extends StatefulWidget {
  @override
  _MigrationScreenState createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isMigrating = false;
  bool _isInitialized = false;
  String _status = 'Инициализация...';
  List<String> _logs = [];
  int _totalProcessed = 0;
  int _totalErrors = 0;
  int _totalEvents = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _addLog('⏳ Инициализация Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _addLog('✅ Firebase инициализирован');

      setState(() {
        _isInitialized = true;
        _status = 'Готово к миграции';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка инициализации: $e';
      });
      _addLog('❌ Ошибка: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  Future<void> _startMigration() async {
    if (!_isInitialized) {
      _addLog('❌ Firebase не инициализирован');
      return;
    }

    setState(() {
      _isMigrating = true;
      _status = 'Копирование Realm файла из assets...';
      _logs.clear();
      _totalProcessed = 0;
      _totalErrors = 0;
    });

    Realm? realm;
    String? tempRealmPath;

    try {
      // 1. Копируем Realm файл из assets во временную директорию
      _addLog('📂 Загрузка Realm файла из assets...');

      final ByteData data =
          await rootBundle.load('assets/mybaby-default.realm');
      final List<int> bytes = data.buffer.asUint8List();

      _addLog('✅ Файл загружен: ${bytes.length / 1024 / 1024} MB');

      // 2. Сохраняем во временную директорию
      final tempDir = await getTemporaryDirectory();
      tempRealmPath = '${tempDir.path}/mybaby.realm';

      final tempFile = File(tempRealmPath);
      await tempFile.writeAsBytes(bytes);

      _addLog('✅ Файл сохранен: $tempRealmPath');

      setState(() {
        _status = 'Открытие базы данных...';
      });

      // 3. Открываем Realm
      final config = Configuration.local(
        [],
        path: tempRealmPath,
        isReadOnly: true,
      );

      realm = Realm(config);
      _addLog('✅ Realm открыт');

      final firestore = FirebaseFirestore.instance;
      final events = realm.dynamic.all('EventItem');
      _totalEvents = events.length;

      _addLog('📝 Найдено событий: $_totalEvents');

      if (events.isEmpty) {
        setState(() {
          _status = '⚠️ Нет событий для миграции';
          _isMigrating = false;
        });
        return;
      }

      setState(() {
        _status = 'Миграция $_totalEvents событий...';
      });

      _addLog('🔄 Начинаем миграцию...\n');

      int batchSize = 100;

      for (int i = 0; i < events.length; i += batchSize) {
        final batch = firestore.batch();
        final endIndex =
            (i + batchSize < events.length) ? i + batchSize : events.length;

        _addLog(
            '📦 Обрабатываем батч ${(i ~/ batchSize) + 1} (события ${i + 1}-${endIndex})');

        for (int j = i; j < endIndex; j++) {
          final realmEvent = events[j];
          try {
            final eventId = parseString(realmEvent, 'id', Uuid.v4().toString());
            final realmType = parseString(realmEvent, 'type');
            final enteredDate =
                parseNullableDateTime(realmEvent, 'enteredDate') ??
                    DateTime.now();

            if (eventId.isEmpty) continue;

            final eventType = mapRealmTypeToFirestoreEventType(realmType);
            final eventData = await createMainEvent(
                realmEvent, eventId, eventType, enteredDate);

            final eventRef = firestore.collection('events').doc(eventId);
            batch.set(eventRef, eventData);
            print(eventData);

            switch (eventType) {
              case 'sleep':
                final sleepDetails = createSleepDetails(realmEvent, eventId);
                if (sleepDetails.isNotEmpty) {
                  final sleepRef =
                      firestore.collection('sleep_details').doc(eventId);
                  batch.set(sleepRef, sleepDetails);
                }
                break;

              case 'feeding':
                final feedingDetails =
                    createFeedingDetails(realmEvent, eventId);
                if (feedingDetails.isNotEmpty) {
                  final feedingRef =
                      firestore.collection('feeding_details').doc(eventId);
                  batch.set(feedingRef, feedingDetails);
                }
                break;

              case 'diaper':
                final diaperDetails = createDiaperDetails(realmEvent, eventId);
                if (diaperDetails.isNotEmpty) {
                  final diaperRef =
                      firestore.collection('diaper_details').doc(eventId);
                  batch.set(diaperRef, diaperDetails);
                }
                break;
            }
          } catch (e) {
            _totalErrors++;
          }
        }

        try {
          await batch.commit();
          _totalProcessed += (endIndex - i);
          _addLog(
              '  ✅ Батч ${(i ~/ batchSize) + 1}: загружено ${endIndex - i} событий');

          setState(() {
            _status = 'Обработано: $_totalProcessed из $_totalEvents';
          });
        } catch (e) {
          _totalErrors += (endIndex - i);
          _addLog('  ❌ Ошибка в батче ${(i ~/ batchSize) + 1}: $e');
        }
      }

      _addLog('\n🎉 Миграция завершена!');
      _addLog('✅ События: $_totalProcessed успешно');
      if (_totalErrors > 0) {
        _addLog('❌ Ошибки: $_totalErrors');
      }

      setState(() {
        _isMigrating = false;
        _status = '✅ Миграция завершена! $_totalProcessed событий загружено';
      });
    } catch (e, stackTrace) {
      _addLog('❌ Критическая ошибка: $e');
      _addLog('Стек: $stackTrace');
      setState(() {
        _isMigrating = false;
        _status = '❌ Ошибка миграции: $e';
      });
    } finally {
      realm?.close();

      // Удаляем временный файл
      if (tempRealmPath != null) {
        try {
          await File(tempRealmPath).delete();
          _addLog('🧹 Временный файл удален');
        } catch (e) {
          _addLog('⚠️ Не удалось удалить временный файл');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baby Tracker Migration'),
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Статус
            Card(
              color: _isMigrating
                  ? Colors.blue.shade50
                  : (_totalProcessed > 0
                      ? Colors.green.shade50
                      : Colors.grey.shade50),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isMigrating)
                          Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_totalEvents > 0) ...[
                      SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _totalEvents > 0
                            ? _totalProcessed / _totalEvents
                            : 0,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Обработано: $_totalProcessed из $_totalEvents (${(_totalProcessed / _totalEvents * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 14),
                      ),
                      if (_totalErrors > 0)
                        Text(
                          'Ошибок: $_totalErrors',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Кнопка миграции
            ElevatedButton.icon(
              onPressed:
                  (_isInitialized && !_isMigrating) ? _startMigration : null,
              icon: Icon(
                  _isMigrating ? Icons.hourglass_empty : Icons.cloud_upload),
              label: Text(
                _isMigrating ? 'Миграция...' : 'Начать миграцию',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey,
              ),
            ),

            SizedBox(height: 16),

            // Логи
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Лог миграции:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_logs.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _logs.clear();
                                });
                              },
                              icon: Icon(Icons.clear, size: 16),
                              label: Text('Очистить'),
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? Center(
                              child: Text(
                                'Логи появятся здесь',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(12),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    _logs[index],
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Константы
const String DEFAULT_BABY_ID = 'yIXfZqAxnhYUM7aU7cWY';
const String DEFAULT_FAMILY_ID = 'khBYoNHgnfxii3V8BqNn';
const String DEFAULT_USER_ID = 'zPWohlRtNkRNx6stRDXbKG9zfbM2';
const String DEFAULT_USER_NAME = 'dts';

// Функции маппинга и парсинга
String mapRealmTypeToFirestoreEventType(String realmType) {
  switch (realmType.toLowerCase()) {
    case 'sleep':
      return 'sleep';
    case 'lactation':
    case 'feeding':
    case 'breast':
      return 'feeding';
    case 'bottle':
      return 'bottle';
    case 'diaper':
    case 'nappy':
      return 'diaper';
    case 'medicine':
    case 'medication':
      return 'medicine';
    default:
      return 'other';
  }
}

String mapDiaperType(String? realmType) {
  if (realmType == null || realmType.isEmpty) return 'wet';
  switch (realmType.toLowerCase()) {
    case 'wet':
    case 'pee':
      return 'wet';
    case 'dirty':
    case 'poop':
    case 'soiled':
      return 'dirty';
    case 'mixed':
    case 'both':
      return 'mixed';
    default:
      return 'wet';
  }
}

String mapSleepType(bool isDaySleep) => isDaySleep ? 'day' : 'night';

String mapBreastSide(String? breast) {
  if (breast == null || breast.isEmpty) return 'both';
  switch (breast.toLowerCase()) {
    case 'left':
    case 'l':
      return 'left';
    case 'right':
    case 'r':
      return 'right';
    case 'both':
    case 'b':
      return 'both';
    default:
      return 'both';
  }
}

DateTime? parseNullableDateTime(RealmObject obj, String field) {
  try {
    return obj.dynamic.get<DateTime?>(field);
  } catch (e) {
    return null;
  }
}

int? parseNullableInt(RealmObject obj, String field) {
  try {
    return obj.dynamic.get<int>(field);
  } catch (e) {
    return null;
  }
}

String parseString(RealmObject obj, String field, [String defaultValue = '']) {
  try {
    return obj.dynamic.get<String>(field);
  } catch (e) {
    return defaultValue;
  }
}

bool parseBool(RealmObject obj, String field, [bool defaultValue = false]) {
  try {
    return obj.dynamic.get<bool>(field) ?? defaultValue;
  } catch (e) {
    return defaultValue;
  }
}

int parseInt(RealmObject obj, String field, [int defaultValue = 0]) {
  try {
    return obj.dynamic.get<int>(field) ?? defaultValue;
  } catch (e) {
    return defaultValue;
  }
}

Future<Map<String, dynamic>> createMainEvent(RealmObject realmEvent,
    String eventId, String eventType, DateTime enteredDate) async {
  final leftStart = parseNullableDateTime(realmEvent, 'leftStart');
  final leftEnd = parseNullableDateTime(realmEvent, 'leftEnd');
  final rightStart = parseNullableDateTime(realmEvent, 'rightStart');
  final rightEnd = parseNullableDateTime(realmEvent, 'rightEnd');
  final singleTimerStart =
      parseNullableDateTime(realmEvent, 'singleTimerStart');

  DateTime startedAt = enteredDate;
  DateTime? endedAt;

  if (singleTimerStart != null) {
    startedAt = singleTimerStart;
    final singleTimerSeconds =
        parseNullableInt(realmEvent, 'singleTimerSeconds');
    if (singleTimerSeconds != null && singleTimerSeconds > 0) {
      endedAt = startedAt.add(Duration(seconds: singleTimerSeconds));
    }
  } else if (leftStart != null || rightStart != null) {
    startedAt = leftStart ?? rightStart ?? enteredDate;
    if (leftEnd != null || rightEnd != null) {
      endedAt = [leftEnd, rightEnd]
          .where((d) => d != null)
          .reduce((a, b) => a!.isAfter(b!) ? a : b);
    }
  }

  final data = <String, dynamic>{
    'family_id': DEFAULT_FAMILY_ID,
    'baby_id': DEFAULT_BABY_ID,
    'event_type': eventType,
    'started_at': Timestamp.fromDate(startedAt),
    'ended_at': endedAt != null ? Timestamp.fromDate(endedAt) : null,
    'notes': parseString(realmEvent, 'comment').isNotEmpty
        ? parseString(realmEvent, 'comment')
        : null,
    'created_at': Timestamp.fromDate(enteredDate),
    'last_modified_at': Timestamp.fromDate(DateTime.now()),
    'created_by': DEFAULT_USER_ID,
    'created_by_name': DEFAULT_USER_NAME,
    'version': 1,
    'status': endedAt != null ? 'completed' : 'active',
  };

  if (eventType == 'bottle') {
    final bottleAmount = parseString(realmEvent, 'bottleAmount');
    if (bottleAmount.isNotEmpty) {
      try {
        final volumeMl = double.parse(bottleAmount);
        data['volume_ml'] = volumeMl;
        data['bottle_type'] = 'formula';
      } catch (e) {}
    }
  }

  return data;
}

Map<String, dynamic> createSleepDetails(
    RealmObject realmEvent, String eventId) {
  final isDaySleep = parseBool(realmEvent, 'isDaySleep', false);
  final notes = parseString(realmEvent, 'comment');
  return {
    'event_id': eventId,
    'sleep_type': mapSleepType(isDaySleep),
    'notes': notes.isNotEmpty ? notes : null,
  };
}

Map<String, dynamic> createFeedingDetails(
    RealmObject realmEvent, String eventId) {
  final breast = parseString(realmEvent, 'breast');
  final leftSeconds = parseInt(realmEvent, 'leftSeconds', 0);
  final rightSeconds = parseInt(realmEvent, 'rightSeconds', 0);
  final notes = parseString(realmEvent, 'comment');

  final data = <String, dynamic>{
    'event_id': eventId,
    'notes': notes.isNotEmpty ? notes : null,
    'active_state': 'none',
  };

  if (breast.isNotEmpty) data['breast_side'] = mapBreastSide(breast);
  if (leftSeconds > 0) data['left_duration_seconds'] = leftSeconds;
  if (rightSeconds > 0) data['right_duration_seconds'] = rightSeconds;

  if (leftSeconds > 0 && rightSeconds > 0) {
    final leftStart = parseNullableDateTime(realmEvent, 'leftStart');
    final rightStart = parseNullableDateTime(realmEvent, 'rightStart');
    if (leftStart != null && rightStart != null) {
      if (leftStart.isBefore(rightStart)) {
        data['first_breast'] = 'left';
        data['second_breast'] = 'right';
      } else {
        data['first_breast'] = 'right';
        data['second_breast'] = 'left';
      }
    }
  } else if (leftSeconds > 0) {
    data['first_breast'] = 'left';
  } else if (rightSeconds > 0) {
    data['first_breast'] = 'right';
  }

  return data;
}

Map<String, dynamic> createDiaperDetails(
    RealmObject realmEvent, String eventId) {
  final mixType = parseString(realmEvent, 'customComment');
  final notes = parseString(realmEvent, 'comment');
  return {
    'event_id': eventId,
    'diaper_type': mapDiaperType(mixType),
    'notes': notes.isNotEmpty ? notes : null,
  };
}
