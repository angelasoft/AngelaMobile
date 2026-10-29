import 'activity_definition.dart';

/// 목록에 표시되는 활동 한 줄 (즐겨찾기·횟수).
class ActivityReportEntry {
  ActivityReportEntry({
    required this.definition,
    this.count = 0,
    this.isFavorite = false,
  });

  final ActivityDefinition definition;
  int count;
  bool isFavorite;

  int get id => definition.id;
  String get name => definition.name;
}
