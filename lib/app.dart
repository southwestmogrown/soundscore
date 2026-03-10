import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'features/tablature/bloc/tab_bloc.dart';
import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';

class SoundScoreApp extends StatelessWidget {
  const SoundScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TabBloc lives at the app level so it persists across page navigation.
    // RecordingPage adds notes; TabViewerPage reads them.
    return BlocProvider(
      create: (_) => TabBloc(),
      child: MaterialApp.router(
        title:                      AppConfig.instance.appName,
        theme:                      AppTheme.light,
        darkTheme:                  AppTheme.dark,
        themeMode:                  ThemeMode.system,
        routerConfig:               AppRouter.router,
        debugShowCheckedModeBanner: AppConfig.instance.isDev,
      ),
    );
  }
}
