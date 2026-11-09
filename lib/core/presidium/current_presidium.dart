import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 지금 보고 있는 쁘레시디움. 어른 1곳 + 소년소녀 여러 곳에 가입한 단원이 고른 곳으로,
/// [ApiClient] 가 모든 요청에 X-Presidium-Id 헤더로 실어 보낸다. 앱을 다시 켜도 유지된다.
class CurrentPresidium {
  CurrentPresidium._();

  static const header = 'X-Presidium-Id';
  static const _idKey = 'presidium.selectedId';
  static const _nameKey = 'presidium.selectedName';

  /// 고른 쁘레시디움 번호. 아직 고르지 않았거나 가입하지 않았으면 null (서버가 어른 쁘레시디움을 쓴다).
  static final id = ValueNotifier<int?>(null);

  /// 화면 안내용 이름 (예: 즐거움의샘Pr(황금궁전Cu)).
  static String? name;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString(_nameKey);
    id.value = prefs.getInt(_idKey);
  }

  static Future<void> select(int presidiumId, String displayName) async {
    name = displayName;
    id.value = presidiumId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idKey, presidiumId);
    await prefs.setString(_nameKey, displayName);
  }

  static Future<void> clear() async {
    name = null;
    id.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
    await prefs.remove(_nameKey);
  }
}
