// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_manager/main.dart';

void main() {
  testWidgets('Home screen renders with title and add button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudentManagerApp());

    expect(find.text('Danh sách sinh viên'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
