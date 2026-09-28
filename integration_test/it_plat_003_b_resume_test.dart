import 'package:flutter_test/flutter_test.dart';

import 'support/device_app.dart';
import 'support/study_steps.dart';

// IT-PLAT-003 (DEVICE-E2E) phase b, steps 3-4: reopened the same day, the
// entry offers Continue beside starting something new, and Continue returns
// to the same mode, card and counter phase a left.
void main() {
  initDeviceBinding();

  testWidgets('IT-PLAT-003 b: Continue resumes where the OS stopped it', (
    tester,
  ) async {
    final checkpoint = valueOf('CHECKPOINT');
    expect(checkpoint, isNotEmpty, reason: 'phase a signals CHECKPOINT');

    await launchApp(tester);
    await openStudyEntry(tester, studyRoot);
    final l10n = l10nOf(tester);
    await waitFor(tester, find.text(l10n.studyEntryContinue));
    expect(find.text(l10n.studyEntryResumeBody), findsOneWidget);

    await tapText(tester, l10n.studyEntryContinue);
    await waitUntil(
      tester,
      () => modeOnScreen() != null,
      'the resumed session shows a turn',
    );
    expect(sessionCheckpoint(tester), checkpoint);
  });
}
