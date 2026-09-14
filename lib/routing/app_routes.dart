import '../models/enums.dart';

/// Named top-level destinations. Only these (plus [root]) go through the
/// RBAC middleware in `auth_middleware.dart` — screens pushed from within a
/// role's shell (catalog, cart, order detail, ...) use ordinary unnamed
/// `Navigator.push` since they're already behind a route the middleware has
/// approved.
class AppRoutes {
  AppRoutes._();

  static const root = '/';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const customer = '/customer';
  static const partner = '/partner';
  static const driver = '/driver';
  static const admin = '/admin';
  static const staff = '/staff';

  /// Routes reachable only while signed out — visiting one while already
  /// signed in redirects to the caller's own role shell instead.
  static bool isPublicOnly(String name) => name == signIn || name == signUp || name == forgotPassword;

  static String forRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return customer;
      case UserRole.partner:
        return partner;
      case UserRole.driver:
        return driver;
      case UserRole.admin:
        return admin;
      case UserRole.staff:
        return staff;
    }
  }

  /// The role a guarded shell route requires, or null if [name] isn't one
  /// (sign-in/sign-up/root/unknown).
  static UserRole? roleFor(String name) {
    if (name == customer) return UserRole.customer;
    if (name == partner) return UserRole.partner;
    if (name == driver) return UserRole.driver;
    if (name == admin) return UserRole.admin;
    if (name == staff) return UserRole.staff;
    return null;
  }
}
