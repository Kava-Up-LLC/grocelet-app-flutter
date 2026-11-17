import 'package:flutter/foundation.dart';

import '../../core/appambit/analytics.dart';
import '../../core/errors.dart';
import '../../core/house_session.dart';
import 'data/house_repository.dart';

/// State for Create and Join: busy while the cloud answers, the failure if any.
class HouseController extends ChangeNotifier {
  HouseController({required HouseRepository houses, required Analytics analytics})
      : _houses = houses,
        _analytics = analytics;

  final HouseRepository _houses;
  final Analytics _analytics;

  bool busy = false;
  AppFailure? failure;

  static bool validNickname(String s) => s.trim().isNotEmpty && s.trim().length <= 20;
  static bool validCode(String s) => RegExp(r'^[A-Z]{6}$').hasMatch(s.trim().toUpperCase());

  /// Returns the new house, or null (then [failure] says why).
  Future<HouseSession?> create(String nickname) =>
      _run(() => _houses.create(nickname.trim()), 'house_created');

  Future<HouseSession?> join(String code, String nickname) =>
      _run(() => _houses.join(code.trim().toUpperCase(), nickname.trim()), 'house_joined');

  void clearFailure() {
    if (failure == null) return;
    failure = null;
    notifyListeners();
  }

  Future<HouseSession?> _run(Future<HouseSession> Function() action, String event) async {
    busy = true;
    failure = null;
    notifyListeners();
    try {
      final session = await action();
      _analytics.track(event);
      return session;
    } on AppFailure catch (f) {
      failure = f;
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
