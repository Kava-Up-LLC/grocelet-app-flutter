import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/appambit/analytics.dart';
import '../../core/errors.dart';
import 'data/item.dart';
import 'data/list_repository.dart';
import 'data/list_snapshot.dart';
import 'data/trip.dart';

/// The shared list and the store trip. Changes show at once and are undone if the
/// cloud can't save them.
class ListController extends ChangeNotifier {
  ListController({required ListRepository list, required Analytics analytics, required String memberId})
      : _list = list,
        _analytics = analytics,
        _memberId = memberId;

  final ListRepository _list;
  final Analytics _analytics;
  final String _memberId;

  ListSnapshot snapshot = ListSnapshot.empty;
  bool loading = true;
  bool tripBusy = false;
  AppFailure? failure;

  List<Item> get items => snapshot.items;
  Trip? get trip => snapshot.trip;
  bool get iAmShopping => trip?.shopperId == _memberId;
  int get checkedCount => items.where((i) => i.checked).length;
  bool isNew(Item item) => snapshot.isNew(item);

  /// "Leo and Sam got the alert." for the shopper's card.
  String get alertedText {
    final others = [
      for (final e in snapshot.members.entries)
        if (e.key != _memberId) e.value,
    ];
    return switch (others.length) {
      0 => 'Nobody else is in the house yet.',
      1 => '${others[0]} got the alert.',
      2 => '${others[0]} and ${others[1]} got the alert.',
      _ => '${others[0]} and ${others.length - 1} others got the alert.',
    };
  }

  Future<void> load() async {
    failure = null;
    notifyListeners();
    try {
      snapshot = await _list.load();
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

  /// "I'm at the store". Returns a message to show when someone else got there first.
  Future<String?> startShopping() async {
    if (tripBusy) return null;
    tripBusy = true;
    failure = null;
    notifyListeners();
    try {
      final result = await _list.startShopping();
      switch (result) {
        case TripStarted(:final notified):
          _analytics.track('shopping_started', {'notified': '$notified'});
          await _quietReload();
          return null;
        case TripTaken(:final shopperName):
          _analytics.track('shopping_refused');
          await _quietReload();
          return '$shopperName is already at the store.';
      }
    } on AppFailure catch (f) {
      failure = f;
      return null;
    } finally {
      tripBusy = false;
      notifyListeners();
    }
  }

  /// Ends my trip: every "New" badge goes away.
  Future<void> done() async {
    final before = snapshot;
    snapshot = ListSnapshot(items: items, trip: null, members: snapshot.members);
    failure = null;
    notifyListeners();
    try {
      await _list.done();
      _analytics.track('shopping_done');
    } on AppFailure catch (f) {
      snapshot = before;
      failure = f;
      notifyListeners();
    }
  }

  /// A ShopList notification was tapped.
  Future<void> openedFromPush() {
    _analytics.track('push_opened');
    return refresh();
  }

  Future<bool> _change(List<Item> Function() optimistic, Future<void> Function() save) async {
    final before = snapshot;
    snapshot = ListSnapshot(items: optimistic(), trip: snapshot.trip, members: snapshot.members);
    failure = null;
    notifyListeners();
    try {
      await save();
      return true;
    } on AppFailure catch (f) {
      snapshot = before;
      failure = f;
      notifyListeners();
      return false;
    }
  }

  Future<void> _quietReload() async {
    try {
      snapshot = await _list.load();
      notifyListeners();
    } on AppFailure {
      // The change already succeeded; the next refresh will catch up.
    }
  }
}
