import 'package:flutter/material.dart';

import '../../core/ads/ads_config.dart';
import '../../core/ads/native_ad_slot.dart';
import '../../core/push/push_service.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/notification_service.dart';
import '../notifications/notifications_page.dart';
import 'home/presidium_home.dart';
import 'models/presidium_info.dart';
import 'my_presidiums.dart';
import 'widgets/join_presidium_prompt.dart';
import 'widgets/presidium_header.dart';
import 'widgets/presidium_type_badge.dart';

class PresidiumPage extends StatefulWidget {
  const PresidiumPage({super.key});

  @override
  State<PresidiumPage> createState() => _PresidiumPageState();
}

class _PresidiumPageState extends State<PresidiumPage> {
  final _notificationService = const NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // 앱을 쓰는 중에 푸시가 오면 종 배지를 바로 새로 고친다.
    PushService.instance.received.addListener(_loadUnreadCount);
    _reload();
  }

  @override
  void dispose() {
    PushService.instance.received.removeListener(_loadUnreadCount);
    super.dispose();
  }

  Future<void> _reload() async {
    await MyPresidiums.load();
    await _loadUnreadCount();
  }

  /// 쁘레시디움 이름을 누르면: 가입한 쁘레시디움 사이를 오가거나 소년소녀 쁘레시디움에 더 가입한다.
  Future<void> _onSwitchTap(MyPresidiumsState state) async {
    final choice = await showModalBottomSheet<_SwitchChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PresidiumSwitchSheet(
        presidiums: state.presidiums,
        selectedId: state.selected?.id,
        canJoinAdult: !state.hasAdult,
      ),
    );
    if (choice == null || !mounted) return;
    if (choice.presidium != null) {
      await MyPresidiums.switchTo(choice.presidium!);
    } else {
      await MyPresidiums.openJoin(context, juniorOnly: state.hasAdult);
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

  Future<void> _onNotificationsTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
    // 신청 승인·간부 임명 결과로 내 등급이 바뀌었을 수 있다.
    await _reload();
  }

  Future<void> _onSettingsTap() async {
    await MyPresidiums.openSettings(context);
    await _loadUnreadCount();
  }

  Widget _buildBody(MyPresidiumsState state) {
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final presidium = state.selected;
    if (presidium == null) {
      return const JoinPresidiumPrompt();
    }
    // 쁘레시디움을 바꾸면 홈 카드들을 새로 만들어 그 쁘레시디움의 내용을 불러온다.
    return PresidiumHome(key: ValueKey(presidium.id), presidium: presidium);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MyPresidiumsState>(
      valueListenable: MyPresidiums.state,
      builder: (context, state, _) => ColoredBox(
        color: AppColors.backgroundMid,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PresidiumHeader(
              presidium: state.selected,
              onTitleTap: state.joined ? () => _onSwitchTap(state) : null,
              onSettingsTap: _onSettingsTap,
              onNotificationsTap: _onNotificationsTap,
              unreadCount: _unreadCount,
            ),
            // 쁘레시디움을 바꾸면 홈을 새로 만들므로, 광고는 홈 밖에 두어 같은 광고가 두 번 붙지 않게 한다.
            if (state.joined)
              const NativeAdSlot(
                placement: AdPlacement.home,
                tabIndex: 0,
                margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
              ),
            Expanded(child: _buildBody(state)),
          ],
        ),
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
