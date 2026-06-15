import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/angela_page_background.dart';
import '../../core/widgets/brand_header.dart';
import 'auth_service.dart';
import 'models/auth_result.dart';
import 'models/social_provider.dart';
import 'signup_page.dart';
import 'widgets/social_login_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = const AuthService();
  SocialProvider? _loadingProvider;

  Future<void> _showRegistrationNotice(SocialProvider provider) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.person_add_alt_1_rounded,
          color: AppColors.accent,
          size: 36,
        ),
        title: const Text('회원가입이 필요해요'),
        content: Text(
          '${provider.label} 인증은 완료되었지만\n'
          '아직 활동수첩에 가입된 계정이 없어요.\n\n'
          '회원가입 화면으로 이동합니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('회원가입 진행'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSocialLogin(SocialProvider provider) async {
    if (_loadingProvider != null) return;

    setState(() => _loadingProvider = provider);

    try {
      final result = await _authService.signInWithProvider(provider);
      if (!mounted) return;

      switch (result) {
        case AuthAuthenticated():
          // 이미 활동수첩 회원 → 홈으로
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        case AuthNeedsRegistration(:final identity):
          // 소셜 인증은 됐으나 미가입 → 안내 후 회원가입 화면
          await _showRegistrationNotice(provider);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SignUpPage(identity: identity),
            ),
          );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('로그인 중 오류가 발생했습니다.\n$e');
    } finally {
      if (mounted) {
        setState(() => _loadingProvider = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AngelaPageBackground(
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const BrandHeader(compact: true),
                  const Spacer(flex: 2),
                  Text(
                    '로그인하고\n활동을 기록해 보세요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.title,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '카카오 또는 네이버 계정으로 간편하게 시작할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subtitle.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 36),
                  SocialLoginButton(
                    provider: SocialProvider.kakao,
                    isLoading: _loadingProvider == SocialProvider.kakao,
                    onPressed: () => _onSocialLogin(SocialProvider.kakao),
                  ),
                  const SizedBox(height: 12),
                  SocialLoginButton(
                    provider: SocialProvider.naver,
                    isLoading: _loadingProvider == SocialProvider.naver,
                    onPressed: () => _onSocialLogin(SocialProvider.naver),
                  ),
                  const Spacer(flex: 3),
                  const _TermsNotice(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      '로그인 시 서비스 이용약관 및 개인정보 처리방침에\n동의하는 것으로 간주합니다.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.subtitle.withValues(alpha: 0.65),
            height: 1.45,
            fontSize: 12,
          ),
    );
  }
}
