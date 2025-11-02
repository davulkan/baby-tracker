// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, color: context.appColors.primaryAccent),
            SizedBox(width: 8),
            Text(
              'Статистика',
              style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.appColors.primaryAccent,
          labelColor: context.appColors.primaryAccent,
          unselectedLabelColor: context.appColors.textSecondaryColor,
          tabs: const [
            Tab(text: 'Ежедневные события'),
            Tab(text: 'Вес и рост'),
          ],
        ),
      ),
      body: !_localeInitialized
          ? Center(
              child: CircularProgressIndicator(color: context.appColors.primaryAccent),
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
