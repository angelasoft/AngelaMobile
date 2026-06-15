import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/prayer_item.dart';

class PrayerExpandableTile extends StatelessWidget {
  const PrayerExpandableTile({
    super.key,
    required this.prayer,
    required this.isExpanded,
    required this.onTap,
    this.showOrder,
  });

  final PrayerItem prayer;
  final bool isExpanded;
  final VoidCallback onTap;
  final int? showOrder;

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
                      if (showOrder != null) ...[
                        _OrderBadge(order: showOrder!),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.title,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                            ),
                            if (!isExpanded && prayer.summary != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                prayer.summary!,
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
                  secondChild: _PrayerBody(prayer: prayer),
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
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$order',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PrayerBody extends StatelessWidget {
  const _PrayerBody({required this.prayer});

  final PrayerItem prayer;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.title.withValues(alpha: 0.9),
          height: 1.65,
          fontSize: 15,
        );
    final headingStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          height: 1.4,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            color: AppColors.shadow.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),
          if (prayer.summary != null && prayer.sections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                prayer.summary!,
                style: bodyStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtitle,
                ),
              ),
            ),
          for (final section in prayer.sections) ...[
            if (section.heading != null) ...[
              Text(section.heading!, style: headingStyle),
              const SizedBox(height: 8),
            ],
            for (final line in section.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(line, style: bodyStyle),
              ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
