import 'presidium_item.dart';

/// 가입한 쁘레시디움 정보와 내 등급·간부 직책.
class PresidiumInfo {
  const PresidiumInfo({
    required this.id,
    required this.name,
    this.prName,
    this.curiaName,
    this.parishName,
    this.type = 'ADULT',
    this.typeLabel = '어른',
    this.grade = 'ACTIVE',
    this.gradeLabel = '행동단원',
    this.officerRole,
    this.officerLabel,
  });

  final int id;

  /// 헤더 표시용 (예: 즐거움의샘Pr).
  final String name;

  /// Pr 이름만 (예: 즐거움의샘). 해산 확인 입력에 쓴다.
  final String? prName;
  final String? curiaName;
  final String? parishName;

  /// ADULT(어른) | JUNIOR(소년소녀). 어른은 1곳, 소년소녀는 여러 곳 가입할 수 있다.
  final String type;
  final String typeLabel;

  /// ACTIVE(행동단원) | PRAETORIAN(쁘레또리움 단원) | AUXILIARY(협조단원) | ADJUTORIAN(아듀또리움 단원)
  final String grade;
  final String gradeLabel;

  /// PRESIDENT | VICE_PRESIDENT | SECRETARY | TREASURER, 간부가 아니면 null.
  final String? officerRole;
  final String? officerLabel;

  bool get isOfficer => officerRole != null;
  /// 행동단원 갈래(행동단원·쁘레또리움 단원).
  bool get isActiveMember => grade == 'ACTIVE' || grade == 'PRAETORIAN';
  bool get isPresident => officerRole == 'PRESIDENT';
  bool get isJunior => type == 'JUNIOR';

  /// 예: "단장 · 행동단원", "협조단원"
  String get myStatusLabel =>
      officerLabel == null ? gradeLabel : '$officerLabel · $gradeLabel';

  /// 메뉴·헤더에는 Pr 이름만 보여 한 줄로 유지한다.
  static String displayName(String prName) => '${prName}Pr';

  factory PresidiumInfo.fromItem(PresidiumItem item) {
    return PresidiumInfo(
      id: item.id,
      name: displayName(item.name),
      prName: item.name,
      curiaName: item.curiaName,
      parishName: item.parishName,
      type: item.type,
      typeLabel: item.typeLabel,
    );
  }

  factory PresidiumInfo.fromMyPresidiumJson(Map<String, dynamic> json) {
    final p = json['presidium'] as Map<String, dynamic>;
    final curia = p['curiaName'] as String;
    final pr = p['name'] as String;
    return PresidiumInfo(
      id: p['id'] as int,
      name: displayName(pr),
      prName: pr,
      curiaName: curia,
      parishName: p['parishName'] as String?,
      type: p['type'] as String? ?? 'ADULT',
      typeLabel: p['typeLabel'] as String? ?? '어른',
      grade: json['grade'] as String? ?? 'ACTIVE',
      gradeLabel: json['gradeLabel'] as String? ?? '행동단원',
      officerRole: json['officerRole'] as String?,
      officerLabel: json['officerLabel'] as String?,
    );
  }
}
