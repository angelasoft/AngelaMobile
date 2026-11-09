import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/korean_date.dart';
import '../../../core/widgets/relative_time.dart';
import 'governance_models.dart';
import 'governance_service.dart';
import 'officer_term_dialog.dart';

/// 간부 이동: 현재 4간부와 임기, 진행 중인 투표(찬반)·당선자 임명, 지난 투표 결과.
/// 4간부는 새 투표를 시작하고 간부 임기를 입력할 수 있다.
class OfficerElectionPage extends StatefulWidget {
  const OfficerElectionPage({super.key});

  @override
  State<OfficerElectionPage> createState() => _OfficerElectionPageState();
}

class _OfficerElectionPageState extends State<OfficerElectionPage> {
  final _service = const GovernanceService();

  List<PresidiumMember> _members = const [];
  List<OfficerElectionItem> _elections = const [];
  bool _isLoading = true;
  String? _error;
  int? _votingElectionId;
  int? _busyElectionId;

  bool get _iAmOfficer => _members.any((m) => m.isMe && m.officerRole != null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_service.fetchMembers(), _service.fetchElections()]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<PresidiumMember>;
        _elections = results[1] as List<OfficerElectionItem>;
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

  Future<void> _vote(OfficerElectionItem election, bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? '찬성하시겠어요?' : '반대하시겠어요?'),
        content: Text(
          '${election.candidateName} 단원의 ${election.positionLabel} 임명에 '
          '${approve ? '찬성' : '반대'}합니다.\n투표 후에는 바꿀 수 없어요.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('투표')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _votingElectionId = election.id);
    try {
      final result = await _service.vote(election.id, approve: approve);
      if (result.isElected) {
        _showMessage('${result.candidateName} 단원이 ${result.positionLabel}에 당선되었습니다. 임명일을 정해 임명해 주세요.');
      } else if (result.status == 'REJECTED') {
        _showMessage('${result.positionLabel} 임명 투표가 부결되었습니다.');
      } else {
        _showMessage('투표했습니다.');
      }
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _votingElectionId = null);
    }
  }

  Future<void> _appoint(OfficerElectionItem election) async {
    final term = await showOfficerTermDialog(
      context,
      title: '${election.positionLabel} 임명',
      description: '${election.candidateName} 단원을 ${election.positionLabel}(으)로 임명해요. '
          '같은 직책의 이전 간부는 물러나요.',
      confirmLabel: '임명',
    );
    if (term == null) return;

    setState(() => _busyElectionId = election.id);
    try {
      final result = await _service.appoint(
        election.id,
        appointedDate: term.appointedDate,
        termYears: term.years,
        termMonths: term.months,
      );
      _showMessage('${result.candidateName} 단원이 ${result.positionLabel}에 임명되었습니다.');
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
      await _load();
    } finally {
      if (mounted) setState(() => _busyElectionId = null);
    }
  }

  Future<void> _cancelElected(OfficerElectionItem election) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('당선을 취소할까요?'),
        content: Text('${election.candidateName} 단원을 ${election.positionLabel}(으)로 임명하지 않고 투표를 취소해요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('당선 취소')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyElectionId = election.id);
    try {
      await _service.cancelElected(election.id);
      _showMessage('당선을 취소했습니다.');
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _busyElectionId = null);
    }
  }

  /// 4간부: 지금 간부의 임명일·임기 입력 (앱을 쓰기 전에 임명된 간부는 지난 날짜로).
  Future<void> _editTerm(PresidiumMember officer) async {
    final term = await showOfficerTermDialog(
      context,
      title: '${officer.officerLabel} 임기',
      description: '${officer.displayName} 단원의 임명일과 임기를 입력해요.',
      confirmLabel: '저장',
      initialDate: officer.officerAppointedDate,
      initialTermMonths: officer.officerTermMonths,
    );
    if (term == null) return;

    try {
      await _service.updateOfficerTerm(
        officer.userId,
        appointedDate: term.appointedDate,
        termYears: term.years,
        termMonths: term.months,
      );
      _showMessage('${officer.officerLabel} 임기를 저장했습니다.');
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _openStartSheet() async {
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StartElectionSheet(
        members: _members.where((m) => m.isActive).toList(),
        busyPositions: _elections.where((e) => e.isActive).map((e) => e.positionLabel).toSet(),
        service: _service,
      ),
    );
    if (started == true) {
      _showMessage('투표를 시작했습니다. 행동단원에게 알림이 전송되었습니다.');
      await _load();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: const Text('간부 이동'), backgroundColor: Colors.white),
      floatingActionButton: !_isLoading && _iAmOfficer
          ? FloatingActionButton.extended(
              onPressed: _openStartSheet,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.how_to_vote_outlined),
              label: const Text('투표 시작'),
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

    final open = _elections.where((e) => e.isActive).toList();
    final closed = _elections.where((e) => !e.isActive).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _SectionTitle('현재 4간부'),
          _OfficersCard(members: _members, onEditTerm: _iAmOfficer ? _editTerm : null),
          const SizedBox(height: 20),
          _SectionTitle('진행 중인 투표·임명'),
          if (open.isEmpty)
            _EmptyCard(
              _iAmOfficer
                  ? '진행 중인 투표가 없어요.\n아래 「투표 시작」으로 간부를 임명할 수 있어요.'
                  : '진행 중인 투표가 없어요.',
            )
          else
            for (final e in open)
              _ElectionCard(
                election: e,
                isVoting: _votingElectionId == e.id || _busyElectionId == e.id,
                onVote: (approve) => _vote(e, approve),
                onAppoint: e.canAppoint ? () => _appoint(e) : null,
                onCancel: e.isElected && _iAmOfficer ? () => _cancelElected(e) : null,
              ),
          if (closed.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle('지난 투표'),
            for (final e in closed) _ElectionCard(election: e),
          ],
          const SizedBox(height: 12),
          Text(
            '· 투표 시작 시점의 행동단원 과반이 찬성하면 당선돼요.\n'
            '· 당선되면 4간부나 당선자가 임명일·임기를 정해 「간부 임명」을 눌러요.\n'
            '· 과반 찬성이 불가능해지면 부결되고, 7일이 지나면 자동으로 종료돼요.\n'
            '· 간부 임기가 끝나기 한 달 전에 단원 모두에게 간부 이동 알림이 가요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.subtitle,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
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
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.subtitle, height: 1.5),
      ),
    );
  }
}

class _OfficersCard extends StatelessWidget {
  const _OfficersCard({required this.members, this.onEditTerm});

  final List<PresidiumMember> members;

  /// 4간부만: 간부를 눌러 임명일·임기를 입력한다.
  final ValueChanged<PresidiumMember>? onEditTerm;

  static const _warning = Color(0xFFD9534F);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final position in OfficerPosition.values)
            Builder(builder: (context) {
              final holder = _holder(position);
              final ending = holder != null && holder.isTermEndingBy(today);
              return ListTile(
                dense: true,
                onTap: holder != null && onEditTerm != null ? () => onEditTerm!(holder) : null,
                leading: SizedBox(
                  width: 52,
                  child: Text(
                    position.label,
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(
                  holder?.displayName ?? '공석',
                  style: TextStyle(
                    color: holder == null ? AppColors.subtitle : AppColors.title,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: holder == null
                    ? null
                    : Text(
                        _termText(holder, ending),
                        style: TextStyle(color: ending ? _warning : AppColors.subtitle, fontSize: 12),
                      ),
                trailing: holder != null && onEditTerm != null
                    ? Icon(
                        holder.officerAppointedDate == null ? Icons.edit_calendar_outlined : Icons.chevron_right,
                        color: holder.officerAppointedDate == null ? AppColors.accent : AppColors.subtitle,
                      )
                    : null,
              );
            }),
        ],
      ),
    );
  }

  String _termText(PresidiumMember holder, bool ending) {
    final appointed = holder.officerAppointedDate;
    final end = holder.officerTermEndDate;
    if (appointed == null || end == null) {
      return onEditTerm == null ? '임기 미입력' : '임기 미입력 · 눌러서 임명일·임기 입력';
    }
    final text = '${_dotDate(appointed)} 임명 · 임기 ${holder.officerTermLabel} (~${_dotDate(end)})';
    return ending ? '$text\n임기 만료 임박 · 간부 이동이 필요해요' : text;
  }

  static String _dotDate(DateTime d) => '${d.year}.${d.month}.${d.day}';

  PresidiumMember? _holder(OfficerPosition position) {
    for (final m in members) {
      if (m.officerRole == position.code) return m;
    }
    return null;
  }
}

class _ElectionCard extends StatelessWidget {
  const _ElectionCard({
    required this.election,
    this.isVoting = false,
    this.onVote,
    this.onAppoint,
    this.onCancel,
  });

  final OfficerElectionItem election;
  final bool isVoting;
  final ValueChanged<bool>? onVote;

  /// 당선 뒤 4간부·당선자에게만.
  final VoidCallback? onAppoint;

  /// 당선 뒤 4간부에게만.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final e = election;
    final statusColor = switch (e.status) {
      'OPEN' => AppColors.accent,
      'ELECTED' => const Color(0xFFE08A00),
      'APPOINTED' => const Color(0xFF2E9E5B),
      _ => AppColors.subtitle,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${e.positionLabel} · ${e.candidateName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.title,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '찬성 ${e.yesCount} · 반대 ${e.noCount}  (임명에 찬성 ${e.requiredVotes}표 필요, 행동단원 ${e.eligibleVoterCount}명)',
            style: TextStyle(color: AppColors.subtitle, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            e.isOpen
                ? '${e.startedByName} 시작 · ${remainingTime(e.closesAt)}'
                : '${e.startedByName} 시작 · ${e.closedAt == null ? '' : relativeTime(e.closedAt!)} 종료',
            style: TextStyle(color: AppColors.subtitle.withValues(alpha: 0.8), fontSize: 12),
          ),
          if (e.appointedDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${koreanFullDate(e.appointedDate!)} 임명 · 임기 ${e.termLabel ?? '-'}',
              style: const TextStyle(color: Color(0xFF2E9E5B), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          if (e.myVote != null) ...[
            const SizedBox(height: 8),
            Text(
              '내 투표: ${e.myVote! ? '찬성' : '반대'}',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ],
          if (e.isElected) ...[
            const SizedBox(height: 12),
            if (onAppoint != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isVoting ? null : onAppoint,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('간부 임명'),
                ),
              )
            else
              Text(
                '당선되었어요. 4간부나 당선자가 임명일을 정해 임명하면 간부가 돼요.',
                style: TextStyle(color: AppColors.subtitle, fontSize: 13),
              ),
            if (onCancel != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isVoting ? null : onCancel,
                  child: const Text('당선 취소', style: TextStyle(color: AppColors.subtitle)),
                ),
              ),
          ],
          if (e.isOpen && e.canVote && onVote != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isVoting ? null : () => onVote!(false),
                    child: const Text('반대'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: isVoting ? null : () => onVote!(true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                    child: const Text('찬성'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 투표 시작: 직책과 후보(행동단원)를 고른다.
class _StartElectionSheet extends StatefulWidget {
  const _StartElectionSheet({
    required this.members,
    required this.busyPositions,
    required this.service,
  });

  final List<PresidiumMember> members;
  final Set<String> busyPositions;
  final GovernanceService service;

  @override
  State<_StartElectionSheet> createState() => _StartElectionSheetState();
}

class _StartElectionSheetState extends State<_StartElectionSheet> {
  OfficerPosition? _position;
  int? _candidateId;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final position = _position;
    final candidateId = _candidateId;
    if (position == null || candidateId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.service.startElection(position: position, candidateUserId: candidateId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '간부 이동 투표 시작',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '후보 1명을 정하면 행동단원에게 찬반 투표 알림이 가요.',
              style: TextStyle(color: AppColors.subtitle),
            ),
            const SizedBox(height: 20),
            Text('직책', style: TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in OfficerPosition.values)
                  ChoiceChip(
                    label: Text(widget.busyPositions.contains(p.label) ? '${p.label} (진행 중)' : p.label),
                    selected: _position == p,
                    onSelected: widget.busyPositions.contains(p.label)
                        ? null
                        : (_) => setState(() => _position = p),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('후보 (행동단원)', style: TextStyle(color: AppColors.title, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            RadioGroup<int>(
              groupValue: _candidateId,
              onChanged: (v) => setState(() => _candidateId = v),
              child: Column(
                children: [
                  for (final m in widget.members)
                    RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      value: m.userId,
                      title: Text(m.isMe ? '${m.displayName} (나)' : m.displayName),
                      subtitle: m.officerLabel == null ? null : Text('현재 ${m.officerLabel}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _position == null || _candidateId == null || _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('투표 시작', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
