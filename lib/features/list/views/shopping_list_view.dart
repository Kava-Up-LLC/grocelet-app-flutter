import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_services.dart';
import '../../../core/house_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/banners.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/notepad.dart';
import '../data/list_repository.dart';
import '../list_controller.dart';
import '../widgets/add_item_bar.dart';
import '../widgets/item_tile.dart';
import '../widgets/trip_widgets.dart';

/// Home: the house's list on the fridge, and the trip to the store.
class ShoppingListView extends StatefulWidget {
  const ShoppingListView({super.key, required this.services, required this.session});

  final AppServices services;
  final HouseSession session;

  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> {
  late final _controller = ListController(
    list: ListRepository(
      db: widget.services.db,
      cloud: widget.services.cloud,
      houseId: widget.session.houseId,
      memberId: widget.session.memberId,
    ),
    analytics: widget.services.analytics,
    memberId: widget.session.memberId,
  );
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _askForNotifications = ValueNotifier(false);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _controller.load();
    // "Everyone sees the same list": reload whenever the app comes back to the front.
    _lifecycle = AppLifecycleListener(onResume: _controller.refresh);
    final push = widget.services.push;
    push.listen(onArrived: (_) => _controller.refresh(), onOpened: (_) => _controller.openedFromPush());
    widget.services.houses.refreshMembership();
    _maybeAskForNotifications();
  }

  Future<void> _maybeAskForNotifications() async {
    if (widget.services.store.askedForNotifications) return;
    if (await widget.services.push.hasPermission()) return;
    _askForNotifications.value = true;
  }

  Future<void> _answerNotifications({required bool turnOn}) async {
    _askForNotifications.value = false;
    await widget.services.store.markAskedForNotifications();
    if (!turnOn) return;
    await widget.services.push.requestPermission();
    widget.services.houses.refreshMembership(); // the push registration may be new
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    _name.dispose();
    _quantity.dispose();
    _askForNotifications.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final added = await _controller.add(_name.text, _quantity.text);
    if (added) {
      _name.clear();
      _quantity.clear();
    }
  }

  Future<void> _startShopping() async {
    final message = await _controller.startShopping();
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListenableBuilder(
            listenable: Listenable.merge([_controller, _askForNotifications]),
            builder: (context, _) {
              final failure = _controller.failure;
              final trip = _controller.trip;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(code: widget.session.code),
                  if (failure != null) ...[
                    const SizedBox(height: 18),
                    NoConnectionBanner(message: failure.message, onRetry: _controller.refresh),
                  ],
                  if (_askForNotifications.value) ...[
                    const SizedBox(height: 18),
                    NotificationsNote(
                      onTurnOn: () => _answerNotifications(turnOn: true),
                      onNotNow: () => _answerNotifications(turnOn: false),
                    ),
                  ],
                  if (trip != null) ...[
                    const SizedBox(height: 18),
                    _controller.iAmShopping
                        ? MyTripCard(alerted: _controller.alertedText, onDone: _controller.done)
                        : SomeoneShoppingCard(name: trip.shopperName),
                  ],
                  const SizedBox(height: 18),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Notepad(child: _ItemsOnPaper(controller: _controller)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AddItemBar(name: _name, quantity: _quantity, onAdd: _add),
                  if (trip == null) ...[
                    const SizedBox(height: 14),
                    StoreButton(onPressed: _startShopping, busy: _controller.tripBusy),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Semantics(header: true, child: const Text('ShopList', style: AppText.title))),
        Semantics(
          button: true,
          label: 'Copy house code ${code.split('').join(' ')}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.fieldDrop,
              ),
              child: Text(code, style: AppText.chip),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemsOnPaper extends StatelessWidget {
  const _ItemsOnPaper({required this.controller});

  final ListController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.items;
    final checked = controller.checkedCount;
    return RefreshIndicator(
      color: AppColors.pine,
      onRefresh: controller.refresh,
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (controller.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: AppColors.pine, strokeWidth: 2.4)),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 48, 24, 48),
              child: Column(
                children: [
                  Text('Nothing on the list yet.', style: AppText.body, textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text('Add the first item below.', style: AppText.meta, textAlign: TextAlign.center),
                ],
              ),
            )
          else
            for (final item in items)
              ItemTile(
                key: ValueKey(item.id),
                item: item,
                isNew: controller.isNew(item),
                onToggle: () => controller.toggle(item),
                onDelete: () => controller.delete(item),
              ),
          if (checked > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PineTextButton(label: 'Clear checked ($checked)', underline: true, onPressed: controller.clearChecked),
              ),
            ),
        ],
      ),
    );
  }
}
