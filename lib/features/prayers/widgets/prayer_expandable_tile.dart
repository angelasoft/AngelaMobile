import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/prayer_item.dart';

class PrayerExpandableTile extends StatelessWidget {
  const PrayerExpandableTile({
    super.key,
    required this.prayer,
    required this.isExpanded,
    required this.onTap,
  });

  final PrayerItem prayer;
  final bool isExpanded;

  /// null 이면 접을 수 없는 기도문 (탭에 한 편뿐일 때).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
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
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          prayer.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.title,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.accent,
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: isExpanded ? _PrayerBody(prayer: prayer) : const SizedBox.shrink(),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeOut,
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: AppColors.shadow.withValues(alpha: 0.08)),
          const SizedBox(height: 14),
          for (final block in prayer.blocks)
            switch (block) {
              PrayerHeading() => _Heading(block),
              PrayerImage() => _PrayerImageView(block.assetPath),
              PrayerParagraph() => _Paragraph(block),
            },
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.heading);

  final PrayerHeading heading;

  @override
  Widget build(BuildContext context) {
    final major = heading.level <= 2;
    return Padding(
      padding: EdgeInsets.only(top: major ? 10 : 4, bottom: 8),
      child: Text(
        heading.text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: major ? AppColors.accent : AppColors.title,
              fontWeight: major ? FontWeight.w700 : FontWeight.w600,
              height: 1.4,
            ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.paragraph);

  final PrayerParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.title.withValues(alpha: 0.9),
          height: 1.6,
          fontSize: 15,
        );
    final rubricStyle = bodyStyle?.copyWith(
      color: AppColors.subtitle.withValues(alpha: 0.85),
      fontSize: 13,
    );
    final markerWidth = MediaQuery.textScalerOf(context).scale(22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in paragraph.lines)
            _buildLine(line, bodyStyle, rubricStyle, markerWidth),
        ],
      ),
    );
  }

  Widget _buildLine(
    PrayerLine line,
    TextStyle? bodyStyle,
    TextStyle? rubricStyle,
    double markerWidth,
  ) {
    var style = line.isRubric ? rubricStyle : bodyStyle;
    if (line.underlined) {
      style = style?.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.accent,
      );
    }
    final text = Text(line.text, style: style);
    if (line.marker == null && !line.indented) return text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: markerWidth,
          child: line.marker == null
              ? null
              : Text(
                  line.marker!,
                  style: bodyStyle?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        Expanded(child: text),
      ],
    );
  }
}

/// 본문 그림. 누르면 크게 보고 확대할 수 있다.
class _PrayerImageView extends StatelessWidget {
  const _PrayerImageView(this.assetPath);

  final String assetPath;

  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
          body: InteractiveViewer(
            maxScale: 5,
            child: Center(child: Image.asset(assetPath)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openViewer(context),
            child: Image.asset(assetPath, fit: BoxFit.fitWidth),
          ),
          const SizedBox(height: 4),
          Text(
            '그림을 누르면 크게 볼 수 있어요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.subtitle.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}
