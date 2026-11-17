import 'package:app_shoplist/core/appambit/db_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nulls become literal NULL and leave the other params in order', () {
    final r = AppAmbitDbService.inlineNulls('INSERT INTO items VALUES (?, ?, ?)', ['a', null, 'c']);
    expect(r.sql, 'INSERT INTO items VALUES (?, NULL, ?)');
    expect(r.params, ['a', 'c']);
  });

  test('a ? inside quotes is not a parameter', () {
    final r = AppAmbitDbService.inlineNulls("SELECT '?' WHERE a = ?", [null]);
    expect(r.sql, "SELECT '?' WHERE a = NULL");
    expect(r.params, isEmpty);
  });

  test('no nulls, no change', () {
    final r = AppAmbitDbService.inlineNulls('SELECT ?', [1]);
    expect(r.sql, 'SELECT ?');
    expect(r.params, [1]);
  });
}
