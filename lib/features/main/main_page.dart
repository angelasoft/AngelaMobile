import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../activity_report/activity_report_page.dart';
import '../prayers/prayers_page.dart';
import '../presidium/presidium_page.dart';
import '../weekly_meeting/weekly_meeting_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  static const _tabs = [
    _MainTab(
      label: '쁘레시디움',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
    ),
    _MainTab(
      label: '활동보고',
      icon: Icons.edit_note_outlined,
      activeIcon: Icons.edit_note,
    ),
    _MainTab(
      label: '주 회합',
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
    ),
    _MainTab(
      label: '주요 기도문',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
    ),
  ];

  final _pages = const [
    PresidiumPage(),
    ActivityReportPage(),
    WeeklyMeetingPage(),
    PrayersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accentLight.withValues(alpha: 0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon, color: AppColors.subtitle),
              selectedIcon: Icon(tab.activeIcon, color: AppColors.accent),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _MainTab {
  const _MainTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
