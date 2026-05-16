enum Flavor { dev, staging, prod }

class AppConfig {
  final Flavor flavor;
  final String appName;
  final String revenueCatApiKeyAndroid;
  final String revenueCatApiKeyIos;
  final String admobAppIdAndroid;
  final String admobAppIdIos;
  final bool enableAnalytics;
  final bool enableCrashlytics;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.revenueCatApiKeyAndroid,
    required this.revenueCatApiKeyIos,
    required this.admobAppIdAndroid,
    required this.admobAppIdIos,
    required this.enableAnalytics,
    required this.enableCrashlytics,
  });

  static AppConfig? _instance;
  static AppConfig get instance {
    assert(_instance != null, 'AppConfig not initialized. Call AppConfig.setInstance() in main.');
    return _instance!;
  }

  /// Whether [instance] has been set. Used in error handlers that run before
  /// [AppConfig.setInstance] is called.
  static bool get hasInstance => _instance != null;

  static void setInstance(AppConfig config) => _instance = config;

  bool get isDev => flavor == Flavor.dev;
  bool get isStaging => flavor == Flavor.staging;
  bool get isProd => flavor == Flavor.prod;

  // Google test AdMob IDs — replace with real IDs in prod flavor
  static const String _testAdmobAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const String _testAdmobAppIdIos = 'ca-app-pub-3940256099942544~1458002511';

  static const AppConfig dev = AppConfig(
    flavor: Flavor.dev,
    appName: 'SoundScore Dev',
    revenueCatApiKeyAndroid: 'PLACEHOLDER_REVENUECAT_ANDROID_DEV',
    revenueCatApiKeyIos: 'PLACEHOLDER_REVENUECAT_IOS_DEV',
    admobAppIdAndroid: _testAdmobAppIdAndroid,
    admobAppIdIos: _testAdmobAppIdIos,
    enableAnalytics: false,
    enableCrashlytics: false,
  );

  static const AppConfig staging = AppConfig(
    flavor: Flavor.staging,
    appName: 'SoundScore Staging',
    revenueCatApiKeyAndroid: 'PLACEHOLDER_REVENUECAT_ANDROID_STAGING',
    revenueCatApiKeyIos: 'PLACEHOLDER_REVENUECAT_IOS_STAGING',
    admobAppIdAndroid: 'PLACEHOLDER_ADMOB_APP_ID_STAGING',
    admobAppIdIos: 'PLACEHOLDER_ADMOB_APP_ID_STAGING',
    enableAnalytics: true,
    enableCrashlytics: true,
  );

  static const AppConfig prod = AppConfig(
    flavor: Flavor.prod,
    appName: 'SoundScore',
    revenueCatApiKeyAndroid: 'PLACEHOLDER_REVENUECAT_ANDROID_PROD',
    revenueCatApiKeyIos: 'PLACEHOLDER_REVENUECAT_IOS_PROD',
    admobAppIdAndroid: 'PLACEHOLDER_ADMOB_APP_ID_ANDROID',
    admobAppIdIos: 'PLACEHOLDER_ADMOB_APP_ID_IOS',
    enableAnalytics: true,
    enableCrashlytics: true,
  );
}
