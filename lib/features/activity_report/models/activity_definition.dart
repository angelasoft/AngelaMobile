/// 활동보고 대상 활동 정의 (서버 `GET /app/activities`).
class ActivityDefinition {
  const ActivityDefinition({
    required this.id,
    required this.name,
  });

  factory ActivityDefinition.fromJson(Map<String, dynamic> json) {
    return ActivityDefinition(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}
