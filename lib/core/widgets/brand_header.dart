import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 앱 로고·타이틀 (스플래시·로그인 공통).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});

  /// 로그인 등에서 로고를 조금 작게 표시할 때 true.
  final bool compact;

  static const _imagePath = 'assets/icons/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MaryIllustration(compact: compact),
        SizedBox(height: compact ? 20 : 32),
        const _AppTitle(),
      ],
    );
  }
}

class _MaryIllustration extends StatelessWidget {
  const _MaryIllustration({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).shortestSide;
    final ratio = compact ? 0.38 : 0.6;
    final minSize = compact ? 140.0 : 220.0;
    final maxSize = compact ? 180.0 : 320.0;
    final extent = (size * ratio).clamp(minSize, maxSize);

    // 아이콘 그림은 투명 배경이라 자르지 않고 그대로 보여주고, 뒤에 크림색 빛을 은은하게 깐다.
    return Container(
      width: extent,
      height: extent,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppColors.backgroundCream, Color(0x00FEF6E9)],
          stops: [0.45, 1],
        ),
      ),
      child: Image.asset(
        BrandHeader._imagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '레지오마리애',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.title,
                height: 1.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '활동수첩',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: AppColors.subtitle,
                height: 1.3,
              ),
        ),
      ],
    );
  }
}
