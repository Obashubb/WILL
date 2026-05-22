import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../care/care_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../insights/insights_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/will_nav_bar.dart';
import '../../controllers/home_controller.dart';

enum WillTab {
  dashboard(label: 'Dashboard', icon: CupertinoIcons.gauge),
  history(label: 'History', icon: CupertinoIcons.chart_bar),
  insights(label: 'Insights', icon: CupertinoIcons.sparkles),
  care(label: 'Care', icon: CupertinoIcons.heart),
  profile(label: 'Profile', icon: CupertinoIcons.person);

  const WillTab({required this.label, required this.icon});

  final String label;
  final IconData icon;

  Widget get screen {
    switch (this) {
      case WillTab.dashboard:
        return const DashboardScreen();
      case WillTab.history:
        return const HistoryScreen();
      case WillTab.insights:
        return const InsightsScreen();
      case WillTab.care:
        return const CareScreen();
      case WillTab.profile:
        return const ProfileScreen();
    }
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => IndexedStack(
            index: controller.tabIndex.value,
            children: WillTab.values
                .map((tab) => tab.screen)
                .toList(growable: false),
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => WillNavBar(
          currentTab: WillTab.values[controller.tabIndex.value],
          onSelect: (tab) => controller.setTab(tab.index),
        ),
      ),
    );
  }
}
