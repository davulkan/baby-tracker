import 'package:flutter/material.dart';
import 'package:baby_tracker/providers/theme_provider.dart';

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
        color: context.appColors.surfaceColor,
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
                            style: TextStyle(
                              color: context.appColors.textSecondaryColor,
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
                              constraints.maxHeight, context);
                        }).toList();
                      })(),

                      // Белые точки посередине на каждом часу
                      ...List.generate(24, (hour) {
                        final left = (hour / 24) * constraints.maxWidth +
                            (constraints.maxWidth / 24) / 2 -
                            2;
                        return Positioned(
                          left: left,
                          top: constraints.maxHeight / 2 - 2,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.appColors.textSecondaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
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

  Widget _buildEventBar(Map<String, dynamic> event, double totalWidth,
      double totalHeight, BuildContext context) {
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
          border: hasEndTime
              ? null
              : Border.all(
                  color: context.appColors.textSecondaryColor.withOpacity(0.3),
                  width: 1),
        ),
      ),
    );
  }
}
