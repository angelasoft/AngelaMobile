import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_config.dart';
import 'ads_service.dart';

/// 앱 오프닝 광고. 앱을 켤 때(스플래시)와 오래 쉬었다가 돌아올 때만, 하루 횟수를 정해 보여 준다.
/// 닫기·노출 시간은 SDK 가 정하며 광고 위에 다른 안내를 겹치지 않는다.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final instance = AppOpenAdManager._();

  static const _launchCountKey = 'ads.launchCount';
  static const _lastShownKey = 'ads.appOpen.lastShownAt';
  static const _dayKey = 'ads.appOpen.day';
  static const _dayCountKey = 'ads.appOpen.dayCount';

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _loading = false;
  bool _showing = false;
  bool _suppressNextResume = false;
  bool _wentToBackground = false;
  Completer<void>? _loadWaiter;
  AppLifecycleListener? _lifecycle;

  bool get _hasFreshAd =>
      _ad != null && _loadedAt != null && DateTime.now().difference(_loadedAt!) < AdsConfig.appOpenExpiry;

  /// 앱 실행 횟수를 센다. 스플래시에서 한 번.
  Future<void> recordLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_launchCountKey, (prefs.getInt(_launchCountKey) ?? 0) + 1);
  }

  void load() {
    if (_loading || _hasFreshAd) return;
    _ad?.dispose();
    _ad = null;
    _loading = true;
    AppOpenAd.load(
      adUnitId: AdsConfig.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
          _completeWaiter();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[Ads] 앱 오프닝 광고 로드 실패: ${error.message}');
          _loading = false;
          _completeWaiter();
        },
      ),
    );
  }

  /// 스플래시에서. 조건이 맞고 [deadline] 전에 광고가 준비되면 보여 주고 사용자가 닫을 때까지 기다린다.
  /// 광고가 없거나 늦으면 바로 끝난다.
  Future<void> showOnLaunch({required DateTime deadline}) async {
    if (!AdsConfig.appOpenEnabled) return;
    Duration remaining() {
      final left = deadline.difference(DateTime.now());
      return left.isNegative ? Duration.zero : left;
    }

    final ready = await AdsService.instance.ready.timeout(remaining(), onTimeout: () => false);
    if (!ready) return;
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_launchCountKey) ?? 0) <= AdsConfig.appOpenSkipFirstLaunches) return;
    if (_todayCount(prefs) >= AdsConfig.appOpenMaxPerDay) return;

    if (!_hasFreshAd) {
      load();
      _loadWaiter ??= Completer<void>();
      await _loadWaiter!.future.timeout(remaining(), onTimeout: () {});
    }
    if (!_hasFreshAd) return;
    await _show(prefs);
  }

  /// 메인 화면에 들어간 뒤부터 백그라운드 → 포그라운드 복귀를 지켜본다.
  void watchAppResume() {
    if (_lifecycle != null) return;
    // 로그인 화면에서 남은 "다음 복귀 무시"는 메인 화면에서는 필요 없다.
    _suppressNextResume = false;
    _lifecycle = AppLifecycleListener(
      onHide: () => _wentToBackground = true,
      onResume: () {
        if (!_wentToBackground) return;
        _wentToBackground = false;
        _showOnResume();
      },
    );
  }

  /// 로그인 브라우저처럼 앱이 직접 연 화면에서 돌아올 때는 광고를 띄우지 않는다.
  void suppressNextResume() => _suppressNextResume = true;

  Future<void> _showOnResume() async {
    if (_suppressNextResume) {
      _suppressNextResume = false;
      return;
    }
    if (!AdsConfig.appOpenEnabled || _showing || !await AdsService.instance.ready) return;
    final prefs = await SharedPreferences.getInstance();
    if (_todayCount(prefs) >= AdsConfig.appOpenMaxPerDay) return;
    final lastShown = prefs.getInt(_lastShownKey);
    if (lastShown != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastShown)) < AdsConfig.appOpenMinInterval) {
      return;
    }
    if (!_hasFreshAd) {
      load();
      return;
    }
    await _show(prefs);
  }

  Future<void> _show(SharedPreferences prefs) async {
    final ad = _ad!;
    _ad = null;
    _showing = true;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _recordShown(prefs),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[Ads] 앱 오프닝 광고 표시 실패: ${error.message}');
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );
    await ad.show();
    await closed.future;
    _showing = false;
    // 광고 화면이 닫히며 생기는 복귀는 광고 표시 대상이 아니다.
    _wentToBackground = false;
    load();
  }

  int _todayCount(SharedPreferences prefs) =>
      prefs.getString(_dayKey) == _today() ? prefs.getInt(_dayCountKey) ?? 0 : 0;

  void _recordShown(SharedPreferences prefs) {
    final count = _todayCount(prefs) + 1;
    prefs
      ..setString(_dayKey, _today())
      ..setInt(_dayCountKey, count)
      ..setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
  }

  void _completeWaiter() {
    final waiter = _loadWaiter;
    _loadWaiter = null;
    if (waiter != null && !waiter.isCompleted) waiter.complete();
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
