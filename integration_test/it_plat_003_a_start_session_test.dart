import 'package:flutter_test/flutter_test.dart';

import 'support/device_app.dart';
import 'support/study_steps.dart';

// IT-PLAT-003 (DEVICE-E2E) phase a, step 1: SETUP-STUDY-EB-5-FULL, Learn, two
// turns, and where the session stands, signalled for phase b. Step 2, the OS
// taking the process, is the tool's force-stop after this phase.
void main() {
  initDeviceBinding();

  testWidgets('IT-PLAT-003 a: two turns into a new session', (tester) async {
    await launchApp(tester);
    await seedStudyDeck(tester);
    await studyFromLibrary(tester, studyRoot);
    await startLearning(tester);
    await answerTurn(tester);
    await answerTurn(tester);

    expect(isSessionOver(tester), isFalse);
    signal('value CHECKPOINT=${sessionCheckpoint(tester)}');
  });
}
