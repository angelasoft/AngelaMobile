import 'package:flutter/material.dart';

/// 앱 전반에서 쓰는 색상. 앱 아이콘(성모님 일러스트)의 색에서 뽑은 흰색 바탕 톤.
abstract final class AppColors {
  /// 스플래시·로그인 배경 그라데이션 (흰색 → 베일의 크림색).
  static const backgroundTop = Color(0xFFFFFFFF);
  static const backgroundCream = Color(0xFFFEF6E9);

  /// 탭 화면 바탕. 흰 카드가 구분되도록 아주 옅은 아이보리.
  static const backgroundMid = Color(0xFFFAF8F4);
  static const backgroundBottom = Color(0xFFFFFFFF);

  static const title = Color(0xFF2C3E50);
  static const subtitle = Color(0xFF6B7A89);

  /// 망토의 파란색을 흰 글씨가 읽히도록 한 단계 진하게.
  static const accent = Color(0xFF4A8BC6);

  /// 망토의 하늘색.
  static const accentLight = Color(0xFF9CC6E9);

  /// 베일 테두리의 금색 (즐겨찾기 별 등).
  static const gold = Color(0xFFF2C24F);

  /// 테두리·그림자. 흰 바탕에서 푸른 기가 돌지 않도록 따뜻한 회갈색.
  static const shadow = Color(0xFF8A7B6B);

  static const kakaoYellow = Color(0xFFFEE500);
  static const kakaoText = Color(0xFF191919);
  static const naverGreen = Color(0xFF03C75A);
}
