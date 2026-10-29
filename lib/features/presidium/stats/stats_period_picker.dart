import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'activity_stats_service.dart';

/// 통계 기간 선택: 연도 → 월 → 그 달의 주(월~토) 또는 월 전체. 고르지 않고 닫으면 null.
Future<StatsPeriod?> showStatsPeriodPicker(BuildContext context, StatsPeriod initial) {
  return showModalBottomSheet<StatsPeriod>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _StatsPeriodSheet(initial: initial),
  );
}

/// [year]년 [month]월과 월~토가 하루라도 겹치는 주의 월요일들.
List<DateTime> weeksOfMonth(int year, int month) {
  final first = DateTime(year, month);
  final last = DateTime(year, month + 1, 0);
  final weeks = <DateTime>[];
  for (var monday = weekStartOf(first);
      !monday.isAfter(last);
      monday = DateTime(monday.year, monday.month, monday.day + 7)) {
    if (!monday.add(const Duration(days: 5)).isBefore(first)) {
      weeks.add(monday);
    }
  }
  return weeks;
}

class _StatsPeriodSheet extends StatefulWidget {
  const _StatsPeriodSheet({required this.initial});

  final StatsPeriod initial;

  @override
  State<_StatsPeriodSheet> createState() => _StatsPeriodSheetState();
}

class _StatsPeriodSheetState extends State<_StatsPeriodSheet> {
  final _thisWeek = weekStartOf(DateTime.now());
  final _now = DateTime.now();
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _year = initial.weekStart?.year ?? initial.year;
    _month = initial.weekStart?.month ?? initial.month;
  }

  bool _isFutureMonth(int year, int month) =>
      year > _now.year || (year == _now.year && month > _now.month);

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
      if (_isFutureMonth(_year, _month)) _month = _now.month;
    });
  }

  bool _isSelectedWeek(DateTime monday) => widget.initial.weekStart == monday;

  bool get _isSelectedMonth =>
      !widget.initial.isWeek && widget.initial.year == _year && widget.initial.month == _month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeks = weeksOfMonth(_year, _month);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '기간 선택',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.title),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(onPressed: () => _changeYear(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    '$_year년',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _year >= _now.year ? null : () => _changeYear(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var m = 1; m <= 12; m++)
                  ChoiceChip(
                    label: Text('$m월'),
                    selected: m == _month,
                    showCheckmark: false,
                    onSelected: _isFutureMonth(_year, m) ? null : (_) => setState(() => _month = m),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '$_month월 주 선택 (월~토)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.title),
            ),
            const SizedBox(height: 8),
            _option(
              label: '$_month월 전체',
              selected: _isSelectedMonth,
              onTap: () => Navigator.pop(context, StatsPeriod.month(_year, _month)),
            ),
            for (var i = 0; i < weeks.length; i++)
              _option(
                label: '${i + 1}주  ${koreanShortDate(weeks[i])} ~ '
                    '${koreanShortDate(weeks[i].add(const Duration(days: 5)))}',
                badge: weeks[i] == _thisWeek ? '이번 주' : null,
                selected: _isSelectedWeek(weeks[i]),
                onTap: weeks[i].isAfter(_thisWeek)
                    ? null
                    : () => Navigator.pop(context, StatsPeriod.week(weeks[i])),
              ),
          ],
        ),
      ),
    );
  }

  Widget _option({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
    String? badge,
  }) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundMid,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: enabled ? AppColors.title : AppColors.subtitle.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 18, color: AppColors.accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
