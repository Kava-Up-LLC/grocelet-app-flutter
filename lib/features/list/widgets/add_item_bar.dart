import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/buttons.dart';

/// Item name + optional quantity + Add, under the notepad.
class AddItemBar extends StatelessWidget {
  const AddItemBar({super.key, required this.name, required this.quantity, required this.onAdd});

  final TextEditingController name;
  final TextEditingController quantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: name,
            hint: 'Add an item',
            semanticLabel: 'Item',
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: AppTextField(
            controller: quantity,
            hint: 'Qty',
            semanticLabel: 'Quantity',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: name,
          builder: (context, _) =>
              PrimaryButton(label: 'Add', expand: false, onPressed: name.text.trim().isEmpty ? null : onAdd),
        ),
      ],
    );
  }
}
