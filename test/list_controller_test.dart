import 'package:app_shoplist/core/errors.dart';
import 'package:app_shoplist/features/list/data/list_repository.dart';
import 'package:app_shoplist/features/list/list_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeDb db;
  late FakeAnalytics analytics;
  late FakeCloud cloud;
  late ListController c;
  final now = DateTime.utc(2026, 11, 17, 18, 0);

  setUp(() {
    db = FakeDb()..rows = [itemRow('1', 'Eggs', qty: '12'), itemRow('2', 'Bread', checked: true)];
    analytics = FakeAnalytics();
    cloud = FakeCloud((_, _) => {'ok': true, 'notified': 1, 'shopping_since': '2026-11-17 18:00:00'});
    c = ListController(
      list: ListRepository(db: db, cloud: cloud, houseId: 'h1', memberId: 'me', clock: () => now),
      analytics: analytics,
      memberId: 'me',
    );
  });

  test('load shows the house list, unchecked first', () async {
    await c.load();
    expect(c.loading, isFalse);
    expect(c.items.map((i) => i.name), ['Eggs', 'Bread']);
    expect(c.checkedCount, 1);
  });

  test('offline load shows No connection and keeps going after Retry', () async {
    db.offline = true;
    await c.load();
    expect(c.failure?.kind, FailureKind.noConnection);
    db.offline = false;
    await c.refresh();
    expect(c.failure, isNull);
    expect(c.items, hasLength(2));
  });

  test('add trims, inserts and tracks; blank names are ignored', () async {
    await c.load();
    expect(await c.add('   ', '2'), isFalse);
    expect(await c.add('  Milk ', ' 2 '), isTrue);
    expect(db.writes, ['INSERT']);
    expect(analytics.events, ['item_added']);
  });

  test('a failed add is taken back and shows No connection', () async {
    await c.load();
    db.offline = true;
    expect(await c.add('Milk', ''), isFalse);
    expect(c.items.map((i) => i.name), ['Eggs', 'Bread']);
    expect(c.failure?.kind, FailureKind.noConnection);
  });

  test('toggle moves the item and is undone on failure', () async {
    await c.load();
    await c.toggle(c.items.first);
    expect(c.items.map((i) => i.checked), [true, true]);
    expect(analytics.events, ['item_checked']);
    db.offline = true;
    await c.toggle(c.items.first);
    expect(c.items.every((i) => i.checked), isTrue);
  });

  test('clear checked removes only checked items', () async {
    await c.load();
    await c.clearChecked();
    expect(c.items.map((i) => i.name), ['Eggs']);
    expect(db.writes, ['DELETE']);
    expect(analytics.events, ['checked_cleared']);
  });

  test('delete removes the item', () async {
    await c.load();
    await c.delete(c.items.first);
    expect(c.items.map((i) => i.name), ['Bread']);
    expect(analytics.events, ['item_deleted']);
  });

  test('nobody shopping: no trip, nothing is new', () async {
    await c.load();
    expect(c.trip, isNull);
    expect(c.items.any(c.isNew), isFalse);
  });

  test('items added after the trip started are New; older ones are not', () async {
    db.house = {'shopper_id': 'leo', 'shopping_since': '2026-11-17 17:30:00'};
    db.rows = [itemRow('milk', 'Milk', at: '2026-11-17 17:45:00'), itemRow('eggs', 'Eggs', at: '2026-11-17 17:00:00')];
    await c.load();
    expect(c.trip?.shopperName, 'Leo');
    expect(c.iAmShopping, isFalse);
    expect(c.items.where(c.isNew).map((i) => i.name), ['Milk']);
  });

  test('a trip older than 3 hours is over', () async {
    db.house = {'shopper_id': 'leo', 'shopping_since': '2026-11-17 14:30:00'};
    await c.load();
    expect(c.trip, isNull);
  });

  test("I'm at the store: calls start_shopping and tracks how many got the alert", () async {
    await c.load();
    db.house = {'shopper_id': 'me', 'shopping_since': '2026-11-17 18:00:00'};
    expect(await c.startShopping(), isNull);
    expect(cloud.calls.single, {'function': 'start_shopping', 'house_id': 'h1', 'member_id': 'me'});
    expect(c.iAmShopping, isTrue);
    expect(c.alertedText, 'Leo got the alert.');
    expect(analytics.events, ['shopping_started']);
  });

  test('someone got there first: a message and no trip of mine', () async {
    cloud.answer = (_, _) => {'ok': false, 'shopper': 'Leo'};
    await c.load();
    expect(await c.startShopping(), 'Leo is already at the store.');
    expect(analytics.events, ['shopping_refused']);
  });

  test('Done ends the trip and clears every New', () async {
    db.house = {'shopper_id': 'me', 'shopping_since': '2026-11-17 17:30:00'};
    db.rows = [itemRow('milk', 'Milk', at: '2026-11-17 17:45:00')];
    await c.load();
    expect(c.items.where(c.isNew), hasLength(1));
    await c.done();
    expect(c.trip, isNull);
    expect(c.items.where(c.isNew), isEmpty);
    expect(db.writes, ['UPDATE']);
    expect(analytics.events, ['shopping_done']);
  });

  test('who got the alert, in words', () async {
    db.members = [{'id': 'me', 'nickname': 'Ana'}];
    await c.load();
    expect(c.alertedText, 'Nobody else is in the house yet.');
    db.members = [{'id': 'me', 'nickname': 'Ana'}, {'id': 'l', 'nickname': 'Leo'}, {'id': 's', 'nickname': 'Sam'}, {'id': 'm', 'nickname': 'Mia'}];
    await c.load();
    expect(c.alertedText, 'Leo and 2 others got the alert.');
  });
}
