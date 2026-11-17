import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/appambit/analytics.dart';
import '../../core/errors.dart';
import 'data/item.dart';
import 'data/list_repository.dart';

/// The shared list. Changes show at once and are undone if the cloud can't save them.
class ListController extends ChangeNotifier {
  ListController({required ListRepository list, required Analytics analytics, required String memberId})
      : _list = list,
        _analytics = analytics,
        _memberId = memberId;

  final ListRepository _list;
  final Analytics _analytics;
  final String _memberId;

  List<Item> items = const [];
  bool loading = true;
  AppFailure? failure;

  int get checkedCount => items.where((i) => i.checked).length;

  Future<void> load() async {
    failure = null;
    notifyListeners();
    try {
      items = await _list.load();
    } on AppFailure catch (f) {
      failure = f;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Same as [load]; kept separate so the view reads like what the user did.
  Future<void> refresh() => load();

  /// Returns false when nothing was added (empty name or no connection).
  Future<bool> add(String name, String quantity) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;
    final cleanQty = quantity.trim();
    final item = Item(id: const Uuid().v4(), name: cleanName, quantity: cleanQty.isEmpty ? null : cleanQty, addedBy: _memberId);
    final ok = await _change(() => Item.sorted([item, ...items]), () => _list.add(item));
    if (ok) {
      _analytics.track('item_added');
      await _quietReload(); // picks up created_at from the database clock
    }
    return ok;
  }

  Future<void> toggle(Item item) async {
    final next = !item.checked;
    final ok = await _change(
      () => Item.sorted(items.map((i) => i.id == item.id ? i.copyWith(checked: next) : i)),
      () => _list.setChecked(item.id, next),
    );
    if (ok && next) _analytics.track('item_checked');
  }

  Future<void> delete(Item item) async {
    final ok = await _change(() => items.where((i) => i.id != item.id).toList(), () => _list.delete(item.id));
    if (ok) _analytics.track('item_deleted');
  }

  Future<void> clearChecked() async {
    final count = checkedCount;
    if (count == 0) return;
    final ok = await _change(() => items.where((i) => !i.checked).toList(), _list.clearChecked);
    if (ok) _analytics.track('checked_cleared', {'count': '$count'});
  }

  Future<bool> _change(List<Item> Function() optimistic, Future<void> Function() save) async {
    final before = items;
    items = optimistic();
    failure = null;
    notifyListeners();
    try {
      await save();
      return true;
    } on AppFailure catch (f) {
      items = before;
      failure = f;
      notifyListeners();
      return false;
    }
  }

  Future<void> _quietReload() async {
    try {
      items = await _list.load();
      notifyListeners();
    } on AppFailure {
      // The add already succeeded; the next refresh will catch up.
    }
  }
}
