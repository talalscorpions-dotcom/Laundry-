import 'dart:convert';

import 'package:crypto/crypto.dart';

/// NOT production security. This exists only so this in-memory demo never
/// stores or compares plaintext passwords, even locally. A real backend
/// must hash passwords with bcrypt/argon2/scrypt **server-side**, salted
/// per-user, and passwords must never be sent to or checked by client-side
/// code the way this demo does for simplicity — this function, and the
/// sign-in/sign-up methods on [AppState] that call it, are exactly the
/// pieces a real build replaces with calls to an auth backend/provider.
String hashPasswordForDemo(String password) {
  final bytes = utf8.encode('laundrygo-demo-salt::$password');
  return sha256.convert(bytes).toString();
}
