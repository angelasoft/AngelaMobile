import 'package:flutter/material.dart';

import '../../core/ads/ads_config.dart';
import '../../core/ads/native_ad_slot.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_tab_header.dart';
import 'rosary_data.dart';
import 'rosary_prayer_page.dart';

/// 묵주기도 탭: 신비를 고르면 한 알씩 따라가며 바치는 화면으로 간다. 오늘 바치는 신비에 "오늘" 표시.
class RosaryPage extends StatelessWidget {
  const RosaryPage({super.key});

  Future<void> _start(BuildContext context, RosaryMystery mystery) async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RosaryPrayerPage(mystery: mystery)),
    );
    if (finished == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${mystery.title} 묵주기도를 마쳤습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = RosaryMystery.forDay(DateTime.now());
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.backgroundMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppTabHeader(title: '묵주기도'),
          // 광고는 위에 고정하고 그 아래만 스크롤한다.
          const NativeAdSlot(
            placement: AdPlacement.rosary,
            tabIndex: 2,
            margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Text(
                  '오늘 바칠 묵주기도',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                for (final mystery in RosaryMystery.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MysteryCard(
                      mystery: mystery,
                      isToday: mystery == today,
                      onTap: () => _start(context, mystery),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MysteryCard extends StatelessWidget {
  const _MysteryCard({required this.mystery, required this.isToday, required this.onTap});

  final RosaryMystery mystery;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isToday ? mystery.color.withValues(alpha: 0.08) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: mystery.color, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(mystery.icon, color: mystery.color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mystery.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: mystery.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(mystery.days, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.subtitle)),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: mystery.color, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    '★ 오늘',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: mystery.color),
            ],
          ),
        ),
      ),
    );
  }
}
