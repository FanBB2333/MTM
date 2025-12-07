// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mtm_gui/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PN532App());

    // Verify that sidebar is rendered
    expect(find.text('PN532'), findsOneWidget);
    expect(find.text('NFC Tools'), findsOneWidget);
    
    // Verify Connect page is default
    expect(find.text('Connect Device'), findsOneWidget);
  });
}
