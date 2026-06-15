import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AgreementTile extends StatelessWidget {
  const AgreementTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.required = false,
    this.emphasize = false,
    this.onView,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final bool required;
  final bool emphasize;

  /// 약관 내용 보기. null이면 보기 버튼을 표시하지 않는다.
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!value),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      value
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 22,
                      color: value
                          ? AppColors.accent
                          : AppColors.subtitle.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: emphasize
                                  ? AppColors.title
                                  : AppColors.subtitle,
                              fontWeight:
                                  emphasize ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ),
                    if (required)
                      Text(
                        '필수',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      )
                    else if (!emphasize)
                      Text(
                        '선택',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.subtitle.withValues(alpha: 0.7),
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (onView != null)
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: AppColors.subtitle,
              ),
              child: const Text(
                '보기',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
