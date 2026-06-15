import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// 회원가입 폼 공통 입력 필드 (라벨 + 텍스트필드).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.initialValue,
    this.required = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onTap,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.title,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (required)
                Text(
                  ' *',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD9534F),
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onTap: onTap,
          style: TextStyle(
            color: enabled ? AppColors.title : AppColors.subtitle,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.subtitle.withValues(alpha: 0.5),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.backgroundMid,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _border(AppColors.shadow.withValues(alpha: 0.12)),
            enabledBorder: _border(AppColors.shadow.withValues(alpha: 0.12)),
            disabledBorder: _border(AppColors.shadow.withValues(alpha: 0.08)),
            focusedBorder: _border(AppColors.accent, width: 1.5),
            errorBorder: _border(const Color(0xFFD9534F)),
            focusedErrorBorder: _border(const Color(0xFFD9534F), width: 1.5),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
