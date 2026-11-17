import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Paper field, radius 14, hard drop. Label above when [label] is set.
/// A denim ring marks an error; a pine ring marks focus.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.hasError = false,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.letterSpacing,
    this.bold = false,
    this.textInputAction,
    this.onSubmitted,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool hasError;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final double? letterSpacing;
  final bool bold;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = ListenableBuilder(
      listenable: _focus,
      builder: (context, _) {
        final ring = widget.hasError
            ? AppColors.denim
            : _focus.hasFocus
                ? AppColors.pine
                : null;
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: ring == null ? null : Border.all(color: ring, width: 2),
            boxShadow: AppColors.fieldDrop,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            style: AppText.item.copyWith(
              letterSpacing: widget.letterSpacing,
              fontWeight: widget.bold ? FontWeight.w700 : FontWeight.w500,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: AppText.item.copyWith(color: AppColors.inkMuted, fontWeight: FontWeight.w400),
            ),
          ),
        );
      },
    );
    final label = widget.label;
    if (label == null) return Semantics(label: widget.semanticLabel, child: field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Text(label, style: AppText.label), const SizedBox(height: 6), field],
    );
  }
}
