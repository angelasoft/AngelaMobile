import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/relative_time.dart';
import 'governance_models.dart';
import 'governance_service.dart';

/// 승인 요청: 4간부는 협조단원·퇴단 신청을 승인/반려하고, 모두 내 신청 내역을 본다.
class MembershipRequestsPage extends StatefulWidget {
  const MembershipRequestsPage({super.key});

  @override
  State<MembershipRequestsPage> createState() => _MembershipRequestsPageState();
}

class _MembershipRequestsPageState extends State<MembershipRequestsPage> {
  final _service = const GovernanceService();

  MembershipRequestsOverview? _overview;
  String? _error;
  int? _busyRequestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final overview = await _service.fetchRequests();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _decide(MembershipRequestItem request, bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? '승인하시겠어요?' : '반려하시겠어요?'),
        content: Text('${request.requesterName} 단원의 ${request.typeLabel}을 ${approve ? '승인' : '반려'}합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? '승인' : '반려'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(request.id, () async {
      final result = await _service.decide(request.id, approve: approve);
      _showMessage(switch (result.status) {
        'APPROVED' => '${result.typeLabel}이 승인되어 처리되었습니다.',
        'REJECTED' => '${result.typeLabel}이 반려되었습니다.',
        _ => '결정했습니다. 다른 간부의 승인을 기다리고 있어요.',
      });
    });
  }

  Future<void> _cancel(MembershipRequestItem request) async {
    await _run(request.id, () async {
      await _service.cancelRequest(request.id);
      _showMessage('${request.typeLabel}을 취소했습니다.');
    });
  }

  Future<void> _run(int requestId, Future<void> Function() action) async {
    setState(() => _busyRequestId = requestId);
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
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
      appBar: AppBar(title: const Text('승인 요청'), backgroundColor: Colors.white),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final overview = _overview;
    if (_error != null && overview == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_error!)));
    }
    if (overview == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (overview.isOfficer) ...[
            _title(context, '승인 대기 (${overview.pendingApprovals.length})'),
            if (overview.pendingApprovals.isEmpty)
              _emptyCard('승인할 신청이 없어요.')
            else
              for (final r in overview.pendingApprovals)
                _RequestCard(
                  request: r,
                  isBusy: _busyRequestId == r.id,
                  onApprove: r.canDecide ? () => _decide(r, true) : null,
                  onReject: r.canDecide ? () => _decide(r, false) : null,
                ),
            const SizedBox(height: 20),
          ],
          _title(context, '내 신청 내역'),
          if (overview.myRequests.isEmpty)
            _emptyCard('신청 내역이 없어요.')
          else
            for (final r in overview.myRequests)
              _RequestCard(
                request: r,
                isBusy: _busyRequestId == r.id,
                onCancel: r.isPending ? () => _cancel(r) : null,
              ),
        ],
      ),
    );
  }

  Widget _title(BuildContext context, String text) {
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

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppColors.subtitle)),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    this.isBusy = false,
    this.onApprove,
    this.onReject,
    this.onCancel,
  });

  final MembershipRequestItem request;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final statusColor = switch (r.status) {
      'PENDING' => AppColors.accent,
      'APPROVED' => const Color(0xFF2E9E5B),
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
                  '${r.typeLabel} · ${r.requesterName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.title,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                r.statusLabel,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '승인 ${r.approveCount} · 반려 ${r.rejectCount}  (간부 ${r.officerCount}명 중 ${r.requiredApprovals}명 승인 필요)',
            style: TextStyle(color: AppColors.subtitle, fontSize: 13),
          ),
          Text(
            relativeTime(r.createdAt),
            style: TextStyle(color: AppColors.subtitle.withValues(alpha: 0.8), fontSize: 12),
          ),
          if (r.myDecision != null) ...[
            const SizedBox(height: 6),
            Text(
              '내 결정: ${r.myDecision! ? '승인' : '반려'}',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ],
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: isBusy ? null : onReject, child: const Text('반려')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy ? null : onApprove,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                    child: const Text('승인'),
                  ),
                ),
              ],
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: isBusy ? null : onCancel, child: const Text('신청 취소')),
            ),
          ],
        ],
      ),
    );
  }
}
