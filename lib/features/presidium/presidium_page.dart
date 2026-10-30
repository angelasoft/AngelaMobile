import 'package:flutter/material.dart';

import '../../core/push/push_service.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/notification_service.dart';
import '../notifications/notifications_page.dart';
import 'governance/presidium_settings_page.dart';
import 'home/presidium_home.dart';
import 'models/presidium_info.dart';
import 'presidium_join_page.dart';
import 'presidium_service.dart';
import 'widgets/presidium_header.dart';

class PresidiumPage extends StatefulWidget {
  const PresidiumPage({super.key});

  @override
  State<PresidiumPage> createState() => _PresidiumPageState();
}

class _PresidiumPageState extends State<PresidiumPage> {
  final _service = const PresidiumService();
  final _notificationService = const NotificationService();
  PresidiumInfo? _presidium;
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // 앱을 쓰는 중에 푸시가 오면 종 배지를 바로 새로 고친다.
    PushService.instance.received.addListener(_loadUnreadCount);
    _loadMyPresidium();
  }

  @override
  void dispose() {
    PushService.instance.received.removeListener(_loadUnreadCount);
    super.dispose();
  }

  Future<void> _loadMyPresidium() async {
    try {
      final info = await _service.fetchMyPresidium();
      if (!mounted) return;
      setState(() {
        _presidium = info;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    await _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.fetchUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {
      // 배지 갱신 실패는 화면 사용을 막지 않는다.
    }
  }

  Future<void> _onJoinTap() async {
    final joined = await Navigator.of(context).push<PresidiumInfo>(
      MaterialPageRoute(builder: (_) => const PresidiumJoinPage()),
    );
    if (!mounted || joined == null) return;
    setState(() => _presidium = joined);
  }

  Future<void> _onNotificationsTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
    // 신청 승인·간부 임명 결과로 내 등급이 바뀌었을 수 있다.
    await _loadMyPresidium();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_presidium == null) {
      return _EmptyPresidiumBody(onJoinTap: _onJoinTap);
    }
    return PresidiumHome(presidium: _presidium!);
  }

  Future<void> _onSettingsTap() async {
    final presidium = _presidium;
    if (presidium == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쁘레시디움에 가입하면 설정을 사용할 수 있어요.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PresidiumSettingsPage(presidium: presidium)),
    );
    await _loadMyPresidium();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundMid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PresidiumHeader(
            presidium: _presidium,
            onSettingsTap: _onSettingsTap,
            onNotificationsTap: _onNotificationsTap,
            unreadCount: _unreadCount,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

class _EmptyPresidiumBody extends StatelessWidget {
  const _EmptyPresidiumBody({required this.onJoinTap});

  final VoidCallback onJoinTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 20),
            Text(
              '아직 가입한 쁘레시디움이 없어요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.title,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '소속 쁘레시디움에 가입하고\n활동을 함께 기록해 보세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtitle.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onJoinTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '쁘레시디움 가입',
                  style: TextStyle(
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
