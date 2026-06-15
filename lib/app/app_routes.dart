import 'package:flutter/material.dart';

import '../features/auth/login_page.dart';
import '../features/main/main_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/splash/splash_page.dart';
import '../features/update/force_update_page.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const onboarding = '/onboarding';
  static const forceUpdate = '/force-update';

  static Map<String, WidgetBuilder> get builders => {
        splash: (_) => const SplashPage(),
        login: (_) => const LoginPage(),
        home: (_) => const MainPage(),
        onboarding: (_) => const OnboardingPage(),
        forceUpdate: (_) => const ForceUpdatePage(),
      };
}
