// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class EventItem extends _EventItem
    with RealmEntity, RealmObjectBase, RealmObject {
  EventItem(
    String id,
    String babyId,
    String comment,
    String type,
    String customComment,
    bool isDaySleep,
    bool manualDaySleep,
    int leftSeconds,
    int rightSeconds,
    String mixType,
    String bottleAmount,
    String bottleAmountOunce,
    String weight,
    String height,
    String headCirc,
    String temperature,
    String weightPounds,
    String heightInches,
    String headCircInches,
    String temperatureFah,
    String breast, {
    Iterable<int> photo = const [],
    DateTime? enteredDate,
    DateTime? leftStart,
    DateTime? leftEnd,
    DateTime? rightStart,
    DateTime? rightEnd,
    DateTime? singleTimerStart,
    int? singleTimerSeconds,
    DateTime? doubleLeftTimerStart,
    DateTime? doubleRightTimerStart,
    int? doubleLeftTimerSeconds,
    int? doubleRightTimerSeconds,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'babyId', babyId);
    RealmObjectBase.set(this, 'comment', comment);
    RealmObjectBase.set<RealmList<int>>(this, 'photo', RealmList<int>(photo));
    RealmObjectBase.set(this, 'type', type);
    RealmObjectBase.set(this, 'enteredDate', enteredDate);
    RealmObjectBase.set(this, 'customComment', customComment);
    RealmObjectBase.set(this, 'isDaySleep', isDaySleep);
    RealmObjectBase.set(this, 'manualDaySleep', manualDaySleep);
    RealmObjectBase.set(this, 'leftStart', leftStart);
    RealmObjectBase.set(this, 'leftEnd', leftEnd);
    RealmObjectBase.set(this, 'rightStart', rightStart);
    RealmObjectBase.set(this, 'rightEnd', rightEnd);
    RealmObjectBase.set(this, 'leftSeconds', leftSeconds);
    RealmObjectBase.set(this, 'rightSeconds', rightSeconds);
    RealmObjectBase.set(this, 'mixType', mixType);
    RealmObjectBase.set(this, 'bottleAmount', bottleAmount);
    RealmObjectBase.set(this, 'bottleAmountOunce', bottleAmountOunce);
    RealmObjectBase.set(this, 'weight', weight);
    RealmObjectBase.set(this, 'height', height);
    RealmObjectBase.set(this, 'headCirc', headCirc);
    RealmObjectBase.set(this, 'temperature', temperature);
    RealmObjectBase.set(this, 'weightPounds', weightPounds);
    RealmObjectBase.set(this, 'heightInches', heightInches);
    RealmObjectBase.set(this, 'headCircInches', headCircInches);
    RealmObjectBase.set(this, 'temperatureFah', temperatureFah);
    RealmObjectBase.set(this, 'breast', breast);
    RealmObjectBase.set(this, 'singleTimerStart', singleTimerStart);
    RealmObjectBase.set(this, 'singleTimerSeconds', singleTimerSeconds);
    RealmObjectBase.set(this, 'doubleLeftTimerStart', doubleLeftTimerStart);
    RealmObjectBase.set(this, 'doubleRightTimerStart', doubleRightTimerStart);
    RealmObjectBase.set(this, 'doubleLeftTimerSeconds', doubleLeftTimerSeconds);
    RealmObjectBase.set(
        this, 'doubleRightTimerSeconds', doubleRightTimerSeconds);
  }

  EventItem._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get babyId => RealmObjectBase.get<String>(this, 'babyId') as String;
  @override
  set babyId(String value) => RealmObjectBase.set(this, 'babyId', value);

  @override
  String get comment => RealmObjectBase.get<String>(this, 'comment') as String;
  @override
  set comment(String value) => RealmObjectBase.set(this, 'comment', value);

  @override
  RealmList<int> get photo =>
      RealmObjectBase.get<int>(this, 'photo') as RealmList<int>;
  @override
  set photo(covariant RealmList<int> value) => throw RealmUnsupportedSetError();

  @override
  String get type => RealmObjectBase.get<String>(this, 'type') as String;
  @override
  set type(String value) => RealmObjectBase.set(this, 'type', value);

  @override
  DateTime? get enteredDate =>
      RealmObjectBase.get<DateTime>(this, 'enteredDate') as DateTime?;
  @override
  set enteredDate(DateTime? value) =>
      RealmObjectBase.set(this, 'enteredDate', value);

  @override
  String get customComment =>
      RealmObjectBase.get<String>(this, 'customComment') as String;
  @override
  set customComment(String value) =>
      RealmObjectBase.set(this, 'customComment', value);

  @override
  bool get isDaySleep => RealmObjectBase.get<bool>(this, 'isDaySleep') as bool;
  @override
  set isDaySleep(bool value) => RealmObjectBase.set(this, 'isDaySleep', value);

  @override
  bool get manualDaySleep =>
      RealmObjectBase.get<bool>(this, 'manualDaySleep') as bool;
  @override
  set manualDaySleep(bool value) =>
      RealmObjectBase.set(this, 'manualDaySleep', value);

  @override
  DateTime? get leftStart =>
      RealmObjectBase.get<DateTime>(this, 'leftStart') as DateTime?;
  @override
  set leftStart(DateTime? value) =>
      RealmObjectBase.set(this, 'leftStart', value);

  @override
  DateTime? get leftEnd =>
      RealmObjectBase.get<DateTime>(this, 'leftEnd') as DateTime?;
  @override
  set leftEnd(DateTime? value) => RealmObjectBase.set(this, 'leftEnd', value);

  @override
  DateTime? get rightStart =>
      RealmObjectBase.get<DateTime>(this, 'rightStart') as DateTime?;
  @override
  set rightStart(DateTime? value) =>
      RealmObjectBase.set(this, 'rightStart', value);

  @override
  DateTime? get rightEnd =>
      RealmObjectBase.get<DateTime>(this, 'rightEnd') as DateTime?;
  @override
  set rightEnd(DateTime? value) => RealmObjectBase.set(this, 'rightEnd', value);

  @override
  int get leftSeconds => RealmObjectBase.get<int>(this, 'leftSeconds') as int;
  @override
  set leftSeconds(int value) => RealmObjectBase.set(this, 'leftSeconds', value);

  @override
  int get rightSeconds => RealmObjectBase.get<int>(this, 'rightSeconds') as int;
  @override
  set rightSeconds(int value) =>
      RealmObjectBase.set(this, 'rightSeconds', value);

  @override
  String get mixType => RealmObjectBase.get<String>(this, 'mixType') as String;
  @override
  set mixType(String value) => RealmObjectBase.set(this, 'mixType', value);

  @override
  String get bottleAmount =>
      RealmObjectBase.get<String>(this, 'bottleAmount') as String;
  @override
  set bottleAmount(String value) =>
      RealmObjectBase.set(this, 'bottleAmount', value);

  @override
  String get bottleAmountOunce =>
      RealmObjectBase.get<String>(this, 'bottleAmountOunce') as String;
  @override
  set bottleAmountOunce(String value) =>
      RealmObjectBase.set(this, 'bottleAmountOunce', value);

  @override
  String get weight => RealmObjectBase.get<String>(this, 'weight') as String;
  @override
  set weight(String value) => RealmObjectBase.set(this, 'weight', value);

  @override
  String get height => RealmObjectBase.get<String>(this, 'height') as String;
  @override
  set height(String value) => RealmObjectBase.set(this, 'height', value);

  @override
  String get headCirc =>
      RealmObjectBase.get<String>(this, 'headCirc') as String;
  @override
  set headCirc(String value) => RealmObjectBase.set(this, 'headCirc', value);

  @override
  String get temperature =>
      RealmObjectBase.get<String>(this, 'temperature') as String;
  @override
  set temperature(String value) =>
      RealmObjectBase.set(this, 'temperature', value);

  @override
  String get weightPounds =>
      RealmObjectBase.get<String>(this, 'weightPounds') as String;
  @override
  set weightPounds(String value) =>
      RealmObjectBase.set(this, 'weightPounds', value);

  @override
  String get heightInches =>
      RealmObjectBase.get<String>(this, 'heightInches') as String;
  @override
  set heightInches(String value) =>
      RealmObjectBase.set(this, 'heightInches', value);

  @override
  String get headCircInches =>
      RealmObjectBase.get<String>(this, 'headCircInches') as String;
  @override
  set headCircInches(String value) =>
      RealmObjectBase.set(this, 'headCircInches', value);

  @override
  String get temperatureFah =>
      RealmObjectBase.get<String>(this, 'temperatureFah') as String;
  @override
  set temperatureFah(String value) =>
      RealmObjectBase.set(this, 'temperatureFah', value);

  @override
  String get breast => RealmObjectBase.get<String>(this, 'breast') as String;
  @override
  set breast(String value) => RealmObjectBase.set(this, 'breast', value);

  @override
  DateTime? get singleTimerStart =>
      RealmObjectBase.get<DateTime>(this, 'singleTimerStart') as DateTime?;
  @override
  set singleTimerStart(DateTime? value) =>
      RealmObjectBase.set(this, 'singleTimerStart', value);

  @override
  int? get singleTimerSeconds =>
      RealmObjectBase.get<int>(this, 'singleTimerSeconds') as int?;
  @override
  set singleTimerSeconds(int? value) =>
      RealmObjectBase.set(this, 'singleTimerSeconds', value);

  @override
  DateTime? get doubleLeftTimerStart =>
      RealmObjectBase.get<DateTime>(this, 'doubleLeftTimerStart') as DateTime?;
  @override
  set doubleLeftTimerStart(DateTime? value) =>
      RealmObjectBase.set(this, 'doubleLeftTimerStart', value);

  @override
  DateTime? get doubleRightTimerStart =>
      RealmObjectBase.get<DateTime>(this, 'doubleRightTimerStart') as DateTime?;
  @override
  set doubleRightTimerStart(DateTime? value) =>
      RealmObjectBase.set(this, 'doubleRightTimerStart', value);

  @override
  int? get doubleLeftTimerSeconds =>
      RealmObjectBase.get<int>(this, 'doubleLeftTimerSeconds') as int?;
  @override
  set doubleLeftTimerSeconds(int? value) =>
      RealmObjectBase.set(this, 'doubleLeftTimerSeconds', value);

  @override
  int? get doubleRightTimerSeconds =>
      RealmObjectBase.get<int>(this, 'doubleRightTimerSeconds') as int?;
  @override
  set doubleRightTimerSeconds(int? value) =>
      RealmObjectBase.set(this, 'doubleRightTimerSeconds', value);

  @override
  Stream<RealmObjectChanges<EventItem>> get changes =>
      RealmObjectBase.getChanges<EventItem>(this);

  @override
  Stream<RealmObjectChanges<EventItem>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<EventItem>(this, keyPaths);

  @override
  EventItem freeze() => RealmObjectBase.freezeObject<EventItem>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'babyId': babyId.toEJson(),
      'comment': comment.toEJson(),
      'photo': photo.toEJson(),
      'type': type.toEJson(),
      'enteredDate': enteredDate.toEJson(),
      'customComment': customComment.toEJson(),
      'isDaySleep': isDaySleep.toEJson(),
      'manualDaySleep': manualDaySleep.toEJson(),
      'leftStart': leftStart.toEJson(),
      'leftEnd': leftEnd.toEJson(),
      'rightStart': rightStart.toEJson(),
      'rightEnd': rightEnd.toEJson(),
      'leftSeconds': leftSeconds.toEJson(),
      'rightSeconds': rightSeconds.toEJson(),
      'mixType': mixType.toEJson(),
      'bottleAmount': bottleAmount.toEJson(),
      'bottleAmountOunce': bottleAmountOunce.toEJson(),
      'weight': weight.toEJson(),
      'height': height.toEJson(),
      'headCirc': headCirc.toEJson(),
      'temperature': temperature.toEJson(),
      'weightPounds': weightPounds.toEJson(),
      'heightInches': heightInches.toEJson(),
      'headCircInches': headCircInches.toEJson(),
      'temperatureFah': temperatureFah.toEJson(),
      'breast': breast.toEJson(),
      'singleTimerStart': singleTimerStart.toEJson(),
      'singleTimerSeconds': singleTimerSeconds.toEJson(),
      'doubleLeftTimerStart': doubleLeftTimerStart.toEJson(),
      'doubleRightTimerStart': doubleRightTimerStart.toEJson(),
      'doubleLeftTimerSeconds': doubleLeftTimerSeconds.toEJson(),
      'doubleRightTimerSeconds': doubleRightTimerSeconds.toEJson(),
    };
  }

  static EJsonValue _toEJson(EventItem value) => value.toEJson();
  static EventItem _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'babyId': EJsonValue babyId,
        'comment': EJsonValue comment,
        'type': EJsonValue type,
        'customComment': EJsonValue customComment,
        'isDaySleep': EJsonValue isDaySleep,
        'manualDaySleep': EJsonValue manualDaySleep,
        'leftSeconds': EJsonValue leftSeconds,
        'rightSeconds': EJsonValue rightSeconds,
        'mixType': EJsonValue mixType,
        'bottleAmount': EJsonValue bottleAmount,
        'bottleAmountOunce': EJsonValue bottleAmountOunce,
        'weight': EJsonValue weight,
        'height': EJsonValue height,
        'headCirc': EJsonValue headCirc,
        'temperature': EJsonValue temperature,
        'weightPounds': EJsonValue weightPounds,
        'heightInches': EJsonValue heightInches,
        'headCircInches': EJsonValue headCircInches,
        'temperatureFah': EJsonValue temperatureFah,
        'breast': EJsonValue breast,
      } =>
        EventItem(
          fromEJson(id),
          fromEJson(babyId),
          fromEJson(comment),
          fromEJson(type),
          fromEJson(customComment),
          fromEJson(isDaySleep),
          fromEJson(manualDaySleep),
          fromEJson(leftSeconds),
          fromEJson(rightSeconds),
          fromEJson(mixType),
          fromEJson(bottleAmount),
          fromEJson(bottleAmountOunce),
          fromEJson(weight),
          fromEJson(height),
          fromEJson(headCirc),
          fromEJson(temperature),
          fromEJson(weightPounds),
          fromEJson(heightInches),
          fromEJson(headCircInches),
          fromEJson(temperatureFah),
          fromEJson(breast),
          photo: fromEJson(ejson['photo'], defaultValue: const []),
          enteredDate: fromEJson(ejson['enteredDate']),
          leftStart: fromEJson(ejson['leftStart']),
          leftEnd: fromEJson(ejson['leftEnd']),
          rightStart: fromEJson(ejson['rightStart']),
          rightEnd: fromEJson(ejson['rightEnd']),
          singleTimerStart: fromEJson(ejson['singleTimerStart']),
          singleTimerSeconds: fromEJson(ejson['singleTimerSeconds']),
          doubleLeftTimerStart: fromEJson(ejson['doubleLeftTimerStart']),
          doubleRightTimerStart: fromEJson(ejson['doubleRightTimerStart']),
          doubleLeftTimerSeconds: fromEJson(ejson['doubleLeftTimerSeconds']),
          doubleRightTimerSeconds: fromEJson(ejson['doubleRightTimerSeconds']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(EventItem._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, EventItem, 'EventItem', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('babyId', RealmPropertyType.string),
      SchemaProperty('comment', RealmPropertyType.string),
      SchemaProperty('photo', RealmPropertyType.int,
          collectionType: RealmCollectionType.list),
      SchemaProperty('type', RealmPropertyType.string),
      SchemaProperty('enteredDate', RealmPropertyType.timestamp,
          optional: true),
      SchemaProperty('customComment', RealmPropertyType.string),
      SchemaProperty('isDaySleep', RealmPropertyType.bool),
      SchemaProperty('manualDaySleep', RealmPropertyType.bool),
      SchemaProperty('leftStart', RealmPropertyType.timestamp, optional: true),
      SchemaProperty('leftEnd', RealmPropertyType.timestamp, optional: true),
      SchemaProperty('rightStart', RealmPropertyType.timestamp, optional: true),
      SchemaProperty('rightEnd', RealmPropertyType.timestamp, optional: true),
      SchemaProperty('leftSeconds', RealmPropertyType.int),
      SchemaProperty('rightSeconds', RealmPropertyType.int),
      SchemaProperty('mixType', RealmPropertyType.string),
      SchemaProperty('bottleAmount', RealmPropertyType.string),
      SchemaProperty('bottleAmountOunce', RealmPropertyType.string),
      SchemaProperty('weight', RealmPropertyType.string),
      SchemaProperty('height', RealmPropertyType.string),
      SchemaProperty('headCirc', RealmPropertyType.string),
      SchemaProperty('temperature', RealmPropertyType.string),
      SchemaProperty('weightPounds', RealmPropertyType.string),
      SchemaProperty('heightInches', RealmPropertyType.string),
      SchemaProperty('headCircInches', RealmPropertyType.string),
      SchemaProperty('temperatureFah', RealmPropertyType.string),
      SchemaProperty('breast', RealmPropertyType.string),
      SchemaProperty('singleTimerStart', RealmPropertyType.timestamp,
          optional: true),
      SchemaProperty('singleTimerSeconds', RealmPropertyType.int,
          optional: true),
      SchemaProperty('doubleLeftTimerStart', RealmPropertyType.timestamp,
          optional: true),
      SchemaProperty('doubleRightTimerStart', RealmPropertyType.timestamp,
          optional: true),
      SchemaProperty('doubleLeftTimerSeconds', RealmPropertyType.int,
          optional: true),
      SchemaProperty('doubleRightTimerSeconds', RealmPropertyType.int,
          optional: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
