import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_tab_header.dart';
import 'data/prayers_data.dart';
import 'models/prayer_item.dart';
import 'widgets/prayer_expandable_tile.dart';

class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});

  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<PrayerCategory>> _categories;
  String? _expandedPrayerId;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: PrayersData.tabs.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _categories = PrayersData.load();
  }

  void _retry() => setState(() => _categories = PrayersData.load());

  void _onTabChanged() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    setState(() => _expandedPrayerId = null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPrayerTap(String id) {
    setState(() {
      _expandedPrayerId = _expandedPrayerId == id ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppTabHeader(title: '주요 기도문'),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.subtitle,
              indicatorColor: AppColors.accent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              dividerColor: AppColors.shadow.withValues(alpha: 0.08),
              tabs: [
                for (final tab in PrayersData.tabs) Tab(text: tab.title),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PrayerCategory>>(
              future: _categories,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _LoadError(onRetry: _retry);
                }
                final categories = snapshot.data;
                if (categories == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    for (final category in categories)
                      _PrayerList(
                        category: category,
                        expandedPrayerId: _expandedPrayerId,
                        onPrayerTap: _onPrayerTap,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerList extends StatelessWidget {
  const _PrayerList({
    required this.category,
    required this.expandedPrayerId,
    required this.onPrayerTap,
  });

  final PrayerCategory category;
  final String? expandedPrayerId;
  final ValueChanged<String> onPrayerTap;

  @override
  Widget build(BuildContext context) {
    final prayers = category.prayers;
    if (prayers.isEmpty) {
      return _Message(
        icon: Icons.menu_book_outlined,
        text: '${category.title}는 준비 중이에요.',
      );
    }

    // 한 편뿐인 탭(고해성사, 십자가의 길)은 펼친 채로 보여 준다.
    final single = prayers.length == 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final prayer in prayers)
          PrayerExpandableTile(
            prayer: prayer,
            isExpanded: single || expandedPrayerId == prayer.id,
            onTap: single ? null : () => onPrayerTap(prayer.id),
          ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Message(
      icon: Icons.error_outline,
      text: '기도문을 불러오지 못했어요.',
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('다시 시도'),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.accent.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtitle,
                    height: 1.5,
                  ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
