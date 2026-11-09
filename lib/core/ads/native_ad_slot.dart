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
    this.tabIndex,
    this.margin = EdgeInsets.zero,
  });

  final AdPlacement placement;

  /// 광고가 보일 때만 두는 바깥 여백 (광고가 없으면 여백도 없다).
  final EdgeInsets margin;

  /// 이 광고가 있는 하단 탭 번호. 탭이 아니라 새로 여는 화면이면 null 이며, 화면을 열 때마다 들어온 것으로 본다.
  final int? tabIndex;

  @override
  State<NativeAdSlot> createState() => _NativeAdSlotState();
}

class _NativeAdSlotState extends State<NativeAdSlot> {
  late final NativeAdController _controller = NativeAdController.of(widget.placement);
  late bool _collapsed = _controller.status.value == NativeAdStatus.unavailable;

  /// 같은 광고를 쓰던 이전 자리가 같은 프레임에 아직 정리되지 않았을 수 있어, 한 프레임 뒤에 광고를 붙인다.
  bool _attached = false;

  bool get _enabled => AdsConfig.supported && AdsConfig.placementEnabled(widget.placement);

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _attached = true);
    });
    _controller.start();
    if (widget.tabIndex == null) {
      _controller.onScreenEntered();
    } else {
      VisibleTab.index.addListener(_onTabChanged);
    }
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

    // 광고는 모두 화면 위쪽에 고정되므로 아래 내용이 넉넉히 보이도록 한 줄형 높이로 맞춘다.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = 92.0 * math.max(1, math.min(textScale, 1.4));

    return Container(
      height: height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: NativeAdController.adCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DFD4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<NativeAd?>(
        valueListenable: _controller.shown,
        builder: (context, ad, _) => ad == null || !_attached
            ? const SizedBox.expand()
            // 같은 광고가 다시 그려질 때 플랫폼 뷰를 새로 만들지 않도록 광고별 키를 둔다.
            : AdWidget(key: ObjectKey(ad), ad: ad),
      ),
    );
  }
}
