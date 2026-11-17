/// One thing to buy.
class Item {
  const Item({
    required this.id,
    required this.name,
    this.quantity,
    this.checked = false,
    required this.addedBy,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? quantity;
  final bool checked;
  final String addedBy;

  /// From the database clock (UTC). Null only for an item still on its way to the cloud.
  final DateTime? createdAt;

  factory Item.fromRow(Map<String, dynamic> row) => Item(
        id: row['id'] as String,
        name: row['name'] as String,
        quantity: (row['quantity'] as String?)?.trim().isEmpty ?? true ? null : (row['quantity'] as String).trim(),
        checked: (row['checked'] as num? ?? 0) != 0,
        addedBy: row['added_by'] as String,
        createdAt: parseDbTime(row['created_at'] as String?),
      );

  Item copyWith({bool? checked}) =>
      Item(id: id, name: name, quantity: quantity, checked: checked ?? this.checked, addedBy: addedBy, createdAt: createdAt);

  /// Unchecked first; newest first inside each group. Items not saved yet count as newest.
  static List<Item> sorted(Iterable<Item> items) {
    final list = items.toList();
    list.sort((a, b) {
      if (a.checked != b.checked) return a.checked ? 1 : -1;
      final at = a.createdAt, bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return -1;
      if (bt == null) return 1;
      final byTime = bt.compareTo(at);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return list;
  }
}

/// SQLite `datetime('now')` text ("2026-11-17 19:08:23", UTC) → DateTime (UTC).
DateTime? parseDbTime(String? text) {
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse('${text.replaceFirst(' ', 'T')}Z');
}
