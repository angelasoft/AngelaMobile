import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/bootstrap/bootstrap_destination.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/angela_page_background.dart';
import '../../core/widgets/brand_header.dart';

/// 앱 최초 랜딩(스플래시) 화면. 터치 시 다음 화면으로 이동한다.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  final _bootstrap = const AppBootstrap();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  BootstrapDestination? _destination;
  bool _isInitializing = true;
  bool _isNavigating = false;

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
    _initialize();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    BootstrapDestination destination;
    try {
      destination = await _bootstrap.run();
    } catch (_) {
      destination = BootstrapDestination.login;
    }

    if (!mounted) return;
    setState(() {
      _destination = destination;
      _isInitializing = false;
    });
  }

  void _onTap() {
    if (_isInitializing || _isNavigating || _destination == null) return;

    setState(() => _isNavigating = true);

    final route = switch (_destination!) {
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: AngelaPageBackground(
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
                    _BottomHint(isInitializing: _isInitializing),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomHint extends StatelessWidget {
  const _BottomHint({required this.isInitializing});

  final bool isInitializing;

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.accent.withValues(alpha: 0.75),
        ),
      );
    }

    return Text(
      '화면을 터치하세요',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.subtitle.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
    );
  }
}
