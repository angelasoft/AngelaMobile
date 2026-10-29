import 'presidium_item.dart';

/// 가입한 쁘레시디움 정보와 내 등급·간부 직책.
class PresidiumInfo {
  const PresidiumInfo({
    required this.id,
    required this.name,
    this.curiaName,
    this.parishName,
    this.grade = 'ACTIVE',
    this.gradeLabel = '활동단원',
    this.officerRole,
    this.officerLabel,
  });

  final int id;

  /// 헤더 표시용 (예: 즐거움의샘Pr(황금궁전Cu)).
  final String name;
  final String? curiaName;
  final String? parishName;

  /// ACTIVE(활동단원) | AUXILIARY(협조단원)
  final String grade;
  final String gradeLabel;

  /// PRESIDENT | VICE_PRESIDENT | SECRETARY | TREASURER, 간부가 아니면 null.
  final String? officerRole;
  final String? officerLabel;

  bool get isOfficer => officerRole != null;
  bool get isActiveMember => grade == 'ACTIVE';

  /// 예: "단장 · 활동단원", "협조단원"
  String get myStatusLabel =>
      officerLabel == null ? gradeLabel : '$officerLabel · $gradeLabel';

  /// Pr 이름 뒤에 소속 Cu 를 괄호로 붙인다.
  static String displayName(String curiaName, String prName) =>
      '${prName}Pr(${curiaName}Cu)';

  factory PresidiumInfo.fromItem(PresidiumItem item) {
    return PresidiumInfo(
      id: item.id,
      name: displayName(item.curiaName, item.name),
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
      curiaName: curia,
      parishName: p['parishName'] as String?,
      grade: json['grade'] as String? ?? 'ACTIVE',
      gradeLabel: json['gradeLabel'] as String? ?? '활동단원',
      officerRole: json['officerRole'] as String?,
      officerLabel: json['officerLabel'] as String?,
    );
  }
}
