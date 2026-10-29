import 'package:flutter/services.dart';

/// 1344000 → "1,344,000"
String formatWon(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

/// "1,344,000" → 1344000. 숫자가 없으면 null.
int? parseWon(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.parse(digits);
}

/// 금액 입력칸: 숫자만 받고 세 자리마다 쉼표를 넣는다.
class WonInputFormatter extends TextInputFormatter {
  const WonInputFormatter();

  static const _maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final text = digits.isEmpty ? '' : formatWon(int.parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
