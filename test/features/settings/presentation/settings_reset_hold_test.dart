import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The confirm's spinner never settles: time moves by hand while held.
const _frames = Duration(milliseconds: 300);

/// A point on the scrim, outside the dialog.
const _scrim = Offset(8, 8);

MxButton _button(WidgetTester tester, String label) => tester.widget<MxButton>(
  find.ancestor(of: find.text(label), matching: find.byType(MxButton)).first,
);

// Reset app options (UC-SETTINGS-001 A3): while the write runs, the dialog
// is held, so nothing can look like a cancel (settings_reset_dialog_widget).
void main() {
  libraryTest('while the reset writes, the scrim and Back leave the dialog '
      'open, Cancel is off and Reset spins; the dialog closes when it '
      'lands', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    final reset = ResetAppSettingsUseCase(store);
    await store.saveStudyDefaults(cardLimit: 50);
    store.writes = 0;
    await pumpLibraryScreen(
      tester,
      env,
      SettingsScreen(
        onOpenStudyDefaults: () {},
        onOpenTheme: () {},
        onOpenLanguage: () {},
        onOpenReminder: () {},
        resetAppOptions: reset.call,
        onOpenSync: () {},
        onOpenAdmin: () {},
      ),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isFalse);

    final gate = store.hold = Completer<void>();
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pump();

    expect(store.writes, 1);
    expect(tester.widget<MxDialog>(find.byType(MxDialog)).isHeld, isTrue);
    expect(_button(tester, _en.commonCancel).onPressed, isNull);
    expect(_button(tester, _en.settingsResetConfirm).isLoading, isTrue);

    await tester.tapAt(_scrim);
    await tester.pump(_frames);
    expect(find.byType(MxDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(_frames);
    expect(find.byType(MxDialog), findsOneWidget);

    final context = tester.element(find.byType(MxDialog));
    await Navigator.of(context).maybePop();
    await tester.pump(_frames);
    expect(find.byType(MxDialog), findsOneWidget);

    // A second press while it writes does not write again.
    await tester.tap(find.text(_en.settingsResetConfirm), warnIfMissed: false);
    await tester.pump(_frames);
    expect(store.writes, 1);

    gate.complete();
    store.hold = null;
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(store.writes, 1);
    expect(find.text(_en.settingsResetDone), findsOneWidget);
    final settings = await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).watchAppSettings().first,
    );
    expect(settings!.studyDefaults.cardLimit, StudyOptions.defaultCardLimit);
  });
}
