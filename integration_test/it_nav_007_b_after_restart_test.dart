import 'package:flutter_test/flutter_test.dart';

import 'support/content_steps.dart';
import 'support/device_app.dart';

// IT-NAV-007 (DEVICE-E2E) phase b, steps 4-5, still offline: after the
// restart everything from phase a is there, and the card moves to the Trash.
void main() {
  initDeviceBinding();

  testWidgets('IT-NAV-007 b: offline changes survive, and delete works', (
    tester,
  ) async {
    await launchApp(tester);
    await openDeck(tester, 'D-EB');
    await waitFor(tester, find.text('D-NEW'));
    await openDeck(tester, 'D-LEAF');
    await waitFor(tester, find.text('C-OFF'));
    expect(find.text('ngoại tuyến'), findsOneWidget);

    await deleteCard(tester, 'C-OFF');
    expect(find.text('C-OFF'), findsNothing);
  });
}
