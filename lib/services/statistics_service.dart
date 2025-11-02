// lib/services/statistics_service.dart
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/services/events_repository.dart';

/// Сервис для расчета статистики событий
class StatisticsService {
  final EventsRepository _eventsRepo;

  StatisticsService({EventsRepository? eventsRepository})
      : _eventsRepo = eventsRepository ?? EventsRepository();

  /// Получение статистики за период
  Future<Map<String, int>> getStatistics(
      String babyId, DateTime startDate, DateTime endDate) async {
    try {
      final events =
          await _eventsRepo.getEventsByPeriod(babyId, startDate, endDate);

      final stats = <String, int>{
        'sleep_count': 0,
        'sleep_minutes': 0,
        'feeding_count': 0,
        'feeding_minutes': 0,
        'diaper_count': 0,
      };

      for (final event in events) {
        switch (event.eventType) {
          case EventType.sleep:
            stats['sleep_count'] = stats['sleep_count']! + 1;
            if (event.duration != null) {
              stats['sleep_minutes'] =
                  stats['sleep_minutes']! + event.duration!.inMinutes;
            }
            break;
          case EventType.feeding:
            stats['feeding_count'] = stats['feeding_count']! + 1;
            if (event.duration != null) {
              stats['feeding_minutes'] =
                  stats['feeding_minutes']! + event.duration!.inMinutes;
            }
            break;
          case EventType.diaper:
            stats['diaper_count'] = stats['diaper_count']! + 1;
            break;
          default:
            break;
        }
      }

      return stats;
    } catch (e) {
      return {};
    }
  }
}
