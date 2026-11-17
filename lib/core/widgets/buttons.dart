import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Pine, 56 px, radius 14. Shows a small spinner while [busy].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.pine,
        foregroundColor: AppColors.onColor,
        disabledBackgroundColor: AppColors.pine.withValues(alpha: 0.45),
        disabledForegroundColor: AppColors.onColor,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppText.button,
        elevation: 0,
      ),
      child: busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onColor))
          : Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Transparent, 2 px pine border, pine text.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.height = 56, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.pine,
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        side: const BorderSide(color: AppColors.pine, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(height < 56 ? 12 : 14)),
        textStyle: AppText.button.copyWith(fontSize: height < 56 ? 16 : 17),
      ),
      child: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Pine text button, underlined when [underline] (e.g. "Clear checked (2)").
class PineTextButton extends StatelessWidget {
  const PineTextButton({super.key, required this.label, required this.onPressed, this.underline = false});

  final String label;
  final VoidCallback? onPressed;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.pine,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        textStyle: AppText.button.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          decoration: underline ? TextDecoration.underline : null,
          decorationColor: AppColors.pine,
        ),
      ),
      child: Text(label),
    );
  }
}
