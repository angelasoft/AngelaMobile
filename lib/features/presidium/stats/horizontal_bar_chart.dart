import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class BarEntry {
  const BarEntry(this.label, this.value, {this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;
}

/// 가로 막대 그래프. 가장 큰 값을 기준으로 막대 길이를 정한다. 넘겨받은 순서대로 그린다.
class HorizontalBarChart extends StatelessWidget {
  const HorizontalBarChart({
    super.key,
    required this.entries,
    this.labelWidth = 104,
    this.color = AppColors.accent,
  });

  final List<BarEntry> entries;
  final double labelWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    return Column(
      children: [
        for (final e in entries)
          InkWell(
            onTap: e.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Text(
                      e.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.title, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final ratio = maxValue == 0 ? 0.0 : e.value / maxValue;
                        return Stack(
                          children: [
                            Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundMid,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            Container(
                              height: 14,
                              width: constraints.maxWidth * ratio,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.55), color],
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${e.value}',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
