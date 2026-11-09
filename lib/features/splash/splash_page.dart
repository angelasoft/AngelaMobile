import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/ads/ads_config.dart';
import '../../core/ads/ads_service.dart';
import '../../core/ads/app_open_ad_manager.dart';
import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/bootstrap/bootstrap_destination.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/angela_page_background.dart';
import '../../core/widgets/brand_header.dart';

/// 앱 최초 랜딩(스플래시) 화면. 초기화(광고 동의 포함)가 끝나면 조건에 따라 앱 오프닝 광고를 보여 준 뒤
/// 스스로 다음 화면으로 넘어간다.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  final _bootstrap = const AppBootstrap();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    // 동의 화면 등 광고 SDK 화면은 첫 화면이 그려진 뒤에 띄울 수 있다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final adDeadline = DateTime.now().add(AdsConfig.appOpenLoadTimeout);
    unawaited(AdsService.instance.init());
    final launch = AppOpenAdManager.instance.recordLaunch();
    final minimumSplash = Future<void>.delayed(const Duration(milliseconds: 1200));
    BootstrapDestination destination;
    try {
      destination = await _bootstrap.run();
    } catch (_) {
      destination = BootstrapDestination.login;
    }
    await Future.wait([launch, minimumSplash]);
    await AppOpenAdManager.instance.showOnLaunch(deadline: adDeadline);

    if (!mounted) return;
    final route = switch (destination) {
      BootstrapDestination.home => AppRoutes.home,
      BootstrapDestination.login => AppRoutes.login,
      BootstrapDestination.onboarding => AppRoutes.onboarding,
      BootstrapDestination.forceUpdate => AppRoutes.forceUpdate,
    };
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AngelaPageBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  const BrandHeader(),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accent.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
