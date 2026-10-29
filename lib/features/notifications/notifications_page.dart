import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/relative_time.dart';
import '../presidium/governance/membership_requests_page.dart';
import '../presidium/governance/officer_election_page.dart';
import 'notification_service.dart';

/// 알림함. 알림을 누르면 읽음 처리하고 관련 화면으로 이동한다.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = const NotificationService();

  List<AppNotification> _items = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.fetchRecent();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      try {
        await _service.markRead(item.id);
      } on ApiException catch (_) {
        // 읽음 처리 실패는 이동을 막지 않는다.
      }
    }
    if (!mounted) return;

    final Widget page = item.isAboutElection
        ? const OfficerElectionPage()
        : const MembershipRequestsPage();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    await _load();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      backgroundColor: AppColors.backgroundMid,
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: Colors.white,
        actions: [
          if (hasUnread)
            TextButton(onPressed: _markAllRead, child: const Text('모두 읽음')),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: Text('알림이 없어요.')),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.shadow.withValues(alpha: 0.08),
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  tileColor: item.isRead ? Colors.white : AppColors.accent.withValues(alpha: 0.06),
                  leading: Icon(
                    item.isAboutElection ? Icons.how_to_vote_outlined : Icons.assignment_ind_outlined,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.title,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${item.message}\n${relativeTime(item.createdAt)}'),
                  ),
                  isThreeLine: true,
                  onTap: () => _open(item),
                );
              },
            ),
    );
  }
}
