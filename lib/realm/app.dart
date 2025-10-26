import 'package:realm/realm.dart'; // import realm package

part 'app.realm.dart'; // declare a part file.


@RealmModel()
class _EventItem {
  @PrimaryKey()
  late String id;

  late String babyId;
  late String comment;
  // Используем пустой список вместо null
  List<int> photo = const [];
  late String type;
  late DateTime? enteredDate;
  late String customComment;
  late bool isDaySleep;
  late bool manualDaySleep;
  late DateTime? leftStart;
  late DateTime? leftEnd;
  late DateTime? rightStart;
  late DateTime? rightEnd;
  late int leftSeconds;
  late int rightSeconds;
  late String mixType;
  late String bottleAmount;
  late String bottleAmountOunce;
  late String weight;
  late String height;
  late String headCirc;
  late String temperature;
  late String weightPounds;
  late String heightInches;
  late String headCircInches;
  late String temperatureFah;
  late String breast;
  late DateTime? singleTimerStart;
  late int? singleTimerSeconds;
  late DateTime? doubleLeftTimerStart;
  late DateTime? doubleRightTimerStart;
  late int? doubleLeftTimerSeconds;
  late int? doubleRightTimerSeconds;
}
