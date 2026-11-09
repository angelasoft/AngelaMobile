import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../text_scale/text_scale_controller.dart';
import '../theme/app_colors.dart';
import 'ads_config.dart';
import 'ads_service.dart';

enum NativeAdStatus { loading, ready, unavailable }

/// 화면(위치)마다 광고 1개를 보여 주고 다음 광고 1개를 미리 불러 둔다.
/// 화면에 다시 들어왔을 때 지금 광고가 실제로 노출됐고, [AdsConfig.nativeRefreshMin] 이 지났고,
/// 다음 광고가 준비됐을 때만 바꾼다.
class NativeAdController {
  NativeAdController._(this.placement);

  static final _controllers = <AdPlacement, NativeAdController>{};

  static NativeAdController of(AdPlacement placement) =>
      _controllers.putIfAbsent(placement, () => NativeAdController._(placement));

  final AdPlacement placement;

  /// 화면에 보여 줄 광고. [status] 가 ready 일 때만 값이 있다.
  final shown = ValueNotifier<NativeAd?>(null);
  final status = ValueNotifier<NativeAdStatus>(NativeAdStatus.loading);

  NativeAd? _next;
  bool _nextReady = false;
  bool _impressed = false;
  DateTime _lastSwap = DateTime.fromMillisecondsSinceEpoch(0);
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!await AdsService.instance.ready) {
      status.value = NativeAdStatus.unavailable;
      return;
    }
    _load(asCurrent: true);
  }

  /// 광고가 있는 화면(탭)에 들어올 때.
  void onScreenEntered() {
    if (status.value == NativeAdStatus.unavailable) {
      _retryIfDue();
      return;
    }
    if (!_impressed || !_nextReady) return;
    if (DateTime.now().difference(_lastSwap) < AdsConfig.nativeRefreshMin) return;
    final old = shown.value;
    shown.value = _next;
    status.value = NativeAdStatus.ready;
    _next = null;
    _nextReady = false;
    _impressed = false;
    _lastSwap = DateTime.now();
    // 이전 광고 위젯이 화면에서 빠진 뒤에 해제한다.
    SchedulerBinding.instance.addPostFrameCallback((_) => old?.dispose());
    _load(asCurrent: false);
  }

  /// 광고를 못 받은 자리는 화면에 다시 들어올 때 가끔 다시 요청한다.
  Future<void> _retryIfDue() async {
    if (!_started || !await AdsService.instance.ready) return;
    if (DateTime.now().difference(_lastSwap) < AdsConfig.nativeRefreshMin) return;
    _lastSwap = DateTime.now();
    status.value = NativeAdStatus.loading;
    _load(asCurrent: true);
  }

  void _load({required bool asCurrent}) {
    late final NativeAd ad;
    ad = NativeAd(
      adUnitId: AdsConfig.nativeUnitId(placement),
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(videoOptions: VideoOptions(startMuted: true)),
      nativeTemplateStyle: _templateStyle(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (asCurrent) {
            shown.value = ad;
            status.value = NativeAdStatus.ready;
            _lastSwap = DateTime.now();
            _load(asCurrent: false);
          } else {
            _next = ad;
            _nextReady = true;
          }
        },
        onAdFailedToLoad: (failed, error) {
          debugPrint('[Ads] ${placement.name} 네이티브 광고 로드 실패: ${error.message}');
          failed.dispose();
          if (asCurrent) status.value = NativeAdStatus.unavailable;
        },
        onAdImpression: (_) {
          if (identical(shown.value, ad)) _impressed = true;
        },
      ),
    );
    ad.load();
  }

  /// 앱 글자 크기 단계에 맞춰 광고 글자도 키운다 (불러올 때의 크기로 고정된다).
  static NativeTemplateStyle _templateStyle() {
    final scale = TextScaleController.instance.value;
    NativeTemplateTextStyle text(Color color, double size, {bool bold = false}) => NativeTemplateTextStyle(
          textColor: color,
          size: size * scale,
          style: bold ? NativeTemplateFontStyle.bold : NativeTemplateFontStyle.normal,
        );
    return NativeTemplateStyle(
      templateType: TemplateType.small,
      mainBackgroundColor: adCardBackground,
      cornerRadius: 10,
      primaryTextStyle: text(AppColors.title, 15, bold: true),
      secondaryTextStyle: text(AppColors.subtitle, 13),
      tertiaryTextStyle: text(AppColors.subtitle, 12),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: const Color(0xFFFFFFFF),
        backgroundColor: AppColors.accent,
        size: 13 * scale,
        style: NativeTemplateFontStyle.bold,
      ),
    );
  }

  static const adCardBackground = Color(0xFFFCFBF8);
}
