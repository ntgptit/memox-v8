import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

// The States rows of screen 06 (Trash) whose detail file cites no executed
// test: purgeFailed.

final _en = lookupAppLocalizations(const Locale('en'));

const _entry = 'meokda · eat';
const _busy = DatabaseLockedFailure(cause: 'busy');

/// The first purge finds the database busy; the next ones go through.
final class _BusyOnce extends TrashController {
  var _isBusy = true;

  @override
  Future<PurgeReport> purge(Set<String> batchIds) {
    if (_isBusy) {
      _isBusy = false;
      throw _busy;
    }
    return super.purge(batchIds);
  }
}

MxButton _button(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

void main() {
  libraryTest('purgeFailed: a purge that fails keeps the dialog, shows the '
      'failure toast and makes Delete usable again', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [trashControllerProvider.overrideWith(_BusyOnce.new)],
    );
    await tester.tap(byControlLabel(_en.trashEntryActions(_entry)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.trashDeletePermanently));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.trashPurgeConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isFalse);
    expect(find.text(_en.failure(_busy)), findsOneWidget);
    expect(_button(tester, _en.trashPurgeConfirm).isLoading, isFalse);
    expect(_button(tester, _en.trashPurgeConfirm).onPressed, isNotNull);
    expect(_button(tester, _en.trashPurgeKeep).onPressed, isNotNull);
    expect(find.text(_entry), findsWidgets);

    await tester.tap(find.text(_en.trashPurgeConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.trashPurgedCards(1)), findsOneWidget);
    expect(find.text(_entry), findsNothing);
  });
}
