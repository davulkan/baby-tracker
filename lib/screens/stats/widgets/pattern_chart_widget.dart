import 'package:flutter/material.dart';

class PatternChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> chartEvents;

  const PatternChartWidget({
    super.key,
    required this.chartEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: [
            // Часовая шкала
            Row(
              children: List.generate(24, (hour) {
                return Expanded(
                  child: Center(
                    child: hour % 3 == 0
                        ? Text(
                            hour.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          )
                        : const SizedBox(),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),

            // График с событиями
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Сетка
                      Row(
                        children: List.generate(24, (hour) {
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: hour % 3 == 0
                                        ? Colors.white12
                                        : Colors.white.withOpacity(0.03),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // События (сортируем по длительности - длинные рисуются первыми)
                      ...(() {
                        final sortedEvents =
                            List<Map<String, dynamic>>.from(chartEvents);
                        sortedEvents.sort((a, b) {
                          final aDuration = (a['endMinuteOfDay'] as int) -
                              (a['startMinuteOfDay'] as int);
                          final bDuration = (b['endMinuteOfDay'] as int) -
                              (b['startMinuteOfDay'] as int);
                          return bDuration
                              .compareTo(aDuration); // От длинных к коротким
                        });
                        return sortedEvents.map((event) {
                          return _buildEventBar(event, constraints.maxWidth,
                              constraints.maxHeight);
                        }).toList();
                      })(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBar(
      Map<String, dynamic> event, double totalWidth, double totalHeight) {
    final startMinuteOfDay = event['startMinuteOfDay'] as int;
    final endMinuteOfDay = event['endMinuteOfDay'] as int;
    final color = event['color'] as Color;
    final hasEndTime = event['hasEndTime'] as bool;
    final track = event['track'] as int;
    final totalTracks = event['totalTracks'] as int;

    // Общее количество минут в сутках = 24 * 60 = 1440
    final totalMinutes = 24 * 60;

    final left = (startMinuteOfDay / totalMinutes) * totalWidth;
    final width =
        ((endMinuteOfDay - startMinuteOfDay) / totalMinutes) * totalWidth;

    // Минимальная ширина для видимости и защита от отрицательных ограничений
    final maxAvailableWidth = totalWidth - left;
    if (maxAvailableWidth <= 0) {
      return const SizedBox.shrink();
    }

    double displayWidth = width.clamp(0.0, maxAvailableWidth);
    if (displayWidth < 2.0) {
      displayWidth = maxAvailableWidth >= 2.0 ? 2.0 : maxAvailableWidth;
    }

    final trackHeight = totalHeight / totalTracks.clamp(1, 10);
    final top = track * trackHeight;

    return Positioned(
      left: left,
      top: top,
      width: displayWidth,
      height: trackHeight - 4, // Отступ между дорожками
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border:
              hasEndTime ? null : Border.all(color: Colors.white30, width: 1),
        ),
      ),
    );
  }
}