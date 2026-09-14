import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/customer/customer_shell.dart';
import '../screens/driver/driver_shell.dart';
import '../screens/partner/partner_shell.dart';
import '../screens/staff/staff_shell.dart';
import 'app_routes.dart';

/// The RBAC gate for the whole app. Every top-level navigation (see
/// [AppRoutes]) is resolved through [resolve] before a screen is shown —
/// this is the single place that decides "is this visitor allowed here":
///
///   - Signed out and asking for a role's shell -> redirected to sign-in.
///   - Signed in and asking for sign-in/sign-up -> redirected straight to
///     their own shell (no point re-authenticating).
///   - Signed in as the "wrong" role for the shell requested (e.g. a driver
///     deep-linking to `/admin`) -> redirected to *their own* shell rather
///     than the one they asked for.
///
/// A real backend-driven app expresses the same idea server-side — API
/// middleware checking a JWT's role claim before handling a request. This
/// is that same guard, enforced client-side over the in-memory session in
/// [AppState.currentAccount].
class AuthMiddleware {
  AuthMiddleware._();

  static Route<dynamic> resolve(RouteSettings settings, AppState appState) {
    final role = appState.currentRole;
    final name = settings.name ?? AppRoutes.root;

    if (name == AppRoutes.root) {
      return _routeTo(role == null ? AppRoutes.signIn : AppRoutes.forRole(role), settings);
    }

    if (AppRoutes.isPublicOnly(name)) {
      // Already signed in: no reason to show a sign-in/sign-up/reset form.
      if (role != null) return _routeTo(AppRoutes.forRole(role), settings);
      return _routeTo(name, settings);
    }

    final requiredRole = AppRoutes.roleFor(name);
    if (requiredRole == null) {
      // Unknown route name — send wherever the visitor currently belongs.
      return _routeTo(role == null ? AppRoutes.signIn : AppRoutes.forRole(role), settings);
    }
    if (role == null) return _routeTo(AppRoutes.signIn, settings);
    if (role != requiredRole) return _routeTo(AppRoutes.forRole(role), settings);
    return _routeTo(name, settings);
  }

  static Route<dynamic> _routeTo(String routeName, RouteSettings requestedSettings) {
    // Keep the *resolved* route's name on the Route, not the one that was
    // originally requested — a redirect should not look, to the rest of the
    // app, like the page it got redirected away from.
    final settings = RouteSettings(name: routeName, arguments: requestedSettings.arguments);
    return MaterialPageRoute(builder: (_) => _widgetFor(routeName), settings: settings);
  }

  static Widget _widgetFor(String routeName) {
    switch (routeName) {
      case AppRoutes.signIn:
        return const SignInScreen();
      case AppRoutes.signUp:
        return const SignUpScreen();
      case AppRoutes.forgotPassword:
        return const ForgotPasswordScreen();
      case AppRoutes.customer:
        return const CustomerShell();
      case AppRoutes.partner:
        return const PartnerShell();
      case AppRoutes.driver:
        return const DriverShell();
      case AppRoutes.admin:
        return const AdminShell();
      case AppRoutes.staff:
        return const StaffShell();
      default:
        // Unreachable given resolve()'s checks above.
        return const SignInScreen();
    }
  }
}
