import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/magnet.dart';

/// Someone else is at the store: paper card, denim avatar with their initial.
class SomeoneShoppingCard extends StatelessWidget {
  const SomeoneShoppingCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return _SlideIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.fieldDrop),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.denim, shape: BoxShape.circle),
              child: ExcludeSemantics(
                child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: AppText.cardTitle.copyWith(color: AppColors.onColor, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name is at the store', style: AppText.cardTitle),
                  const SizedBox(height: 2),
                  Text('Add what you need now. $name will see it.', style: AppText.meta.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// I'm at the store: soft denim card with Done.
class MyTripCard extends StatelessWidget {
  const MyTripCard({super.key, required this.alerted, required this.onDone});

  final String alerted;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _SlideIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(color: AppColors.denimSoft, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.softDrop),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You're at the store", style: AppText.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(alerted, style: AppText.meta.copyWith(fontSize: 14, color: AppColors.inkOnSoft)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.denim,
                foregroundColor: AppColors.onColor,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: AppText.button.copyWith(fontSize: 16),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The big denim button, only when nobody is at the store.
class StoreButton extends StatelessWidget {
  const StoreButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: AppColors.denimDrop),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.denim,
            foregroundColor: AppColors.onColor,
            disabledBackgroundColor: AppColors.denim,
            disabledForegroundColor: AppColors.onColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: AppText.button.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          child: busy
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onColor))
              : const Text("I'm at the store"),
        ),
      ),
    );
  }
}

/// The denim "New" magnet, slightly crooked. Pops in once.
class NewMagnet extends StatelessWidget {
  const NewMagnet({super.key});

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    final magnet = Transform.rotate(
      angle: -0.07, // about −4°
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.denim,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: AppColors.denimDeep, offset: Offset(0, 2))],
        ),
        child: const Text('New', style: AppText.magnet),
      ),
    );
    if (still) return magnet;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: magnet,
    );
  }
}

/// One line asking for notifications, before the system prompt.
class NotificationsNote extends StatelessWidget {
  const NotificationsNote({super.key, required this.onTurnOn, required this.onNotNow});

  final VoidCallback onTurnOn;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.fieldDrop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 6), child: Magnet(color: AppColors.denim, size: 10)),
              const SizedBox(width: 10),
              Expanded(child: Text('Turn on notifications to know when someone is at the store.', style: AppText.body.copyWith(fontSize: 15, height: 1.35))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onNotNow,
                style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted, minimumSize: const Size(48, 44), textStyle: AppText.button.copyWith(fontSize: 15)),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: onTurnOn,
                style: TextButton.styleFrom(foregroundColor: AppColors.pine, minimumSize: const Size(48, 44), textStyle: AppText.button.copyWith(fontSize: 15)),
                child: const Text('Turn on'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, -12 * (1 - t)), child: child)),
      child: child,
    );
  }
}
