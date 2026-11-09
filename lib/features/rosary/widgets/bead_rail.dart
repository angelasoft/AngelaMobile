import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../rosary_data.dart';

/// 화면 오른쪽의 세로 나무 묵주. 바친 알은 나무색 그대로, 남은 알은 흐리게, 지금 알은 파란 테두리로 강조하고
/// 지금 알이 가운데 오도록 따라 내려간다. 알을 누르면 그 기도로 바로 간다.
class BeadRail extends StatefulWidget {
  const BeadRail({
    super.key,
    required this.steps,
    required this.current,
    required this.onSelect,
  });

  final List<RosaryStep> steps;
  final int current;
  final ValueChanged<int> onSelect;

  static const width = 72.0;

  @override
  State<BeadRail> createState() => _BeadRailState();
}

/// 나무 묵주 색.
abstract final class _Wood {
  static const light = Color(0xFFDDB385);
  static const mid = Color(0xFFA9763F);
  static const dark = Color(0xFF6B4223);
  static const cord = Color(0xFFB8956E);

  /// 왼쪽 위에서 빛을 받은 둥근 나무 알.
  static const bead = RadialGradient(
    center: Alignment(-0.35, -0.4),
    radius: 0.95,
    colors: [light, mid, dark],
    stops: [0.0, 0.55, 1.0],
  );

  /// 나뭇결이 보이도록 세로로 밝고 어두운 띠를 둔 십자가.
  static const grain = LinearGradient(
    colors: [dark, mid, light, mid, dark],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// 남은 알은 흐리게.
  static const upcomingOpacity = 0.35;
}

class _BeadRailState extends State<BeadRail> {
  final _controller = ScrollController();
  late List<double> _offsets = _computeOffsets();

  static double _extent(BeadKind kind) => switch (kind) {
        BeadKind.cross => 80,
        BeadKind.large => 62,
        BeadKind.small => 44,
        BeadKind.end => 62,
      };

  List<double> _computeOffsets() {
    final offsets = <double>[];
    var y = 0.0;
    for (final step in widget.steps) {
      offsets.add(y);
      y += _extent(step.kind);
    }
    return offsets;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent(animate: false));
  }

  @override
  void didUpdateWidget(BeadRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps) _offsets = _computeOffsets();
    if (oldWidget.current != widget.current) _scrollToCurrent(animate: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToCurrent({required bool animate}) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final step = widget.steps[widget.current];
    final target = (_offsets[widget.current] + _extent(step.kind) / 2 - position.viewportDimension / 2)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (animate) {
      _controller.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: BeadRail.width,
      child: ListView.builder(
        controller: _controller,
        padding: EdgeInsets.zero,
        itemCount: widget.steps.length,
        itemBuilder: (context, index) {
          final step = widget.steps[index];
          final extent = _extent(step.kind);
          return SizedBox(
            height: extent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onSelect(index),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: index == 0 ? extent / 2 : 0,
                    bottom: index == widget.steps.length - 1 ? extent / 2 : 0,
                    child: Container(width: 2, color: _Wood.cord),
                  ),
                  _bead(step, index),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bead(RosaryStep step, int index) {
    final isCurrent = index == widget.current;
    final isUpcoming = index > widget.current;

    final Widget bead = switch (step.kind) {
      BeadKind.cross => const _WoodCross(),
      BeadKind.end => _WoodBead(
          size: isCurrent ? 48 : 42,
          child: const Icon(Icons.favorite, size: 16, color: Color(0xFFFFF4E6)),
        ),
      BeadKind.large => _WoodBead(
          size: isCurrent ? 50 : 42,
          child: step.decade == null ? null : _BeadLabel('${step.decade}단'),
        ),
      BeadKind.small => _WoodBead(
          size: isCurrent ? 36 : 28,
          child: isCurrent && step.bead != null ? _BeadLabel('${step.bead}') : null,
        ),
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isUpcoming ? _Wood.upcomingOpacity : 1,
      child: isCurrent ? _CurrentRing(isCross: step.kind == BeadKind.cross, child: bead) : bead,
    );
  }
}

class _WoodBead extends StatelessWidget {
  const _WoodBead({required this.size, this.child});

  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _Wood.bead,
        border: Border.all(color: _Wood.dark.withValues(alpha: 0.5), width: 0.8),
        boxShadow: [
          BoxShadow(color: _Wood.dark.withValues(alpha: 0.35), blurRadius: 3, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _BeadLabel extends StatelessWidget {
  const _BeadLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFFF4E6),
        shadows: [Shadow(color: _Wood.dark, blurRadius: 2)],
      ),
    );
  }
}

/// 지금 바치는 알: 앱의 파란색 테두리와 은은한 빛.
class _CurrentRing extends StatelessWidget {
  const _CurrentRing({required this.isCross, required this.child});

  final bool isCross;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: isCross ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isCross ? BorderRadius.circular(10) : null,
        border: Border.all(color: AppColors.accent, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 1)],
      ),
      child: child,
    );
  }
}

class _WoodCross extends StatelessWidget {
  const _WoodCross();

  @override
  Widget build(BuildContext context) {
    final shadow = [BoxShadow(color: _Wood.dark.withValues(alpha: 0.35), blurRadius: 3, offset: const Offset(0, 2))];
    return SizedBox(
      width: 40,
      height: 62,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 10,
            height: 62,
            decoration: BoxDecoration(
              gradient: _Wood.grain,
              borderRadius: BorderRadius.circular(2.5),
              boxShadow: shadow,
            ),
          ),
          Positioned(
            top: 14,
            child: Container(
              width: 36,
              height: 10,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_Wood.light, _Wood.mid, _Wood.dark],
                ),
                borderRadius: BorderRadius.circular(2.5),
                boxShadow: shadow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
