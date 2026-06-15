/// 약관 종류.
enum AgreementType { terms, privacy, marketing }

/// 약관 내용 (초안 — 실제 법무 검토 문구로 교체 예정).
class AgreementDocument {
  const AgreementDocument({required this.title, required this.body});

  final String title;
  final String body;

  static AgreementDocument of(AgreementType type) => switch (type) {
        AgreementType.terms => _terms,
        AgreementType.privacy => _privacy,
        AgreementType.marketing => _marketing,
      };

  static const _terms = AgreementDocument(
    title: '서비스 이용약관',
    body: '''제1조 (목적)
이 약관은 레지오마리애 활동수첩(이하 "서비스")의 이용 조건 및 절차, 회원과 서비스 제공자의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.

제2조 (회원 가입)
회원은 카카오 또는 네이버 계정을 통한 소셜 로그인 후, 본인 정보를 입력하여 가입합니다. 1인은 하나의 계정만 보유할 수 있습니다.

제3조 (서비스의 이용)
회원은 쁘레시디움 활동 보고, 주 회합 안내, 기도문 열람 등 서비스가 제공하는 기능을 이용할 수 있습니다.

제4조 (회원의 의무)
회원은 타인의 정보를 도용하거나 서비스 운영을 방해하는 행위를 하여서는 안 됩니다.

제5조 (계정의 관리 및 탈퇴)
회원은 언제든지 탈퇴를 요청할 수 있으며, 탈퇴 시 관련 법령에 따라 개인정보가 처리됩니다.

※ 본 약관은 초안이며, 정식 서비스 시 법무 검토를 거친 내용으로 대체됩니다.''',
  );

  static const _privacy = AgreementDocument(
    title: '개인정보 수집·이용 동의',
    body: '''1. 수집 항목
- 필수: 이메일, 이름, 세례명, 휴대폰 번호, 생년월일, 성별, 소셜 로그인 식별자
- 자동 수집: 서비스 이용 기록, 기기 정보

2. 수집·이용 목적
- 회원 식별 및 본인 확인 (1인 1계정 관리)
- 쁘레시디움 활동 보고 및 집계
- 공지·안내 등 서비스 운영

3. 보유 및 이용 기간
- 회원 탈퇴 시까지 보유하며, 관련 법령에 따라 일정 기간 보관 후 파기합니다.

4. 동의 거부 권리
- 필수 항목 동의를 거부할 수 있으나, 이 경우 회원가입이 제한됩니다.

※ 본 동의서는 초안이며, 정식 서비스 시 개인정보 처리방침으로 대체됩니다.''',
  );

  static const _marketing = AgreementDocument(
    title: '마케팅 정보 수신 동의 (선택)',
    body: '''1. 수신 목적
- 행사·소식·이벤트 등 안내성 정보 제공

2. 수신 방법
- 앱 푸시 알림, 이메일 등

3. 동의 거부
- 본 동의는 선택 사항이며, 거부하셔도 서비스 이용에 제한이 없습니다.
- 가입 후 설정에서 언제든지 변경할 수 있습니다.

※ 본 동의서는 초안입니다.''',
  );
}
