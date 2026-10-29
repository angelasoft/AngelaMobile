import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'volunteer_service.dart';

/// 봉사 일정 한 줄: 날짜 배지 + 시간·장소 + 내용 미리보기.
class VolunteerScheduleTile extends StatelessWidget {
  const VolunteerScheduleTile({
    super.key,
    required this.schedule,
    this.onTap,
    this.dimmed = false,
  });

  final VolunteerSchedule schedule;
  final VoidCallback? onTap;

  /// 지난 일정은 흐리게 표시한다.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    final badgeColor = dimmed ? AppColors.subtitle : AppColors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${s.date.month}월',
                    style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${s.date.day}',
                    style: TextStyle(fontSize: 20, color: badgeColor, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  Text(
                    s.isToday ? '오늘' : koreanWeekday(s.date),
                    style: TextStyle(fontSize: 11, color: badgeColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${koreanTime(s.time)} · ${s.place}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dimmed ? AppColors.subtitle : AppColors.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.subtitle, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
