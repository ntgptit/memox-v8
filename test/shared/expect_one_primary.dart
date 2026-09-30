import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

/// The One Indigo Rule as a check (DESIGN.md; critique 2026-09-30 part 1):
/// at most one enabled primary fill a finger can reach, the FAB included.
/// A surface under a modal barrier is not hit-testable, so a dialog's own
/// primary does not count against the page below it.
void expectOnePrimaryPerDecision(WidgetTester tester) {
  final primaries = find
      .byWidgetPredicate(
        (widget) =>
            widget is MxButton &&
            widget.tone == MxButtonTone.primary &&
            widget.onPressed != null,
      )
      .hitTestable();
  final fabs = find.byType(MxFab).hitTestable();
  final count = primaries.evaluate().length + fabs.evaluate().length;
  expect(count, lessThanOrEqualTo(1), reason: 'more than one primary fill');
}
