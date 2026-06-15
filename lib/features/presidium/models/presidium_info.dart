import 'presidium_item.dart';

/// 가입한 쁘레시디움 정보.
class PresidiumInfo {
  const PresidiumInfo({
    required this.id,
    required this.name,
    required this.sessionNumber,
    this.curiaName,
    this.parishName,
  });

  final int id;

  /// 헤더 표시용 (예: 즐거움의샘Pr(유스티노)).
  final String name;
  final int sessionNumber;
  final String? curiaName;
  final String? parishName;

  static String displayName(String curiaName, String prName) =>
      '${curiaName}Pr($prName)';

  factory PresidiumInfo.fromItem(PresidiumItem item) {
    return PresidiumInfo(
      id: item.id,
      name: displayName(item.curiaName, item.name),
      sessionNumber: item.sessionNumber,
      curiaName: item.curiaName,
      parishName: item.parishName,
    );
  }

  factory PresidiumInfo.fromMyPresidiumJson(Map<String, dynamic> json) {
    final p = json['presidium'] as Map<String, dynamic>;
    final curia = p['curiaName'] as String;
    final pr = p['name'] as String;
    return PresidiumInfo(
      id: p['id'] as int,
      name: displayName(curia, pr),
      sessionNumber: p['sessionNumber'] as int? ?? 1,
      curiaName: curia,
      parishName: p['parishName'] as String?,
    );
  }
}
