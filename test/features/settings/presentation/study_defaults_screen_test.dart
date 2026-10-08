import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/study_defaults_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_speech_synthesizer.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// Screen 23a (settings hub spec §5.2): the study rows that were on the tab,
// with their saving, validation and toasts (UC-SETTINGS-001, FE-A3 D1, D6;
// study speech spec §6).

final _en = lookupAppLocalizations(const Locale('en'));

const _valueKey = ValueKey('mx-stepper-value');

Widget _screen() => const StudyDefaultsScreen();

Future<int> _storedLimit(LibraryEnv env) async => (await SettingsRepositoryImpl(
  env.db,
).watchAppSettings().first).studyDefaults.cardLimit;

void main() {
  libraryTest('the two sections carry their own notes (settings hub spec '
      'D3)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.settingsSessionSection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsSpeechSection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsSessionNote), findsOneWidget);
    expect(find.text(_en.settingsSpeechNote), findsOneWidget);
  });

  libraryTest('a failed read on the Study defaults page shows the error '
      'with Retry and no value (E3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
  });

  libraryTest('steps settle into one save, then "Saved" (D1)', (
    tester,
    env,
  ) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip(_en.settingsMoreCards));
      await tester.pump();
    }
    expect(store.writes, 0);

    await tester.pump(cardLimitSettle);
    await tester.pumpAndSettle();

    expect(store.writes, 1);
    expect(find.text(_en.settingsSaved), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(_valueKey), matching: find.text('23')),
      findsOneWidget,
    );
  });

  libraryTest('while the limit writes, the stepper spins and the order '
      'stays usable (saving)', (tester, env) async {
    final gate = Completer<void>();
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..hold = gate;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump(cardLimitSettle);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(_valueKey),
        matching: find.byType(MxSpinner),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.settingsSaved), findsNothing);

    store.hold = null;
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(_en.settingsSaved), findsOneWidget);
  });

  libraryTest('a typed 250 is refused under the stepper and saves nothing '
      '(E1)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.text(
        _en.settingsCardLimitInvalid(
          StudyOptions.minCardLimit,
          StudyOptions.maxCardLimit,
        ),
      ),
      findsOneWidget,
    );
    expect(store.writes, 0);
  });

  libraryTest('a failed save names the kept value and Retry saves it (E2)', (
    tester,
    env,
  ) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump(cardLimitSettle);
    await tester.pumpAndSettle();

    expect(find.text(_en.settingsCardLimitSaveFailed(20)), findsOneWidget);
    expect(find.textContaining('memox.sqlite'), findsNothing);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => _storedLimit(env)), 21);
  });

  libraryTest('Study defaults show the read-aloud switch and the default '
      'language', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.settingsSpeechAutoPlay), findsOneWidget);
    expect(find.text(_en.settingsSpeechLanguage), findsOneWidget);
    expect(
      find.text(
        _en.settingsSpeechLanguageValue(_en.speechLanguageName('enUs')),
      ),
      findsOneWidget,
    );
  });

  libraryTest('the speech language row opens the sheet; a pick saves and '
      'shows its name (BR-SETTINGS-009)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        speechSynthesizerProvider.overrideWithValue(
          FakeSpeechSynthesizer(available: {'en-US', 'vi-VN'}),
        ),
      ],
    );

    await tester.tap(find.text(_en.settingsSpeechLanguage));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsOneWidget);
    // A language the device lacks says so and stays selectable (D5).
    expect(find.text(_en.settingsSpeechLanguageMissing), findsNWidgets(8));

    await tester.tap(find.text(_en.speechLanguageName('viVn')));
    await tester.pumpAndSettle();

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(
      find.text(
        _en.settingsSpeechLanguageValue(_en.speechLanguageName('viVn')),
      ),
      findsOneWidget,
    );
    // The store answers on the real event loop (as `_storedLimit` is read).
    final stored = await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).watchAppSettings().first,
    );
    expect(stored!.studyDefaults.speechLanguage, SpeechLanguage.viVn);
  });

  libraryTest('the read-aloud toggle saves on change (BR-SETTINGS-010)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen());

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(MxSettingsRow, _en.settingsSpeechAutoPlay),
        matching: find.byType(MxToggle),
      ),
    );
    await tester.pumpAndSettle();

    // The store answers on the real event loop (as `_storedLimit` is read).
    final stored = await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).watchAppSettings().first,
    );
    expect(stored!.isSpeechAutoPlay, isFalse);
  });

  libraryTest('a failed speech save says so, and Retry writes it '
      '(UC-SETTINGS-001 E2)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(MxSettingsRow, _en.settingsSpeechAutoPlay),
        matching: find.byType(MxToggle),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_en.settingsSpeechAutoPlaySaveFailed), findsOneWidget);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    final stored = await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).watchAppSettings().first,
    );
    expect(stored!.isSpeechAutoPlay, isFalse);
  });

  libraryTest('a saved speech language says "Saved", as the other rows do', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen());
    await tester.tap(find.text(_en.settingsSpeechLanguage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.speechLanguageName('jaJp')));
    await tester.pumpAndSettle();

    expect(find.text(_en.settingsSaved), findsOneWidget);
  });

  test('the page is named Study options (owner 2026-10-07)', () {
    expect(_en.settingsStudyDefaults, 'Study options');
    expect(
      lookupAppLocalizations(const Locale('vi')).settingsStudyDefaults,
      'Tuỳ chọn học',
    );
  });

  libraryTest('the card-limit stepper sits on its label\'s line, with no '
      'range line (owner 2026-10-07)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());
    final label = tester.getRect(find.text(_en.settingsCardLimitShort));
    final stepper = tester.getRect(find.byType(MxStepper));

    expect(stepper.left, greaterThan(label.right));
    expect(stepper.top, lessThan(label.bottom));
    expect(find.textContaining('default 20'), findsNothing);
  });

  libraryTest('a typed 250 is refused across the row, under the label '
      '(owner 2026-10-07)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final message = tester.getRect(
      find.text(
        _en.settingsCardLimitInvalid(
          StudyOptions.minCardLimit,
          StudyOptions.maxCardLimit,
        ),
      ),
    );

    expect(
      message.top,
      greaterThan(tester.getRect(find.byType(MxStepper)).bottom),
    );
    // One line at 360 dp: it is not squeezed into the stepper's width.
    expect(
      message.width,
      greaterThan(tester.getSize(find.byType(MxStepper)).width),
    );
  });

  libraryTest('the new-card order row names the order and opens a sheet; a '
      'pick saves it (owner 2026-10-07)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.byType(MxSegmentedTray<NewCardOrder>), findsNothing);
    expect(find.text(_en.settingsNewCardOrderHint), findsNothing);
    expect(find.text(_en.settingsOrderCreated), findsOneWidget);

    await tester.tap(find.text(_en.settingsNewCardOrder));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsOneWidget);

    await tester.tap(find.text(_en.settingsOrderRandom));
    await tester.pumpAndSettle();

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(find.text(_en.settingsOrderRandom), findsOneWidget);
    final stored = await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).watchAppSettings().first,
    );
    expect(stored!.studyDefaults.newCardOrder, NewCardOrder.random);
  });

  libraryTest('the card-limit label fits one line beside the stepper, in '
      'English and Vietnamese (owner 2026-10-07)', (tester, env) async {
    for (final locale in const [Locale('en'), Locale('vi')]) {
      final l10n = lookupAppLocalizations(locale);
      await pumpLibraryScreen(tester, env, _screen(), locale: locale);
      final label = find.text(l10n.settingsCardLimitShort);

      expect(label, findsOneWidget);
      // settingsLabel is one line of at most 17 × 1.5.
      expect(tester.getSize(label).height, lessThan(30));
      // The stepper still says what it counts.
      final stepper = tester.widget<MxStepper>(find.byType(MxStepper));
      expect(stepper.valueLabel, l10n.settingsCardLimit);
    }
  });

  libraryTest('the card-limit row reads "Cards · Per session" and stands as '
      'tall as the order row (owner 2026-10-07)', (tester, env) async {
    for (final locale in const [Locale('en'), Locale('vi')]) {
      final l10n = lookupAppLocalizations(locale);
      await pumpLibraryScreen(tester, env, _screen(), locale: locale);
      final perSession = find.text(l10n.settingsCardLimitPerSession);

      expect(perSession, findsOneWidget);
      // rowDescription is one line of 14 × 1.5.
      expect(tester.getSize(perSession).height, lessThan(24));
      Finder rowOf(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(MxSettingsRow),
      );
      expect(
        tester.getSize(rowOf(l10n.settingsCardLimitShort)).height,
        tester.getSize(rowOf(l10n.settingsNewCardOrder)).height,
      );
    }
  });
}
