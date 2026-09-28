import 'package:flutter_test/flutter_test.dart';

import 'support/content_steps.dart';
import 'support/device_app.dart';

// IT-PLAT-002 (DEVICE-E2E) phase b, steps 5-6: after the restart, D-EB is in
// the root and D-LEAF still holds C-001 with "rời bỏ".
void main() {
  initDeviceBinding();

  testWidgets('IT-PLAT-002 b: the tree and C-001 survive a restart', (
    tester,
  ) async {
    await launchApp(tester);
    await waitFor(tester, find.text('D-EB'));
    await openDeck(tester, 'D-EB');
    await openDeck(tester, 'D-BRANCH');
    await openDeck(tester, 'D-LEAF');

    await waitFor(tester, find.text('C-001'));
    expect(find.text('rời bỏ'), findsOneWidget);
  });
}
