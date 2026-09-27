import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _valueKey = ValueKey('mx-stepper-value');

SettingsScreen _screen({
  VoidCallback? onOpenTheme,
  VoidCallback? onOpenLanguage,
}) => SettingsScreen(
  onOpenTheme: onOpenTheme ?? () {},
  onOpenLanguage: onOpenLanguage ?? () {},
);

Future<int> _storedLimit(LibraryEnv env) async => (await SettingsRepositoryImpl(
  env.db,
).watchAppSettings().first).studyDefaults.cardLimit;

void main() {
  libraryTest('the three sections show the stored values; the reminder row '
      'is hidden until FE-B5', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    // Section titles show in capitals; their semantics keep the words.
    expect(find.text(_en.settingsStudyDefaults.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsApp.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsResetRow), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(_valueKey), matching: find.text('20')),
      findsOneWidget,
    );
    expect(find.text(_en.settingsThemeFollowsSystem), findsOneWidget);
    expect(find.textContaining('eminder'), findsNothing);
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

  libraryTest('before the first read the screen shows skeleton rows and no '
      'value (loading)', (tester, env) async {
    final never = StreamController<AppSettingsEntity>();
    addTearDown(never.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [appSettingsProvider.overrideWith((ref) => never.stream)],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
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

  libraryTest('the Theme row names a fixed choice by its name (§5.2)', (
    tester,
    env,
  ) async {
    await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark),
    );
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.settingsThemeDark), findsOneWidget);
  });

  libraryTest('Reset asks first, then puts the defaults back (A3)', (
    tester,
    env,
  ) async {
    final repository = SettingsRepositoryImpl(env.db);
    await tester.runAsync(() async {
      await repository.setTheme(theme: ThemeChoice.dark);
      await repository.saveStudyDefaults(
        options: const StudyOptions(
          cardLimit: 50,
          newCardOrder: NewCardOrder.random,
        ),
      );
    });
    await pumpLibraryScreen(tester, env, _screen());

    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.settingsResetSafe), findsOneWidget);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(await tester.runAsync(() => _storedLimit(env)), 50);

    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(_en.settingsResetDone), findsOneWidget);
    expect(
      await tester.runAsync(() => _storedLimit(env)),
      StudyOptions.defaultCardLimit,
    );
    expect(find.text(_en.settingsThemeFollowsSystem), findsOneWidget);
  });

  libraryTest('at large text the reset buttons stack instead of wrapping '
      '(UI-base row 118)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen(), textScale: 2);
    await tester.scrollUntilVisible(
      find.text(_en.settingsResetRow),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text(_en.settingsResetConfirm)).dy,
      greaterThan(tester.getBottomLeft(find.text(_en.commonCancel)).dy),
    );
    expect(tester.takeException(), isNull);
  });

  libraryTest('a failed read shows the error with Retry and no invented '
      'value (E3)', (tester, env) async {
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
    expect(find.text(_en.settingsLoadErrorTitle), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
    expect(find.textContaining('memox.sqlite'), findsNothing);
  });

  libraryTest('the Theme and Language rows open their pages', (
    tester,
    env,
  ) async {
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      _screen(
        onOpenTheme: () => opened.add('theme'),
        onOpenLanguage: () => opened.add('language'),
      ),
    );
    await tester.tap(find.text(_en.settingsTheme));
    await tester.tap(find.text(_en.settingsLanguage));

    expect(opened, ['theme', 'language']);
  });
}
