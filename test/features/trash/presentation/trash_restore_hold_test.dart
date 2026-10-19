import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The sheet's spinner-free frames never settle while held: time moves by
/// hand.
const _frames = Duration(milliseconds: 300);

/// A point on the scrim, above the sheet.
const _scrim = Offset(8, 8);

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(MxDeckPickerSheet), matching: finder);

Future<void> _openRestore(WidgetTester tester, String name) async {
  await tester.tap(byControlLabel(_en.trashEntryActions(name)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.trashRestore));
  await tester.pumpAndSettle();
}

Future<bool> _isActive(LibraryEnv env, String id) async =>
    (await env.db
            .customSelect(
              'SELECT delete_batch_id IS NULL AS active FROM card WHERE id = ?',
              variables: [Variable<String>(id)],
            )
            .getSingle())
        .read<bool>('active');

// UC-TRASH-001 steps 5-7: once a target is picked, the sheet stays until the
// restore lands (trash_restore_sheet_widget.dart, MxBottomSheet.isHeld).
void main() {
  libraryTest('while the restore writes, the sheet is held: the scrim and Back '
      'leave it open, Cancel and the targets are off; it closes when the '
      'cards are back', (tester, env) async {
    await seedTrash(env);
    final gate = Completer<void>();
    final trash = _SlowTrash(gate);
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [trashControllerProvider.overrideWith(() => trash)],
    );
    await _openRestore(tester, 'meokda · eat');
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld,
      false,
    );

    await tester.tap(_inSheet(find.text('Korean › Words')));
    await tester.pump(_frames);

    expect(trash.restores, 1);
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).isHeld,
      true,
    );
    final cancel = _inSheet(find.widgetWithText(MxButton, _en.commonCancel));
    expect(tester.widget<MxButton>(cancel).onPressed, isNull);
    final rows = tester.widgetList<MxListRow>(_inSheet(find.byType(MxListRow)));
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row.isEnabled, isFalse);
    }

    expect(
      tester.getTopLeft(find.byType(MxBottomSheet)).dy,
      greaterThan(_scrim.dy),
      reason: 'the tap lands on the scrim',
    );
    await tester.tapAt(_scrim);
    await tester.pump(_frames);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(_frames);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);

    unawaited(
      Navigator.of(tester.element(find.byType(MxBottomSheet))).maybePop(),
    );
    await tester.pump(_frames);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);

    // A second press of the same target does not restore again.
    await tester.tap(
      _inSheet(find.text('Korean › Words')),
      warnIfMissed: false,
    );
    await tester.pump(_frames);
    expect(trash.restores, 1);
    expect(await _isActive(env, 'meokda'), isFalse);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(trash.restores, 1);
    expect(
      find.text(_en.trashRestoredOne('meokda · eat', 'Words')),
      findsOneWidget,
    );
    expect(await _isActive(env, 'meokda'), isTrue);
  });
}

/// Restores only once [gate] opens, so a test can look while it writes.
final class _SlowTrash extends TrashController {
  _SlowTrash(this.gate);

  final Completer<void> gate;
  var restores = 0;

  @override
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
  }) async {
    restores++;
    await gate.future;
    return super.restoreCards(batchIds: batchIds, deckId: deckId);
  }
}
