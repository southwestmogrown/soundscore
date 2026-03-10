import 'package:go_router/go_router.dart';

import '../../features/onboarding/onboarding_page.dart';
import '../../features/recording/recording_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/subscription/paywall_page.dart';
import '../../features/tablature/tab_viewer_page.dart';
import '../../features/sheet_music/sheet_music_page.dart';

abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: Routes.recording,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.recording,
        builder: (context, state) => const RecordingPage(),
      ),
      GoRoute(
        path: Routes.tablature,
        builder: (context, state) => const TabViewerPage(),
      ),
      GoRoute(
        path: Routes.sheetMusic,
        builder: (context, state) => const SheetMusicPage(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: Routes.paywall,
        builder: (context, state) => const PaywallPage(),
      ),
    ],
  );
}

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const recording = '/';
  static const tablature = '/tablature';
  static const sheetMusic = '/sheet-music';
  static const settings = '/settings';
  static const paywall = '/paywall';
}
