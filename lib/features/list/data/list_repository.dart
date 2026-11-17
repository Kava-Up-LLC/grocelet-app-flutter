import '../../../core/appambit/db_service.dart';
import 'item.dart';

/// The house's items in ShopListDb. Every query is scoped to this house.
class ListRepository {
  ListRepository({required DbService db, required String houseId})
      : _db = db,
        _houseId = houseId;

  final DbService _db;
  final String _houseId;

  Future<List<Item>> load() async {
    final rows = await _db.query(
      'SELECT id, name, quantity, checked, added_by, created_at FROM items WHERE house_id = ?',
      [_houseId],
    );
    return Item.sorted(rows.map(Item.fromRow));
  }

  /// created_at is left to the database clock.
  Future<void> add(Item item) => _db.execute(
        'INSERT INTO items (id, house_id, name, quantity, added_by) VALUES (?, ?, ?, ?, ?)',
        [item.id, _houseId, item.name, item.quantity, item.addedBy],
      );

  Future<void> setChecked(String id, bool checked) => _db.execute(
        'UPDATE items SET checked = ? WHERE id = ? AND house_id = ?',
        [checked ? 1 : 0, id, _houseId],
      );

  Future<void> delete(String id) =>
      _db.execute('DELETE FROM items WHERE id = ? AND house_id = ?', [id, _houseId]);

  Future<int> clearChecked() =>
      _db.execute('DELETE FROM items WHERE house_id = ? AND checked = 1', [_houseId]);
}
