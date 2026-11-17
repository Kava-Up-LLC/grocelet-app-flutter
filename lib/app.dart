import 'package:flutter/material.dart';

import 'app_services.dart';
import 'core/theme/app_theme.dart';
import 'features/house/views/welcome_view.dart';
import 'features/list/views/shopping_list_view.dart';

class App extends StatelessWidget {
  const App({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final session = services.houses.current;
    return MaterialApp(
      title: 'Grocelet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: session == null
          ? WelcomeView(services: services)
          : ShoppingListView(services: services, session: session),
    );
  }
}
