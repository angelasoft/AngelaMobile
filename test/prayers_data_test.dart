import 'package:angelamobile/features/prayers/data/prayer_text_parser.dart';
import 'package:angelamobile/features/prayers/data/prayers_data.dart';
import 'package:angelamobile/features/prayers/models/prayer_item.dart';
import 'package:angelamobile/features/prayers/widgets/prayer_expandable_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('구분선으로 기도문을 나누고 기호·들여쓰기·안내문·밑줄을 읽는다', () {
    const source = '''
첫 기도
○ 주님, 제 입술을 열어 주소서.
    제 입이 주님을 찬미할 것입니다.
(잠깐 묵상한다.)

영광이 성부와 성자와 성령께(여기에 밑줄)

---------------------------------------


둘째 기도
## 환희의 신비
@image assets/prayers/rosary_guide.gif
### 1단
본문
''';
    final prayers = PrayerTextParser.parse('x', source);

    expect(prayers.map((p) => p.title), ['첫 기도', '둘째 기도']);
    final first = prayers.first.blocks;
    expect(first, hasLength(2));
    final lines = (first[0] as PrayerParagraph).lines;
    expect(lines[0].marker, '○');
    expect(lines[0].text, '주님, 제 입술을 열어 주소서.');
    expect(lines[1].indented, isTrue);
    expect(lines[2].isRubric, isTrue);
    final underlined = (first[1] as PrayerParagraph).lines.single;
    expect(underlined.underlined, isTrue);
    expect(underlined.text, '영광이 성부와 성자와 성령께');

    final second = prayers[1].blocks;
    expect(second[1], isA<PrayerImage>());
    expect((second[2] as PrayerHeading).level, 3);
  });

  test('모든 탭 파일을 읽을 수 있고 기도문 수가 맞다', () async {
    final categories = await PrayersData.load();
    final counts = {for (final c in categories) c.id: c.prayers.length};

    expect(counts, {
      'legion': 6,
      'main': 21,
      'monthly': 6,
      'litany': 6,
      'various': 42,
      'confession': 1,
      'rosary': 2,
      'stations': 1,
    });
    expect(categories.first.prayers.map((p) => p.title).take(3),
        ['1. 시작 기도', '묵주기도(로사리오)', '2. 레지오의 까떼나']);
    final stations = categories.last.prayers.single.blocks.whereType<PrayerHeading>();
    expect(stations, hasLength(14));
  });

  testWidgets('모든 기도문을 펼쳐도 좁은 화면·큰 글자에서 넘치지 않는다', (tester) async {
    final categories = (await tester.runAsync(PrayersData.load))!;
    final prayers = [for (final c in categories) ...c.prayers];
    tester.view.physicalSize = const Size(320 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 800), textScaler: TextScaler.linear(1.6)),
        child: Scaffold(
          body: ListView(
            children: [
              for (final prayer in prayers)
                PrayerExpandableTile(prayer: prayer, isExpanded: true, onTap: () {}),
            ],
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
