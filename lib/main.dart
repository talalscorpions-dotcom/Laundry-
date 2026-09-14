import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'routing/app_routes.dart';
import 'routing/auth_middleware.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LaundryGoApp());
}

class LaundryGoApp extends StatefulWidget {
  const LaundryGoApp({super.key});

  @override
  State<LaundryGoApp> createState() => _LaundryGoAppState();
}

class _LaundryGoAppState extends State<LaundryGoApp> {
  // Held directly (rather than only inside the Provider) so the routing
  // middleware passed to onGenerateRoute can read it without needing a
  // BuildContext of its own.
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _appState,
      child: MaterialApp(
        title: 'LaundryGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.root,
        onGenerateRoute: (settings) => AuthMiddleware.resolve(settings, _appState),
      ),
    );
  }
}
