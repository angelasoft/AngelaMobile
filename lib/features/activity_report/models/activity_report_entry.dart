import 'activity_definition.dart';

/// 목록에 표시되는 활동 한 줄 (즐겨찾기·추가·횟수).
class ActivityReportEntry {
  ActivityReportEntry({
    required this.definition,
    this.count = 0,
    this.isFavorite = false,
    this.isAdded = false,
  });

  final ActivityDefinition definition;
  int count;
  bool isFavorite;
  bool isAdded;

  String get id => definition.id;
  String get name => definition.name;

  bool get isVisible => isFavorite || isAdded;

  ActivityReportEntry copyWith({
    int? count,
    bool? isFavorite,
    bool? isAdded,
  }) {
    return ActivityReportEntry(
      definition: definition,
      count: count ?? this.count,
      isFavorite: isFavorite ?? this.isFavorite,
      isAdded: isAdded ?? this.isAdded,
    );
  }
}
