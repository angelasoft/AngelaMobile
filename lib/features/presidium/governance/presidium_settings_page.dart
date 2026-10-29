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

/// 쁘레시디움 설정: 간부 이동, 승인 요청, 협조단원·퇴단 신청, 단원 목록.
class PresidiumSettingsPage extends StatefulWidget {
  const PresidiumSettingsPage({super.key, required this.presidium});

  final PresidiumInfo presidium;

  @override
  State<PresidiumSettingsPage> createState() => _PresidiumSettingsPageState();
}

class _PresidiumSettingsPageState extends State<PresidiumSettingsPage> {
  final _service = const GovernanceService();

  List<PresidiumMember> _members = const [];
  MembershipRequestsOverview? _requests;
  bool _isLoading = true;
  bool _isSubmitting = false;

  PresidiumInfo get _me => widget.presidium;

  @override
  void initState() {
    super.initState();
    _load();
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

  /// 신청할 수 없는 이유. 신청할 수 있으면 null.
  String? _blockReason({required bool auxiliary}) {
    if (_me.isOfficer) return '간부는 간부 이동으로 후임이 임명된 뒤 신청할 수 있어요.';
    if (auxiliary && !_me.isActiveMember) return '이미 협조단원이에요.';
    final pending = _requests?.myPendingRequest;
    if (pending != null) return '처리 중인 ${pending.typeLabel}이 있어요.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests?.pendingApprovals.length ?? 0;
    final auxiliaryBlock = _blockReason(auxiliary: true);
    final withdrawalBlock = _blockReason(auxiliary: false);

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
                subtitle: Text(_me.isOfficer ? '협조단원·퇴단 신청 승인' : '협조단원·퇴단 신청 진행 상황'),
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
              ListTile(
                enabled: !_isLoading && !_isSubmitting && auxiliaryBlock == null,
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: const Text('협조단원 신청'),
                subtitle: Text(auxiliaryBlock ?? '활동단원에서 협조단원으로 등급을 바꿔요.'),
                onTap: () => _submit(
                  'AUXILIARY',
                  '협조단원 신청',
                  '4간부 과반이 승인하면 협조단원으로 변경돼요.\n협조단원은 간부 투표권이 없어요.',
                ),
              ),
              _divider(),
              ListTile(
                enabled: !_isLoading && !_isSubmitting && withdrawalBlock == null,
                leading: const Icon(Icons.logout, color: Color(0xFFD9534F)),
                title: const Text('퇴단 신청'),
                subtitle: Text(withdrawalBlock ?? '4간부 과반이 승인하면 퇴단돼요.'),
                onTap: () => _submit(
                  'WITHDRAWAL',
                  '퇴단 신청',
                  '4간부 과반이 승인하면 쁘레시디움에서 퇴단 처리돼요.',
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '단원 목록 (${_members.length}명)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.title,
                      fontWeight: FontWeight.w700,
                    ),
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
            _card([
              ListTile(
                leading: const Icon(Icons.power_settings_new, color: AppColors.subtitle),
                title: const Text('로그아웃'),
                onTap: _logout,
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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
