import '../models/activity_definition.dart';

/// 검색 가능한 전체 활동 목록 (서버 연동 전 목업).
abstract final class ActivityCatalog {
  static const List<ActivityDefinition> all = [
    ActivityDefinition(id: 'rosary', name: '묵주기도'),
    ActivityDefinition(id: 'family_prayer', name: '가정성화 기도'),
    ActivityDefinition(id: 'family_mass', name: '가정성화 미사'),
    ActivityDefinition(id: 'annual', name: '연도'),
    ActivityDefinition(id: 'resting_member_care', name: '쉬는교우 돌봄'),
    ActivityDefinition(id: 'sunday_school_student', name: '주일학교 학생 돌봄'),
    ActivityDefinition(id: 'sunday_school_meeting', name: '주일학교 회의'),
    ActivityDefinition(id: 'mass_spirituality', name: '미사영성체'),
    ActivityDefinition(id: 'home_visit', name: '가정방문'),
    ActivityDefinition(id: 'evangelization', name: '전도 활동'),
    ActivityDefinition(id: 'accompaniment', name: '동행방문'),
    ActivityDefinition(id: 'legion_meeting', name: '쁘레시디움 회의'),
  ];

  /// 앱 최초 진입 시 즐겨찾기로 표시할 활동 ID.
  static const defaultFavoriteIds = ['rosary'];

  static ActivityDefinition? findById(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}
