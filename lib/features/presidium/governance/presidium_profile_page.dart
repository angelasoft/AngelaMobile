import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import 'presidium_profile.dart';
import 'presidium_profile_edit_page.dart';

/// 쁘레시디움 정보: 이번 주 주회합 차수, 설립일·승인일·주회합 일정, 휴회 주. 4간부만 수정한다.
class PresidiumProfilePage extends StatefulWidget {
  const PresidiumProfilePage({super.key, required this.presidiumName});

  final String presidiumName;

  @override
  State<PresidiumProfilePage> createState() => _PresidiumProfilePageState();
}

class _PresidiumProfilePageState extends State<PresidiumProfilePage> {
  final _service = const PresidiumProfileService();

  PresidiumProfile? _profile;
  String? _error;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _service.fetch();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<PresidiumProfile>(
      MaterialPageRoute(builder: (_) => PresidiumProfileEditPage(profile: _profile!)),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  /// 4간부: 결과를 받아 화면에 반영하는 공통 처리.
  Future<void> _run(Future<PresidiumProfile> Function() action, String doneMessage) async {
    setState(() => _isBusy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _profile = updated);
      _showMessage(doneMessage);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _matchNumber() async {
    final profile = _profile!;
    final actual = await showDialog<int>(
      context: context,
      builder: (_) => _MatchNumberDialog(recess: profile.thisWeekRecess),
    );
    if (actual == null) return;
    final offset = profile.offsetToMatch(actual);
    if (offset == null) return;
    await _run(() => _service.saveOffset(profile, offset), '주회합 차수를 제$actual차로 맞췄어요.');
  }

  Future<void> _addRecess() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      helpText: '휴회할 주의 아무 날짜나 고르세요',
      initialDate: now,
      firstDate: _profile?.approvedDate ?? DateTime(1921),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (date == null || !mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RecessReasonDialog(weekStart: weekStartOf(date)),
    );
    if (reason == null) return;
    await _run(
      () => _service.addRecess(date, reason: reason.isEmpty ? null : reason),
      '휴회 주를 등록했어요. 이 주는 차수에서 빠져요.',
    );
  }

  Future<void> _removeRecess(PresidiumRecess recess) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('휴회 기록을 지울까요?'),
        content: Text('${recess.weekLabel}\n지우면 이 주도 주회합 차수에 들어가요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('지우기')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _service.removeRecess(recess.id), '휴회 기록을 지웠어요.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(
        title: const Text('쁘레시디움 정보'),
        backgroundColor: Colors.white,
        actions: [
          if (profile?.canEdit ?? false)
            TextButton.icon(
              onPressed: _isBusy ? null : _edit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('수정'),
            ),
        ],
      ),
      body: profile == null
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
                  _ThisWeekMeetingCard(
                    presidiumName: widget.presidiumName,
                    profile: profile,
                    onMatchNumber: profile.canEdit && profile.offsetToMatch(1) != null && !_isBusy
                        ? _matchNumber
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _infoCard(profile),
                  if (profile.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, left: 4),
                      child: Text(
                        profile.canEdit
                            ? '오른쪽 위 수정을 눌러 쁘레시디움 정보를 입력해 주세요.'
                            : '아직 입력된 정보가 없어요. 4간부가 입력하면 여기에 보여요.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _councilSection(profile),
                  const SizedBox(height: 24),
                  _recessSection(profile),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(PresidiumProfile profile) {
    String dateOrDash(DateTime? date) => date == null ? '-' : koreanFullDate(date);
    final offset = profile.meetingNumberOffset;
    final rows = [
      ('설립일', dateOrDash(profile.foundedDate), Icons.flag_outlined),
      ('승인일', dateOrDash(profile.approvedDate), Icons.verified_outlined),
      ('주회합', profile.meetingScheduleLabel ?? '-', Icons.schedule),
      ('회합 장소', (profile.meetingPlace?.isNotEmpty ?? false) ? profile.meetingPlace! : '-', Icons.place_outlined),
      if (offset != 0) ('차수 보정', '${offset > 0 ? '+' : ''}$offset차', Icons.tune),
    ];
    return _card([
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) _divider(),
        ListTile(
          leading: Icon(rows[i].$3, color: AppColors.accent),
          title: Text(rows[i].$1, style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
          subtitle: Text(
            rows[i].$2,
            style: const TextStyle(color: AppColors.title, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ]);
  }

  Future<void> _editCouncil() async {
    final result = await showDialog<_CouncilInput>(
      context: context,
      builder: (_) => _CouncilDialog(council: _profile!.council),
    );
    if (result == null) return;
    await _run(
      () => _service.saveCouncil(
        weekOfMonth: result.weekOfMonth,
        day: result.day,
        time: result.time,
        place: result.place,
      ),
      result.weekOfMonth == null ? '평의회 월례회의 일정을 지웠어요.' : '평의회 월례회의 일정을 저장했어요.',
    );
  }

  Widget _councilSection(PresidiumProfile profile) {
    final council = profile.council;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '평의회 월례회의${council.curiaName == null ? '' : ' (${council.curiaName})'}',
                      style: textTheme.titleSmall?.copyWith(color: AppColors.title, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '같은 평의회의 모든 쁘레시디움이 함께 보는 일정이에요.',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
                    ),
                  ],
                ),
              ),
              if (profile.canEdit)
                TextButton.icon(
                  onPressed: _isBusy ? null : _editCouncil,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(council.isSet ? '수정' : '입력'),
                ),
            ],
          ),
        ),
        _card([
          ListTile(
            leading: const Icon(Icons.groups_outlined, color: AppColors.accent),
            title: const Text('일정', style: TextStyle(color: AppColors.subtitle, fontSize: 13)),
            subtitle: Text(
              council.label ?? '-',
              style: const TextStyle(color: AppColors.title, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          _divider(),
          ListTile(
            leading: const Icon(Icons.place_outlined, color: AppColors.accent),
            title: const Text('장소', style: TextStyle(color: AppColors.subtitle, fontSize: 13)),
            subtitle: Text(
              (council.place?.isNotEmpty ?? false) ? council.place! : '-',
              style: const TextStyle(color: AppColors.title, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (council.nextDate != null) ...[
            _divider(),
            ListTile(
              leading: const Icon(Icons.event_outlined, color: AppColors.accent),
              title: const Text('다음 월례회의', style: TextStyle(color: AppColors.subtitle, fontSize: 13)),
              subtitle: Text(
                koreanFullDate(council.nextDate!),
                style: const TextStyle(color: AppColors.title, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ]),
      ],
    );
  }

  Widget _recessSection(PresidiumProfile profile) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '휴회 주 (${profile.recesses.length})',
                      style: textTheme.titleSmall?.copyWith(color: AppColors.title, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '주회합을 쉰 주는 차수에서 빠져요.',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
                    ),
                  ],
                ),
              ),
              if (profile.canEdit)
                TextButton.icon(
                  onPressed: _isBusy ? null : _addRecess,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('휴회 등록'),
                ),
            ],
          ),
        ),
        if (profile.recesses.isEmpty)
          _card([
            const ListTile(
              title: Text('등록된 휴회 주가 없어요.', style: TextStyle(color: AppColors.subtitle)),
            ),
          ])
        else
          _card([
            for (var i = 0; i < profile.recesses.length; i++) ...[
              if (i > 0) _divider(),
              ListTile(
                dense: true,
                leading: const Icon(Icons.event_busy_outlined, color: AppColors.subtitle),
                title: Text(
                  profile.recesses[i].weekLabel,
                  style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w600),
                ),
                subtitle: profile.recesses[i].reason == null ? null : Text(profile.recesses[i].reason!),
                trailing: profile.canEdit
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '지우기',
                        onPressed: _isBusy ? null : () => _removeRecess(profile.recesses[i]),
                      )
                    : null,
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

class _ThisWeekMeetingCard extends StatelessWidget {
  const _ThisWeekMeetingCard({required this.presidiumName, required this.profile, this.onMatchNumber});

  final String presidiumName;
  final PresidiumProfile profile;

  /// 4간부만: 실제 차수로 맞추기.
  final VoidCallback? onMatchNumber;

  @override
  Widget build(BuildContext context) {
    final number = profile.thisWeekMeetingNumber;
    final date = profile.thisWeekMeetingDate;
    final String headline;
    final String detail;
    if (profile.thisWeekRecess) {
      headline = '이번 주는 휴회예요';
      detail = [
        if (profile.thisWeekRecessReason != null) profile.thisWeekRecessReason!,
        if (profile.nextMeetingNumber != null) '다음 회합은 제${profile.nextMeetingNumber}차',
      ].join(' · ');
    } else if (profile.approvedDate == null) {
      headline = '주회합 차수를 계산할 수 없어요';
      detail = '승인일을 입력하면 이번 주 회합이 몇 차인지 보여 드려요.';
    } else if (number == null) {
      headline = '아직 첫 주회합 전이에요';
      detail = '승인일 ${koreanFullDate(profile.approvedDate!)} 이후 첫 회합이 제1차예요.';
    } else {
      headline = '이번 주 제$number차 주회합';
      detail = [
        if (date != null) koreanMonthDay(date),
        if (profile.meetingTime != null) koreanTime(profile.meetingTime!),
        if (profile.meetingPlace?.isNotEmpty ?? false) profile.meetingPlace!,
      ].join(' · ');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.title],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(presidiumName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            headline,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
          if (onMatchNumber != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onMatchNumber,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('차수 맞추기'),
              ),
            ),
        ],
      ),
    );
  }
}

/// 이번 주(휴회면 다음 회합) 실제 차수 입력.
class _MatchNumberDialog extends StatefulWidget {
  const _MatchNumberDialog({required this.recess});

  final bool recess;

  @override
  State<_MatchNumberDialog> createState() => _MatchNumberDialogState();
}

class _MatchNumberDialogState extends State<_MatchNumberDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('주회합 차수 맞추기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recess
                ? '회합록에 적을 다음 회합의 실제 차수를 입력하세요. 앞으로도 이 차수에 맞춰 이어서 세요.'
                : '회합록에 적는 이번 주 실제 차수를 입력하세요. 앞으로도 이 차수에 맞춰 이어서 세요.',
            style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            decoration: InputDecoration(
              prefixText: '제 ',
              suffixText: '차',
              hintText: widget.recess ? '다음 회합 차수' : '이번 주 차수',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: _submit, child: const Text('맞추기')),
      ],
    );
  }
}

class _CouncilInput {
  const _CouncilInput({this.weekOfMonth, this.day, this.time, this.place});

  final int? weekOfMonth;
  final String? day;
  final TimeOfDay? time;
  final String? place;
}

/// 평의회 월례회의: 매달 몇째 주 무슨 요일, 시간, 장소.
class _CouncilDialog extends StatefulWidget {
  const _CouncilDialog({required this.council});

  final CouncilSchedule council;

  @override
  State<_CouncilDialog> createState() => _CouncilDialogState();
}

class _CouncilDialogState extends State<_CouncilDialog> {
  late int? _week = widget.council.weekOfMonth;
  late String? _day = widget.council.day;
  late TimeOfDay? _time = widget.council.time;
  late final _placeController = TextEditingController(text: widget.council.place ?? '');

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  bool get _valid => (_week == null) == (_day == null);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('평의회 월례회의 일정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('매달', style: TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in councilWeekLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _week == entry.key,
                    onSelected: (selected) => setState(() => _week = selected ? entry.key : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < meetingDayCodes.length; i++)
                  ChoiceChip(
                    label: Text(meetingDayLabels[i].substring(0, 1)),
                    selected: _day == meetingDayCodes[i],
                    onSelected: (selected) => setState(() => _day = selected ? meetingDayCodes[i] : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule, size: 18),
              label: Text(_time == null ? '시간 선택' : koreanTime(_time!)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _placeController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: '장소', hintText: '예) 본당 대성전'),
            ),
            if (!_valid)
              const Text('주차와 요일을 함께 골라 주세요.', style: TextStyle(color: Color(0xFFD9534F), fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(
                    context,
                    _CouncilInput(
                      weekOfMonth: _week,
                      day: _day,
                      time: _time,
                      place: _placeController.text.trim(),
                    ),
                  )
              : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}

/// 휴회 사유 입력. 취소하면 null, 사유 없이 등록하면 빈 문자열.
class _RecessReasonDialog extends StatefulWidget {
  const _RecessReasonDialog({required this.weekStart});

  final DateTime weekStart;

  @override
  State<_RecessReasonDialog> createState() => _RecessReasonDialogState();
}

class _RecessReasonDialogState extends State<_RecessReasonDialog> {
  static const _presets = ['성탄 휴회', '부활 휴회', '여름 휴회', '본당 행사'];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = widget.weekStart.add(const Duration(days: 6));
    return AlertDialog(
      title: const Text('휴회 등록'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${koreanShortDate(widget.weekStart)} ~ ${koreanShortDate(weekEnd)}',
              style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 50,
              decoration: const InputDecoration(labelText: '사유 (선택)'),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in _presets)
                  ActionChip(
                    label: Text(preset),
                    onPressed: () => setState(() => _controller.text = preset),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: const Text('등록')),
      ],
    );
  }
}
