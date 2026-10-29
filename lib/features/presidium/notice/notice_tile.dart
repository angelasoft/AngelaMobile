import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'notice_service.dart';

/// 공지 한 줄: 제목 + 날짜 (+ 내용 첫 줄).
class NoticeTile extends StatelessWidget {
  const NoticeTile({super.key, required this.notice, this.onTap, this.showPreview = false});

  final Notice notice;
  final VoidCallback? onTap;
  final bool showPreview;

  bool get _isNew => DateTime.now().difference(notice.createdAt).inDays < 3;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isNew) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'N',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB8860B)),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${notice.createdAt.month}.${notice.createdAt.day}',
                  style: TextStyle(color: AppColors.subtitle, fontSize: 12),
                ),
              ],
            ),
            if (showPreview) ...[
              const SizedBox(height: 4),
              Text(
                notice.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.subtitle, height: 1.4),
              ),
              const SizedBox(height: 2),
              Text(
                '${notice.createdByName} · ${koreanMonthDay(notice.createdAt)}',
                style: TextStyle(color: AppColors.subtitle.withValues(alpha: 0.8), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
