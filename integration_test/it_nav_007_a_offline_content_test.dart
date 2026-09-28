import 'package:flutter_test/flutter_test.dart';

import 'support/content_steps.dart';
import 'support/device_app.dart';

// IT-NAV-007 (DEVICE-E2E) phase a, steps 1-3, in airplane mode (the script
// turns it on): a new sub-deck in D-EB, and a card created, edited and
// flagged in D-LEAF, with no sign-in and no network prompt.
void main() {
  initDeviceBinding();

  testWidgets('IT-NAV-007 a: manage content offline', (tester) async {
    await launchApp(tester);
    await createRootDeck(tester, 'D-EB');
    await openDeck(tester, 'D-EB');
    await createSubDeck(tester, 'D-LEAF');
    await createSubDeck(tester, 'D-NEW');
    await openDeck(tester, 'D-LEAF');
    await createCard(tester, 'C-OFF', 'offline');
    await editCardBack(tester, 'C-OFF', 'ngoại tuyến');
    await flagCard(tester, 'C-OFF');

    expect(find.text('ngoại tuyến'), findsOneWidget);
  });
}
