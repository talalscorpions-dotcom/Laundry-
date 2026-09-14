// Smoke tests for the LaundryGo app's auth/RBAC flow: signed-out visitors
// land on sign-in, sign-in/sign-up hand off to the right role's shell, and
// the demo accounts seeded in MockData actually work.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laundrygo/main.dart';

Future<void> _fillField(WidgetTester tester, String label, String value) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), value);
}

void main() {
  testWidgets('Shows the sign-in screen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());
    await tester.pumpAndSettle();

    expect(find.text('LaundryGo'), findsWidgets);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });

  testWidgets('Signing in with the demo customer account opens the customer shell', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());
    await tester.pumpAndSettle();

    await _fillField(tester, 'Email', 'aisha@example.com');
    await _fillField(tester, 'Password', 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Browse'), findsOneWidget);
    expect(find.textContaining('Sparkle Laundry'), findsOneWidget);
  });

  testWidgets('An incorrect password is rejected with an error, not a crash', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());
    await tester.pumpAndSettle();

    await _fillField(tester, 'Email', 'aisha@example.com');
    await _fillField(tester, 'Password', 'wrong-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget); // still on the sign-in screen
  });

  testWidgets('Signing up as a new customer opens the customer shell', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await _fillField(tester, 'Full name', 'Test Customer');
    await _fillField(tester, 'Email', 'newcustomer@example.com');
    await _fillField(tester, 'Password', 'password123');
    await _fillField(tester, 'Phone', '+968 9000 0000');
    await _fillField(tester, 'Address', 'Way 100');
    await _fillField(tester, 'City', 'Muscat');
    final createAccountButton = find.widgetWithText(ElevatedButton, 'Create account');
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(find.text('Browse'), findsOneWidget);
  });

  testWidgets('Signing in as a driver opens the driver shell, not the customer one', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());
    await tester.pumpAndSettle();

    await _fillField(tester, 'Email', 'ali@example.com');
    await _fillField(tester, 'Password', 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Browse'), findsNothing);
  });
}
