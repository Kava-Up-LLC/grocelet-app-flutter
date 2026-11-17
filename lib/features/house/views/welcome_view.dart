import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/magnet.dart';
import 'create_house_view.dart';
import 'join_house_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 90),
              Row(
                children: [
                  for (final color in [AppColors.denim, ...AppColors.magnets.take(3)]) ...[
                    Magnet(color: color, size: 22, shaded: true),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Semantics(header: true, child: const Text('Grocelet', style: AppText.hero)),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: const Text("The whole house's grocery list. One list, everyone's phone.", style: AppText.lead),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Create a house',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => CreateHouseView(services: services)),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Join with a code',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => JoinHouseView(services: services)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
