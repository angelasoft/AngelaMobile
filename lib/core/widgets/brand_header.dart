import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 앱 로고·타이틀 (스플래시·로그인 공통).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});

  /// 로그인 등에서 로고를 조금 작게 표시할 때 true.
  final bool compact;

  static const _imagePath = 'assets/images/mary_splash.png';

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
    final ratio = compact ? 0.32 : 0.48;
    final minSize = compact ? 120.0 : 200.0;
    final maxSize = compact ? 160.0 : 280.0;
    final diameter = (size * ratio).clamp(minSize, maxSize);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.12),
            blurRadius: compact ? 20 : 32,
            offset: Offset(0, compact ? 8 : 12),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: ClipOval(
        child: Image.asset(
          BrandHeader._imagePath,
          fit: BoxFit.cover,
        ),
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
