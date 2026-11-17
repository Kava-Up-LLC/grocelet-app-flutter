import '../../../core/appambit/cloud_service.dart';
import '../../../core/appambit/db_service.dart';
import '../../../core/errors.dart';
import 'item.dart';
import 'list_snapshot.dart';
import 'trip.dart';

/// The house's list and trip in ShopListDb. Every query is scoped to this house.
class ListRepository {
  ListRepository({required DbService db, required CloudService cloud, required String houseId, required String memberId, DateTime Function()? clock})
      : _db = db,
        _cloud = cloud,
        _houseId = houseId,
        _memberId = memberId,
        _clock = clock ?? DateTime.now;

  final DbService _db;
  final CloudService _cloud;
  final String _houseId;
  final String _memberId;
  final DateTime Function() _clock;

  Future<ListSnapshot> load() async {
    final results = await Future.wait([
      _db.query('SELECT id, name, quantity, checked, added_by, created_at FROM items WHERE house_id = ?', [_houseId]),
      _db.query('SELECT shopper_id, shopping_since FROM houses WHERE id = ?', [_houseId]),
      _db.query('SELECT id, nickname FROM members WHERE house_id = ?', [_houseId]),
    ]);
    final members = {for (final m in results[2]) m['id'] as String: m['nickname'] as String};
    final house = results[1].isEmpty ? null : results[1].first;
    final shopperId = house?['shopper_id'] as String?;
    final since = parseDbTime(house?['shopping_since'] as String?);
    Trip? trip;
    if (shopperId != null && since != null) {
      final t = Trip(shopperId: shopperId, shopperName: members[shopperId] ?? 'Someone', since: since);
      if (t.isActive(_clock().toUtc())) trip = t;
    }
    return ListSnapshot(items: Item.sorted(results[0].map(Item.fromRow)), trip: trip, members: members);
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

  /// "I'm at the store": the cloud claims the trip and notifies the rest of the house.
  Future<TripStart> startShopping() async {
    final res = await _cloud.call('start_shopping', {'house_id': _houseId, 'member_id': _memberId});
    if (res['ok'] == true) return TripStarted((res['notified'] as num?)?.toInt() ?? 0);
    if (res.containsKey('shopper')) return TripTaken((res['shopper'] as String?) ?? 'Someone');
    throw AppFailure(FailureKind.unexpected, res['error']);
  }

  /// Ends my trip. Only the shopper can.
  Future<void> done() => _db.execute(
        'UPDATE houses SET shopper_id = NULL, shopping_since = NULL WHERE id = ? AND shopper_id = ?',
        [_houseId, _memberId],
      );
}
