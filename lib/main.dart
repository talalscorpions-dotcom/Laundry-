import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'models/enums.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/driver/driver_shell.dart';
import 'screens/partner/partner_shell.dart';
import 'screens/role_select_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LaundryGoApp());
}

class LaundryGoApp extends StatelessWidget {
  const LaundryGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'LaundryGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Routes to the right role's app based on who is "signed in" — the demo's
/// stand-in for real authentication/session handling.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().currentRole;
    if (role == null) return const RoleSelectScreen();
    if (role == UserRole.customer) return const CustomerShell();
    if (role == UserRole.partner) return const PartnerShell();
    if (role == UserRole.driver) return const DriverShell();
    return const AdminShell();
  }
}
