/// 기도문 한 편.
class PrayerItem {
  const PrayerItem({
    required this.id,
    required this.title,
    this.summary,
    this.sections = const [],
  });

  final String id;
  final String title;
  final String? summary;
  final List<PrayerSection> sections;
}

class PrayerSection {
  const PrayerSection({
    this.heading,
    required this.lines,
  });

  final String? heading;
  final List<String> lines;
}

class PrayerCategory {
  const PrayerCategory({
    required this.id,
    required this.title,
    required this.prayers,
  });

  final String id;
  final String title;
  final List<PrayerItem> prayers;
}
