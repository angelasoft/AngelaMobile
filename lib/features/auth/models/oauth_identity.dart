import 'social_provider.dart';

/// 소셜 로그인 성공 후 AngelaCore가 돌려주는 본인 식별 정보.
///
/// 아직 활동수첩 회원가입이 끝나지 않은 단계에서, 회원가입 폼을
/// 미리 채우는 데 사용한다.
class OAuthIdentity {
  const OAuthIdentity({
    required this.provider,
    required this.providerId,
    required this.email,
  });

  final SocialProvider provider;
  final String providerId;

  /// 1인 1계정 식별 키. 카카오·네이버 공통으로 이메일을 기준으로 연결한다.
  final String email;
}
