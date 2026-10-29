import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 글자 크기 단계. 지금 크기(100%)가 기준이고 130% 까지 키울 수 있다.
///
/// 130% 는 휴대폰 "큰 글꼴" 설정과 비슷한 크기로, 화면 배치가 깨지지 않는 최대치다.
/// 선택한 단계는 기기에 저장되어 앱을 다시 켜도 유지된다.
class TextScaleController extends ValueNotifier<double> {
  TextScaleController._(this._prefs, double initial) : super(initial);

  static const steps = [1.0, 1.1, 1.2, 1.3];

  /// 휴대폰 자체 글꼴 크기 설정까지 곱했을 때의 상한.
  static const maxCombinedScale = 1.6;

  static const _prefsKey = 'app_text_scale';

  static late final TextScaleController instance;

  final SharedPreferences _prefs;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsKey) ?? steps.first;
    instance = TextScaleController._(prefs, steps.contains(saved) ? saved : steps.first);
  }

  int get _index => steps.indexOf(value);

  bool get canIncrease => _index < steps.length - 1;
  bool get canDecrease => _index > 0;

  /// 화면 표시용. 예: "120%"
  String get percentLabel => '${(value * 100).round()}%';

  void increase() => _set(_index + 1);

  void decrease() => _set(_index - 1);

  void _set(int index) {
    if (index < 0 || index >= steps.length) return;
    value = steps[index];
    _prefs.setDouble(_prefsKey, value);
  }
}
