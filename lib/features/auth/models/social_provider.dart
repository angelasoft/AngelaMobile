/// 지원하는 소셜 로그인 제공자.
enum SocialProvider {
  kakao,
  naver;

  /// 한글 표기 (UI·메시지용).
  String get label => switch (this) {
        SocialProvider.kakao => '카카오',
        SocialProvider.naver => '네이버',
      };

  /// AngelaCore OAuth registrationId (Spring `oauth2/authorization/{id}`).
  String get registrationId => switch (this) {
        SocialProvider.kakao => 'kakao',
        SocialProvider.naver => 'naver',
      };
}
