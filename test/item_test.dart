import 'package:app_shoplist/core/theme/app_colors.dart';
import 'package:app_shoplist/features/list/data/item.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('parses database time as UTC', () {
    expect(parseDbTime('2026-11-17 19:08:23'), DateTime.utc(2026, 11, 17, 19, 8, 23));
    expect(parseDbTime(null), isNull);
  });

  test('fromRow reads checked as int and blank quantity as null', () {
    final item = Item.fromRow(itemRow('a', 'Milk', qty: '  ', checked: true));
    expect(item.checked, isTrue);
    expect(item.quantity, isNull);
    expect(Item.fromRow(itemRow('b', 'Eggs', qty: ' 12 ')).quantity, '12');
  });

  test('unchecked first, newest first, unsaved items on top', () {
    final items = Item.sorted([
      Item.fromRow(itemRow('old', 'Bread', at: '2026-11-17 09:00:00')),
      Item.fromRow(itemRow('done', 'Soap', checked: true, at: '2026-11-17 12:00:00')),
      Item.fromRow(itemRow('new', 'Eggs', at: '2026-11-17 11:00:00')),
      const Item(id: 'pending', name: 'Milk', addedBy: 'm1'),
    ]);
    expect(items.map((i) => i.id), ['pending', 'new', 'old', 'done']);
  });

  test('a member keeps the same magnet color', () {
    expect(AppColors.magnetFor('member-123'), AppColors.magnetFor('member-123'));
    expect(AppColors.magnets, contains(AppColors.magnetFor('anything')));
  });
}
