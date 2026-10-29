/// 앱 전역 환경 설정.
class AppConfig {
  const AppConfig._();

  /// AngelaCore 백엔드 base URL.
  ///
  /// 빌드 시 `--dart-define=API_BASE_URL=https://api.angelasoft.com` 으로 지정한다.
  /// 지정하지 않으면 로컬 개발용 `localhost:8080` 을 쓴다.
  /// - 카카오 OAuth는 IP 주소(10.0.2.2)를 redirect_uri로 허용하지 않으므로
  ///   에뮬레이터에서도 `localhost` 를 써야 한다.
  /// - 안드로이드 에뮬레이터에서 호스트 PC로 연결하려면:
  ///     adb reverse tcp:8080 tcp:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// OAuth 콜백 딥링크 스킴 (AndroidManifest / 백엔드 설정과 일치해야 함).
  static const String oauthCallbackScheme = 'angela';
}
