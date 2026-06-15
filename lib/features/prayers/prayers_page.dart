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
  String? _expandedPrayerId;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: PrayersData.categories.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

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
                for (final category in PrayersData.categories)
                  Tab(text: category.title),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final category in PrayersData.categories)
                  _PrayerList(
                    category: category,
                    expandedPrayerId: _expandedPrayerId,
                    onPrayerTap: _onPrayerTap,
                  ),
              ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (category.id != 'legion')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '가톨릭 기도서·매일미사 주요 전례를 참고하였습니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subtitle.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
            ),
          ),
        for (var i = 0; i < category.prayers.length; i++)
          PrayerExpandableTile(
            prayer: category.prayers[i],
            isExpanded: expandedPrayerId == category.prayers[i].id,
            onTap: () => onPrayerTap(category.prayers[i].id),
            showOrder: category.id == 'stations' ? i + 1 : null,
          ),
      ],
    );
  }
}
