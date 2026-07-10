// Widget-level smoke tests. Kept separate from repository_smoke_test.dart
// because these pump real widgets and therefore need care around database
// work — sqflite_common_ffi talks to a real background isolate, and the
// default testWidgets virtual-time zone doesn't reliably service that with
// pumpAndSettle() (it can time out waiting on real async I/O that a fixed
// number of pump() calls handles fine).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphics_bay_tracker/app.dart';
import 'package:graphics_bay_tracker/db/database_helper.dart';
import 'package:path/path.dart' as p;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('widget_smoke_');
    await DatabaseHelper.instance.resetForTesting(p.join(dir.path, 'test.db'));
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeForTesting();
  });

  testWidgets(
      'navigating from the truck list to Add Truck does not throw '
      '(regression: HomeShell keeps every tab mounted via IndexedStack, so '
      'FloatingActionButtons on different tabs must have distinct heroTags '
      'or Hero animation throws on the very first navigation)',
      (tester) async {
    await tester.pumpWidget(const BayTrackerApp());
    await _settle(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Truck'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(AppBar, 'Add Truck'), findsOneWidget);
  });

  testWidgets('navigating from the tag request list to Add Request does not throw',
      (tester) async {
    await tester.pumpWidget(const BayTrackerApp());
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.label_outline));
    await _settle(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Request'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(AppBar, 'Add Tag Request'), findsOneWidget);
  });
}
