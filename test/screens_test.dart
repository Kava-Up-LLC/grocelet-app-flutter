import 'package:app_shoplist/app.dart';
import 'package:app_shoplist/app_services.dart';
import 'package:app_shoplist/core/house_session.dart';
import 'package:app_shoplist/core/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<AppServices> services(FakeDb db, {bool withHouse = false}) async {
  SharedPreferences.setMockInitialValues({'asked_notifications': true});
  final store = await LocalStore.open();
  if (withHouse) {
    await store.saveSession(HouseSession(houseId: 'h1', code: 'KTMRQW', nickname: 'Ana', memberId: store.memberId));
  }
  return AppServices(
    db: db,
    cloud: FakeCloud((_, _) => {'ok': true, 'house_id': 'h1', 'code': 'KTMRQW'}),
    analytics: FakeAnalytics(),
    push: FakePush(),
    store: store,
    platform: 'ios',
  );
}

void main() {
  testWidgets('no house yet: Welcome with Create and Join', (tester) async {
    await tester.pumpWidget(App(services: await services(FakeDb())));
    expect(find.text('Grocelet'), findsOneWidget);
    expect(find.text('Create a house'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
  });

  testWidgets('create a house → the code → the list', (tester) async {
    await tester.pumpWidget(App(services: await services(FakeDb())));
    await tester.tap(find.text('Create a house'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump(); // the button turns on once there is a nickname
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Your house is ready'), findsOneWidget);
    expect(find.text('KTMRQW'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing on the list yet.'), findsOneWidget);
  });

  testWidgets('with a house: the list, Clear checked, and No connection', (tester) async {
    final db = FakeDb()..rows = [itemRow('1', 'Eggs', qty: '12'), itemRow('2', 'Bread', checked: true)];
    await tester.pumpWidget(App(services: await services(db, withHouse: true)));
    await tester.pumpAndSettle();
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Clear checked (1)'), findsOneWidget);

    db.offline = true;
    await tester.enterText(find.byType(TextField).first, 'Milk');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text("No connection. Changes can't be saved right now."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets("nobody shopping shows I'm at the store; Leo shopping shows his card and New", (tester) async {
    final db = FakeDb()..rows = [itemRow('1', 'Eggs')];
    await tester.pumpWidget(App(services: await services(db, withHouse: true)));
    await tester.pumpAndSettle();
    expect(find.text("I'm at the store"), findsOneWidget);

    final since = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
    String db_(DateTime t) => t.toIso8601String().substring(0, 19).replaceFirst('T', ' ');
    db.house = {'shopper_id': 'leo', 'shopping_since': db_(since)};
    db.rows = [itemRow('1', 'Eggs', at: db_(since.subtract(const Duration(hours: 1)))), itemRow('2', 'Milk', qty: '2', at: db_(since.add(const Duration(minutes: 2))))];
    await tester.drag(find.text('Eggs'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Leo is at the store'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text("I'm at the store"), findsNothing);
  });
}
