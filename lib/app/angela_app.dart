import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'app_routes.dart';

class AngelaApp extends StatelessWidget {
  const AngelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '레지오마리애 활동수첩',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.backgroundBottom,
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.builders,
    );
  }
}
