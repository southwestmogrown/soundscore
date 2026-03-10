import 'core/config/app_config.dart';
import 'bootstrap.dart';

void main() {
  AppConfig.setInstance(AppConfig.staging);
  bootstrap();
}
