import 'dart:io';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'app_services.dart';
import 'core/appambit/analytics.dart';
import 'core/appambit/cloud_service.dart';
import 'core/appambit/db_service.dart';
import 'core/appambit/push_service.dart';
import 'core/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await dotenv.load();

  // One AppAmbit app per platform; both share the ShopListDb database.
  final appKey = Platform.isIOS ? dotenv.env['APPAMBIT_IOS_APP_KEY'] : dotenv.env['APPAMBIT_ANDROID_APP_KEY'];
  if (appKey != null && appKey.isNotEmpty) await AppAmbitSdk.start(appKey: appKey);
  const push = AppAmbitPushService();
  await push.start(); // after the core SDK, as AppAmbit asks

  final services = AppServices(
    db: const AppAmbitDbService(),
    cloud: const AppAmbitCloudService(),
    analytics: const AppAmbitAnalytics(),
    push: push,
    store: await LocalStore.open(),
    platform: Platform.isIOS ? 'ios' : 'android',
  );
  runApp(App(services: services));
}
