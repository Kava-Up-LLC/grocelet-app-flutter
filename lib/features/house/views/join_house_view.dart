import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_services.dart';
import '../../../core/errors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/banners.dart';
import '../../../core/widgets/buttons.dart';
import '../../list/views/shopping_list_view.dart';
import '../house_controller.dart';

class JoinHouseView extends StatefulWidget {
  const JoinHouseView({super.key, required this.services});

  final AppServices services;

  @override
  State<JoinHouseView> createState() => _JoinHouseViewState();
}

class _JoinHouseViewState extends State<JoinHouseView> {
  late final _controller = HouseController(houses: widget.services.houses, analytics: widget.services.analytics);
  final _code = TextEditingController();
  final _nickname = TextEditingController();

  bool get _ready => HouseController.validCode(_code.text) && HouseController.validNickname(_nickname.text);

  @override
  void initState() {
    super.initState();
    _code.addListener(_controller.clearFailure);
  }

  @override
  void dispose() {
    _controller.dispose();
    _code.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_ready) return;
    final session = await _controller.join(_code.text, _nickname.text);
    if (session == null || !mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => ShoppingListView(services: widget.services, session: session)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, _code, _nickname]),
          builder: (context, _) {
            final failure = _controller.failure;
            final wrongCode = failure?.kind == FailureKind.houseNotFound;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: PineTextButton(label: 'Back', onPressed: () => Navigator.of(context).pop())),
                  const SizedBox(height: 12),
                  Semantics(header: true, child: const Text('Join a house', style: AppText.title)),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _code,
                    label: 'House code',
                    autofocus: true,
                    hasError: wrongCode,
                    bold: true,
                    letterSpacing: 3.6,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(6),
                      _UpperCase(),
                    ],
                  ),
                  if (wrongCode) ...[const SizedBox(height: 12), InlineNote(text: failure!.message)],
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _nickname,
                    label: 'Your nickname',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _join(),
                  ),
                  if (failure != null && !wrongCode) ...[
                    const SizedBox(height: 16),
                    NoConnectionBanner(message: failure.message, onRetry: _join),
                  ],
                  const Spacer(),
                  PrimaryButton(label: 'Join', busy: _controller.busy, onPressed: _ready ? _join : null),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
