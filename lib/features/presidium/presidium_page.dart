import 'package:flutter/material.dart';

import '../../core/presidium/current_presidium.dart';
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
import 'widgets/presidium_type_badge.dart';

class PresidiumPage extends StatefulWidget {
  const PresidiumPage({super.key});

  @override
  State<PresidiumPage> createState() => _PresidiumPageState();
}

class _PresidiumPageState extends State<PresidiumPage> {
  final _service = const PresidiumService();
  final _notificationService = const NotificationService();

  /// 가입한 쁘레시디움 전체 (어른 1곳 + 소년소녀 여러 곳, 어른이 먼저).
  List<PresidiumInfo> _presidiums = const [];

  /// 지금 보고 있는 쁘레시디움.
  PresidiumInfo? _presidium;
  bool _isLoading = true;
  int _unreadCount = 0;

  bool get _hasAdult => _presidiums.any((p) => !p.isJunior);

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

  /// 가입 목록을 새로 받고, 전에 고른 쁘레시디움이 있으면 그대로, 없으면 어른 쁘레시디움을 보여 준다.
  Future<void> _loadMyPresidium({int? select}) async {
    try {
      final list = await _service.fetchMyPresidiums();
      final wanted = select ?? CurrentPresidium.id.value;
      final selected = list.where((p) => p.id == wanted).firstOrNull ?? list.firstOrNull;
      if (selected == null) {
        await CurrentPresidium.clear();
      } else {
        await CurrentPresidium.select(selected.id, selected.name);
      }
      if (!mounted) return;
      setState(() {
        _presidiums = list;
        _presidium = selected;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    await _loadUnreadCount();
  }

  Future<void> _switchTo(PresidiumInfo presidium) async {
    await CurrentPresidium.select(presidium.id, presidium.name);
    if (!mounted) return;
    setState(() => _presidium = presidium);
  }

  /// 쁘레시디움 이름을 누르면: 가입한 쁘레시디움 사이를 오가거나 소년소녀 쁘레시디움에 더 가입한다.
  Future<void> _onSwitchTap() async {
    final choice = await showModalBottomSheet<_SwitchChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PresidiumSwitchSheet(
        presidiums: _presidiums,
        selectedId: _presidium?.id,
        canJoinAdult: !_hasAdult,
      ),
    );
    if (choice == null || !mounted) return;
    if (choice.presidium != null) {
      await _switchTo(choice.presidium!);
    } else {
      await _onJoinTap(juniorOnly: _hasAdult);
    }
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

  Future<void> _onJoinTap({bool juniorOnly = false}) async {
    final joined = await Navigator.of(context).push<PresidiumInfo>(
      MaterialPageRoute(builder: (_) => PresidiumJoinPage(juniorOnly: juniorOnly)),
    );
    if (!mounted || joined == null) return;
    await _loadMyPresidium(select: joined.id);
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
    // 쁘레시디움을 바꾸면 홈 카드들을 새로 만들어 그 쁘레시디움의 내용을 불러온다.
    return PresidiumHome(key: ValueKey(_presidium!.id), presidium: _presidium!);
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
            onTitleTap: _presidium == null ? null : _onSwitchTap,
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

/// 쁘레시디움 바꾸기 창의 선택. [presidium] 이 null 이면 "가입하기"를 고른 것.
class _SwitchChoice {
  const _SwitchChoice(this.presidium);

  final PresidiumInfo? presidium;
}

class _PresidiumSwitchSheet extends StatelessWidget {
  const _PresidiumSwitchSheet({
    required this.presidiums,
    required this.selectedId,
    required this.canJoinAdult,
  });

  final List<PresidiumInfo> presidiums;
  final int? selectedId;

  /// 어른 쁘레시디움이 없으면 어른 쁘레시디움에도 가입할 수 있다.
  final bool canJoinAdult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '내 쁘레시디움',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.title),
            ),
            const SizedBox(height: 4),
            Text(
              '어른 쁘레시디움은 한 곳, 소년소녀 쁘레시디움은 여러 곳 가입할 수 있어요.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
            ),
            const SizedBox(height: 12),
            for (final p in presidiums)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: p.id == selectedId ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundMid,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context, _SwitchChoice(p)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      p.name,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.title,
                                      ),
                                    ),
                                    if (p.isJunior) PresidiumTypeBadge(label: p.typeLabel),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.myStatusLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
                                ),
                              ],
                            ),
                          ),
                          if (p.id == selectedId) const Icon(Icons.check, color: AppColors.accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, const _SwitchChoice(null)),
              icon: const Icon(Icons.add),
              label: Text(canJoinAdult ? '쁘레시디움 더 가입하기' : '소년소녀 쁘레시디움 가입하기'),
            ),
          ],
        ),
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
