import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/magnet.dart';
import '../data/item.dart';
import 'trip_widgets.dart';

/// A ruled line on the notepad: checkbox, name, quantity, who added it. Swipe left to delete.
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, required this.onToggle, required this.onDelete, this.isNew = false});

  final Item item;

  /// Added while someone is at the store.
  final bool isNew;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: AppColors.pine,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Text('Delete', style: AppText.button.copyWith(color: AppColors.onColor)),
      ),
      child: Semantics(
        checked: item.checked,
        label: [item.name, ?qty, if (isNew) 'new'].join(', '),
        excludeSemantics: true,
        onTap: onToggle,
        child: InkWell(
          onTap: onToggle,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
            child: Row(
              children: [
                _Checkbox(checked: item.checked),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: item.checked
                        ? AppText.item.copyWith(
                            color: AppColors.inkMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.inkMuted,
                          )
                        : isNew
                            ? AppText.item.copyWith(fontWeight: FontWeight.w700)
                            : AppText.item,
                  ),
                ),
                if (qty != null) ...[const SizedBox(width: 10), Text(qty, style: AppText.meta)],
                const SizedBox(width: 14),
                isNew ? const NewMagnet() : Magnet(color: AppColors.magnetFor(item.addedBy)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.pine : null,
        border: checked ? null : Border.all(color: AppColors.pine, width: 2),
      ),
      child: checked ? const Icon(Icons.check_rounded, size: 17, color: AppColors.onColor) : null,
    );
  }
}
