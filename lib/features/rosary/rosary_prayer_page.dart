import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/ads/ads_config.dart';
import '../../core/ads/native_ad_slot.dart';
import '../../core/text_scale/text_scale_buttons.dart';
import '../../core/theme/app_colors.dart';
import 'rosary_data.dart';
import 'widgets/bead_rail.dart';

/// 묵주기도를 한 알씩 따라가며 바치는 화면. 다 마치면 true 를 돌려준다.
class RosaryPrayerPage extends StatefulWidget {
  const RosaryPrayerPage({super.key, required this.mystery});

  final RosaryMystery mystery;

  @override
  State<RosaryPrayerPage> createState() => _RosaryPrayerPageState();
}

class _RosaryPrayerPageState extends State<RosaryPrayerPage> {
  late final List<RosaryStep> _steps = buildRosarySteps(widget.mystery);
  int _current = 0;

  bool get _isLast => _current == _steps.length - 1;

  /// 기도하는 동안 화면이 꺼지지 않게 하고, 화면을 나가면 원래대로 돌린다.
  @override
  void initState() {
    super.initState();
    _keepScreenOn(true);
  }

  @override
  void dispose() {
    _keepScreenOn(false);
    super.dispose();
  }

  static void _keepScreenOn(bool on) {
    WakelockPlus.toggle(enable: on).catchError((Object e) {
      debugPrint('[Rosary] 화면 켜짐 유지 설정 실패: $e');
    });
  }

  void _goTo(int index) {
    if (index < 0 || index >= _steps.length || index == _current) return;
    setState(() => _current = index);
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop(true);
    } else {
      _goTo(_current + 1);
    }
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -250) _next();
    if (velocity > 250) _goTo(_current - 1);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_current];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('묵주기도'),
        actions: const [TextScaleButtons(), SizedBox(width: 8)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(14),
          child: _DecadeDots(decade: step.decade, color: widget.mystery.color),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const NativeAdSlot(
              placement: AdPlacement.rosaryPrayer,
              margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: _onSwipe,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _StepContent(
                          key: ValueKey(_current),
                          mystery: widget.mystery,
                          step: step,
                        ),
                      ),
                    ),
                  ),
                  BeadRail(steps: _steps, current: _current, onSelect: _goTo),
                ],
              ),
            ),
            _BottomBar(
              current: _current,
              total: _steps.length,
              isLast: _isLast,
              onPrevious: _current == 0 ? null : () => _goTo(_current - 1),
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

/// 다섯 단 중 지금 몇 단인지.
class _DecadeDots extends StatelessWidget {
  const _DecadeDots({required this.decade, required this.color});

  final int? decade;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var d = 1; d <= 5; d++)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: d == decade
                    ? color
                    : decade != null && d < decade!
                        ? color.withValues(alpha: 0.4)
                        : AppColors.shadow.withValues(alpha: 0.15),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({super.key, required this.mystery, required this.step});

  final RosaryMystery mystery;
  final RosaryStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDecadeStart = step.kind == BeadKind.large && step.decade != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 24),
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: mystery.title, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            TextSpan(text: ' ${step.label}', style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
          ]),
          style: theme.textTheme.titleSmall,
        ),
        if (step.meditation != null && !isDecadeStart) ...[
          const SizedBox(height: 2),
          Text(
            step.meditation!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accent, fontStyle: FontStyle.italic),
          ),
        ],
        const Divider(height: 24),
        if (isDecadeStart) ...[
          Text(
            step.meditation!,
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700, height: 1.4),
          ),
          const SizedBox(height: 16),
        ],
        for (var i = 0; i < step.prayers.length; i++) ...[
          if (i > 0) const Divider(height: 32),
          _PrayerBlock(prayer: step.prayers[i]),
        ],
      ],
    );
  }
}

class _PrayerBlock extends StatelessWidget {
  const _PrayerBlock({required this.prayer});

  final RosaryPrayer prayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = prayer.text.split('\n');
    final body = theme.textTheme.bodyLarge?.copyWith(color: AppColors.title.withValues(alpha: 0.9), height: 1.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prayer.title,
          style: theme.textTheme.titleSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        // 첫 줄은 선창하는 부분이라 강조한다.
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: lines.first,
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
            ),
            if (lines.length > 1) TextSpan(text: '\n${lines.skip(1).join('\n')}'),
          ]),
          style: body,
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.current,
    required this.total,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
  });

  final int current;
  final int total;
  final bool isLast;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.shadow.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: const Text('이전'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${current + 1} / $total',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.subtitle),
            ),
          ),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isLast ? '마침' : '다음', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (!isLast) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
