import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../my_presidiums.dart';
import '../onboarding/presidium_guide_page.dart';

/// 가입한 쁘레시디움이 없을 때 쁘레시디움·활동보고 탭에 보여 주는 안내와 가입 버튼.
/// 처음 한 번은 가입·만들기 가이드를 먼저 띄운다.
class JoinPresidiumPrompt extends StatefulWidget {
  const JoinPresidiumPrompt({super.key});

  @override
  State<JoinPresidiumPrompt> createState() => _JoinPresidiumPromptState();
}

class _JoinPresidiumPromptState extends State<JoinPresidiumPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideOnce());
  }

  /// 쁘레시디움·활동보고 탭이 IndexedStack 으로 함께 만들어지므로, 보이는 탭에서만 띄운다.
  Future<void> _showGuideOnce() async {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;
    final goJoin = await PresidiumGuide.showOnce(context);
    if (goJoin && mounted) await MyPresidiums.openJoin(context);
  }

  Future<void> _openGuide() async {
    final goJoin = await PresidiumGuide.open(context);
    if (goJoin && mounted) await MyPresidiums.openJoin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 20),
            Text(
              '아직 가입한 쁘레시디움이 없어요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '소속 쁘레시디움에 가입하고\n활동을 함께 기록해 보세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtitle.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => MyPresidiums.openJoin(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '쁘레시디움 가입',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _openGuide,
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('처음이신가요? 가입·만들기 방법 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
