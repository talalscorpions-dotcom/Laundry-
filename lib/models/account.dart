import 'enums.dart';

/// A registered login for the platform. Customer/Partner/Driver accounts
/// each control exactly one underlying domain record — see [linkedId],
/// which points at a [Customer]/[LaundryPartner]/[Driver] id. Admin
/// accounts have no linked record: an admin isn't a marketplace
/// participant, just an operator of the platform.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.linkedId,
  });

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final UserRole role;
  final String? linkedId;
}

/// Outcome of a sign-in/sign-up attempt: either the [Account] that is now
/// signed in, or a human-readable [error] to show the user.
class AuthResult {
  const AuthResult.success(this.account) : error = null;

  const AuthResult.failure(this.error) : account = null;

  final Account? account;
  final String? error;

  bool get isSuccess => account != null;
}

