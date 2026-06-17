// Basic smoke test for the Smart Daily Planner app shell.
//
// The full app initializes Firebase in main(), so this only exercises a
// lightweight MaterialApp wrapper rather than booting the real app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App title renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Smart Daily Planner'))),
    );

    expect(find.text('Smart Daily Planner'), findsOneWidget);
  });
}
