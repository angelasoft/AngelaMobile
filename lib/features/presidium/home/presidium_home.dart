import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../activity_report/activity_service.dart';
import '../../../core/widgets/won_format.dart';
import '../ledger/ledger_page.dart';
import '../ledger/ledger_service.dart';
import '../models/presidium_info.dart';
import '../notice/notice_list_page.dart';
import '../notice/notice_service.dart';
import '../notice/notice_tile.dart';
import '../stats/activity_stats_page.dart';
import '../stats/activity_stats_service.dart';
import '../stats/horizontal_bar_chart.dart';
import '../volunteer/volunteer_schedule_page.dart';
import '../volunteer/volunteer_schedule_tile.dart';
import '../volunteer/volunteer_service.dart';

/// 가입한 쁘레시디움 첫 화면: 공지사항 · 봉사 일정 · 이번 달 활동 통계 · 회계 보고 카드.
class PresidiumHome extends StatefulWidget {
  const PresidiumHome({super.key, required this.presidium});

  final PresidiumInfo presidium;

  @override
  State<PresidiumHome> createState() => _PresidiumHomeState();
}

class _PresidiumHomeState extends State<PresidiumHome> {
  static const _statsPreviewCount = 5;

  final _noticeService = const NoticeService();
  final _volunteerService = const VolunteerService();
  final _statsService = const ActivityStatsService();
  final _ledgerService = const LedgerService();

  List<Notice>? _notices;
  List<VolunteerSchedule>? _upcoming;
  MonthlyActivityStats? _stats;
  Ledger? _ledger;
  String? _noticeError;
  String? _scheduleError;
  String? _statsError;
  String? _ledgerError;

  @override
  void initState() {
    super.initState();
    ActivityReportEvents.submitted.addListener(_loadStats);
    _loadAll();
  }

  @override
  void dispose() {
    ActivityReportEvents.submitted.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadAll() => Future.wait([_loadNotices(), _loadSchedules(), _loadStats(), _loadLedger()]);

  Future<void> _loadLedger() async {
    final now = DateTime.now();
    try {
      final ledger = await _ledgerService.fetch(now.year, now.month);
      if (!mounted) return;
      setState(() {
        _ledger = ledger;
        _ledgerError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _ledgerError = e.message);
    }
  }

  Future<void> _openLedger() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LedgerPage()));
    await _loadLedger();
  }

  Future<void> _loadNotices() async {
    try {
      final page = await _noticeService.fetchPage(page: 0, size: 3);
      if (!mounted) return;
      setState(() {
        _notices = page.items;
        _noticeError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _noticeError = e.message);
    }
  }

  Future<void> _openNotices() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoticeListPage(canManage: widget.presidium.isOfficer)),
    );
    await _loadNotices();
  }

  Future<void> _loadSchedules() async {
    try {
      final upcoming = await _volunteerService.fetchUpcoming(limit: 3);
      if (!mounted) return;
      setState(() {
        _upcoming = upcoming;
        _scheduleError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _scheduleError = e.message);
    }
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    try {
      final stats = await _statsService.fetchMonthly(year: now.year, month: now.month);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _statsError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _statsError = e.message);
    }
  }

  Future<void> _openSchedules() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VolunteerSchedulePage(canManage: widget.presidium.isOfficer),
      ),
    );
    await _loadSchedules();
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ActivityStatsPage()));
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _HomeCard(
            icon: Icons.campaign_outlined,
            title: '공지사항',
            subtitle: widget.presidium.isOfficer ? '눌러서 공지 보기·등록' : '최근 공지',
            onTap: _openNotices,
            child: _noticeContent(),
          ),
          const SizedBox(height: 14),
          _HomeCard(
            icon: Icons.volunteer_activism_outlined,
            title: '봉사 일정',
            subtitle: widget.presidium.isOfficer ? '눌러서 일정 보기·등록' : '다가오는 봉사',
            onTap: _openSchedules,
            child: _scheduleContent(),
          ),
          const SizedBox(height: 14),
          _HomeCard(
            icon: Icons.bar_chart_rounded,
            title: '${DateTime.now().month}월 활동 통계',
            subtitle: _stats == null ? null : '총 ${_stats!.totalCount}회',
            onTap: _openStats,
            child: _statsContent(),
          ),
          const SizedBox(height: 14),
          _HomeCard(
            icon: Icons.account_balance_wallet_outlined,
            title: '${DateTime.now().month}월 회계 보고',
            subtitle: widget.presidium.isOfficer ? '눌러서 장부 보기·작성' : '눌러서 장부 보기',
            onTap: _openLedger,
            child: _ledgerContent(),
          ),
        ],
      ),
    );
  }

  Widget _noticeContent() {
    if (_noticeError != null && _notices == null) return _message(_noticeError!);
    final notices = _notices;
    if (notices == null) return const _CardLoading();
    if (notices.isEmpty) {
      return _message(widget.presidium.isOfficer ? '공지사항이 없어요. 눌러서 공지를 등록해 보세요.' : '공지사항이 없어요.');
    }
    return Column(
      children: [
        for (var i = 0; i < notices.length; i++) ...[
          if (i > 0) Divider(height: 1, color: AppColors.shadow.withValues(alpha: 0.1)),
          NoticeTile(notice: notices[i]),
        ],
      ],
    );
  }

  Widget _scheduleContent() {
    if (_scheduleError != null && _upcoming == null) return _message(_scheduleError!);
    final upcoming = _upcoming;
    if (upcoming == null) return const _CardLoading();
    if (upcoming.isEmpty) {
      return _message(widget.presidium.isOfficer ? '예정된 봉사가 없어요. 눌러서 일정을 등록해 보세요.' : '예정된 봉사가 없어요.');
    }
    return Column(
      children: [
        for (var i = 0; i < upcoming.length; i++) ...[
          if (i > 0) Divider(height: 1, color: AppColors.shadow.withValues(alpha: 0.1)),
          VolunteerScheduleTile(schedule: upcoming[i]),
        ],
      ],
    );
  }

  Widget _statsContent() {
    if (_statsError != null && _stats == null) return _message(_statsError!);
    final stats = _stats;
    if (stats == null) return const _CardLoading();
    if (stats.activities.isEmpty) return _message('이번 달에 보고된 활동이 아직 없어요.');

    final preview = stats.activities.take(_statsPreviewCount).toList();
    final rest = stats.activities.length - preview.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HorizontalBarChart(entries: [for (final a in preview) BarEntry(a.name, a.count)]),
        if (rest > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '외 $rest개 활동 · 눌러서 전체 통계 보기',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.subtitle, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _ledgerContent() {
    if (_ledgerError != null && _ledger == null) return _message(_ledgerError!);
    final ledger = _ledger;
    if (ledger == null) return const _CardLoading();
    if (!ledger.exists) {
      return _message(widget.presidium.isOfficer
          ? '이번 달 장부가 아직 없어요. 눌러서 전월 이월금을 입력해 주세요.'
          : '이번 달 장부가 아직 없어요.');
    }
    Widget amount(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label, style: TextStyle(color: AppColors.subtitle, fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${formatWon(value)}원', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          amount('수입', ledger.monthlyIncome, const Color(0xFF2E7D4F)),
          amount('지출', ledger.monthlyExpense, const Color(0xFFC0504D)),
          amount('잔액', ledger.finalBalance, AppColors.accent),
        ],
      ),
    );
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: AppColors.subtitle, height: 1.5)),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.shadow.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: onTap == null ? AppColors.subtitle : AppColors.accent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.title),
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: AppColors.subtitle, fontSize: 12)),
                  if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.subtitle),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CardLoading extends StatelessWidget {
  const _CardLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
    );
  }
}
