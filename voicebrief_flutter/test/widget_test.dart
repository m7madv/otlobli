// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_theme.dart';

void main() {
  testWidgets('primary action is accessible and responds to input', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Create brief',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Create brief'), findsOneWidget);
    await tester.tap(find.text('Create brief'));
    expect(tapped, isTrue);
  });
}
