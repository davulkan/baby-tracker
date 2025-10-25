// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/models/event.dart';
import 'package:baby_tracker/screens/stats/widgets/pattern_view_widget.dart';
import 'package:baby_tracker/screens/stats/widgets/growth_view_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _localeInitialized = false;
  Set<EventType> _selectedEventTypes =
      {}; // Пустой по умолчанию - показывать все

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('ru', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, color: Color(0xFFFF8A80)),
            SizedBox(width: 8),
            Text(
              'Статистика',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF8A80),
          labelColor: const Color(0xFFFF8A80),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Паттерн'),
            Tab(text: 'Вес, рост и прочее'),
          ],
        ),
      ),
      body: !_localeInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                PatternViewWidget(
                  baby: Provider.of<BabyProvider>(context).currentBaby,
                  selectedTypes: _selectedEventTypes,
                  onToggle: _toggleEventType,
                ),
                const GrowthViewWidget(),
              ],
            ),
    );
  }

  void _toggleEventType(EventType type) {
    setState(() {
      if (_selectedEventTypes.contains(type)) {
        _selectedEventTypes.remove(type);
      } else {
        _selectedEventTypes.add(type);
      }
    });
  }
}
