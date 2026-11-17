import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The notepad stuck on the fridge: white paper, a glue strip on top, a hard drop.
class Notepad extends StatelessWidget {
  const Notepad({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.paperDrop,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [const SizedBox(height: 14, child: ColoredBox(color: AppColors.glue)), Flexible(child: child)],
        ),
      ),
    );
  }
}
