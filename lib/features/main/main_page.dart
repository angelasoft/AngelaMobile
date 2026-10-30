import 'package:flutter/material.dart';

import '../../core/push/push_service.dart';
import '../../core/theme/app_colors.dart';
import '../activity_report/activity_report_page.dart';
import '../notifications/notifications_page.dart';
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
  final _push = PushService.instance;

  @override
  void initState() {
    super.initState();
    _push.received.addListener(_onPushReceived);
    _push.opened.addListener(_onPushOpened);
    _push.registerDevice();
    // 알림을 눌러 앱을 처음 열었으면 첫 화면이 그려진 뒤 알림함으로 간다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPushOpened());
  }

  @override
  void dispose() {
    _push.received.removeListener(_onPushReceived);
    _push.opened.removeListener(_onPushOpened);
    super.dispose();
  }

  /// 앱을 쓰는 중에 온 알림은 화면 아래에 잠깐 보여 준다.
  void _onPushReceived() {
    final notification = _push.received.value?.notification;
    if (!mounted || notification == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          [notification.title, notification.body].whereType<String>().join('\n'),
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: '보기', onPressed: _openNotifications),
      ),
    );
  }

  void _onPushOpened() {
    if (!mounted || _push.opened.value == null) return;
    _push.opened.value = null;
    _openNotifications();
  }

  void _openNotifications() {
    setState(() => _currentIndex = 0);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
  }

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
