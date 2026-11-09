import 'package:flutter/material.dart';

import '../../core/presidium/current_presidium.dart';
import 'governance/presidium_settings_page.dart';
import 'models/presidium_info.dart';
import 'presidium_join_page.dart';
import 'presidium_service.dart';

/// 내가 가입한 쁘레시디움 목록과 지금 고른 쁘레시디움. 쁘레시디움 탭과 활동보고 탭이 함께 본다.
class MyPresidiumsState {
  const MyPresidiumsState({required this.loaded, this.presidiums = const [], this.selected});

  /// 처음 불러오기 전에는 false (가입 여부를 아직 모름).
  final bool loaded;

  /// 어른 1곳 + 소년소녀 여러 곳, 어른이 먼저.
  final List<PresidiumInfo> presidiums;
  final PresidiumInfo? selected;

  bool get joined => selected != null;
  bool get hasAdult => presidiums.any((p) => !p.isJunior);
}

abstract final class MyPresidiums {
  static const _service = PresidiumService();

  static final state = ValueNotifier(const MyPresidiumsState(loaded: false));

  static PresidiumInfo? get selected => state.value.selected;

  /// 가입 목록을 새로 받는다. [select] 가 있으면 그 쁘레시디움을, 없으면 전에 고른 곳(없으면 어른 쁘레시디움)을 고른다.
  static Future<void> load({int? select}) async {
    try {
      final list = await _service.fetchMyPresidiums();
      final wanted = select ?? CurrentPresidium.id.value;
      final selected = list.where((p) => p.id == wanted).firstOrNull ?? list.firstOrNull;
      if (selected == null) {
        await CurrentPresidium.clear();
      } else {
        await CurrentPresidium.select(selected.id, selected.name);
      }
      state.value = MyPresidiumsState(loaded: true, presidiums: list, selected: selected);
    } catch (_) {
      // 네트워크 오류면 지금 상태를 그대로 두되, 처음이면 "불러옴"으로 바꿔 화면이 멈춰 있지 않게 한다.
      if (!state.value.loaded) state.value = const MyPresidiumsState(loaded: true);
    }
  }

  static Future<void> switchTo(PresidiumInfo presidium) async {
    await CurrentPresidium.select(presidium.id, presidium.name);
    final current = state.value;
    state.value = MyPresidiumsState(loaded: true, presidiums: current.presidiums, selected: presidium);
  }

  /// 로그아웃할 때. 다음 사용자가 이전 사용자의 쁘레시디움을 잠깐이라도 보지 않게 한다.
  static void reset() => state.value = const MyPresidiumsState(loaded: false);

  /// 쁘레시디움 가입(또는 만들기) 화면을 열고, 가입하면 그 쁘레시디움을 고른다.
  static Future<void> openJoin(BuildContext context, {bool juniorOnly = false}) async {
    final joined = await Navigator.of(context).push<PresidiumInfo>(
      MaterialPageRoute(builder: (_) => PresidiumJoinPage(juniorOnly: juniorOnly)),
    );
    if (joined != null) await load(select: joined.id);
  }

  /// 설정 화면. 가입한 쁘레시디움이 없으면 로그아웃만 보인다.
  /// 돌아오면 신청 승인·퇴단 결과로 등급이나 가입 상태가 바뀌었을 수 있어 다시 불러온다.
  static Future<void> openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PresidiumSettingsPage(presidium: selected)),
    );
    await load();
  }
}
