import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';

/// 간부 임명일과 임기.
class OfficerTerm {
  const OfficerTerm({required this.appointedDate, required this.years, required this.months});

  final DateTime appointedDate;
  final int years;
  final int months;

  /// 임기 마지막 날 (서버와 같은 계산). 예: 2026-01-07 부터 3년 0개월이면 2029-01-06.
  DateTime get endDate {
    final monthStart = DateTime(appointedDate.year, appointedDate.month + years * 12 + months);
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final day = appointedDate.day > lastDay ? lastDay : appointedDate.day;
    return DateTime(monthStart.year, monthStart.month, day - 1);
  }
}

/// 임명일(오늘이나 지난 날짜)과 임기(년·개월)를 고른다. 취소하면 null.
Future<OfficerTerm?> showOfficerTermDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  DateTime? initialDate,
  int? initialTermMonths,
}) {
  return showDialog<OfficerTerm>(
    context: context,
    builder: (_) => _OfficerTermDialog(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      initialDate: initialDate,
      initialTermMonths: initialTermMonths ?? 36,
    ),
  );
}

class _OfficerTermDialog extends StatefulWidget {
  const _OfficerTermDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.initialDate,
    required this.initialTermMonths,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final DateTime? initialDate;
  final int initialTermMonths;

  @override
  State<_OfficerTermDialog> createState() => _OfficerTermDialogState();
}

class _OfficerTermDialogState extends State<_OfficerTermDialog> {
  late DateTime _date;
  late int _years;
  late int _months;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _years = widget.initialTermMonths ~/ 12;
    _months = widget.initialTermMonths % 12;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      helpText: '임명일 (지난 날짜도 고를 수 있어요)',
      initialDate: _date,
      firstDate: DateTime(1921),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool get _valid => _years * 12 + _months >= 1;

  @override
  Widget build(BuildContext context) {
    final term = OfficerTerm(appointedDate: _date, years: _years, months: _months);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description, style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('임명일', style: TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event, size: 18),
              label: Text(koreanFullDate(_date)),
            ),
            const SizedBox(height: 16),
            const Text('임기', style: TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                DropdownButton<int>(
                  value: _years,
                  items: [for (var y = 0; y <= 10; y++) DropdownMenuItem(value: y, child: Text('$y년'))],
                  onChanged: (v) => setState(() => _years = v ?? _years),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _months,
                  items: [for (var m = 0; m <= 11; m++) DropdownMenuItem(value: m, child: Text('$m개월'))],
                  onChanged: (v) => setState(() => _months = v ?? _months),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _valid ? '임기 마지막 날: ${koreanFullDate(term.endDate)}' : '임기는 1개월 이상이어야 해요.',
              style: TextStyle(color: _valid ? AppColors.accent : const Color(0xFFD9534F), fontSize: 13),
            ),
            if (_valid)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '임기 마지막 날 한 달 전에 단원 모두에게 간부 이동 알림이 가요.',
                  style: TextStyle(color: AppColors.subtitle, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: _valid ? () => Navigator.pop(context, term) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
