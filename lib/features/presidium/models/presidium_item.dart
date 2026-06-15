/// 본당 소속 쁘레시디움 목록 항목 (Cu > Pr 표시용).
class PresidiumItem {
  const PresidiumItem({
    required this.id,
    required this.curiaId,
    required this.curiaName,
    required this.name,
    required this.sessionNumber,
    required this.parishId,
    required this.parishName,
  });

  factory PresidiumItem.fromJson(Map<String, dynamic> json) {
    return PresidiumItem(
      id: json['id'] as int,
      curiaId: json['curiaId'] as int,
      curiaName: json['curiaName'] as String,
      name: json['name'] as String,
      sessionNumber: json['sessionNumber'] as int? ?? 1,
      parishId: json['parishId'] as int,
      parishName: json['parishName'] as String? ?? '',
    );
  }

  final int id;
  final int curiaId;
  final String curiaName;
  final String name;
  final int sessionNumber;
  final int parishId;
  final String parishName;

  /// 화면 표시: "즐거움의샘 Cu > 유스티노 Pr"
  String get hierarchyLabel => '$curiaName Cu > $name Pr';
}
