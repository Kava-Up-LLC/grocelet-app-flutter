import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Butter banner under the header: what failed, and a Retry button.
class NoConnectionBanner extends StatelessWidget {
  const NoConnectionBanner({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(color: AppColors.butter, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: Text(message, style: AppText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3))),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.onColor,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: AppText.button.copyWith(fontSize: 15),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paper note with a small denim dot, for a form error.
class InlineNote extends StatelessWidget {
  const InlineNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ExcludeSemantics(
                child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.denim, shape: BoxShape.circle)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 15, height: 1.4))),
          ],
        ),
      ),
    );
  }
}
