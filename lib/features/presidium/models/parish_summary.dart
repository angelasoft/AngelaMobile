/// 본당 검색 결과 (지역 API).
class ParishSummary {
  const ParishSummary({
    required this.id,
    required this.name,
    required this.districtName,
    this.type = '본당',
  });

  factory ParishSummary.fromJson(Map<String, dynamic> json) {
    return ParishSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      districtName: json['districtName'] as String? ?? '',
      type: json['type'] as String? ?? '본당',
    );
  }

  final int id;
  final String name;
  final String districtName;
  final String type;

  String get displayLabel =>
      districtName.isEmpty ? name : '$districtName · $name';
}
