import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// 갱신 토큰으로 새 토큰을 받은 결과.
enum RefreshResult {
  /// 새 토큰 한 쌍을 받았다.
  refreshed,

  /// 갱신 토큰이 없거나 서버가 거절했다 (만료·로그아웃·탈취 대응). 다시 로그인해야 한다.
  rejected,

  /// 서버에 연결하지 못했다. 세션은 그대로 두고 나중에 다시 시도한다.
  offline,
}

/// 서버에 연결하지 못해 토큰을 갱신하지 못했을 때.
class SessionOfflineException implements Exception {
  const SessionOfflineException();

  @override
  String toString() => '서버에 연결하지 못했습니다. 네트워크 연결을 확인해 주세요.';
}

/// 로그인 세션. 접근 토큰(1시간)이 만료되면 갱신 토큰(60일)으로 사용자 모르게 새로 받고,
/// 갱신까지 실패하면 [expire] 로 로그인 화면으로 보낸다.
abstract final class AuthSession {
  static const _tokenStorage = TokenStorage();

  /// 로그인한 뒤 true, 로그아웃·만료 뒤 false. 로그인 화면에서 같은 처리를 되풀이하지 않게 한다.
  static bool _active = false;

  /// 세션이 끝났을 때 할 일 (상태 정리, 로그인 화면 이동). 앱 시작 시 등록한다.
  static Future<void> Function()? onExpired;

  /// 여러 요청이 동시에 갱신하려 해도 서버에는 한 번만 요청한다 (갱신 토큰은 한 번 쓰면 바뀐다).
  static Future<RefreshResult>? _refreshing;

  static _ResumeWatcher? _resumeWatcher;

  static bool get isActive => _active;

  static void markSignedIn() => _active = true;

  static void markSignedOut() => _active = false;

  /// 앱을 켤 때: 갱신 토큰이 살아 있으면 로그인 상태를 되살린다. 앱 회원가입까지 마친 회원이면 true.
  /// 서버에 연결하지 못하면 저장된 토큰을 믿고 홈으로 간다 (요청할 때 다시 갱신한다).
  static Future<bool> restore() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;
    final (result, registered) = await _refreshNow();
    switch (result) {
      case RefreshResult.refreshed:
        if (!registered) return false;
        _active = true;
        return true;
      case RefreshResult.rejected:
        await _tokenStorage.clear();
        return false;
      case RefreshResult.offline:
        final hasAccess = await _tokenStorage.readAccessToken() != null;
        _active = hasAccess;
        return hasAccess;
    }
  }

  /// 요청에 쓸 접근 토큰. 만료됐으면 먼저 갱신한다.
  /// 다시 로그인해야 하면 세션을 끝내고(로그인 화면으로) null, 서버에 연결하지 못하면 [SessionOfflineException].
  static Future<String?> accessToken() async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && !isExpired(token)) return token;
    return _renewOrExpire();
  }

  /// 서버가 401 을 돌려줬을 때: 한 번 갱신해 새 접근 토큰을 돌려준다. 실패하면 [accessToken] 과 같다.
  static Future<String?> renewAfterUnauthorized() => _renewOrExpire();

  static Future<String?> _renewOrExpire() async {
    final result = await refresh();
    switch (result) {
      case RefreshResult.refreshed:
        return _tokenStorage.readAccessToken();
      case RefreshResult.rejected:
        await expire();
        return null;
      case RefreshResult.offline:
        throw const SessionOfflineException();
    }
  }

  /// 갱신 토큰으로 새 토큰 한 쌍을 받는다. 동시에 불러도 서버 요청은 한 번.
  static Future<RefreshResult> refresh() {
    return _refreshing ??= _refreshNow().then((r) => r.$1).whenComplete(() => _refreshing = null);
  }

  static Future<(RefreshResult, bool)> _refreshNow() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return (RefreshResult.rejected, false);
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/app/auth/token/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return (RefreshResult.offline, false);
    }
    if (response.statusCode == 401 || response.statusCode == 400) return (RefreshResult.rejected, false);
    if (response.statusCode != 200) return (RefreshResult.offline, false);
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
      return (RefreshResult.refreshed, json['registered'] as bool? ?? true);
    } catch (_) {
      return (RefreshResult.offline, false);
    }
  }

  /// 로그아웃: 서버에서 이 기기의 갱신 토큰을 끊는다 (실패해도 앱에서는 지운다).
  static Future<void> revokeOnServer() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return;
    try {
      await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/app/auth/logout'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // 네트워크가 없어도 로그아웃은 진행한다. 서버의 토큰은 기간이 지나면 만료된다.
    }
  }

  /// 세션을 끝내고 로그인 화면으로 보낸다. 이미 끝났으면 아무것도 하지 않는다.
  static Future<void> expire() async {
    if (!_active) return;
    _active = false;
    await _tokenStorage.clear();
    await onExpired?.call();
  }

  /// 앱으로 돌아왔을 때: 접근 토큰이 만료됐으면 미리 갱신하고, 갱신할 수 없으면 로그인 화면으로.
  static Future<void> checkToken() async {
    if (!_active) return;
    try {
      await accessToken();
    } on SessionOfflineException {
      // 오프라인이면 다음 요청 때 다시 시도한다.
    }
  }

  /// 앱으로 돌아올 때마다 [checkToken]. 메인 화면에서 한 번 부른다.
  static void watchAppResume() {
    if (_resumeWatcher != null) return;
    _resumeWatcher = _ResumeWatcher();
    WidgetsBinding.instance.addObserver(_resumeWatcher!);
  }

  /// JWT 의 exp(만료 시각)가 지났는지. 시계 차이를 감안해 [leeway] 만큼 일찍 만료로 본다.
  /// 형식을 읽을 수 없으면 서버 판단(401)에 맡긴다.
  static bool isExpired(String token, {Duration leeway = const Duration(seconds: 30), DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload is Map<String, dynamic> ? payload['exp'] : null;
      if (exp is! num) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return !(now ?? DateTime.now()).add(leeway).isBefore(expiresAt);
    } catch (_) {
      return false;
    }
  }
}

class _ResumeWatcher with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) AuthSession.checkToken();
  }
}
