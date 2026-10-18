import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/forui_expect.dart';
import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _entry = 'meokda · eat';

/// A purge and a restore that die on a bug, not a Failure (ADR-016).
final class _BrokenTrash extends TrashController {
  @override
  Future<PurgeReport> purge(Set<String> batchIds) async => throw heldBug();

  @override
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
  }) async => throw heldBug();
}

Future<void> _openActions(WidgetTester tester) async {
  await tester.tap(byControlLabel(_en.trashEntryActions(_entry)));
  await tester.pumpAndSettle();
}

// LIB-6: a held write that meets a bug releases its flow, says so as an
// unknown failure and reports the bug (runHeld).
void main() {
  libraryTest(
    'a purge that dies on a bug releases the dialog (UC-TRASH-001 A3)',
    (tester, env) async {
      await seedTrash(env);
      await pumpLibraryScreen(
        tester,
        env,
        const TrashScreen(),
        overrides: [trashControllerProvider.overrideWith(_BrokenTrash.new)],
      );
      await _openActions(tester);
      await tester.tap(find.text(_en.trashDeletePermanently));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.trashPurgeConfirm));
      await tester.pump();

      expectBugReported(tester);
      expect(find.text(_en.failureUnknown), findsOneWidget);
      expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MxDialog), findsNothing);
    },
  );

  libraryTest('a restore that dies on a bug releases the sheet (UC-TRASH-001 '
      'steps 5-7)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [trashControllerProvider.overrideWith(_BrokenTrash.new)],
    );
    await _openActions(tester);
    await tester.tap(find.text(_en.trashRestore));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MxDeckPickerSheet),
        matching: find.text('Korean › Words'),
      ),
    );
    await tester.pump();

    expectBugReported(tester);
    expect(find.text(_en.failureUnknown), findsOneWidget);
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld,
      isFalse,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
  });
}
