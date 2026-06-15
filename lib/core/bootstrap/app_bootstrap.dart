import 'bootstrap_destination.dart';

/// 앱 시작 시 스플래시 동안 수행하는 초기화.
///
/// ChatGPT가 정리한 흐름(설정, 인증, 프리로드, 버전·딥링크·최초실행)을
/// 이 클래스에서 순서대로 호출하도록 확장하면 된다.
class AppBootstrap {
  const AppBootstrap();

  Future<BootstrapDestination> run() async {
    await _loadConfig();
    await _initDependencies();
    await _initLocalStorage();

    final destination = await _resolveDestination();

    // 홈 진입 전에 꼭 필요한 데이터만 미리 로드 (무거운 작업은 홈에서 lazy).
    if (destination == BootstrapDestination.home) {
      await _preloadEssentials();
    }

    return destination;
  }

  Future<void> _loadConfig() async {
    // TODO: 환경설정, Remote Config
  }

  Future<void> _initDependencies() async {
    // TODO: API 클라이언트, 로깅, Firebase 등
  }

  Future<void> _initLocalStorage() async {
    // TODO: Hive/SQLite, SharedPreferences, SecureStorage
  }

  Future<BootstrapDestination> _resolveDestination() async {
    if (await _requiresForceUpdate()) {
      return BootstrapDestination.forceUpdate;
    }

    if (await _isFirstLaunch()) {
      return BootstrapDestination.onboarding;
    }

    final auth = await _checkAuth();
    return switch (auth) {
      AuthCheckResult.authenticated => BootstrapDestination.home,
      AuthCheckResult.unauthenticated => BootstrapDestination.login,
    };
  }

  Future<bool> _requiresForceUpdate() async {
    // TODO: 서버 최소 버전 / 점검 여부
    return false;
  }

  Future<bool> _isFirstLaunch() async {
    // TODO: SharedPreferences 등으로 최초 실행 여부
    return false;
  }

  Future<AuthCheckResult> _checkAuth() async {
    // TODO: Access/Refresh 토큰 저장소 + AngelaCore 검증
    return AuthCheckResult.unauthenticated;
  }

  Future<void> _preloadEssentials() async {
    // TODO: 프로필, 소속 쁘레시디움, 오늘 활동, 공지 등
  }
}

enum AuthCheckResult {
  authenticated,
  unauthenticated,
}
