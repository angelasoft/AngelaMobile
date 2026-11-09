import 'package:flutter/material.dart';

import '../../core/ads/ads_config.dart';
import '../../core/ads/native_ad_slot.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_tab_header.dart';
import '../../core/network/api_client.dart';
import '../../core/presidium/current_presidium.dart';
import '../../core/widgets/korean_date.dart';
import '../presidium/governance/governance_service.dart';
import '../presidium/my_presidiums.dart';
import '../presidium/widgets/join_presidium_prompt.dart';
import 'activity_service.dart';
import 'models/activity_report_entry.dart';
import 'widgets/activity_report_row.dart';
import 'widgets/activity_search_bar.dart';

class ActivityReportPage extends StatefulWidget {
  const ActivityReportPage({super.key});

  @override
  State<ActivityReportPage> createState() => _ActivityReportPageState();
}

class _ActivityReportPageState extends State<ActivityReportPage>
    with WidgetsBindingObserver {
  /// 즐겨찾기 저장 기능 전까지 처음 즐겨찾기로 표시할 활동.
  static const _defaultFavoriteNames = {'묵주기도'};

  final _service = const ActivityService();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Map<int, ActivityReportEntry> _entries = {};

  /// 이번 주에 서버에 제출된 보고. 쁘레시디움 미가입 등으로 못 불러오면 null.
  WeeklyActivityReport? _week;
  String? _weekError;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    CurrentPresidium.id.addListener(_onPresidiumChanged);
    _loadActivities();
  }

  /// 쁘레시디움 탭에서 다른 쁘레시디움을 고르면 그 쁘레시디움의 이번 주 보고로 다시 채운다.
  void _onPresidiumChanged() {
    _week = null;
    _loadActivities();
  }

  /// 앱을 다시 열었을 때 주가 바뀌었으면 이번 주 보고(빈 값)로 새로 채운다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _isLoading) return;
    final week = _week;
    if (week == null || weekStartOf(DateTime.now()) != week.weekStart) {
      _loadActivities();
    }
  }

  /// 서버 활동 목록과 이번 주 보고로 갱신한다.
  /// 같은 주 안에서 새로 고치면 아직 제출하지 않은 입력값은 그대로 두고,
  /// 처음 열거나 주가 바뀌었으면 서버에 제출된 이번 주 값으로 채운다.
  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = _entries.isEmpty;
      _loadError = null;
    });
    try {
      final definitions = await _service.fetchActivities();
      final week = await _fetchWeek();
      if (!mounted) return;
      setState(() {
        final weekChanged = week != null && week.weekStart != _week?.weekStart;
        final previous = Map<int, ActivityReportEntry>.of(_entries);
        _entries.clear();
        for (final definition in definitions) {
          final old = previous[definition.id];
          _entries[definition.id] = ActivityReportEntry(
            definition: definition,
            count: weekChanged || old == null
                ? week?.counts[definition.id] ?? 0
                : old.count,
            isFavorite: old?.isFavorite ??
                _defaultFavoriteNames.contains(definition.name),
          );
        }
        if (week != null) _week = week;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ActivityReport] 활동 목록 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e is ActivityServiceException
            ? e.message
            : '활동 목록을 불러오지 못했습니다.\n네트워크 연결을 확인해 주세요.';
      });
    }
  }

  /// 이번 주 보고를 못 불러와도 활동 목록은 보여 준다.
  Future<WeeklyActivityReport?> _fetchWeek() async {
    try {
      final week = await _service.fetchCurrentWeek();
      _weekError = null;
      return week;
    } on ApiException catch (e) {
      debugPrint('[ActivityReport] 이번 주 보고 로드 실패: $e');
      _weekError = e.message;
      return null;
    }
  }

  /// 서버에 제출된 이번 주 값과 화면 입력값이 다르면 true.
  bool get _hasUnsavedChanges {
    final saved = _week?.counts ?? const <int, int>{};
    return _entries.values.any((e) => e.count != (saved[e.id] ?? 0));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CurrentPresidium.id.removeListener(_onPresidiumChanged);
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  /// 검색어로 거른 전체 활동. 즐겨찾기가 위, 그 안에서는 가나다순.
  List<ActivityReportEntry> get _visibleEntries {
    final query = _searchController.text.trim().replaceAll(' ', '');
    final list = _entries.values
        .where((e) => query.isEmpty || e.name.replaceAll(' ', '').contains(query))
        .toList();
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    return list;
  }

  void _toggleFavorite(int id) {
    setState(() {
      final entry = _entries[id]!;
      entry.isFavorite = !entry.isFavorite;
    });
  }

  void _increment(int id) {
    setState(() => _entries[id]!.count++);
  }

  void _decrement(int id) {
    setState(() {
      final entry = _entries[id]!;
      if (entry.count > 0) entry.count--;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {});
  }

  /// 이번 주 누적 횟수 전체를 제출한다. 제출 뒤에도 입력값은 남고, 서버에 저장된 값으로 다시 맞춘다.
  Future<void> _submit() async {
    final reported = _entries.values.where((e) => e.count > 0).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final wasSubmitted = _week?.isSubmitted ?? false;
    if (reported.isEmpty) {
      if (!wasSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보고할 활동 횟수를 1개 이상 입력해 주세요.')),
        );
        return;
      }
      if (!await _confirmClearWeek()) return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.submitReport({for (final e in reported) e.id: e.count});
      final week = await _fetchWeek();
      if (!mounted) return;
      final summary = reported.map((e) => '${e.name} ${e.count}회').join(', ');
      final message = reported.isEmpty
          ? '이번 주 보고를 모두 지웠습니다.'
          : wasSubmitted
              ? '이번 주 보고를 수정했습니다.\n$summary'
              : '쁘레시디움에 제출되었습니다.\n$summary';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
      setState(() {
        if (week != null) {
          _week = week;
          for (final entry in _entries.values) {
            entry.count = week.counts[entry.id] ?? 0;
          }
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _confirmClearWeek() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이번 주 보고 지우기'),
        content: const Text('모든 횟수가 0이에요.\n이번 주에 제출한 보고를 지울까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 목록에 없는 활동을 등록 요청한다. 내 쁘레시디움 4간부 과반이 승인하면 모든 쁘레시디움 목록에 추가된다.
  Future<void> _requestActivity(String initialName) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _ActivityRequestDialog(initialName: initialName.trim()),
    );
    if (name == null || !mounted) return;
    try {
      await const GovernanceService().requestActivity(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("'$name' 활동 등록을 요청했어요.\n4간부가 승인하면 활동 목록에 추가돼요."),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _buildList(List<ActivityReportEntry> visibleEntries, String query) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null && _entries.isEmpty) {
      return _LoadErrorView(message: _loadError!, onRetry: _loadActivities);
    }

    // 목록을 아래로 당기면 서버에서 활동 목록을 다시 불러온다.
    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: visibleEntries.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _EmptyReportList(
                  query: query,
                  onRequest: () => _requestActivity(query),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              // 마지막 줄은 "목록에 없는 활동 등록 요청".
              itemCount: visibleEntries.length + 1,
              itemBuilder: (context, index) {
                if (index == visibleEntries.length) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () => _requestActivity(query),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('찾는 활동이 없나요? 활동 등록 요청'),
                    ),
                  );
                }
                final entry = visibleEntries[index];
                return ActivityReportRow(
                  entry: entry,
                  onFavoriteToggle: () => _toggleFavorite(entry.id),
                  onIncrement: () => _increment(entry.id),
                  onDecrement: () => _decrement(entry.id),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleEntries = _visibleEntries;
    final query = _searchController.text.trim();

    return ColoredBox(
      color: AppColors.backgroundMid,
      child: ValueListenableBuilder<MyPresidiumsState>(
        valueListenable: MyPresidiums.state,
        builder: (context, membership, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTabHeader(
              title: '활동보고',
              actions: [
                IconButton(
                  onPressed: () => MyPresidiums.openSettings(context),
                  icon: const Icon(Icons.settings_outlined),
                  color: AppColors.subtitle,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                  tooltip: '설정',
                ),
              ],
            ),
            if (!membership.loaded)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!membership.joined)
              const Expanded(child: JoinPresidiumPrompt())
            else
              ..._reportBody(visibleEntries, query),
          ],
        ),
      ),
    );
  }

  /// 가입한 쁘레시디움이 있을 때의 활동보고 화면. 광고와 검색창은 위에 고정하고 보고 목록만 스크롤한다.
  List<Widget> _reportBody(List<ActivityReportEntry> visibleEntries, String query) {
    return [
      const NativeAdSlot(
        placement: AdPlacement.activity,
        tabIndex: 1,
        margin: EdgeInsets.fromLTRB(16, 10, 16, 0),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: ActivitySearchBar(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() {}),
          onClear: _clearSearch,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        child: Row(
          children: [
            Text(
              '보고 목록',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 6),
            Text(
              query.isEmpty
                  ? '★ 즐겨찾기가 위에 표시돼요'
                  : '검색 결과 ${visibleEntries.length}개',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.subtitle.withValues(alpha: 0.75),
                  ),
            ),
          ],
        ),
      ),
      Expanded(child: _buildList(visibleEntries, query)),
      _buildSubmitBar(),
    ];
  }

  Widget _buildSubmitBar() {
    final week = _week;
    final submitted = week?.isSubmitted ?? false;
    final dirty = _hasUnsavedChanges;

    final presidiumName = CurrentPresidium.name;
    final String status;
    if (week == null) {
      status = _weekError ?? '이번 주 보고를 불러오는 중이에요.';
    } else {
      final period = '${week.weekStart.month}/${week.weekStart.day}(월)~'
          '${week.weekEnd.month}/${week.weekEnd.day}(일)';
      final updatedAt = week.updatedAt;
      final state = updatedAt == null
          ? '아직 제출 전'
          : dirty
              ? '바꾼 내용은 다시 제출해 주세요'
              : '${koreanShortDate(updatedAt)} ${koreanTime(TimeOfDay.fromDateTime(updatedAt))} 제출됨';
      status = [?presidiumName, '이번 주 $period', state].join(' · ');
    }

    final String label;
    if (!submitted) {
      label = '쁘레시디움 제출';
    } else if (dirty) {
      label = '수정 내용 제출';
    } else {
      label = '이번 주 제출 완료';
    }

    return _SubmitBar(
      status: status,
      highlightStatus: submitted && dirty,
      label: label,
      onSubmit: _isSubmitting || (submitted && !dirty) ? null : _submit,
    );
  }
}

class _EmptyReportList extends StatelessWidget {
  const _EmptyReportList({required this.query, required this.onRequest});

  final String query;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 56,
              color: AppColors.accent.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? '등록된 활동이 없어요.'
                  : "'$query'에 해당하는 활동이 없어요.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtitle.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRequest,
              icon: const Icon(Icons.add),
              label: Text(query.isEmpty ? '활동 등록 요청' : "'$query' 활동 등록 요청"),
            ),
          ],
        ),
      ),
    );
  }
}

/// 등록 요청할 활동 이름을 받는다. 확인하면 다듬은 이름을, 취소하면 null.
class _ActivityRequestDialog extends StatefulWidget {
  const _ActivityRequestDialog({required this.initialName});

  final String initialName;

  @override
  State<_ActivityRequestDialog> createState() => _ActivityRequestDialogState();
}

class _ActivityRequestDialogState extends State<_ActivityRequestDialog> {
  static const _maxLength = 30;
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('활동 등록 요청'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 쁘레시디움 4간부의 과반이 승인하면 모든 쁘레시디움의 활동보고 목록에 추가돼요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtitle, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: _maxLength,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '활동 이름',
                hintText: '예: 본당 꽃꽂이',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: const Text('요청'),
        ),
      ],
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.subtitle.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtitle,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.status,
    required this.highlightStatus,
    required this.label,
    required this.onSubmit,
  });

  /// 이번 주 기간과 제출 상태.
  final String status;
  final bool highlightStatus;
  final String label;

  /// 제출 중이거나 바뀐 내용 없이 이미 제출했으면 null (버튼 비활성).
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.shadow.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              status,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: highlightStatus ? AppColors.accent : AppColors.subtitle,
                    fontWeight: highlightStatus ? FontWeight.w600 : null,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
