import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/presidium_info.dart';

class PresidiumHeader extends StatelessWidget {
  const PresidiumHeader({
    super.key,
    this.presidium,
    this.onSettingsTap,
  });

  final PresidiumInfo? presidium;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 4, 12),
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
            child: presidium != null
                ? Text(
                    presidium!.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.title,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                  )
                : Text(
                    '쁘레시디움',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.title,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
          ),
          if (presidium != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${presidium!.sessionNumber}차',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.subtitle,
            tooltip: '설정',
          ),
        ],
      ),
    );
  }
}
