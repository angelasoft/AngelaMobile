import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import '../governance/presidium_profile_page.dart';
import 'attendance_service.dart';

/// 주회합·평의회 출석부. 회합 당일 회합 시간부터 자정 전까지 4간부가 출석을 체크하고, 모든 단원이 본다.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key, required this.kind, required this.presidiumName});

  final AttendanceKind kind;
  final String presidiumName;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _service = const AttendanceService();

  AttendanceOverview? _overview;
  String? _error;
  Set<int> _present = {};
  bool _dirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final overview = await _service.fetch(widget.kind);
      if (!mounted) return;
      setState(() => _apply(overview));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  void _apply(AttendanceOverview overview) {
    _overview = overview;
    _error = null;
    _present = {for (final e in overview.roster) if (e.present == true) e.userId};
    _dirty = false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final overview = await _service.save(widget.kind, _present);
      if (!mounted) return;
      setState(() => _apply(overview));
      _showMessage('출석부를 저장했어요. (출석 ${_present.length}명)');
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PresidiumProfilePage(presidiumName: widget.presidiumName)),
    );
    await _load();
  }

  Future<void> _openSession(AttendanceSessionSummary session) async {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SessionSheet(kind: widget.kind, session: session, service: _service),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final editing = overview != null && overview.canEdit;
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: Text(widget.kind.title), backgroundColor: Colors.white),
      bottomNavigationBar: editing
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSaving || (!_dirty && overview.recorded) ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(overview.recorded ? '수정 저장 (출석 ${_present.length}명)' : '저장 (출석 ${_present.length}명)'),
                  ),
                ),
              ),
            )
          : null,
      body: overview == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(_error!, style: const TextStyle(color: AppColors.subtitle)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _statusCard(overview),
                  if (overview.open) ...[
                    const SizedBox(height: 16),
                    _rosterSection(overview),
                  ],
                  const SizedBox(height: 16),
                  _monthCard(overview.month),
                  const SizedBox(height: 16),
                  _historySection(overview),
                ],
              ),
            ),
    );
  }

  Widget _statusCard(AttendanceOverview o) {
    final String headline;
    final String detail;
    if (!o.configured) {
      headline = '${widget.kind.meetingName} 일정이 없어요';
      detail = widget.kind == AttendanceKind.presidium
          ? '쁘레시디움 정보에서 주회합 요일과 시간을 입력하면 회합 날 이 시간부터 출석부가 열려요.'
          : '쁘레시디움 정보에서 평의회 월례회의 일정(몇째 주 무슨 요일·시간)을 입력하면 회합 날 출석부가 열려요.';
    } else if (o.open) {
      final number = o.meetingNumber == null ? '' : '제${o.meetingNumber}차 ';
      headline = '오늘 $number${widget.kind.meetingName}';
      detail = [
        if (o.meetingTime != null) koreanTime(o.meetingTime!),
        if (o.meetingPlace?.isNotEmpty ?? false) o.meetingPlace!,
        o.recorded ? '출석부 저장됨' : (o.canEdit ? '출석을 체크해 주세요' : '4간부가 출석을 체크해요'),
      ].join(' · ');
    } else {
      headline = '다음 ${widget.kind.meetingName}: ${o.meetingWhenLabel ?? '-'}';
      detail = '출석부는 회합 날 회합 시간부터 그날 자정 전까지 열려요.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: o.open ? const [AppColors.accent, AppColors.title] : [AppColors.subtitle, AppColors.title],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(o.open ? Icons.lock_open : Icons.lock_clock, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(o.open ? '출석부 열림' : '출석부 닫힘', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(headline, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(detail, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          if (!o.configured)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openProfile,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('쁘레시디움 정보 열기'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rosterSection(AttendanceOverview o) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '오늘 명단 · 출석 ${_present.length} / ${o.roster.length}',
                  style: textTheme.titleSmall?.copyWith(color: AppColors.title, fontWeight: FontWeight.w700),
                ),
              ),
              if (o.canEdit)
                TextButton(
                  onPressed: () => setState(() {
                    final all = _present.length == o.roster.length;
                    _present = all ? {} : {for (final e in o.roster) e.userId};
                    _dirty = true;
                  }),
                  child: Text(_present.length == o.roster.length ? '모두 해제' : '모두 출석'),
                ),
            ],
          ),
        ),
        if (o.roster.isEmpty)
          _card([
            ListTile(
              title: Text(
                widget.kind == AttendanceKind.council ? '간부가 없어요.' : '행동단원이 없어요.',
                style: const TextStyle(color: AppColors.subtitle),
              ),
            ),
          ])
        else
          _card([
            for (var i = 0; i < o.roster.length; i++) ...[
              if (i > 0) _divider(),
              _rosterTile(o, o.roster[i]),
            ],
          ]),
      ],
    );
  }

  Widget _rosterTile(AttendanceOverview o, AttendanceEntry entry) {
    final present = _present.contains(entry.userId);
    final title = Text(
      entry.officerLabel == null ? entry.displayName : '${entry.displayName} · ${entry.officerLabel}',
      style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600),
    );
    if (o.canEdit) {
      return CheckboxListTile(
        dense: true,
        value: present,
        title: title,
        activeColor: AppColors.accent,
        onChanged: (checked) => setState(() {
          checked == true ? _present.add(entry.userId) : _present.remove(entry.userId);
          _dirty = true;
        }),
      );
    }
    return ListTile(
      dense: true,
      title: title,
      trailing: _presenceBadge(entry.present),
    );
  }

  Widget _monthCard(AttendanceMonth m) {
    final isPresidium = widget.kind == AttendanceKind.presidium;
    return _card([
      ListTile(
        leading: const Icon(Icons.insert_chart_outlined, color: AppColors.accent),
        title: Text('${m.month}월 출석 (회합 ${m.meetings}회)',
            style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w700)),
        subtitle: Text(
          m.meetings == 0
              ? '이번 달에 저장된 출석부가 없어요.'
              : isPresidium
                  ? '간부 ${m.officerPresent} / ${m.officerTotal}    단원 ${m.memberPresent} / ${m.memberTotal}'
                  : '간부 ${m.officerPresent} / ${m.officerTotal}',
          style: const TextStyle(color: AppColors.title, fontSize: 15),
        ),
      ),
    ]);
  }

  Widget _historySection(AttendanceOverview o) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '지난 출석부',
            style: textTheme.titleSmall?.copyWith(color: AppColors.title, fontWeight: FontWeight.w700),
          ),
        ),
        if (o.history.isEmpty)
          _card([
            const ListTile(title: Text('아직 저장된 출석부가 없어요.', style: TextStyle(color: AppColors.subtitle))),
          ])
        else
          _card([
            for (var i = 0; i < o.history.length; i++) ...[
              if (i > 0) _divider(),
              ListTile(
                dense: true,
                title: Text(
                  [
                    koreanFullDate(o.history[i].meetingDate),
                    if (o.history[i].meetingNumber != null) '제${o.history[i].meetingNumber}차',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('출석 ${o.history[i].presentCount} / ${o.history[i].totalCount}',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    const Icon(Icons.chevron_right, color: AppColors.subtitle),
                  ],
                ),
                onTap: () => _openSession(o.history[i]),
              ),
            ],
          ]),
      ],
    );
  }

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _divider() => Divider(height: 1, indent: 16, color: AppColors.shadow.withValues(alpha: 0.08));
}

Widget _presenceBadge(bool? present) {
  final (label, color) = switch (present) {
    true => ('출석', const Color(0xFF2E9E5B)),
    false => ('결석', const Color(0xFFD9534F)),
    null => ('미체크', AppColors.subtitle),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

/// 지난 출석부 명단.
class _SessionSheet extends StatelessWidget {
  const _SessionSheet({required this.kind, required this.session, required this.service});

  final AttendanceKind kind;
  final AttendanceSessionSummary session;
  final AttendanceService service;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => FutureBuilder<List<AttendanceEntry>>(
        future: service.fetchRecords(session.id),
        builder: (context, snapshot) {
          final records = snapshot.data;
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(
                [
                  koreanFullDate(session.meetingDate),
                  if (session.meetingNumber != null) '제${session.meetingNumber}차',
                ].join(' · '),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.title,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text('${kind.title} · 출석 ${session.presentCount} / ${session.totalCount}',
                  style: const TextStyle(color: AppColors.subtitle)),
              const SizedBox(height: 12),
              if (snapshot.hasError)
                const Text('명단을 불러오지 못했어요.', style: TextStyle(color: AppColors.subtitle))
              else if (records == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final r in records)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.officerLabel == null ? r.displayName : '${r.displayName} · ${r.officerLabel}'),
                    trailing: _presenceBadge(r.present),
                  ),
            ],
          );
        },
      ),
    );
  }
}
