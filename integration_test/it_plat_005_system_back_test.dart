import 'package:flutter_test/flutter_test.dart';

import 'support/device_app.dart';
import 'support/study_steps.dart';

// IT-PLAT-005 (DEVICE-E2E): the OS's Back button mid-session (the script
// sends KEYCODE_BACK) asks like ✕ does; Keep studying changes nothing; Stop
// ends the session as left early, and the entry offers no Continue.
void main() {
  initDeviceBinding();

  testWidgets('IT-PLAT-005 system Back asks, Keep keeps, Stop stops', (
    tester,
  ) async {
    await launchApp(tester);
    await seedStudyDeck(tester);
    await studyFromLibrary(tester, studyRoot);
    await startLearning(tester);
    await answerTurn(tester);
    final l10n = l10nOf(tester);
    final before = sessionCheckpoint(tester);

    await pressSystemBack(tester, find.text(l10n.studyExitTitle));
    await tapText(tester, l10n.studyExitKeep);
    await waitGone(tester, find.text(l10n.studyExitTitle));
    expect(sessionCheckpoint(tester), before);

    await pressSystemBack(tester, find.text(l10n.studyExitTitle));
    await tapText(tester, l10n.studyExitStop);
    await waitFor(tester, find.text(l10n.summaryLeftEarly));

    await tester.pump(const Duration(milliseconds: 400));
    await tapText(tester, l10n.summaryDone);
    await openStudyEntry(tester, studyRoot);
    await waitFor(
      tester,
      find.text(l10n.studyEntryLearnCta(studyCards.length)),
    );
    expect(find.text(l10n.studyEntryContinue), findsNothing);
  });
}
