import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'native_ad_controller.dart';

/// 지금 보이는 하단 탭. 광고 자리가 자기 탭에 다시 들어왔는지 알 때 쓴다.
abstract final class VisibleTab {
  static final index = ValueNotifier<int>(0);
}

/// 네이티브 광고 자리. 높이를 미리 잡아 두어 광고가 늦게 와도 화면이 밀리지 않는다.
/// 광고를 못 받으면 다음에 이 탭에 들어올 때 자리를 접는다 (보고 있는 중에 갑자기 밀리지 않게).
class NativeAdSlot extends StatefulWidget {
  const NativeAdSlot({
    super.key,
    required this.placement,
    required this.tabIndex,
    this.margin = EdgeInsets.zero,
  });

  final AdPlacement placement;

  /// 광고가 보일 때만 두는 바깥 여백 (광고가 없으면 여백도 없다).
  final EdgeInsets margin;

  /// 이 광고가 있는 하단 탭 번호.
  final int tabIndex;

  @override
  State<NativeAdSlot> createState() => _NativeAdSlotState();
}

class _NativeAdSlotState extends State<NativeAdSlot> {
  late final NativeAdController _controller = NativeAdController.of(widget.placement);
  late bool _collapsed = _controller.status.value == NativeAdStatus.unavailable;

  bool get _enabled => AdsConfig.supported && AdsConfig.placementEnabled(widget.placement);

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    _controller.start();
    VisibleTab.index.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    VisibleTab.index.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (VisibleTab.index.value != widget.tabIndex) return;
    final unavailable = _controller.status.value == NativeAdStatus.unavailable;
    _controller.onScreenEntered();
    if (unavailable != _collapsed) setState(() => _collapsed = unavailable);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _collapsed) return const SizedBox.shrink();

    final compact = widget.placement == AdPlacement.prayer;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = (compact ? 92.0 : 112.0) * math.max(1, math.min(textScale, 1.4));

    return Container(
      height: height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: NativeAdController.adCardBackground,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: const Color(0xFFE4DFD4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<NativeAd?>(
        valueListenable: _controller.shown,
        builder: (context, ad, _) => ad == null
            ? const SizedBox.expand()
            // 같은 광고가 다시 그려질 때 플랫폼 뷰를 새로 만들지 않도록 광고별 키를 둔다.
            : AdWidget(key: ObjectKey(ad), ad: ad),
      ),
    );
  }
}
