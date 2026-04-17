import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/storage/preferences_service.dart';
import 'features/settings/bloc/settings_bloc.dart';
import 'features/settings/bloc/settings_event.dart';
import 'features/settings/bloc/settings_state.dart';
import 'features/tablature/bloc/tab_bloc.dart';
import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';

class SoundScoreApp extends StatelessWidget {
  const SoundScoreApp({super.key, this.preferencesService});

  final PreferencesService? preferencesService;

  @override
  Widget build(BuildContext context) {
    final prefs = preferencesService ?? PreferencesService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TabBloc()),
        BlocProvider(
          create: (_) => SettingsBloc(preferencesService: prefs)
            ..add(const SettingsLoadRequested()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (prev, next) => prev.themeMode != next.themeMode,
        builder: (context, settings) {
          return MaterialApp.router(
            title: AppConfig.instance.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _resolveThemeMode(settings.themeMode),
            routerConfig: AppRouter.router(preferencesService: prefs),
            debugShowCheckedModeBanner: AppConfig.instance.isDev,
          );
        },
      ),
    );
  }

  static ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
