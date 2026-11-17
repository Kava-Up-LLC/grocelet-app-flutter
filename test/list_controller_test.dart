import 'package:app_shoplist/core/errors.dart';
import 'package:app_shoplist/features/list/data/list_repository.dart';
import 'package:app_shoplist/features/list/list_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeDb db;
  late FakeAnalytics analytics;
  late ListController c;

  setUp(() {
    db = FakeDb()..rows = [itemRow('1', 'Eggs', qty: '12'), itemRow('2', 'Bread', checked: true)];
    analytics = FakeAnalytics();
    c = ListController(list: ListRepository(db: db, houseId: 'h1'), analytics: analytics, memberId: 'me');
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
}
