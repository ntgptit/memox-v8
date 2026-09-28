import 'package:flutter_test/flutter_test.dart';

import 'support/device_app.dart';

// IT-PLAT-001 (DEVICE-E2E): a cold start of the installed build on cleared
// data opens the Library, with its empty state and Create deck. The script
// clears the data first.
void main() {
  initDeviceBinding();

  testWidgets('IT-PLAT-001 a cold start opens the empty Library', (
    tester,
  ) async {
    await launchApp(tester);
    final l10n = l10nOf(tester);

    await waitFor(tester, find.text(l10n.libraryEmptyTitle));
    expect(find.text(l10n.libraryCreateDeck), findsWidgets);
    expect(find.text(l10n.navLibrary), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
