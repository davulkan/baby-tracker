import 'package:flutter/material.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/screens/home/widgets/home_top_bar.dart';
import 'package:baby_tracker/screens/home/widgets/home_quick_actions.dart';
import 'package:baby_tracker/screens/home/widgets/home_events_sliver_list.dart';
import 'package:baby_tracker/screens/home/widgets/home_add_event_dialog.dart';
import 'package:baby_tracker/widgets/connectivity_banner.dart';

class HomeScreenFull extends StatelessWidget {
  const HomeScreenFull({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    toolbarHeight: 84,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 5,
                    flexibleSpace: const HomeTopBar(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),
                  const SliverToBoxAdapter(
                    child: HomeQuickActions(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),
                  const HomeEventsSliverList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HomeAddEventDialog.show(context);
        },
        backgroundColor: context.appColors.secondaryAccent,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
