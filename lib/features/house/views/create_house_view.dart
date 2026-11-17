import 'package:flutter/material.dart';

import '../../../app_services.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/banners.dart';
import '../../../core/widgets/buttons.dart';
import '../house_controller.dart';
import 'house_code_view.dart';

class CreateHouseView extends StatefulWidget {
  const CreateHouseView({super.key, required this.services});

  final AppServices services;

  @override
  State<CreateHouseView> createState() => _CreateHouseViewState();
}

class _CreateHouseViewState extends State<CreateHouseView> {
  late final _controller = HouseController(houses: widget.services.houses, analytics: widget.services.analytics);
  final _nickname = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!HouseController.validNickname(_nickname.text)) return;
    final session = await _controller.create(_nickname.text);
    if (session == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => HouseCodeView(services: widget.services, session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, _nickname]),
          builder: (context, _) {
            final failure = _controller.failure;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: PineTextButton(label: 'Back', onPressed: () => Navigator.of(context).pop())),
                  const SizedBox(height: 12),
                  Semantics(header: true, child: const Text('Create a house', style: AppText.title)),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _nickname,
                    label: 'Your nickname',
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _create(),
                  ),
                  if (failure != null) ...[
                    const SizedBox(height: 16),
                    NoConnectionBanner(message: failure.message, onRetry: _create),
                  ],
                  const Spacer(),
                  PrimaryButton(
                    label: 'Create',
                    busy: _controller.busy,
                    onPressed: HouseController.validNickname(_nickname.text) ? _create : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
