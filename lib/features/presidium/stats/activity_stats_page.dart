import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import '../governance/governance_models.dart';
import '../governance/governance_service.dart';
import 'activity_stats_service.dart';
import 'horizontal_bar_chart.dart';
import 'stats_period_picker.dart';

/// 활동보고 통계 상세: 기간(기본 이번 주, 연·월·주 선택), 통합/단원별, 활동별·단원별 합계, 월별 추이.
class ActivityStatsPage extends StatefulWidget {
  const ActivityStatsPage({super.key});

  @override
  State<ActivityStatsPage> createState() => _ActivityStatsPageState();
}

class _ActivityStatsPageState extends State<ActivityStatsPage> {
  final _statsService = const ActivityStatsService();
  final _governanceService = const GovernanceService();

  StatsPeriod _period = StatsPeriod.week(weekStartOf(DateTime.now()));
  int? _selectedUserId;
  bool _byMember = false;

  List<PresidiumMember> _members = const [];
  MonthlyActivityStats? _stats;
  YearlyActivityTrend? _trend;
  bool _isLoading = true;
  String? _error;

  /// 이번 주(주 통계) 또는 이번 달(월 통계)이면 더 뒤로 갈 수 없다.
  bool get _isLatest {
    final now = DateTime.now();
    final weekStart = _period.weekStart;
    if (weekStart != null) return !weekStart.isBefore(weekStartOf(now));
    return _period.year == now.year && _period.month == now.month;
  }

  int? get _scopeUserId => _byMember ? _selectedUserId : null;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _load();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _governanceService.fetchMembers();
      if (!mounted) return;
      setState(() => _members = members);
    } on ApiException catch (_) {
      // 단원 목록이 없어도 통합 통계는 볼 수 있다.
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _statsService.fetchPeriod(_period, userId: _scopeUserId),
        _statsService.fetchYearly(year: _period.trendYear, userId: _scopeUserId),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as MonthlyActivityStats;
        _trend = results[1] as YearlyActivityTrend;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    }
  }

  /// 주 통계는 한 주씩, 월 통계는 한 달씩 옮긴다.
  void _move(int delta) {
    final weekStart = _period.weekStart;
    final month = DateTime(_period.year, _period.month + delta);
    _setPeriod(weekStart != null
        ? StatsPeriod.week(DateTime(weekStart.year, weekStart.month, weekStart.day + 7 * delta))
        : StatsPeriod.month(month.year, month.month));
  }

  void _setPeriod(StatsPeriod period) {
    setState(() => _period = period);
    _load();
  }

  Future<void> _pickPeriod() async {
    final picked = await showStatsPeriodPicker(context, _period);
    if (picked != null) _setPeriod(picked);
  }

  String get _periodTitle {
    final weekStart = _period.weekStart;
    if (weekStart == null) return '${_period.year}년 ${_period.month}월';
    return '${weekStart.year}년 ${weekStart.month}월';
  }

  String get _periodSubtitle {
    final weekStart = _period.weekStart;
    if (weekStart == null) return '월 전체';
    final range = '${koreanShortDate(weekStart)} ~ ${koreanShortDate(_period.weekSaturday!)}';
    return weekStart == weekStartOf(DateTime.now()) ? '이번 주 · $range' : range;
  }

  /// 카드 제목에 쓰는 기간 이름.
  String get _periodLabel {
    final weekStart = _period.weekStart;
    if (weekStart == null) return '${_period.month}월';
    if (weekStart == weekStartOf(DateTime.now())) return '이번 주';
    return '${koreanShortDate(weekStart)}~${koreanShortDate(_period.weekSaturday!)}';
  }

  String get _emptyPeriod => _period.isWeek ? '이 주에' : '이 달에';

  void _setScope(bool byMember) {
    setState(() {
      _byMember = byMember;
      if (byMember && _selectedUserId == null) {
        final me = _members.where((m) => m.isMe);
        _selectedUserId = me.isNotEmpty ? me.first.userId : (_members.isNotEmpty ? _members.first.userId : null);
      }
    });
    _load();
  }

  void _selectMember(int userId) {
    setState(() {
      _byMember = true;
      _selectedUserId = userId;
    });
    _load();
  }

  String _memberName(int? userId) {
    for (final m in _members) {
      if (m.userId == userId) return m.displayName;
    }
    for (final m in _stats?.members ?? const <MemberCount>[]) {
      if (m.userId == userId) return m.displayName;
    }
    return '단원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: const Text('활동 통계')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _periodNavigator(),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('통합'), icon: Icon(Icons.groups_outlined)),
                ButtonSegment(value: true, label: Text('단원별'), icon: Icon(Icons.person_outline)),
              ],
              selected: {_byMember},
              onSelectionChanged: (s) => _setScope(s.first),
            ),
            if (_byMember) ...[
              const SizedBox(height: 12),
              _memberPicker(),
            ],
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(padding: const EdgeInsets.all(32), child: Text(_error!, textAlign: TextAlign.center))
            else
              ..._content(),
          ],
        ),
      ),
    );
  }

  /// 가운데 기간 표시를 누르면 연·월·주를 고르는 창이 열린다.
  Widget _periodNavigator() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          IconButton(onPressed: () => _move(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _pickPeriod,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _periodTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.title,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                      ],
                    ),
                    Text(
                      _periodSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.subtitle),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _isLatest ? null : () => _move(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _memberPicker() {
    if (_members.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final m in _members)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(m.isMe ? '${m.displayName} (나)' : m.displayName),
                selected: _selectedUserId == m.userId,
                onSelected: (_) => _selectMember(m.userId),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _content() {
    final stats = _stats!;
    final trend = _trend!;
    final scopeLabel = _byMember ? _memberName(_selectedUserId) : '쁘레시디움 전체';

    return [
      _card(
        title: '$scopeLabel · $_periodLabel 활동',
        trailing: '총 ${stats.totalCount}회',
        child: stats.activities.isEmpty
            ? _empty('$_emptyPeriod 보고된 활동이 없어요.')
            : HorizontalBarChart(
                entries: [for (final a in stats.activities) BarEntry(a.name, a.count)],
              ),
      ),
      if (!_byMember) ...[
        const SizedBox(height: 16),
        _card(
          title: '단원별 합계',
          trailing: '단원을 누르면 개별 통계',
          child: stats.members.isEmpty
              ? _empty('$_emptyPeriod 활동보고를 제출한 단원이 없어요.')
              : HorizontalBarChart(
                  color: AppColors.accentLight,
                  entries: [
                    for (final m in stats.members)
                      BarEntry(m.displayName, m.count, onTap: () => _selectMember(m.userId)),
                  ],
                ),
        ),
      ],
      const SizedBox(height: 16),
      _card(
        title: '${trend.year}년 월별 추이',
        trailing: '총 ${trend.monthCounts.fold<int>(0, (a, b) => a + b)}회',
        child: HorizontalBarChart(
          labelWidth: 40,
          color: AppColors.gold,
          entries: [
            for (var i = 0; i < 12; i++) BarEntry('${i + 1}월', trend.monthCounts[i]),
          ],
        ),
      ),
    ];
  }

  Widget _card({required String title, String? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.title)),
              ),
              if (trailing != null) Text(trailing, style: TextStyle(color: AppColors.subtitle, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppColors.subtitle)),
    );
  }
}
