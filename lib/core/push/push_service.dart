import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../network/api_client.dart';

// 서버(Firebase Admin SDK)는 FCM 등록 토큰으로 보내므로, 설치 ID(FID)를 주는 register()/onRegistered 대신
// 등록 토큰 API(getToken/onTokenRefresh/deleteToken)를 쓴다.
// ignore_for_file: deprecated_member_use

/// FCM 푸시 알림. 로그인한 사용자의 기기 토큰을 서버에 등록하고, 받은 알림을 화면에 알린다.
///
/// 앱이 꺼져 있거나 뒤에 있을 때는 휴대폰이 알림을 직접 띄우고,
/// 앱을 쓰는 중에 온 알림은 [received] 로 알려 화면에서 안내한다.
class PushService {
  PushService._();

  static final instance = PushService._();

  /// 앱을 쓰는 중에 받은 알림.
  final received = ValueNotifier<RemoteMessage?>(null);

  /// 알림을 눌러 앱이 열렸을 때 (알림함으로 이동할 때 쓴다).
  final opened = ValueNotifier<RemoteMessage?>(null);

  final _client = const ApiClient();
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefresh;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 앱 시작 때 한 번. Firebase 설정이 실패해도 앱은 푸시 없이 동작한다.
  Future<void> init() async {
    if (!_supported || _initialized) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onMessage.listen((message) => received.value = message);
      FirebaseMessaging.onMessageOpenedApp.listen((message) => opened.value = message);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) opened.value = initial;
      _initialized = true;
    } catch (e) {
      debugPrint('[Push] Firebase 초기화 실패: $e');
    }
  }

  /// 로그인한 뒤 메인 화면에 들어올 때. 알림 권한을 묻고 이 기기 토큰을 내 계정에 등록한다.
  Future<void> registerDevice() async {
    if (!_initialized) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[Push] 알림 권한이 거부되었습니다.');
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);
      _tokenRefresh ??= FirebaseMessaging.instance.onTokenRefresh.listen(_sendToken);
    } catch (e) {
      debugPrint('[Push] 토큰 등록 실패: $e');
    }
  }

  /// 로그아웃 전에. 이 기기로 더 이상 내 알림이 오지 않게 한다.
  Future<void> unregisterDevice() async {
    if (!_initialized) return;
    try {
      await _tokenRefresh?.cancel();
      _tokenRefresh = null;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _client.delete('/app/notifications/push-tokens?token=${Uri.encodeQueryComponent(token)}');
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[Push] 토큰 해제 실패: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    await _client.post('/app/notifications/push-tokens', {
      'token': token,
      'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
    });
  }
}
