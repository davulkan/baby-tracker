// lib/models/settings.dart
import 'package:baby_tracker/models/event.dart';

class UserSettings {
  final List<EventType> favoriteEventTypes;

  const UserSettings({
    this.favoriteEventTypes = const [],
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      favoriteEventTypes: (json['favoriteEventTypes'] as List<dynamic>?)
              ?.map((e) => EventType.values.firstWhere(
                    (type) => type.name == e,
                    orElse: () => EventType.other,
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteEventTypes': favoriteEventTypes.map((e) => e.name).toList(),
    };
  }

  UserSettings copyWith({
    List<EventType>? favoriteEventTypes,
  }) {
    return UserSettings(
      favoriteEventTypes: favoriteEventTypes ?? this.favoriteEventTypes,
    );
  }
}
