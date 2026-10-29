import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'volunteer_schedule_detail_page.dart';
import 'volunteer_schedule_form_page.dart';
import 'volunteer_schedule_tile.dart';
import 'volunteer_service.dart';

/// 봉사 일정 전체: 다가오는 일정(가까운 순) + 지난 일정(무한 스크롤). 4간부는 등록할 수 있다.
class VolunteerSchedulePage extends StatefulWidget {
  const VolunteerSchedulePage({super.key, required this.canManage});

  final bool canManage;

  @override
  State<VolunteerSchedulePage> createState() => _VolunteerSchedulePageState();
}

class _VolunteerSchedulePageState extends State<VolunteerSchedulePage> {
  static const _pageSize = 20;

  final _service = const VolunteerService();
  final _scrollController = ScrollController();

  List<VolunteerSchedule> _upcoming = const [];
  final List<VolunteerSchedule> _past = [];
  int _nextPastPage = 0;
  bool _hasMorePast = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final results = await Future.wait([
        _service.fetchUpcoming(limit: 50),
        _service.fetchPast(page: 0, size: _pageSize),
      ]);
      if (!mounted) return;
      final past = results[1] as VolunteerPage;
      setState(() {
        _upcoming = results[0] as List<VolunteerSchedule>;
        _past
          ..clear()
          ..addAll(past.items);
        _nextPastPage = 1;
        _hasMorePast = past.hasNext;
        _isLoading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      _loadMorePast();
    }
  }

  Future<void> _loadMorePast() async {
    if (_isLoadingMore || !_hasMorePast || _isLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service.fetchPast(page: _nextPastPage, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _past.addAll(page.items);
        _nextPastPage++;
        _hasMorePast = page.hasNext;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openDetail(VolunteerSchedule schedule) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VolunteerScheduleDetailPage(schedule: schedule, canManage: widget.canManage),
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<VolunteerSchedule>(
      MaterialPageRoute(builder: (_) => const VolunteerScheduleFormPage()),
    );
    if (created != null) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: const Text('봉사 일정')),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('봉사 등록'),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_error!)));
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _sectionTitle('다가오는 봉사'),
          _section(
            _upcoming.isEmpty
                ? [_emptyText(widget.canManage ? '예정된 봉사가 없어요.\n아래 「봉사 등록」으로 일정을 추가해 보세요.' : '예정된 봉사가 없어요.')]
                : [
                    for (final s in _upcoming)
                      VolunteerScheduleTile(schedule: s, onTap: () => _openDetail(s)),
                  ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('지난 봉사'),
          _section([
            if (_past.isEmpty && !_hasMorePast) _emptyText('지난 봉사가 없어요.'),
            for (final s in _past) VolunteerScheduleTile(schedule: s, dimmed: true, onTap: () => _openDetail(s)),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.title,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _section(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppColors.subtitle, height: 1.5)),
    );
  }
}
