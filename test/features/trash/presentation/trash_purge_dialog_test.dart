import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _button(String label) => find.widgetWithText(MxButton, label);

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Selects the two cards of [seedTrash].
Future<void> _selectCards(WidgetTester tester) async {
  await _tap(tester, _button(_en.trashSelect));
  await _tap(tester, find.text('meokda · eat'));
  await _tap(tester, find.text('homework · bai tap'));
}

void main() {
  libraryTest(
    'a failed purge keeps the dialog with a banner, and Delete is the retry '
    '(SP2b 2.27)',
    (tester, env) async {
      await seedTrash(env);
      final hold = WriteHold()
        ..open()
        ..failNext();
      await pumpLibraryScreen(
        tester,
        env,
        const TrashScreen(),
        overrides: [
          trashRepositoryProvider.overrideWithValue(
            HeldTrash(TrashRepositoryImpl(env.db), hold),
          ),
        ],
      );
      await _selectCards(tester);
      await _tap(tester, _button(_en.trashPurgeSelected(2)));
      await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
      await tester.pumpAndSettle();

      expect(find.byType(MxDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MxInlineBanner),
          matching: find.text(_en.failure(WriteHold.failure)),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
      await tester.pumpAndSettle();
      expect(find.byType(MxDialog), findsNothing);
      expect(find.text(_en.trashPurgedCards(2)), findsOneWidget);
    },
  );
}
