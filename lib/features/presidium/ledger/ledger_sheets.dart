import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import '../../../core/widgets/won_format.dart';
import 'ledger_service.dart';

/// 전월 이월금 입력. [initial] 은 전월 장부 누계 또는 지금 값.
Future<LedgerAmounts?> showCarryoverSheet(
  BuildContext context, {
  required int month,
  LedgerAmounts? initial,
}) {
  return showModalBottomSheet<LedgerAmounts>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CarryoverSheet(month: month, initial: initial),
  );
}

/// 장부 내역 추가·수정. [initial] 이 있으면 수정.
Future<LedgerEntryInput?> showEntrySheet(
  BuildContext context, {
  required int year,
  required int month,
  LedgerEntry? initial,
}) {
  return showModalBottomSheet<LedgerEntryInput>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EntrySheet(year: year, month: month, initial: initial),
  );
}

InputDecoration _decoration(String hint, {String? suffix}) => InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: AppColors.backgroundMid,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 6),
      child: Text(text, style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
    );

Widget _sheetFrame(BuildContext context, {required String title, String? subtitle, required List<Widget> children}) {
  return Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: AppColors.subtitle, height: 1.4)),
          ],
          ...children,
        ],
      ),
    ),
  );
}

Widget _submitButton(String text, VoidCallback onPressed) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );

class _CarryoverSheet extends StatefulWidget {
  const _CarryoverSheet({required this.month, this.initial});

  final int month;
  final LedgerAmounts? initial;

  @override
  State<_CarryoverSheet> createState() => _CarryoverSheetState();
}

class _CarryoverSheetState extends State<_CarryoverSheet> {
  late final _income = TextEditingController(text: _text(widget.initial?.income));
  late final _expense = TextEditingController(text: _text(widget.initial?.expense));
  late final _balance = TextEditingController(text: _text(widget.initial?.balance));

  /// 잔액을 직접 고치기 전까지는 수입 - 지출로 채운다.
  late bool _balanceEdited = widget.initial != null;

  static String _text(int? v) => v == null ? '' : formatWon(v);

  @override
  void dispose() {
    _income.dispose();
    _expense.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _syncBalance() {
    if (_balanceEdited) return;
    final income = parseWon(_income.text) ?? 0;
    final expense = parseWon(_expense.text) ?? 0;
    final balance = income - expense;
    _balance.text = balance < 0 ? '' : formatWon(balance);
  }

  void _submit() {
    final income = parseWon(_income.text);
    final expense = parseWon(_expense.text);
    final balance = parseWon(_balance.text);
    if (income == null || expense == null || balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수입금액, 지출금액, 잔액을 모두 입력해 주세요. 없으면 0을 입력하세요.')),
      );
      return;
    }
    Navigator.of(context).pop(LedgerAmounts(income, expense, balance));
  }

  Widget _amountField(TextEditingController controller, String hint, {ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: const [WonInputFormatter()],
      onChanged: onChanged,
      decoration: _decoration(hint, suffix: '원'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _sheetFrame(
      context,
      title: '${widget.month}월 전월 이월금',
      subtitle: '지난달 장부의 누계(수입금액·지출금액)와 잔액을 입력합니다.',
      children: [
        _label('수입금액 (누계)'),
        _amountField(_income, '예: 1,344,000', onChanged: (_) => setState(_syncBalance)),
        _label('지출금액 (누계)'),
        _amountField(_expense, '예: 1,209,000', onChanged: (_) => setState(_syncBalance)),
        _label('잔액'),
        _amountField(_balance, '수입금액 - 지출금액', onChanged: (_) => _balanceEdited = true),
        _submitButton('저장', _submit),
      ],
    );
  }
}

class _EntrySheet extends StatefulWidget {
  const _EntrySheet({required this.year, required this.month, this.initial});

  final int year;
  final int month;
  final LedgerEntry? initial;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  late DateTime _date = widget.initial?.date ?? _defaultDate();
  late bool _isIncome = widget.initial?.isIncome ?? false;
  late ExpenseCategory _category = widget.initial?.category ?? ExpenseCategory.flower;
  late final _description = TextEditingController(
    text: _initialDescription(),
  );
  late final _amount = TextEditingController(
    text: widget.initial == null ? '' : formatWon(widget.initial!.amount),
  );

  String _initialDescription() {
    final e = widget.initial;
    if (e == null) return '';
    if (!e.isIncome && e.category != ExpenseCategory.other) return '';
    return e.description;
  }

  DateTime _defaultDate() {
    final now = DateTime.now();
    if (now.year == widget.year && now.month == widget.month) return DateTime(now.year, now.month, now.day);
    return DateTime(widget.year, widget.month, 1);
  }

  bool get _needsDescription => _isIncome || _category == ExpenseCategory.other;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(widget.year, widget.month, 1),
      lastDate: DateTime(widget.year, widget.month + 1, 0),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final amount = parseWon(_amount.text);
    final description = _description.text.trim();
    String? missing;
    if (amount == null || amount <= 0) missing = '금액을 입력해 주세요.';
    if (_needsDescription && description.isEmpty) {
      missing = _isIncome ? '적요를 입력해 주세요. (예: 제612차 비밀헌금)' : '기타 지출 내용을 입력해 주세요.';
    }
    if (missing != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(missing)));
      return;
    }
    Navigator.of(context).pop(LedgerEntryInput(
      date: _date,
      isIncome: _isIncome,
      category: _isIncome ? null : _category,
      description: _needsDescription ? description : _category.label,
      amount: amount!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _sheetFrame(
      context,
      title: widget.initial == null ? '장부 내역 추가' : '장부 내역 수정',
      children: [
        _label('날짜'),
        Material(
          color: AppColors.backgroundMid,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Text(koreanFullDate(_date), style: const TextStyle(color: AppColors.title, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
        _label('구분'),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('지출'), icon: Icon(Icons.remove_circle_outline)),
            ButtonSegment(value: true, label: Text('수입'), icon: Icon(Icons.add_circle_outline)),
          ],
          selected: {_isIncome},
          onSelectionChanged: (s) => setState(() => _isIncome = s.first),
        ),
        if (!_isIncome) ...[
          _label('지출 항목'),
          Wrap(
            spacing: 8,
            children: [
              for (final c in ExpenseCategory.values)
                ChoiceChip(
                  label: Text(c == ExpenseCategory.other ? '기타 (직접 입력)' : c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
        ],
        if (_needsDescription) ...[
          _label(_isIncome ? '적요' : '기타 지출 내용'),
          TextField(
            controller: _description,
            maxLength: 100,
            decoration: _decoration(_isIncome ? '예: 제612차 비밀헌금' : '예: 회합 다과'),
          ),
        ],
        _label('금액'),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [WonInputFormatter()],
          decoration: _decoration('예: 5,000', suffix: '원'),
        ),
        _submitButton(widget.initial == null ? '추가' : '수정', _submit),
      ],
    );
  }
}