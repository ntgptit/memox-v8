import 'package:flutter_test/flutter_test.dart';

import 'support/content_steps.dart';
import 'support/device_app.dart';

// IT-PLAT-002 (DEVICE-E2E) phase a, steps 1-5: D-EB > D-BRANCH > D-LEAF, C-001
// with its meaning changed to "rời bỏ". Phase b checks it after a restart.
void main() {
  initDeviceBinding();

  testWidgets('IT-PLAT-002 a: build the tree and C-001', (tester) async {
    await launchApp(tester);
    await createRootDeck(tester, 'D-EB');
    await openDeck(tester, 'D-EB');
    await createSubDeck(tester, 'D-BRANCH');
    await openDeck(tester, 'D-BRANCH');
    await createSubDeck(tester, 'D-LEAF');
    await openDeck(tester, 'D-LEAF');
    await createCard(tester, 'C-001', 'leave');
    await editCardBack(tester, 'C-001', 'rời bỏ');

    expect(find.text('rời bỏ'), findsOneWidget);
    await goToLibraryRoot(tester);
    await waitFor(tester, find.text('D-EB'));
  });
}
