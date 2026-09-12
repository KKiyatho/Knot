// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:knot/knot_app.dart';

void main() {
  testWidgets('Knot shows the weekly routine drawer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KnotApp());

    expect(find.textContaining('Routine'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('오늘의 5개 매듭'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('물 마시기'), findsOneWidget);
    expect(find.textContaining('0/35'), findsOneWidget);
  });
}
