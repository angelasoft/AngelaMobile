import 'dart:convert';

import 'package:angelamobile/core/auth/auth_session.dart';
import 'package:angelamobile/core/storage/token_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(DateTime expiresAt) {
  String part(Map<String, dynamic> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = expiresAt.millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256'})}.${part({'sub': '1', 'exp': exp})}.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = <String, String>{};

  setUp(() {
    // flutter_secure_storage 를 메모리로 대신한다.
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
        switch (call.method) {
          case 'write':
            store[args['key'] as String] = args['value'] as String;
          case 'read':
            return store[args['key']];
          case 'delete':
            store.remove(args['key']);
        }
        return null;
      },
    );
  });

  test('토큰 만료 시각을 읽는다', () {
    final now = DateTime(2026, 11, 10, 21, 0);
    expect(AuthSession.isExpired(_jwt(now.add(const Duration(minutes: 10))), now: now), isFalse);
    expect(AuthSession.isExpired(_jwt(now.subtract(const Duration(minutes: 1))), now: now), isTrue);
    // 30초 안에 끝나는 토큰은 미리 만료로 본다.
    expect(AuthSession.isExpired(_jwt(now.add(const Duration(seconds: 10))), now: now), isTrue);
    // 읽을 수 없는 형식은 서버 판단(401)에 맡긴다.
    expect(AuthSession.isExpired('not-a-jwt', now: now), isFalse);
  });

  test('갱신 토큰이 없으면 자동 로그인하지 않는다', () async {
    expect(await AuthSession.restore(), isFalse);
    expect(AuthSession.isActive, isFalse);
  });

  test('만료되면 접근·갱신 토큰을 모두 지운다', () async {
    const storage = TokenStorage();
    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
    AuthSession.onExpired = () async {};
    AuthSession.markSignedIn();
    await AuthSession.expire();
    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });

  test('로그인 중일 때만 한 번 로그인 화면으로 보낸다', () async {
    var calls = 0;
    AuthSession.onExpired = () async => calls++;

    await AuthSession.expire();
    expect(calls, 0, reason: '로그인 전(로그인 화면)에는 아무것도 하지 않는다');

    AuthSession.markSignedIn();
    await AuthSession.expire();
    await AuthSession.expire();
    expect(calls, 1, reason: '여러 요청이 동시에 401 을 받아도 한 번만 이동한다');

    AuthSession.markSignedIn();
    AuthSession.markSignedOut();
    await AuthSession.expire();
    expect(calls, 1, reason: '직접 로그아웃한 뒤에는 만료 처리하지 않는다');
  });
}
