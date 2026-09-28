import 'package:flutter_test/flutter_test.dart';

import 'support/content_steps.dart';
import 'support/device_app.dart';

// IT-PLAT-004 (DEVICE-E2E) phase a: a deck to link to. It signals the deck's
// id; the script then opens memox://app/decks/deck/<id> from the OS.
void main() {
  initDeviceBinding();

  testWidgets('IT-PLAT-004 a: a deck, and its id for the link', (tester) async {
    await launchApp(tester);
    await createRootDeck(tester, 'D-EB');
    await openDeck(tester, 'D-EB');

    await waitUntil(
      tester,
      () => currentPath(tester).startsWith('/decks/deck/'),
      "D-EB's page is the route",
    );
    final path = currentPath(tester);
    signal('value DECK_ID=${path.split('/').last}');
  });
}
