import 'package:shared_preferences/shared_preferences.dart';

/// 활동보고 즐겨찾기. 앱을 다시 켜도 유지된다.
///
/// 한 번도 저장한 적 없으면 기본값(묵주기도)을 쓰고, 별을 한 번이라도 누르면
/// 그 시점의 목록을 저장한다.
class ActivityFavorites {
  ActivityFavorites._();

  static const _key = 'activity_report.favoriteIds';

  /// 저장 기능 도입 전·처음 사용 시 기본으로 즐겨찾기할 활동 이름.
  static const defaultNames = {'묵주기도'};

  /// null 이면 아직 저장한 적 없음 (기본 이름 목록을 쓴다).
  static Set<int>? _ids;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    _ids = saved == null ? null : {for (final s in saved) int.parse(s)};
  }

  /// [name] 은 아직 저장한 적 없을 때 기본 즐겨찾기 여부를 정하는 데 쓴다.
  static bool isFavorite(int activityId, String name) {
    final ids = _ids;
    if (ids == null) return defaultNames.contains(name);
    return ids.contains(activityId);
  }

  /// 지금 화면의 즐겨찾기 전체를 그대로 저장한다.
  static Future<void> save(Set<int> favoriteIds) async {
    _ids = Set<int>.of(favoriteIds);
    final prefs = await SharedPreferences.getInstance();
    final sorted = _ids!.toList()..sort();
    await prefs.setStringList(_key, [for (final id in sorted) '$id']);
  }
}
