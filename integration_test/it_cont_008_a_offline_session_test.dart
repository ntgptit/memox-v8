import 'package:flutter_test/flutter_test.dart';

import 'support/device_app.dart';
import 'support/study_steps.dart';

// IT-CONT-008 (DEVICE-E2E) phase a, steps 1-2, in airplane mode (the script
// turns it on): SETUP-STUDY-EB-5-FULL, then a whole Learn session to its
// summary, with no sign-in and no network prompt.
void main() {
  initDeviceBinding();

  /// More than the 25 turns of five new cards through five modes.
  const maxTurns = 40;

  testWidgets('IT-CONT-008 a: a whole session offline', (tester) async {
    await launchApp(tester);
    await seedStudyDeck(tester);
    await studyFromLibrary(tester, studyRoot);
    await startLearning(tester);

    var turns = 0;
    while (!isSessionOver(tester)) {
      expect(turns, lessThan(maxTurns), reason: 'the session never ended');
      await answerTurn(tester);
      turns++;
    }
    final l10n = l10nOf(tester);
    expect(find.text(l10n.summaryLeftEarly), findsNothing);
    signal('value TURNS=$turns');
  });
}
