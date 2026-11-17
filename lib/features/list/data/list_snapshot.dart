import 'item.dart';
import 'trip.dart';

/// Everything the list screen shows, read together.
class ListSnapshot {
  const ListSnapshot({required this.items, required this.trip, required this.members});

  final List<Item> items;

  /// Null when nobody is at the store (or the last trip is older than 3 hours).
  final Trip? trip;

  /// member id → nickname, for "Leo and Sam got the alert."
  final Map<String, String> members;

  static const empty = ListSnapshot(items: [], trip: null, members: {});

  /// "New" = added after the trip started. An item still on its way to the cloud is new too.
  bool isNew(Item item) {
    final t = trip;
    if (t == null) return false;
    final created = item.createdAt;
    return created == null || !created.isBefore(t.since);
  }
}
