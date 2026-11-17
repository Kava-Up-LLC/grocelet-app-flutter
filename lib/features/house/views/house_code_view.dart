import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_services.dart';
import '../../../core/house_session.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/notepad.dart';
import '../../list/views/shopping_list_view.dart';

/// "Your house is ready": the code big, to share with the people you live with.
class HouseCodeView extends StatelessWidget {
  const HouseCodeView({super.key, required this.services, required this.session});

  final AppServices services;
  final HouseSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: const Text('Your house is ready', style: AppText.title)),
              const SizedBox(height: 24),
              Notepad(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    children: [
                      const Text('House code', style: AppText.meta),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(left: 9.7), // balances the letter spacing
                        child: Text(session.code, style: AppText.code, semanticsLabel: session.code.split('').join(' ')),
                      ),
                      const SizedBox(height: 18),
                      SecondaryButton(
                        label: 'Copy code',
                        height: 48,
                        expand: false,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: session.code));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Share this code with the people you live with. They join with it and their nickname. No accounts.',
                style: AppText.body,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => ShoppingListView(services: services, session: session)),
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
