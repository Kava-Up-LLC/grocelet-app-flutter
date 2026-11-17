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

/// Home: the house's list on the fridge.
class ShoppingListView extends StatefulWidget {
  const ShoppingListView({super.key, required this.services, required this.session});

  final AppServices services;
  final HouseSession session;

  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> {
  late final _controller = ListController(
    list: ListRepository(db: widget.services.db, houseId: widget.session.houseId),
    analytics: widget.services.analytics,
    memberId: widget.session.memberId,
  );
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _controller.load();
    // "Everyone sees the same list": reload whenever the app comes back to the front.
    _lifecycle = AppLifecycleListener(onResume: _controller.refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final added = await _controller.add(_name.text, _quantity.text);
    if (added) {
      _name.clear();
      _quantity.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final failure = _controller.failure;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(code: widget.session.code),
                  if (failure != null) ...[
                    const SizedBox(height: 18),
                    NoConnectionBanner(message: failure.message, onRetry: _controller.refresh),
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
