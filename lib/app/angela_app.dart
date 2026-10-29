import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/text_scale/text_scale_controller.dart';
import '../core/theme/app_colors.dart';
import 'app_routes.dart';

/// 흰색 바탕 테마. Material 3 기본값은 표면에 주 색상을 살짝 섞으므로 흰색으로 고정한다.
final ThemeData _whiteTheme = () {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.accent,
    surface: Colors.white,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: AppColors.backgroundMid,
    onSurface: AppColors.title,
    secondaryContainer: AppColors.accentLight.withValues(alpha: 0.35),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.backgroundBottom,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.title,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accentLight.withValues(alpha: 0.3),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: AppColors.shadow.withValues(alpha: 0.12)),
  );
}();

class AngelaApp extends StatelessWidget {
  const AngelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '레지오마리애 활동수첩',
      debugShowCheckedModeBanner: false,
      theme: _whiteTheme,
      // 날짜·시간 선택기 등 기본 위젯 문구를 한국어로 표시한다.
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.builders,
      builder: (context, child) => ValueListenableBuilder<double>(
        valueListenable: TextScaleController.instance,
        builder: (context, appScale, _) {
          // 휴대폰 글꼴 크기 설정(지금 크기) 위에 앱 글자 크기 단계를 곱한다.
          // 상한을 넘으면 상한까지만 키우고, 휴대폰 설정보다 작아지게 하지는 않는다.
          final systemScale = MediaQuery.textScalerOf(context).scale(100) / 100;
          final scaled = math.min(systemScale * appScale, TextScaleController.maxCombinedScale);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(math.max(systemScale, scaled)),
            ),
            // 입력창 밖의 빈 곳을 탭하면 키보드를 내린다. (버튼 등 다른 위젯의 탭은 그대로 동작)
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
