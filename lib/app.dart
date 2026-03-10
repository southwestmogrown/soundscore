import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';

class SoundScoreApp extends StatelessWidget {
  const SoundScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.instance.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: AppConfig.instance.isDev,
    );
  }
}
