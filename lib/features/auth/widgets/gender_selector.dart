import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/gender.dart';

class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.errorText,
  });

  final Gender? value;
  final ValueChanged<Gender> onChanged;
  final bool required;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              const Text(
                '성별',
                style: TextStyle(
                  color: AppColors.title,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Color(0xFFD9534F),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            for (final gender in Gender.values) ...[
              Expanded(
                child: _GenderChip(
                  gender: gender,
                  selected: gender == value,
                  onTap: () => onChanged(gender),
                ),
              ),
              if (gender != Gender.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFD9534F),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  final Gender gender;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : AppColors.shadow.withValues(alpha: 0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            gender.label,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.subtitle,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
