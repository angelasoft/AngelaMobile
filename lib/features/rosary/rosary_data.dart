import 'package:flutter/material.dart';

/// 묵주기도의 네 가지 신비.
enum RosaryMystery {
  joyful('환희의 신비', '월 · 토', Icons.local_florist_outlined, Color(0xFF6E9E7E), [
    '마리아께서 예수님을 잉태하심을 묵상합시다.',
    '마리아께서 엘리사벳을 찾아보심을 묵상합시다.',
    '마리아께서 예수님을 낳으심을 묵상합시다.',
    '마리아께서 예수님을 성전에 바치심을 묵상합시다.',
    '마리아께서 잃으셨던 예수님을 성전에서 찾으심을 묵상합시다.',
  ]),
  sorrowful('고통의 신비', '화 · 금', Icons.favorite_border, Color(0xFF8A7BB5), [
    '예수님께서 우리를 위하여 피땀 흘리심을 묵상합시다.',
    '예수님께서 우리를 위하여 매 맞으심을 묵상합시다.',
    '예수님께서 우리를 위하여 가시관 쓰심을 묵상합시다.',
    '예수님께서 우리를 위하여 십자가 지심을 묵상합시다.',
    '예수님께서 우리를 위하여 십자가에 못 박혀 돌아가심을 묵상합시다.',
  ]),
  glorious('영광의 신비', '수 · 일', Icons.auto_awesome_outlined, Color(0xFFC9962E), [
    '예수님께서 부활하심을 묵상합시다.',
    '예수님께서 승천하심을 묵상합시다.',
    '예수님께서 성령을 보내심을 묵상합시다.',
    '예수님께서 마리아를 하늘에 불러올리심을 묵상합시다.',
    '예수님께서 마리아께 천상 모후의 관을 씌우심을 묵상합시다.',
  ]),
  luminous('빛의 신비', '목', Icons.lightbulb_outline, Color(0xFF4A8BC6), [
    '예수님께서 세례 받으심을 묵상합시다.',
    '예수님께서 카나에서 첫 기적을 행하심을 묵상합시다.',
    '예수님께서 하느님 나라를 선포하심을 묵상합시다.',
    '예수님께서 거룩하게 변모하심을 묵상합시다.',
    '예수님께서 성체성사를 세우심을 묵상합시다.',
  ]);

  const RosaryMystery(this.title, this.days, this.icon, this.color, this.decades);

  final String title;

  /// 바치는 요일 (교황 요한 바오로 2세 『동정 마리아의 묵주기도』).
  final String days;
  final IconData icon;

  /// 앱의 흰색·파랑·금색 톤에 맞춘 차분한 색.
  final Color color;

  /// 1~5단의 묵상 내용.
  final List<String> decades;

  /// 오늘 바치는 신비. 월·토 환희, 화·금 고통, 수·일 영광, 목 빛.
  static RosaryMystery forDay(DateTime date) => switch (date.weekday) {
        DateTime.monday || DateTime.saturday => joyful,
        DateTime.tuesday || DateTime.friday => sorrowful,
        DateTime.thursday => luminous,
        _ => glorious,
      };
}

/// 한 걸음에 바치는 기도 하나. 첫 줄은 선창 부분이라 강조해서 보여 준다.
class RosaryPrayer {
  const RosaryPrayer(this.title, this.text);

  final String title;
  final String text;
}

enum BeadKind { cross, large, small, end }

/// 묵주알 하나 = 기도 한 걸음.
class RosaryStep {
  const RosaryStep({
    required this.kind,
    required this.label,
    required this.prayers,
    this.decade,
    this.bead,
    this.meditation,
  });

  final BeadKind kind;

  /// 머리글 (예: "1단 2번째 알").
  final String label;
  final List<RosaryPrayer> prayers;

  /// 1~5단. 시작 기도와 마침 기도는 null.
  final int? decade;

  /// 단 안의 성모송 번호(1~10) 또는 시작 부분 성모송 번호(1~3).
  final int? bead;
  final String? meditation;
}

abstract final class RosaryPrayers {
  static const signOfCross = RosaryPrayer('성호경', '성부와 성자와 성령의 이름으로.\n아멘.');

  static const creed = RosaryPrayer('사도신경', '''전능하신 천주 성부
천지의 창조주를 저는 믿나이다.
그 외아들 우리 주 예수 그리스도님
성령으로 인하여 동정 마리아께 잉태되어 나시고
본시오 빌라도 통치 아래서 고난을 받으시고
십자가에 못 박혀 돌아가시고 묻히셨으며
저승에 가시어 사흗날에 죽은 이들 가운데서 부활하시고
하늘에 올라 전능하신 천주 성부 오른편에 앉으시며
그리로부터 산 이와 죽은 이를 심판하러 오시리라 믿나이다.
성령을 믿으며
거룩하고 보편된 교회와 모든 성인의 통공을 믿으며
죄의 용서와 육신의 부활을 믿으며
영원한 삶을 믿나이다.
아멘.''');

  static const lordsPrayer = RosaryPrayer('주님의 기도', '''하늘에 계신 우리 아버지,
아버지의 이름이 거룩히 빛나시며
아버지의 나라가 오시며
아버지의 뜻이 하늘에서와 같이
땅에서도 이루어지소서!

오늘 저희에게 일용할 양식을 주시고
저희에게 잘못한 이를 저희가 용서하오니
저희 죄를 용서하시고
저희를 유혹에 빠지지 않게 하시고
악에서 구하소서.
아멘.''');

  static const hailMary = RosaryPrayer('성모송', '''은총이 가득하신 마리아님, 기뻐하소서!
주님께서 함께 계시니 여인 중에 복되시며
태중의 아들 예수님 또한 복되시나이다.

천주의 성모 마리아님,
이제와 저희 죽을 때에
저희 죄인을 위하여 빌어주소서.
아멘.''');

  static const gloryBe = RosaryPrayer('영광송', '''영광이 성부와 성자와 성령께
처음과 같이
이제와 항상 영원히.
아멘.''');

  static const fatima = RosaryPrayer('구원을 비는 기도', '''예수님, 저희 죄를 용서하시며
저희를 지옥 불에서 구하시고
연옥 영혼을 돌보시며
가장 버림받은 영혼을 돌보소서.''');

  static const salveRegina = RosaryPrayer('성모 찬송', '''○ 모후이시며 사랑이 넘친 어머니,
우리의 생명, 기쁨, 희망이시여,
● 당신 우러러 하와의 그 자손들이
눈물을 흘리며 부르짖나이다,
슬픔의 골짜기에서.
○ 우리들의 보호자 성모님,
불쌍한 저희를
인자로운 눈으로 굽어보소서.
● 귀양살이 끝날 때에
당신의 아들 우리 주 예수님 뵙게 하소서.
너그러우시고 자애로우시며
오! 아름다우신 동정 마리아님.
○ 천주의 성모님, 저희를 위하여 빌어 주시어
● 그리스도께서 약속하신 영원한 생명을 얻게 하소서.''');

  static const closingPrayer = RosaryPrayer('기도합시다', '''하느님,
외아드님께서 삶과 죽음과 부활로
저희에게 영원한 구원을 마련해 주셨나이다.
복되신 동정 마리아와 함께 이 신비를 묵상하며
묵주 기도를 바치오니
저희가 그 가르침을 따라
영원한 생명을 얻게 하소서.
우리 주 그리스도를 통하여 비나이다.
아멘.''');
}

/// 묵주기도 한 번의 순서 (61걸음).
///
/// 십자가(성호경·사도신경) → 큰 알(주님의 기도) → 작은 알 3개(성모송, 셋째 알에 영광송·구원을 비는 기도)
/// → 1~5단(신비 묵상과 주님의 기도, 성모송 10번, 열째 알에 영광송·구원을 비는 기도) → 성모 찬송과 마침 기도.
List<RosaryStep> buildRosarySteps(RosaryMystery mystery) {
  return [
    const RosaryStep(kind: BeadKind.cross, label: '시작', prayers: [RosaryPrayers.signOfCross, RosaryPrayers.creed]),
    const RosaryStep(kind: BeadKind.large, label: '시작', prayers: [RosaryPrayers.lordsPrayer]),
    for (var i = 1; i <= 3; i++)
      RosaryStep(
        kind: BeadKind.small,
        label: '$i번째 알',
        bead: i,
        prayers: [RosaryPrayers.hailMary, if (i == 3) ...[RosaryPrayers.gloryBe, RosaryPrayers.fatima]],
      ),
    for (var d = 1; d <= 5; d++) ...[
      RosaryStep(
        kind: BeadKind.large,
        label: '$d단',
        decade: d,
        meditation: mystery.decades[d - 1],
        prayers: const [RosaryPrayers.lordsPrayer],
      ),
      for (var i = 1; i <= 10; i++)
        RosaryStep(
          kind: BeadKind.small,
          label: '$d단 $i번째 알',
          decade: d,
          bead: i,
          meditation: mystery.decades[d - 1],
          prayers: [RosaryPrayers.hailMary, if (i == 10) ...[RosaryPrayers.gloryBe, RosaryPrayers.fatima]],
        ),
    ],
    const RosaryStep(
      kind: BeadKind.end,
      label: '마침 기도',
      prayers: [RosaryPrayers.salveRegina, RosaryPrayers.closingPrayer, RosaryPrayers.signOfCross],
    ),
  ];
}
