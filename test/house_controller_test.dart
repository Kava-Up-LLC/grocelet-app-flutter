import 'package:app_shoplist/core/errors.dart';
import 'package:app_shoplist/core/local_store.dart';
import 'package:app_shoplist/features/house/data/house_repository.dart';
import 'package:app_shoplist/features/house/house_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late LocalStore store;
  late FakeAnalytics analytics;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    analytics = FakeAnalytics();
  });

  HouseController controller(FakeCloud cloud) =>
      HouseController(houses: HouseRepository(cloud: cloud, store: store, platform: 'ios'), analytics: analytics);

  test('create calls join_house, remembers the house and tracks it', () async {
    final cloud = FakeCloud((_, _) => {'ok': true, 'house_id': 'h1', 'code': 'KTMRQW'});
    final session = await controller(cloud).create('  Ana ');
    expect(session?.code, 'KTMRQW');
    expect(cloud.calls.single, {'function': 'join_house', 'action': 'create', 'nickname': 'Ana', 'member_id': store.memberId, 'platform': 'ios'});
    expect(store.session?.houseId, 'h1');
    expect(analytics.events, ['house_created']);
  });

  test('join sends the code in capitals', () async {
    final cloud = FakeCloud((_, body) => {'ok': true, 'house_id': 'h1', 'code': body['code']});
    final session = await controller(cloud).join(' ktmrqw ', 'Leo');
    expect(cloud.calls.single['code'], 'KTMRQW');
    expect(session?.nickname, 'Leo');
    expect(analytics.events, ['house_joined']);
  });

  test('a wrong code says so and remembers nothing', () async {
    final c = controller(FakeCloud((_, _) => {'ok': false, 'error': 'HOUSE_NOT_FOUND'}));
    expect(await c.join('ZZZZZZ', 'Leo'), isNull);
    expect(c.failure?.kind, FailureKind.houseNotFound);
    expect(c.busy, isFalse);
    expect(store.session, isNull);
  });

  test('the member id is created once and kept', () {
    expect(store.memberId, store.memberId);
  });

  test('nickname and code rules', () {
    expect(HouseController.validNickname('  '), isFalse);
    expect(HouseController.validNickname('Ana'), isTrue);
    expect(HouseController.validCode('ktmrqw'), isTrue);
    expect(HouseController.validCode('KTMRQ'), isFalse);
  });
}
