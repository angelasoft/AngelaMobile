import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/meeting_order_step.dart';

class MeetingStepTile extends StatelessWidget {
  const MeetingStepTile({
    super.key,
    required this.step,
    required this.isExpanded,
    required this.onTap,
  });

  final MeetingOrderStep step;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: isExpanded
                    ? AppColors.accent.withValues(alpha: 0.35)
                    : AppColors.shadow.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrderBadge(order: step.order),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.title,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                            ),
                            if (!isExpanded) ...[
                              const SizedBox(height: 6),
                              Text(
                                step.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.subtitle
                                          .withValues(alpha: 0.85),
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _StepBody(step: step),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  sizeCurve: Curves.easeOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$order',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step});

  final MeetingOrderStep step;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.title.withValues(alpha: 0.88),
          height: 1.55,
        );
    final bulletStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.subtitle,
          height: 1.5,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            color: AppColors.shadow.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),
          Text(
            step.summary,
            style: bodyStyle?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          for (final paragraph in step.paragraphs) ...[
            const SizedBox(height: 12),
            Text(paragraph, style: bodyStyle),
          ],
          if (step.bullets.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...step.bullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(child: Text(item, style: bulletStyle)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
