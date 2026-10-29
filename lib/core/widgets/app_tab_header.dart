import 'package:flutter/material.dart';

import '../text_scale/text_scale_buttons.dart';
import '../theme/app_colors.dart';

/// 탭 상단 제목 + 글자 크기 버튼.
class AppTabHeader extends StatelessWidget {
  const AppTabHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const TextScaleButtons(),
        ],
      ),
    );
  }
}
