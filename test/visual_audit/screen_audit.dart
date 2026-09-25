import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps one variant of a screen: [brightness]'s theme at [textScale].
typedef AuditPump = Future<void> Function(
  Brightness brightness,
  double textScale,
);

/// The text scales every production screen is audited at: the default and
/// the 200% a low-vision user sets.
const List<double> auditTextScales = [1, 2];

/// The strict audit every production screen companion runs (MX-VIS-001).
///
/// Each theme at each text scale must show [screen], lay out without an
/// exception (an overflow fails the test), and meet Android's 48 dp and iOS's
/// 44 pt tap targets, with a label on every tappable node. Text contrast joins
/// when FE-C1 settles the palette.
Future<void> auditProductionScreen(
  WidgetTester tester, {
  required Type screen,
  required AuditPump pump,
}) async {
  final semantics = tester.ensureSemantics();
  try {
    for (final brightness in Brightness.values) {
      for (final scale in auditTextScales) {
        await pump(brightness, scale);
        await tester.pumpAndSettle();
        final variant = '${brightness.name} at ${scale}x text';
        expect(find.byType(screen), findsOneWidget, reason: variant);
        for (final guideline in [
          androidTapTargetGuideline,
          iOSTapTargetGuideline,
          labeledTapTargetGuideline,
        ]) {
          await expectLater(tester, meetsGuideline(guideline), reason: variant);
        }
      }
    }
  } finally {
    semantics.dispose();
  }
}
