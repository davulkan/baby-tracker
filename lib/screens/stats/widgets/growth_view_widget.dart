import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/models/event.dart';

class GrowthViewWidget extends StatefulWidget {
  const GrowthViewWidget({super.key});

  @override
  State<GrowthViewWidget> createState() => _GrowthViewWidgetState();
}

class _GrowthViewWidgetState extends State<GrowthViewWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context);

    if (babyProvider.currentBaby == null) {
      return const Center(
        child: Text('Ребенок не выбран'),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Вес'),
            Tab(text: 'Рост'),
            Tab(text: 'Окружность головы'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _WeightChart(babyId: babyProvider.currentBaby!.id),
              _HeightChart(babyId: babyProvider.currentBaby!.id),
              _HeadCircumferenceChart(babyId: babyProvider.currentBaby!.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightChart extends StatelessWidget {
  final String babyId;

  const _WeightChart({required this.babyId});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);

    return StreamBuilder<List<Event>>(
      stream: eventsProvider.getEventsStream(babyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        print(events);
        final weightEvents = events
            .where((event) =>
                event.eventType == EventType.weight && event.weightKg != null)
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

        if (weightEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timeline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет данных о весе',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте измерения веса в разделе событий',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final spots = weightEvents
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weightKg!))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'График веса (кг)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toStringAsFixed(1)} кг');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < weightEvents.length) {
                              final date = weightEvents[index].startedAt;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${date.day}/${date.month}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    minX: 0,
                    maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 1,
                    minY: spots.isNotEmpty
                        ? spots
                                .map((s) => s.y)
                                .reduce((a, b) => a < b ? a : b) -
                            0.5
                        : 0,
                    maxY: spots.isNotEmpty
                        ? spots
                                .map((s) => s.y)
                                .reduce((a, b) => a > b ? a : b) +
                            0.5
                        : 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeightChart extends StatelessWidget {
  final String babyId;

  const _HeightChart({required this.babyId});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);

    return StreamBuilder<List<Event>>(
      stream: eventsProvider.getEventsStream(babyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];
        final heightEvents = events
            .where((event) =>
                event.eventType == EventType.height && event.heightCm != null)
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

        if (heightEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.height,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет данных о росте',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте измерения роста в разделе событий',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final spots = heightEvents
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.heightCm!))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'График роста (см)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toStringAsFixed(0)} см');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < heightEvents.length) {
                              final date = heightEvents[index].startedAt;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${date.day}/${date.month}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    minX: 0,
                    maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 1,
                    minY: spots.isNotEmpty
                        ? spots
                                .map((s) => s.y)
                                .reduce((a, b) => a < b ? a : b) -
                            2
                        : 0,
                    maxY: spots.isNotEmpty
                        ? spots
                                .map((s) => s.y)
                                .reduce((a, b) => a > b ? a : b) +
                            2
                        : 100,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeadCircumferenceChart extends StatelessWidget {
  final String babyId;

  const _HeadCircumferenceChart({required this.babyId});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);

    return StreamBuilder<List<Event>>(
      stream: eventsProvider.getEventsStream(babyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];
        final headCircumferenceEvents = events
            .where((event) =>
                event.eventType == EventType.headCircumference &&
                event.headCircumferenceCm != null)
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

        if (headCircumferenceEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет данных об окружности головы',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте измерения окружности головы в разделе событий',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final spots = headCircumferenceEvents
            .asMap()
            .entries
            .map((entry) =>
                FlSpot(entry.key.toDouble(), entry.value.headCircumferenceCm!))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'График окружности головы (см)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toStringAsFixed(1)} см');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 &&
                                index < headCircumferenceEvents.length) {
                              final date =
                                  headCircumferenceEvents[index].startedAt;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${date.day}/${date.month}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    minX: 0,
                    maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 1,
                    minY: spots.isNotEmpty
                        ? spots
                                .map((s) => s.y)
                                .reduce((a, b) => a < b ? a : b) -
                            0.5
                        : 0,
                    maxY: spots.isNotEmpty
                        ? spots
                                .map((s) => s.y)
                                .reduce((a, b) => a > b ? a : b) +
                            0.5
                        : 50,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
