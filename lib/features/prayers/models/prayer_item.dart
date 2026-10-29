/// 기도문 한 편.
class PrayerItem {
  const PrayerItem({
    required this.id,
    required this.title,
    this.blocks = const [],
  });

  final String id;
  final String title;
  final List<PrayerBlock> blocks;
}

/// 기도문 본문을 이루는 덩어리: 소제목, 그림, 문단.
sealed class PrayerBlock {
  const PrayerBlock();
}

class PrayerHeading extends PrayerBlock {
  const PrayerHeading(this.text, {this.level = 2});

  final String text;

  /// 2: 큰 소제목, 3: 작은 소제목.
  final int level;
}

class PrayerImage extends PrayerBlock {
  const PrayerImage(this.assetPath);

  final String assetPath;
}

/// 빈 줄 없이 이어지는 줄 묶음.
class PrayerParagraph extends PrayerBlock {
  const PrayerParagraph(this.lines);

  final List<PrayerLine> lines;
}

class PrayerLine {
  const PrayerLine({
    required this.text,
    this.marker,
    this.indented = false,
    this.isRubric = false,
    this.underlined = false,
  });

  final String text;

  /// 줄 앞의 응답 기호 (○ ● ◎ ╋ † 등).
  final String? marker;

  /// 기호 다음 칸에 맞춰 들여 쓰는 줄.
  final bool indented;

  /// 괄호로 감싼 안내문 (예: "(잠깐 묵상한다.)").
  final bool isRubric;

  final bool underlined;
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
