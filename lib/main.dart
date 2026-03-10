// Default entry point — dev flavor.
// Use flavor-specific targets for store builds:
//   flutter run --flavor dev     -t lib/main_dev.dart
//   flutter run --flavor staging -t lib/main_staging.dart
//   flutter run --flavor prod    -t lib/main_prod.dart
import 'core/config/app_config.dart';
import 'bootstrap.dart';

void main() {
  AppConfig.setInstance(AppConfig.dev);
  bootstrap();
}
