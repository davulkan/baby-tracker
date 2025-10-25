// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:baby_tracker/screens/home/widgets/home_top_bar.dart';
import 'package:baby_tracker/screens/home/widgets/home_baby_profile.dart';
import 'package:baby_tracker/screens/home/widgets/home_quick_actions.dart';
import 'package:baby_tracker/screens/home/widgets/home_events_sliver_list.dart';
import 'package:baby_tracker/screens/home/widgets/home_add_event_dialog.dart';

class HomeScreenFull extends StatelessWidget {
  const HomeScreenFull({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeTopBar(),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            SliverToBoxAdapter(
              child: HomeBabyProfile(),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            SliverToBoxAdapter(
              child: HomeQuickActions(),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
            HomeEventsSliverList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HomeAddEventDialog.show(context);
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
