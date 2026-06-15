import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_tab_header.dart';
import 'data/meeting_order_data.dart';
import 'widgets/meeting_step_tile.dart';

class WeeklyMeetingPage extends StatefulWidget {
  const WeeklyMeetingPage({super.key});

  @override
  State<WeeklyMeetingPage> createState() => _WeeklyMeetingPageState();
}

class _WeeklyMeetingPageState extends State<WeeklyMeetingPage> {
  int? _expandedOrder;

  void _onStepTap(int order) {
    setState(() {
      _expandedOrder = _expandedOrder == order ? null : order;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppTabHeader(title: '주 회합'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const _IntroCard(),
                const SizedBox(height: 16),
                Text(
                  '회합 순서 (${MeetingOrderData.steps.length}단계)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.title,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                for (final step in MeetingOrderData.steps)
                  MeetingStepTile(
                    step: step,
                    isExpanded: _expandedOrder == step.order,
                    onTap: () => _onStepTap(step.order),
                  ),
                const SizedBox(height: 8),
                const _SourceNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.shadow.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_note_outlined,
                color: AppColors.accent.withValues(alpha: 0.85),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '쁘레시디움 주회합',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.title,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '각 단계를 눌러 회합 순서와 안내를 확인하세요. '
            '진행 시간은 보통 1시간~1시간 30분입니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitle.withValues(alpha: 0.9),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      '회합 순서 안내는 레지오 마리애 교본 제18장 및 '
      '모라 성요한 성당 카페 「교본 해설」을 참고하였습니다.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.subtitle.withValues(alpha: 0.6),
            height: 1.45,
            fontSize: 11,
          ),
    );
  }
}
