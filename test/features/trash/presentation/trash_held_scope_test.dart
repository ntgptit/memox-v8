import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/forui_expect.dart';
import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _entry = 'meokda · eat';

/// Trash writes that land, counted: a second one would write twice.
final class _CountedTrash extends TrashController {
  final writes = <String>[];

  @override
  Future<PurgeReport> purge(Set<String> batchIds) {
    writes.add('purge');
    return super.purge(batchIds);
  }

  @override
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
  }) {
    writes.add('restore');
    return super.restoreCards(batchIds: batchIds, deckId: deckId);
  }
}

/// The trash with every toast throwing (no toast host), its entry's
/// actions open.
Future<_CountedTrash> _openActions(WidgetTester tester, LibraryEnv env) async {
  await seedTrash(env);
  final trash = _CountedTrash();
  await pumpLibraryScreen(
    tester,
    env,
    const TrashScreen(),
    overrides: [trashControllerProvider.overrideWith(() => trash)],
    hasToastHost: false,
  );
  await tester.tap(byControlLabel(_en.trashEntryActions(_entry)));
  await tester.pumpAndSettle();
  return trash;
}

/// Taps [finder]: the toast after the write meets its bug, which is left
/// uncaught as itself, and no failure is said.
Future<void> _confirm(WidgetTester tester, Finder finder) async {
  final uncaught = await tapKeepingUncaught(tester, finder);
  expect(uncaught, [isA<FlutterError>()]);
  expect(find.text(_en.failureUnknown), findsNothing);
}

// REG-HELD-SCOPE: a bug in what follows a landed write (here the toast,
// which throws with no toast host) is not a failed write. The flow closes
// as after any landed write and never offers Retry, so nothing writes
// twice.
void main() {
  libraryTest('a purge that landed closes its dialog though its toast fails '
      '(UC-TRASH-001 A3)', (tester, env) async {
    final trash = await _openActions(tester, env);
    await tester.tap(find.text(_en.trashDeletePermanently));
    await tester.pumpAndSettle();
    await _confirm(tester, find.text(_en.trashPurgeConfirm));

    expect(find.byType(MxDialog), findsNothing);
    expect(trash.writes, ['purge']);
  });

  libraryTest('a restore that landed closes its sheet though its toast '
      'fails (UC-TRASH-001 steps 5-7)', (tester, env) async {
    final trash = await _openActions(tester, env);
    await tester.tap(find.text(_en.trashRestore));
    await tester.pumpAndSettle();
    await _confirm(
      tester,
      find.descendant(
        of: find.byType(MxDeckPickerSheet),
        matching: find.text('Korean › Words'),
      ),
    );

    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(trash.writes, ['restore']);
  });
}
