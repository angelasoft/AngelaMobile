import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ActivityReportTabHeader extends StatelessWidget {
  const ActivityReportTabHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.shadow.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Text(
        '활동보고',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.title,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
