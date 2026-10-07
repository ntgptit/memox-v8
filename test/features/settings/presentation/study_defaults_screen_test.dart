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
}
