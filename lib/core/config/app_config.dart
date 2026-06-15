import 'dart:io' show Platform;

/// 앱 전역 환경 설정.
class AppConfig {
  const AppConfig._();

  /// AngelaCore 백엔드 base URL.
  ///
  /// Android·iOS 모두 `localhost:8080` 으로 통일한다.
  /// - 카카오 OAuth는 IP 주소(10.0.2.2)를 redirect_uri로 허용하지 않으므로
  ///   에뮬레이터에서도 `localhost` 를 써야 한다.
  /// - 안드로이드 에뮬레이터에서 호스트 PC로 연결하려면 한 번만:
  ///     adb reverse tcp:8080 tcp:8080
  ///
  /// 실기기/운영에서는 실제 서버 주소로 교체한다.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://localhost:8080';
    }
    return 'http://localhost:8080';
  }

  /// OAuth 콜백 딥링크 스킴 (AndroidManifest / 백엔드 설정과 일치해야 함).
  static const String oauthCallbackScheme = 'angela';
}
