import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 소년소녀 쁘레시디움 표시. 어른 쁘레시디움에는 따로 표시하지 않는다.
class PresidiumTypeBadge extends StatelessWidget {
  const PresidiumTypeBadge({super.key, this.label = '소년소녀'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.title,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
