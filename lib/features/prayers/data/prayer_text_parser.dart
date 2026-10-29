import '../models/prayer_item.dart';

/// assets/prayers/*.txt 기도문 파일을 읽는다.
///
/// - 대시(-----)만 있는 줄로 기도문을 나누고, 각 기도문의 첫 줄이 제목이다.
/// - 빈 줄은 문단 구분이다.
/// - "## 소제목", "### 작은 소제목", "@image assets/prayers/파일" 을 쓸 수 있다.
/// - 줄 앞의 ○ ● ◎ ╋ † ✠ ┼ 는 응답 기호, 공백으로 시작하는 줄은 기호 다음 칸에 맞춰 들여 쓴다.
/// - 줄 전체가 ( ), < >, 〈 〉 로 감싸였거나 ※ 또는 * 로 시작하면 안내문으로 흐리게 표시한다.
/// - 줄 끝의 "(여기에 밑줄)" 은 그 줄에 밑줄을 긋는다.
abstract final class PrayerTextParser {
  static const _markers = ['○', '●', '◎', '╋', '†', '✠', '┼'];
  static const _underlineTag = '(여기에 밑줄)';
  static final _separator = RegExp(r'^\s*-{5,}\s*$');

  static List<PrayerItem> parse(String categoryId, String source) {
    final chunks = <List<String>>[[]];
    for (final line in source.replaceAll('\r\n', '\n').split('\n')) {
      if (_separator.hasMatch(line)) {
        chunks.add([]);
      } else {
        chunks.last.add(line);
      }
    }

    final prayers = <PrayerItem>[];
    for (final chunk in chunks) {
      final lines = chunk.skipWhile((l) => l.trim().isEmpty).toList();
      if (lines.isEmpty) continue;
      prayers.add(PrayerItem(
        id: '${categoryId}_${prayers.length}',
        title: lines.first.trim(),
        blocks: _parseBody(lines.skip(1)),
      ));
    }
    return prayers;
  }

  static List<PrayerBlock> _parseBody(Iterable<String> lines) {
    final blocks = <PrayerBlock>[];
    var paragraph = <PrayerLine>[];

    void flush() {
      if (paragraph.isEmpty) return;
      blocks.add(PrayerParagraph(paragraph));
      paragraph = [];
    }

    for (final raw in lines) {
      final text = raw.trim();
      if (text.isEmpty) {
        flush();
      } else if (text.startsWith('@image ')) {
        flush();
        blocks.add(PrayerImage(text.substring(7).trim()));
      } else if (text.startsWith('### ')) {
        flush();
        blocks.add(PrayerHeading(text.substring(4).trim(), level: 3));
      } else if (text.startsWith('## ')) {
        flush();
        blocks.add(PrayerHeading(text.substring(3).trim()));
      } else {
        paragraph.add(_parseLine(raw, text));
      }
    }
    flush();
    return blocks;
  }

  static PrayerLine _parseLine(String raw, String trimmed) {
    var text = trimmed;
    String? marker;
    for (final m in _markers) {
      if (text.startsWith(m)) {
        marker = m;
        text = text.substring(m.length).trimLeft();
        break;
      }
    }

    var underlined = false;
    if (text.endsWith(_underlineTag)) {
      underlined = true;
      text = text.substring(0, text.length - _underlineTag.length).trimRight();
    }

    final isRubric = marker == null &&
        ((text.startsWith('(') && text.endsWith(')')) ||
            (text.startsWith('<') && text.endsWith('>')) ||
            (text.startsWith('〈') && text.endsWith('〉')) ||
            text.startsWith('※') ||
            text.startsWith('*'));

    return PrayerLine(
      text: text,
      marker: marker,
      indented: marker == null && raw.trimLeft().length != raw.length,
      isRubric: isRubric,
      underlined: underlined,
    );
  }
}
