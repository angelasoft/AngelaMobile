import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/activity_report_entry.dart';

class ActivityReportRow extends StatelessWidget {
  const ActivityReportRow({
    super.key,
    required this.entry,
    required this.onFavoriteToggle,
    required this.onIncrement,
    required this.onDecrement,
  });

  final ActivityReportEntry entry;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.shadow.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onFavoriteToggle,
            icon: Icon(
              entry.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: entry.isFavorite
                  ? const Color(0xFFE8B923)
                  : AppColors.subtitle.withValues(alpha: 0.45),
            ),
            tooltip: entry.isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
          ),
          Expanded(
            child: Text(
              entry.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          _CounterButton(
            icon: Icons.remove,
            onPressed: entry.count > 0 ? onDecrement : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${entry.count}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          _CounterButton(
            icon: Icons.add,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null
          ? AppColors.backgroundMid
          : AppColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? AppColors.subtitle.withValues(alpha: 0.35)
                : AppColors.accent,
          ),
        ),
      ),
    );
  }
}
