import '../../../core/network/api_client.dart';
import '../../../core/widgets/korean_date.dart';

/// 지출 항목. 장부 하단 지출 내역에 따로 합산된다.
enum ExpenseCategory {
  flower('FLOWER', '꽃 값'),
  donation('DONATION', '의연금'),
  other('OTHER', '기타');

  const ExpenseCategory(this.code, this.label);

  final String code;
  final String label;

  static ExpenseCategory? fromCode(String? code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// 수입·지출·잔액 (전월 이월금, 누계).
class LedgerAmounts {
  const LedgerAmounts(this.income, this.expense, this.balance);

  static LedgerAmounts? fromJson(Object? json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return LedgerAmounts(m['income'] as int, m['expense'] as int, m['balance'] as int);
  }

  final int income;
  final int expense;
  final int balance;

  bool sameAs(LedgerAmounts other) =>
      income == other.income && expense == other.expense && balance == other.balance;
}

/// 장부 한 줄.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.date,
    required this.isIncome,
    required this.category,
    required this.description,
    required this.amount,
    required this.balance,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as int,
      date: parseIsoDate(json['date'] as String),
      isIncome: json['type'] == 'INCOME',
      category: ExpenseCategory.fromCode(json['category'] as String?),
      description: json['description'] as String,
      amount: json['amount'] as int,
      balance: json['balance'] as int,
    );
  }

  final int id;
  final DateTime date;
  final bool isIncome;

  /// 지출 항목. 수입이면 null.
  final ExpenseCategory? category;
  final String description;
  final int amount;

  /// 이 줄까지 반영한 잔액.
  final int balance;
}

/// 한 달 회계 장부.
class Ledger {
  const Ledger({
    required this.exists,
    required this.year,
    required this.month,
    required this.canEdit,
    required this.carryover,
    required this.entries,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.cumulative,
    required this.donation,
    required this.flower,
    required this.other,
    required this.finalBalance,
    required this.previousCumulative,
    required this.suggestedCarryover,
  });

  factory Ledger.fromJson(Map<String, dynamic> json) {
    final monthly = json['monthly'] as Map<String, dynamic>?;
    final breakdown = json['expenseBreakdown'] as Map<String, dynamic>?;
    return Ledger(
      exists: json['exists'] as bool,
      year: json['year'] as int,
      month: json['month'] as int,
      canEdit: json['canEdit'] as bool? ?? false,
      carryover: LedgerAmounts.fromJson(json['carryover']),
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyIncome: monthly?['income'] as int? ?? 0,
      monthlyExpense: monthly?['expense'] as int? ?? 0,
      cumulative: LedgerAmounts.fromJson(json['cumulative']),
      donation: breakdown?['donation'] as int? ?? 0,
      flower: breakdown?['flower'] as int? ?? 0,
      other: breakdown?['other'] as int? ?? 0,
      finalBalance: json['finalBalance'] as int? ?? 0,
      previousCumulative: LedgerAmounts.fromJson(json['previousCumulative']),
      suggestedCarryover: LedgerAmounts.fromJson(json['suggestedCarryover']),
    );
  }

  final bool exists;
  final int year;
  final int month;
  final bool canEdit;

  /// 전월 이월금. 장부가 없으면 null.
  final LedgerAmounts? carryover;
  final List<LedgerEntry> entries;

  /// 월계.
  final int monthlyIncome;
  final int monthlyExpense;

  /// 누계 = 전월 이월금 + 월계.
  final LedgerAmounts? cumulative;

  /// 지출 내역.
  final int donation;
  final int flower;
  final int other;
  final int finalBalance;

  /// 전월 장부의 누계 (전월 장부가 있을 때).
  final LedgerAmounts? previousCumulative;

  /// 장부가 없을 때 추천 이월금 (전월 장부 누계).
  final LedgerAmounts? suggestedCarryover;

  /// 저장된 이월금이 전월 장부 누계와 다르면 true (전월 장부를 나중에 고친 경우).
  bool get carryoverOutdated {
    final prev = previousCumulative;
    final current = carryover;
    return exists && prev != null && current != null && !current.sameAs(prev);
  }
}

class LedgerService {
  const LedgerService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  static String _path(int year, int month) =>
      '/app/presidiums/me/ledgers/$year-${month.toString().padLeft(2, '0')}';

  Future<Ledger> fetch(int year, int month) async {
    return Ledger.fromJson(await _client.get(_path(year, month)) as Map<String, dynamic>);
  }

  Future<Ledger> create(int year, int month, LedgerAmounts carryover) async {
    final json = await _client.post(_path(year, month), _amounts(carryover));
    return Ledger.fromJson(json as Map<String, dynamic>);
  }

  Future<Ledger> updateCarryover(int year, int month, LedgerAmounts carryover) async {
    final json = await _client.put('${_path(year, month)}/carryover', _amounts(carryover));
    return Ledger.fromJson(json as Map<String, dynamic>);
  }

  Future<Ledger> addEntry(int year, int month, LedgerEntryInput input) async {
    final json = await _client.post('${_path(year, month)}/entries', input.toJson());
    return Ledger.fromJson(json as Map<String, dynamic>);
  }

  Future<Ledger> updateEntry(int year, int month, int entryId, LedgerEntryInput input) async {
    final json = await _client.put('${_path(year, month)}/entries/$entryId', input.toJson());
    return Ledger.fromJson(json as Map<String, dynamic>);
  }

  Future<Ledger> deleteEntry(int year, int month, int entryId) async {
    final json = await _client.delete('${_path(year, month)}/entries/$entryId');
    return Ledger.fromJson(json as Map<String, dynamic>);
  }

  static Map<String, dynamic> _amounts(LedgerAmounts a) =>
      {'income': a.income, 'expense': a.expense, 'balance': a.balance};
}

/// 장부 내역 입력값.
class LedgerEntryInput {
  const LedgerEntryInput({
    required this.date,
    required this.isIncome,
    required this.category,
    required this.description,
    required this.amount,
  });

  final DateTime date;
  final bool isIncome;
  final ExpenseCategory? category;
  final String description;
  final int amount;

  Map<String, dynamic> toJson() => {
        'date': isoDate(date),
        'type': isIncome ? 'INCOME' : 'EXPENSE',
        'category': isIncome ? null : category?.code,
        'description': description,
        'amount': amount,
      };
}
