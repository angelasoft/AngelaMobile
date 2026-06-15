import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 스플래시·로그인 등에서 공통으로 쓰는 그라데이션 배경.
class AngelaPageBackground extends StatelessWidget {
  const AngelaPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundTop,
            AppColors.backgroundMid,
            AppColors.backgroundBottom,
          ],
        ),
      ),
      child: child,
    );
  }
}
