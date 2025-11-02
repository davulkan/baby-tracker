import 'package:baby_tracker/constants/growth_standards.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Functions for normal growth values
double getHeightLowerBound(int days, String gender) {
  int months = days ~/ 30;
  final standards =
      gender == 'male' ? whoGrowthStandardsBoys : whoGrowthStandardsGirls;
  if (standards.containsKey(months)) {
    return standards[months]!['height_lower']!;
  }
  // Simple extrapolation for months > 12
  final lastMonthData = standards[12]!;
  return lastMonthData['height_lower']! + (months - 12) * 0.5;
}

double getHeightUpperBound(int days, String gender) {
  int months = days ~/ 30;
  final standards =
      gender == 'male' ? whoGrowthStandardsBoys : whoGrowthStandardsGirls;
  if (standards.containsKey(months)) {
    return standards[months]!['height_upper']!;
  }
  // Simple extrapolation for months > 12
  final lastMonthData = standards[12]!;
  return lastMonthData['height_upper']! + (months - 12) * 0.5;
}

double getWeightLowerBound(int days, String gender) {
  int months = days ~/ 30;
  final standards =
      gender == 'male' ? whoGrowthStandardsBoys : whoGrowthStandardsGirls;
  if (standards.containsKey(months)) {
    return standards[months]!['weight_lower']!;
  }
  // Simple extrapolation for months > 12
  final lastMonthData = standards[12]!;
  return lastMonthData['weight_lower']! + (months - 12) * 0.2;
}

double getWeightUpperBound(int days, String gender) {
  int months = days ~/ 30;
  final standards =
      gender == 'male' ? whoGrowthStandardsBoys : whoGrowthStandardsGirls;
  if (standards.containsKey(months)) {
    return standards[months]!['weight_upper']!;
  }
  // Simple extrapolation for months > 12
  final lastMonthData = standards[12]!;
  return lastMonthData['weight_upper']! + (months - 12) * 0.3;
}

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
    _tabController = TabController(length: 2, vsync: this);
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
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _WeightChart(babyId: babyProvider.currentBaby!.id),
              _HeightChart(babyId: babyProvider.currentBaby!.id),
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
    final babyProvider = Provider.of<BabyProvider>(context);

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
        final weightEvents = events
            .where((event) =>
                event.eventType == EventType.weight && event.weightKg != null)
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

        // Add birth weight if available
        if (babyProvider.currentBaby!.weightAtBirthKg != null) {
          weightEvents.insert(
              0,
              Event(
                id: 'birth_weight',
                babyId: babyId,
                familyId: babyProvider.currentBaby!.familyId,
                eventType: EventType.weight,
                startedAt: babyProvider.currentBaby!.birthDate,
                status: EventStatus.completed,
                createdAt: babyProvider.currentBaby!.birthDate,
                lastModifiedAt: babyProvider.currentBaby!.birthDate,
                createdBy: '',
                createdByName: '',
                weightKg: babyProvider.currentBaby!.weightAtBirthKg,
              ));
        }

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

        final gender = babyProvider.currentBaby!.gender;
        final birthDate = babyProvider.currentBaby!.birthDate;
        final spots = weightEvents
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weightKg!))
            .toList();

        int maxIndex = spots.isNotEmpty ? spots.length - 1 : 0;
        List<FlSpot> lowerSpots = [];
        List<FlSpot> upperSpots = [];
        for (int i = 0; i <= maxIndex; i++) {
          final event = weightEvents[i];
          int days = event.startedAt.difference(birthDate).inDays;
          lowerSpots
              .add(FlSpot(i.toDouble(), getWeightLowerBound(days, gender)));
          upperSpots
              .add(FlSpot(i.toDouble(), getWeightUpperBound(days, gender)));
        }

        // Create area spots: upper + lower reversed
        List<FlSpot> areaSpots = [...upperSpots];
        for (int i = lowerSpots.length - 1; i >= 0; i--) {
          areaSpots.add(lowerSpots[i]);
        }

        double minYVal = [
          ...spots.map((s) => s.y),
          ...lowerSpots.map((s) => s.y),
          ...upperSpots.map((s) => s.y),
        ].reduce((a, b) => a < b ? a : b);
        double maxYVal = [
          ...spots.map((s) => s.y),
          ...lowerSpots.map((s) => s.y),
          ...upperSpots.map((s) => s.y),
        ].reduce((a, b) => a > b ? a : b);

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
                        spots: areaSpots,
                        isCurved: false,
                        color: Colors.transparent,
                        barWidth: 0,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.2),
                        ),
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: lowerSpots,
                        isCurved: true,
                        color: Colors.grey,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: upperSpots,
                        isCurved: true,
                        color: Colors.grey,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            int i = spot.x.toInt();
                            if (i >= 0 && i < weightEvents.length) {
                              final event = weightEvents[i];
                              int days =
                                  event.startedAt.difference(birthDate).inDays;
                              double lower = getWeightLowerBound(days, gender);
                              double upper = getWeightUpperBound(days, gender);
                              bool isNormal =
                                  spot.y >= lower && spot.y <= upper;
                              return FlDotCirclePainter(
                                color: isNormal ? Colors.blue : Colors.red,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            }
                            return FlDotCirclePainter(color: Colors.blue);
                          },
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: maxIndex.toDouble(),
                    minY: minYVal - 0.5,
                    maxY: maxYVal + 0.5,
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
    final babyProvider = Provider.of<BabyProvider>(context);

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

        // Add birth height if available
        if (babyProvider.currentBaby!.heightAtBirthCm != null) {
          heightEvents.insert(
              0,
              Event(
                id: 'birth_height',
                babyId: babyId,
                familyId: babyProvider.currentBaby!.familyId,
                eventType: EventType.height,
                startedAt: babyProvider.currentBaby!.birthDate,
                status: EventStatus.completed,
                createdAt: babyProvider.currentBaby!.birthDate,
                lastModifiedAt: babyProvider.currentBaby!.birthDate,
                createdBy: '',
                createdByName: '',
                heightCm: babyProvider.currentBaby!.heightAtBirthCm,
              ));
        }

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

        final gender = babyProvider.currentBaby!.gender;
        final birthDate = babyProvider.currentBaby!.birthDate;
        final spots = heightEvents
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value.heightCm!))
            .toList();

        int maxIndex = spots.isNotEmpty ? spots.length - 1 : 0;
        List<FlSpot> lowerSpots = [];
        List<FlSpot> upperSpots = [];
        for (int i = 0; i <= maxIndex; i++) {
          final event = heightEvents[i];
          int days = event.startedAt.difference(birthDate).inDays;
          lowerSpots
              .add(FlSpot(i.toDouble(), getHeightLowerBound(days, gender)));
          upperSpots
              .add(FlSpot(i.toDouble(), getHeightUpperBound(days, gender)));
        }

        // Create area spots: upper + lower reversed
        List<FlSpot> areaSpots = [...upperSpots];
        for (int i = lowerSpots.length - 1; i >= 0; i--) {
          areaSpots.add(lowerSpots[i]);
        }

        double minYVal = [
          ...spots.map((s) => s.y),
          ...lowerSpots.map((s) => s.y),
          ...upperSpots.map((s) => s.y),
        ].reduce((a, b) => a < b ? a : b);
        double maxYVal = [
          ...spots.map((s) => s.y),
          ...lowerSpots.map((s) => s.y),
          ...upperSpots.map((s) => s.y),
        ].reduce((a, b) => a > b ? a : b);

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
                        spots: areaSpots,
                        isCurved: false,
                        color: Colors.transparent,
                        barWidth: 0,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.2),
                        ),
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: lowerSpots,
                        isCurved: true,
                        color: Colors.grey,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: upperSpots,
                        isCurved: true,
                        color: Colors.grey,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            int i = spot.x.toInt();
                            if (i >= 0 && i < heightEvents.length) {
                              final event = heightEvents[i];
                              int days =
                                  event.startedAt.difference(birthDate).inDays;
                              double lower = getHeightLowerBound(days, gender);
                              double upper = getHeightUpperBound(days, gender);
                              bool isNormal =
                                  spot.y >= lower && spot.y <= upper;
                              return FlDotCirclePainter(
                                color: isNormal ? Colors.green : Colors.red,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            }
                            return FlDotCirclePainter(color: Colors.green);
                          },
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: maxIndex.toDouble(),
                    minY: minYVal - 2,
                    maxY: maxYVal + 2,
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

