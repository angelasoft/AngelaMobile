import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/won_format.dart';
import 'ledger_service.dart';
import 'ledger_sheets.dart';

/// 월별 회계 장부. 종이 장부처럼 [월일 | 적요 | 수입금액 | 지출금액 | 잔액] 표와 하단 요약을 보여준다.
class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final _service = const LedgerService();

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Ledger? _ledger;
  String? _error;
  bool _isBusy = false;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _ledger = null;
      _error = null;
    });
    try {
      final ledger = await _service.fetch(_month.year, _month.month);
      if (!mounted) return;
      setState(() => _ledger = ledger);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  void _moveMonth(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    _load();
  }

  /// 장부를 바꾸는 요청. 서버가 돌려준 장부로 화면을 바로 갱신한다.
  Future<void> _mutate(Future<Ledger> Function() request, String doneMessage) async {
    setState(() => _isBusy = true);
    try {
      final ledger = await request();
      if (!mounted) return;
      setState(() => _ledger = ledger);
      _showMessage(doneMessage);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _createLedger() async {
    final ledger = _ledger!;
    final carryover = await showCarryoverSheet(context, month: _month.month, initial: ledger.suggestedCarryover);
    if (carryover == null) return;
    await _mutate(() => _service.create(_month.year, _month.month, carryover), '${_month.month}월 장부를 만들었습니다.');
  }

  Future<void> _editCarryover() async {
    final ledger = _ledger!;
    final carryover = await showCarryoverSheet(context, month: _month.month, initial: ledger.carryover);
    if (carryover == null) return;
    await _mutate(() => _service.updateCarryover(_month.year, _month.month, carryover), '전월 이월금을 수정했습니다.');
  }

  Future<void> _syncCarryover() async {
    final previous = _ledger!.previousCumulative!;
    await _mutate(
      () => _service.updateCarryover(_month.year, _month.month, previous),
      '전월 장부 누계로 이월금을 맞췄습니다.',
    );
  }

  Future<void> _addEntry() async {
    final input = await showEntrySheet(context, year: _month.year, month: _month.month);
    if (input == null) return;
    await _mutate(() => _service.addEntry(_month.year, _month.month, input), '장부에 추가했습니다.');
  }

  Future<void> _openEntryActions(LedgerEntry entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(entry.description, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${entry.isIncome ? '수입' : '지출'} ${formatWon(entry.amount)}원'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('수정'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFD9534F)),
              title: const Text('삭제', style: TextStyle(color: Color(0xFFD9534F))),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      final input = await showEntrySheet(context, year: _month.year, month: _month.month, initial: entry);
      if (input == null) return;
      await _mutate(() => _service.updateEntry(_month.year, _month.month, entry.id, input), '수정했습니다.');
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이 내역을 삭제할까요?'),
          content: Text('${entry.description} ${formatWon(entry.amount)}원\n아래 줄의 잔액이 다시 계산됩니다.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD9534F)),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _mutate(() => _service.deleteEntry(_month.year, _month.month, entry.id), '삭제했습니다.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    final canAdd = ledger != null && ledger.exists && ledger.canEdit;
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: const Text('회계 장부')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _isBusy ? null : _addEntry,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('내역 추가'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            _monthNavigator(),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(padding: const EdgeInsets.all(32), child: Text(_error!, textAlign: TextAlign.center))
            else if (ledger == null)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (!ledger.exists)
              _noLedger(ledger)
            else ...[
              if (ledger.carryoverOutdated && ledger.canEdit) _outdatedBanner(),
              LedgerTable(
                ledger: ledger,
                onCarryoverTap: ledger.canEdit && !_isBusy ? _editCarryover : null,
                onEntryTap: ledger.canEdit && !_isBusy ? _openEntryActions : null,
              ),
              const SizedBox(height: 12),
              LedgerSummary(ledger: ledger),
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthNavigator() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          IconButton(onPressed: () => _moveMonth(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              '${_month.year}년 ${_month.month}월',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.title),
            ),
          ),
          IconButton(
            onPressed: _isCurrentMonth ? null : () => _moveMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _noLedger(Ledger ledger) {
    final suggested = ledger.suggestedCarryover;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 48, color: AppColors.accent.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            '${ledger.month}월 회계 장부가 아직 없어요.',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.title, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            ledger.canEdit
                ? (suggested == null
                    ? '전월 이월금(수입·지출 누계와 잔액)을 입력하면 장부를 시작할 수 있어요.'
                    : '지난달 장부의 누계가 이월금으로 채워져 있어요. 확인 후 저장하면 장부가 만들어져요.')
                : '4간부가 장부를 만들면 여기에서 볼 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtitle, height: 1.5),
          ),
          if (ledger.canEdit) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isBusy ? null : _createLedger,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              icon: const Icon(Icons.edit_note),
              label: const Text('전월 이월금 입력하고 장부 만들기'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _outdatedBanner() {
    final prev = _ledger!.previousCumulative!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '지난달 장부 누계(잔액 ${formatWon(prev.balance)}원)와 이월금이 달라요.',
              style: const TextStyle(color: AppColors.title, fontSize: 13, height: 1.4),
            ),
          ),
          TextButton(onPressed: _isBusy ? null : _syncCarryover, child: const Text('맞추기')),
        ],
      ),
    );
  }
}

/// [월일 | 적요 | 수입금액 | 지출금액 | 잔액] 표.
class LedgerTable extends StatelessWidget {
  const LedgerTable({super.key, required this.ledger, this.onCarryoverTap, this.onEntryTap});

  final Ledger ledger;
  final VoidCallback? onCarryoverTap;
  final ValueChanged<LedgerEntry>? onEntryTap;

  @override
  Widget build(BuildContext context) {
    final carryover = ledger.carryover!;
    final cumulative = ledger.cumulative!;
    final line = Divider(height: 1, color: AppColors.shadow.withValues(alpha: 0.12));
    final strongLine = Divider(height: 1, thickness: 1.5, color: const Color(0xFFD98C8C).withValues(alpha: 0.7));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _Row(
            date: '월일',
            description: '적요',
            income: '수입금액',
            expense: '지출금액',
            balance: '잔액',
            header: true,
          ),
          strongLine,
          _Row(
            date: '${ledger.month}',
            description: '전월 이월금',
            income: formatWon(carryover.income),
            expense: formatWon(carryover.expense),
            balance: formatWon(carryover.balance),
            emphasized: true,
            onTap: onCarryoverTap,
          ),
          for (final e in ledger.entries) ...[
            line,
            _Row(
              date: '${e.date.month}.${e.date.day}',
              description: e.description,
              income: e.isIncome ? formatWon(e.amount) : '',
              expense: e.isIncome ? '' : formatWon(e.amount),
              balance: formatWon(e.balance),
              onTap: onEntryTap == null ? null : () => onEntryTap!(e),
            ),
          ],
          if (ledger.entries.isEmpty) ...[
            line,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                ledger.canEdit ? '아래 「내역 추가」로 수입·지출을 기록하세요.' : '아직 기록된 내역이 없어요.',
                style: TextStyle(color: AppColors.subtitle, fontSize: 13),
              ),
            ),
          ],
          strongLine,
          _Row(
            date: '',
            description: '월계',
            income: formatWon(ledger.monthlyIncome),
            expense: formatWon(ledger.monthlyExpense),
            balance: '',
            emphasized: true,
          ),
          line,
          _Row(
            date: '',
            description: '누계',
            income: formatWon(cumulative.income),
            expense: formatWon(cumulative.expense),
            balance: formatWon(cumulative.balance),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.date,
    required this.description,
    required this.income,
    required this.expense,
    required this.balance,
    this.header = false,
    this.emphasized = false,
    this.onTap,
  });

  final String date;
  final String description;
  final String income;
  final String expense;
  final String balance;
  final bool header;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final weight = header || emphasized ? FontWeight.w700 : FontWeight.w500;
    final base = TextStyle(
      fontSize: header ? 12 : 13,
      color: header ? AppColors.subtitle : AppColors.title,
      fontWeight: weight,
    );

    // 금액은 칸이 좁으면 글자를 줄여서라도 한 줄에 보이게 한다.
    Widget amount(String text, Color color, int flex) => Expanded(
          flex: flex,
          child: Align(
            alignment: header ? Alignment.center : Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, style: base.copyWith(color: header ? null : color)),
            ),
          ),
        );

    return InkWell(
      onTap: onTap,
      child: Container(
        color: header
            ? AppColors.backgroundMid
            : emphasized
                ? AppColors.backgroundCream.withValues(alpha: 0.6)
                : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(date, style: base),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: header ? TextAlign.center : TextAlign.start,
                style: base,
              ),
            ),
            const SizedBox(width: 4),
            amount(income, const Color(0xFF2E7D4F), 4),
            const SizedBox(width: 4),
            amount(expense, const Color(0xFFC0504D), 4),
            const SizedBox(width: 4),
            amount(balance, AppColors.title, 4),
          ],
        ),
      ),
    );
  }
}

/// 장부 하단 요약 (전월 이월금 · 수입 금액 · 지출 계 · 지출 내역 · 잔액).
class LedgerSummary extends StatelessWidget {
  const LedgerSummary({super.key, required this.ledger});

  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, int value, {bool indent = false, bool strong = false}) => Padding(
          padding: EdgeInsets.fromLTRB(indent ? 28 : 16, 9, 16, 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: indent ? AppColors.subtitle : AppColors.title,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${formatWon(value)}원',
                style: TextStyle(
                  color: strong ? AppColors.accent : AppColors.title,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  fontSize: strong ? 17 : 14,
                ),
              ),
            ],
          ),
        );
    final line = Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.shadow.withValues(alpha: 0.1));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          row('전월 이월금', ledger.carryover!.balance),
          line,
          row('수입 금액', ledger.monthlyIncome),
          line,
          row('지출 계', ledger.monthlyExpense),
          row('· 의연금', ledger.donation, indent: true),
          row('· 꽃·초값', ledger.flower, indent: true),
          if (ledger.other > 0) row('· 기타', ledger.other, indent: true),
          line,
          row('잔액', ledger.finalBalance, strong: true),
        ],
      ),
    );
  }
}
