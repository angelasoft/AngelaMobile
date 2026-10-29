import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 스플래시·로그인 등에서 공통으로 쓰는 그라데이션 배경 (흰색 → 크림색).
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
          stops: [0, 0.55, 1],
          colors: [
            AppColors.backgroundTop,
            AppColors.backgroundTop,
            AppColors.backgroundCream,
          ],
        ),
      ),
      child: child,
    );
  }
}
