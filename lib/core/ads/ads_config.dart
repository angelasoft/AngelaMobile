import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// 광고가 들어가는 화면. 활동보고·주 회합에는 광고를 넣지 않는다.
enum AdPlacement { home, prayer }

/// 광고 설정값. 정책(빈도·간격)과 광고 단위 ID 를 한 곳에서 관리한다.
abstract final class AdsConfig {
  /// "후원하고 광고 없이 쓰기" 결제 등으로 광고를 모두 끌 때 false.
  static const adsEnabled = true;

  static const appOpenEnabled = true;

  /// 설치 후 처음 몇 번의 실행에는 앱 오프닝 광고를 보여 주지 않는다.
  static const appOpenSkipFirstLaunches = 3;

  /// 백그라운드에서 돌아올 때, 마지막 앱 오프닝 광고 뒤 이만큼 지나야 다시 보여 준다.
  static const appOpenMinInterval = Duration(hours: 4);
  static const appOpenMaxPerDay = 2;

  /// 앱 시작 때 광고를 이만큼만 기다리고, 넘으면 광고 없이 넘어간다.
  static const appOpenLoadTimeout = Duration(milliseconds: 3000);

  /// 불러온 앱 오프닝 광고는 이 시간이 지나면 버리고 다시 불러온다.
  static const appOpenExpiry = Duration(hours: 4);

  static const nativeHomeEnabled = true;
  static const nativePrayerEnabled = true;

  /// 화면에 다시 들어올 때, 이전 교체 뒤 이만큼 지나야 새 네이티브 광고로 바꾼다.
  static const nativeRefreshMin = Duration(seconds: 60);

  /// 실제 광고 단위로 시험할 때 내 기기가 무효 클릭으로 잡히지 않게 등록하는 테스트 기기 ID.
  /// (광고 요청 시 logcat/Xcode 로그에 "setTestDeviceIds" 안내와 함께 출력되는 값)
  static const testDeviceIds = <String>[];

  /// 이 플랫폼·빌드에서 광고를 쓸 수 있는지. iOS 는 AdMob 에 아직 등록하지 않아 출시 빌드에서는 끈다.
  static bool get supported =>
      adsEnabled && !kIsWeb && (Platform.isAndroid || Platform.isIOS) && _units != null;

  static String get appOpenUnitId => _units!.appOpen;

  static bool placementEnabled(AdPlacement placement) => switch (placement) {
        AdPlacement.home => nativeHomeEnabled,
        AdPlacement.prayer => nativePrayerEnabled,
      };

  static String nativeUnitId(AdPlacement placement) => switch (placement) {
        AdPlacement.home => _units!.homeNative,
        AdPlacement.prayer => _units!.prayerNative,
      };

  /// 개발 중에는 Google 테스트 광고 단위만 쓴다. 실제 ID 로 내 광고를 누르면 계정이 정지될 수 있다.
  static _AdUnits? get _units {
    if (!kReleaseMode) {
      return Platform.isIOS ? _iosTest : _androidTest;
    }
    return Platform.isAndroid ? _androidRelease : null;
  }

  static const _androidRelease = _AdUnits(
    appOpen: 'ca-app-pub-6000104681344689/3487873657',
    homeNative: 'ca-app-pub-6000104681344689/9240774119',
    prayerNative: 'ca-app-pub-6000104681344689/7977783006',
  );

  static const _androidTest = _AdUnits(
    appOpen: 'ca-app-pub-3940256099942544/9257395921',
    homeNative: 'ca-app-pub-3940256099942544/2247696110',
    prayerNative: 'ca-app-pub-3940256099942544/2247696110',
  );

  static const _iosTest = _AdUnits(
    appOpen: 'ca-app-pub-3940256099942544/5575463023',
    homeNative: 'ca-app-pub-3940256099942544/3986624511',
    prayerNative: 'ca-app-pub-3940256099942544/3986624511',
  );
}

class _AdUnits {
  const _AdUnits({required this.appOpen, required this.homeNative, required this.prayerNative});

  final String appOpen;
  final String homeNative;
  final String prayerNative;
}
