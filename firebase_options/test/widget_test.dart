// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Define a minimal test app class
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: const Text("Test App"),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Dummy test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Test App'), findsOneWidget);
  });
}
