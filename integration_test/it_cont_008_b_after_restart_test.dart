import 'package:flutter_test/flutter_test.dart';

import 'support/device_app.dart';
import 'support/study_steps.dart';

// IT-CONT-008 (DEVICE-E2E) phase b, steps 3-4, still offline: after the
// restart the finished session stays finished (no Continue), the five cards
// are learned (no Learn), and the entry asks for no network.
void main() {
  initDeviceBinding();

  testWidgets('IT-CONT-008 b: the finished session survives offline', (
    tester,
  ) async {
    await launchApp(tester);
    await openStudyEntry(tester, studyRoot);
    final l10n = l10nOf(tester);
    await waitFor(tester, find.text(l10n.studyEntryNothingTitle));

    expect(find.text(l10n.studyEntryContinue), findsNothing);
    expect(find.text(l10n.studyEntryLearnCta(studyCards.length)), findsNothing);
  });
}
