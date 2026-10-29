import 'package:flutter/material.dart';

import '../../../core/text_scale/text_scale_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../models/presidium_info.dart';

/// 쁘레시디움 탭 상단: 이름, 글자 크기, 알림, 설정.
class PresidiumHeader extends StatelessWidget {
  const PresidiumHeader({
    super.key,
    this.presidium,
    this.onSettingsTap,
    this.onNotificationsTap,
    this.unreadCount = 0,
  });

  final PresidiumInfo? presidium;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationsTap;
  final int unreadCount;

  static const _iconConstraints = BoxConstraints(minWidth: 40, minHeight: 40);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.shadow.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  presidium?.name ?? '쁘레시디움',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const TextScaleButtons(),
          IconButton(
            onPressed: onNotificationsTap,
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            color: AppColors.subtitle,
            constraints: _iconConstraints,
            padding: EdgeInsets.zero,
            tooltip: '알림',
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.subtitle,
            constraints: _iconConstraints,
            padding: EdgeInsets.zero,
            tooltip: '설정',
          ),
        ],
      ),
    );
  }
}
