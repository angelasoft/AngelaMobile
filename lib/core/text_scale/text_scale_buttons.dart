import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'text_scale_controller.dart';

/// 탭 상단의 글자 작게(−)/크게(+) 버튼.
class TextScaleButtons extends StatelessWidget {
  const TextScaleButtons({super.key});

  static const _buttonConstraints = BoxConstraints(minWidth: 40, minHeight: 40);

  void _change(BuildContext context, VoidCallback change) {
    change();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('글자 크기 ${TextScaleController.instance.percentLabel}'),
        duration: const Duration(milliseconds: 900),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextScaleController.instance;
    return ValueListenableBuilder<double>(
      valueListenable: controller,
      builder: (context, _, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: controller.canDecrease ? () => _change(context, controller.decrease) : null,
            icon: const Icon(Icons.text_decrease),
            color: AppColors.subtitle,
            constraints: _buttonConstraints,
            padding: EdgeInsets.zero,
            tooltip: '글자 작게',
          ),
          IconButton(
            onPressed: controller.canIncrease ? () => _change(context, controller.increase) : null,
            icon: const Icon(Icons.text_increase),
            color: AppColors.subtitle,
            constraints: _buttonConstraints,
            padding: EdgeInsets.zero,
            tooltip: '글자 크게',
          ),
        ],
      ),
    );
  }
}
