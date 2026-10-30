import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/push/push_service.dart';
import '../../core/storage/token_storage.dart';
import 'models/auth_result.dart';
import 'models/oauth_identity.dart';
import 'models/sign_up_request.dart';
import 'models/social_provider.dart';

/// 소셜 로그인 실패/취소 시 발생하는 예외.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// 소셜 로그인 + 활동수첩 회원가입을 AngelaCore와 연동한다.
///
/// 흐름:
///   1) 인앱 브라우저로 `{baseUrl}/app/auth/oauth/{kakao|naver}` 열기
///      → 소셜 인증 후 AngelaCore가 `angela://oauth/callback?token=...&registered=...`
///        딥링크로 되돌려준다.
///   2) registered=true  → 이미 가입된 회원 → [AuthAuthenticated]
///      registered=false → 소셜 인증만 됨 → [AuthNeedsRegistration] → 회원가입 폼
///   3) 회원가입 폼 제출 → [register] → `POST {baseUrl}/app/auth/signup`
class AuthService {
  const AuthService({TokenStorage tokenStorage = const TokenStorage()})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  Future<AuthResult> signInWithProvider(SocialProvider provider) async {
    final authUrl =
        '${AppConfig.baseUrl}/app/auth/oauth/${provider.registrationId}';

    final String callback;
    try {
      callback = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: AppConfig.oauthCallbackScheme,
      );
    } on PlatformException catch (e) {
      // 사용자가 인증창을 직접 닫은 경우
      if (e.code == 'CANCELED' || e.code == 'user_cancelled') {
        throw const AuthException('로그인을 취소했습니다.');
      }
      // 그 외 플랫폼 오류(서버 미실행, URL 오류 등)
      throw AuthException(
        '[${e.code}] ${e.message ?? "알 수 없는 오류가 발생했습니다."}'
        '\n\n서버가 실행 중인지 확인해 주세요.',
      );
    } catch (e) {
      throw AuthException('로그인 중 오류가 발생했습니다.\n$e');
    }

    final uri = Uri.parse(callback);
    final oauthError = uri.queryParameters['error'];
    if (oauthError != null && oauthError.isNotEmpty) {
      final description = uri.queryParameters['error_description'];
      debugPrint('[OAuth callback error] $oauthError ${description ?? ""}');
      // 다른 소셜 계정으로 가입된 이메일: 서버가 보낸 안내 문구를 그대로 보여 준다.
      if (oauthError == 'provider_mismatch' && description != null && description.isNotEmpty) {
        throw AuthException(description);
      }
      throw AuthException(
        '소셜 인증에 실패했습니다.\n'
        'error: $oauthError\n'
        '${description == null || description.isEmpty ? "" : "detail: $description"}',
      );
    }

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      debugPrint('[OAuth callback] token is missing: $callback');
      throw const AuthException(
        '인증 토큰을 받지 못했습니다.\n'
        '카카오 콘솔 Redirect URI와 앱/서버 주소(localhost) 설정을 확인해 주세요.',
      );
    }

    await _tokenStorage.saveAccessToken(token);

    final registered = uri.queryParameters['registered'] == 'true';
    if (registered) {
      return const AuthAuthenticated();
    }

    return AuthNeedsRegistration(
      OAuthIdentity(
        provider: provider,
        providerId: uri.queryParameters['providerId'] ?? '',
        email: uri.queryParameters['email'] ?? '',
      ),
    );
  }

  Future<void> register(SignUpRequest request) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) {
      throw const AuthException('인증 정보가 없습니다. 다시 로그인해 주세요.');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/app/auth/signup'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw AuthException('회원가입에 실패했습니다. (${response.statusCode})');
    }
  }

  /// 로그인 토큰이 남아 있을 때 기기 푸시 등록을 먼저 해제한다.
  Future<void> signOut() async {
    await PushService.instance.unregisterDevice();
    await _tokenStorage.clear();
  }
}
