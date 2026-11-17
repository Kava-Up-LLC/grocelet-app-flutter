import 'core/appambit/analytics.dart';
import 'core/appambit/cloud_service.dart';
import 'core/appambit/db_service.dart';
import 'core/appambit/push_service.dart';
import 'core/local_store.dart';
import 'features/house/data/house_repository.dart';

/// Everything the screens need, built once in main.dart and passed down by constructor.
class AppServices {
  AppServices({required this.db, required this.cloud, required this.analytics, required this.push, required this.store, required this.platform})
      : houses = HouseRepository(cloud: cloud, store: store, platform: platform);

  final DbService db;
  final CloudService cloud;
  final Analytics analytics;
  final PushService push;
  final LocalStore store;
  final String platform;
  final HouseRepository houses;
}
