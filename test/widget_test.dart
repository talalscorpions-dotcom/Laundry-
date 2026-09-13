// Basic smoke test for the LaundryGo app.
//
// It verifies that the app builds and renders the role-selection screen,
// and that picking a role routes into that role's app.

import 'package:flutter_test/flutter_test.dart';

import 'package:laundrygo/main.dart';

void main() {
  testWidgets('Renders the role selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());

    expect(find.text('LaundryGo'), findsWidgets);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Laundry Partner'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('Signing in as a customer opens the customer shell', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());

    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Browse'), findsOneWidget);
    expect(find.textContaining('Sparkle Laundry'), findsOneWidget);
  });
}
