import 'oauth_identity.dart';

/// 소셜 로그인 결과.
///
/// - [AuthAuthenticated]: 이미 활동수첩 회원 → 홈으로 이동
/// - [AuthNeedsRegistration]: 소셜 인증은 됐으나 미가입 → 회원가입 화면
sealed class AuthResult {
  const AuthResult();
}

class AuthAuthenticated extends AuthResult {
  const AuthAuthenticated();
}

class AuthNeedsRegistration extends AuthResult {
  const AuthNeedsRegistration(this.identity);

  final OAuthIdentity identity;
}
