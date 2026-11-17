import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_service.dart';
import '../models/presidium_info.dart';
import 'governance_models.dart';
import 'governance_service.dart';
import 'membership_requests_page.dart';
import 'officer_election_page.dart';
import 'presidium_profile_page.dart';

/// 설정: 쁘레시디움 정보, 간부 이동, 승인 요청, 등급 변경·퇴단 신청, 단원 목록, 로그아웃.
/// 쁘레시디움 탭과 활동보고 탭에서 연다. 가입한 쁘레시디움이 없으면 로그아웃만 보인다.
class PresidiumSettingsPage extends StatefulWidget {
  const PresidiumSettingsPage({super.key, required this.presidium});

  /// 지금 고른 쁘레시디움. 가입하지 않았으면 null.
  final PresidiumInfo? presidium;

  @override
  State<PresidiumSettingsPage> createState() => _PresidiumSettingsPageState();
}

class _PresidiumSettingsPageState extends State<PresidiumSettingsPage> {
  final _service = const GovernanceService();

  List<PresidiumMember> _members = const [];
  MembershipRequestsOverview? _requests;
  bool _isLoading = true;
  bool _isSubmitting = false;

  PresidiumInfo get _me => widget.presidium!;

  @override
  void initState() {
    super.initState();
    if (widget.presidium == null) {
      _isLoading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_service.fetchMembers(), _service.fetchRequests()]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<PresidiumMember>;
        _requests = results[1] as MembershipRequestsOverview;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.message);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    await _load();
  }

  Future<void> _submit(String type, String label, String description) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label을 하시겠어요?'),
        content: Text(description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('신청')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.submitRequest(type);
      _showMessage('$label을 했습니다. 4간부에게 승인 요청 알림이 전송되었습니다.');
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 등급 변경 신청을 할 수 없는 이유. 신청할 수 있으면 null.
  String? _blockReason() {
    if (_me.isOfficer) return '간부는 간부 이동으로 후임이 임명된 뒤 신청할 수 있어요.';
    return _pendingReason();
  }

  String? _pendingReason() {
    final pending = _requests?.myPendingRequest;
    return pending == null ? null : '처리 중인 ${pending.typeLabel}이 있어요.';
  }

  /// 혼자 남았으면 퇴단 = 쁘레시디움 해산.
  bool get _isLastMember => !_isLoading && _members.length == 1;

  /// 남은 단원이 모두 간부.
  bool get _onlyOfficersLeft => _members.isNotEmpty && _members.every((m) => m.officerRole != null);

  /// 퇴단 신청을 할 수 없는 이유. 간부만 남았으면 단장 외 간부도 신청할 수 있다 (단장이 승인).
  String? _withdrawalBlockReason() {
    if (_me.isOfficer) {
      if (!_onlyOfficersLeft) return '간부는 간부 이동으로 후임이 임명된 뒤 신청할 수 있어요.';
      if (_me.isPresident) {
        return '다른 간부가 모두 퇴단한 뒤 퇴단할 수 있어요. 혼자 남으면 퇴단과 함께 쁘레시디움이 해산돼요.';
      }
    }
    return _pendingReason();
  }

  String get _withdrawalDescription => _me.isOfficer
      ? '간부만 남아 있어 단장이 승인하면 퇴단돼요.'
      : '4간부 과반이 승인하면 퇴단돼요.';

  Future<void> _dissolve() async {
    final prName = _me.prName ?? _me.name;
    final typed = await showDialog<String>(
      context: context,
      builder: (_) => _DissolveDialog(prName: prName),
    );
    if (typed == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.dissolve(typed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$prName Pr이 해산되었습니다.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _showMessage(e.message);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.presidium == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundMid,
        appBar: AppBar(title: const Text('설정'), backgroundColor: Colors.white),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [_logoutCard()],
        ),
      );
    }

    final pendingCount = _requests?.pendingApprovals.length ?? 0;
    final block = _blockReason();
    final withdrawalBlock = _withdrawalBlockReason();
    final canSubmit = !_isLoading && !_isSubmitting && block == null;

    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(title: const Text('쁘레시디움 설정'), backgroundColor: Colors.white),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _card([
              ListTile(
                title: Text(
                  _me.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.title),
                ),
                subtitle: Text('내 등급: ${_me.myStatusLabel}'),
              ),
              _divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.accent),
                title: const Text('쁘레시디움 정보'),
                subtitle: Text(_me.isOfficer ? '설립일·승인일·주회합 일정 입력, 이번 주 회합 차수' : '설립일·승인일·주회합 일정, 이번 주 회합 차수'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(PresidiumProfilePage(presidiumName: _me.name)),
              ),
            ]),
            const SizedBox(height: 16),
            _card([
              ListTile(
                leading: const Icon(Icons.how_to_vote_outlined, color: AppColors.accent),
                title: const Text('간부 이동'),
                subtitle: const Text('4간부 현황과 임명 투표'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(const OfficerElectionPage()),
              ),
              _divider(),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined, color: AppColors.accent),
                title: Text(_me.isOfficer ? '승인 요청' : '내 신청 내역'),
                subtitle: Text(_me.isOfficer ? '등급 변경·퇴단 신청 승인' : '등급 변경·퇴단 신청 진행 상황'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pendingCount > 0) Badge(label: Text('$pendingCount')),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _open(const MembershipRequestsPage()),
              ),
            ]),
            const SizedBox(height: 16),
            _card([
              // 지금 등급의 반대쪽으로 바꾸는 신청만 보여 준다.
              if (_me.isActiveMember)
                ListTile(
                  enabled: canSubmit,
                  leading: const Icon(Icons.volunteer_activism_outlined),
                  title: const Text('협조단원 신청'),
                  subtitle: Text(block ?? '행동단원에서 협조단원으로 등급을 바꿔요.'),
                  onTap: () => _submit(
                    'AUXILIARY',
                    '협조단원 신청',
                    '4간부 과반이 승인하면 협조단원으로 변경돼요.\n협조단원은 간부 투표권이 없어요.',
                  ),
                )
              else
                ListTile(
                  enabled: canSubmit,
                  leading: const Icon(Icons.how_to_reg_outlined),
                  title: const Text('행동단원 신청'),
                  subtitle: Text(block ?? '협조단원에서 행동단원으로 등급을 바꿔요.'),
                  onTap: () => _submit(
                    'ACTIVE',
                    '행동단원 신청',
                    '4간부 과반이 승인하면 행동단원으로 변경돼요.\n행동단원은 간부 투표에 참여하고 간부를 맡을 수 있어요.',
                  ),
                ),
              _divider(),
              if (_isLastMember)
                ListTile(
                  enabled: !_isSubmitting,
                  leading: const Icon(Icons.delete_forever_outlined, color: Color(0xFFD9534F)),
                  title: const Text('퇴단 (쁘레시디움 해산)'),
                  subtitle: const Text('혼자 남아 있어 퇴단하면 쁘레시디움과 모든 기록이 삭제돼요.'),
                  onTap: _dissolve,
                )
              else
                ListTile(
                  enabled: !_isLoading && !_isSubmitting && withdrawalBlock == null,
                  leading: const Icon(Icons.logout, color: Color(0xFFD9534F)),
                  title: const Text('퇴단 신청'),
                  subtitle: Text(withdrawalBlock ?? _withdrawalDescription),
                  onTap: () => _submit(
                    'WITHDRAWAL',
                    '퇴단 신청',
                    _me.isOfficer
                        ? '간부만 남아 있어 단장이 승인하면 쁘레시디움에서 퇴단 처리돼요.'
                        : '4간부 과반이 승인하면 쁘레시디움에서 퇴단 처리돼요.',
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '단원 목록 (${_members.length}명)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.title,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_me.isPresident)
                    Text(
                      '단원을 누르면 쁘레또리움·아듀또리움 단원으로 임명하거나 해제할 수 있어요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
                    ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _card([
                for (var i = 0; i < _members.length; i++) ...[
                  if (i > 0) _divider(),
                  ListTile(
                    dense: true,
                    onTap: _me.isPresident ? () => _changeHigherDegree(_members[i]) : null,
                    title: Text(_members[i].isMe ? '${_members[i].displayName} (나)' : _members[i].displayName),
                    trailing: Text(
                      _members[i].officerLabel == null
                          ? _members[i].gradeLabel
                          : '${_members[i].officerLabel} · ${_members[i].gradeLabel}',
                      style: TextStyle(
                        color: _members[i].officerLabel == null ? AppColors.subtitle : AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ]),
            const SizedBox(height: 24),
            _logoutCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 단장만: 행동단원은 쁘레또리움 단원으로, 협조단원은 아듀또리움 단원으로 임명하거나 해제한다.
  Future<void> _changeHigherDegree(PresidiumMember member) async {
    final appoint = !member.isHigherDegree;
    final degree = member.higherDegreeLabel;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appoint ? '$degree 임명' : '$degree 해제'),
        content: Text(appoint
            ? '${member.displayName} 님을 $degree으로 임명할까요?\n'
                '${member.isActive ? '매일 뗏세라 기도 전부, 미사·영성체, 성무일도를 바치는 행동단원이에요.' : '매일 미사·영성체와 성무일도를 바치는 협조단원이에요.'}'
            : '${member.displayName} 님의 $degree 등록을 해제할까요?\n'
                '${member.isActive ? '행동단원' : '협조단원'}으로 돌아가요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(appoint ? '임명' : '해제')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final updated = await _service.changeHigherDegree(member.userId, appoint: appoint);
      _showMessage('${updated.displayName} 님이 ${updated.gradeLabel}이 되었어요.');
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Widget _logoutCard() => _card([
        ListTile(
          leading: const Icon(Icons.power_settings_new, color: AppColors.subtitle),
          title: const Text('로그아웃'),
          onTap: _logout,
        ),
      ]);

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃하시겠어요?'),
        content: const Text('다시 사용하려면 카카오 또는 네이버로 로그인해야 해요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (confirmed != true) return;

    await const AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 16, color: AppColors.shadow.withValues(alpha: 0.08));
}

/// 해산 확인: 지워지는 내용을 보여 주고 Pr 이름을 입력해야 해산할 수 있다. 입력한 글자를 돌려준다.
class _DissolveDialog extends StatefulWidget {
  const _DissolveDialog({required this.prName});

  /// Pr 이름만 (예: 즐거움의 샘).
  final String prName;

  @override
  State<_DissolveDialog> createState() => _DissolveDialogState();
}

class _DissolveDialogState extends State<_DissolveDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 띄어쓰기는 보지 않고, 끝에 "Pr" 을 붙여도 된다 (서버와 같은 기준).
  static String _normalize(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    return compact.toLowerCase().endsWith('pr') ? compact.substring(0, compact.length - 2) : compact;
  }

  bool get _matches => _controller.text.trim().isNotEmpty && _normalize(_controller.text) == _normalize(widget.prName);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('쁘레시디움을 해산할까요?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '혼자 남은 단원이 퇴단하면 쁘레시디움이 없어지고 아래 기록이 모두 삭제돼요. 되돌릴 수 없어요.\n\n'
              '· 공지사항, 봉사 일정\n'
              '· 활동보고, 회계 장부\n'
              '· 출석부, 휴회 주, 쁘레시디움 정보\n'
              '· 간부 투표, 신청 내역과 관련 알림',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              '확인을 위해 Pr 이름 「${widget.prName}」을 입력해 주세요.',
              style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(hintText: widget.prName),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: _matches ? () => Navigator.pop(context, _controller.text.trim()) : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD9534F)),
          child: const Text('해산'),
        ),
      ],
    );
  }
}
