import 'package:flutter/material.dart';

import '../core/auth/auth_session.dart';
import '../core/presidium/current_presidium.dart';
import '../features/presidium/my_presidiums.dart';
import 'app_routes.dart';

/// 화면 밖(API 호출 등)에서 화면을 바꾸거나 안내를 띄울 때 쓰는 전역 키.
abstract final class AppNavigator {
  static final key = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// 로그인이 만료되면 쁘레시디움 상태를 비우고 로그인 화면으로 보낸다.
  static void registerSessionExpiry() {
    AuthSession.onExpired = () async {
      MyPresidiums.reset();
      await CurrentPresidium.clear();
      final navigator = key.currentState;
      if (navigator == null) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('로그인이 만료되었어요. 다시 로그인해 주세요.')));
    };
  }
}
