import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'app_open_ad_manager.dart';
import 'native_ad_controller.dart';

/// 광고 SDK 준비. 동의(유럽 GDPR, iOS 추적 허용 안내)를 먼저 받은 뒤 SDK 를 초기화하고 광고를 미리 불러온다.
class AdsService {
  AdsService._();

  static final instance = AdsService._();

  /// 동의 정보 갱신을 이만큼만 기다린다 (네트워크가 느리면 이번 실행은 광고 없이).
  static const _consentTimeout = Duration(seconds: 3);

  final _ready = Completer<bool>();
  bool _started = false;

  /// 광고를 요청할 수 있으면 true. [init] 이 끝나야 완료된다.
  Future<bool> get ready => _ready.future;

  /// 스플래시에서 한 번. 동의 화면이 필요하면 여기서 보여 준다.
  Future<void> init() async {
    if (_started) return ready.then((_) {});
    _started = true;
    if (!AdsConfig.supported) {
      _ready.complete(false);
      return;
    }
    try {
      final canRequestAds = await _gatherConsent();
      if (canRequestAds) {
        await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          testDeviceIds: AdsConfig.testDeviceIds,
        ));
        await MobileAds.instance.initialize();
      }
      _ready.complete(canRequestAds);
      if (canRequestAds) _preload();
    } catch (e) {
      debugPrint('[Ads] 초기화 실패: $e');
      if (!_ready.isCompleted) _ready.complete(false);
    }
  }

  Future<bool> _gatherConsent() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(),
      (error) {
        debugPrint('[Ads] 동의 정보 갱신 실패: ${error.message}');
        updated.complete();
      },
    );
    await updated.future.timeout(_consentTimeout, onTimeout: () {});
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) debugPrint('[Ads] 동의 화면 오류: ${error.message}');
    });
    return ConsentInformation.instance.canRequestAds();
  }

  void _preload() {
    if (AdsConfig.appOpenEnabled) AppOpenAdManager.instance.load();
    for (final placement in AdPlacement.values) {
      if (AdsConfig.placementEnabled(placement)) NativeAdController.of(placement).start();
    }
  }
}
