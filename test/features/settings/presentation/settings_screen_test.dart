import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_skeleton_widget.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/sync_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _valueKey = ValueKey('mx-stepper-value');

SettingsScreen _screen({
  VoidCallback? onOpenStudyDefaults,
  VoidCallback? onOpenTheme,
  VoidCallback? onOpenLanguage,
  VoidCallback? onOpenReminder,
  ResetAppOptions? resetAppOptions,
}) => SettingsScreen(
  onOpenStudyDefaults: onOpenStudyDefaults ?? () {},
  onOpenTheme: onOpenTheme ?? () {},
  onOpenLanguage: onOpenLanguage ?? () {},
  onOpenReminder: onOpenReminder ?? () {},
  resetAppOptions: resetAppOptions ?? () async => const Ok(null),
  onOpenSync: () {},
);

Future<int> _storedLimit(LibraryEnv env) async => (await SettingsRepositoryImpl(
  env.db,
).watchAppSettings().first).studyDefaults.cardLimit;

void main() {
  libraryTest('the hub names every group and value: Study summary, Theme, '
      'reminder, Reset (settings hub spec §5.1)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    // Section titles show in capitals; their semantics keep the words.
    expect(find.text(_en.settingsStudySection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsApp.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsReset.toUpperCase()), findsOneWidget);
    expect(
      find.text(
        _en.settingsStudyDefaultsSummary(20, _en.settingsOrderCreated, 'true'),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.settingsThemeFollowsSystem), findsOneWidget);
    expect(find.text(_en.settingsReminderOff), findsOneWidget);
    expect(find.text(_en.settingsResetRow), findsOneWidget);
    expect(
      find.byKey(_valueKey),
      findsNothing,
      reason: 'no stepper on the hub',
    );
    // The summary may wrap, never clip (review focus 4).
    final summary = tester.widget<Text>(
      find.text(
        _en.settingsStudyDefaultsSummary(20, _en.settingsOrderCreated, 'true'),
      ),
    );
    expect(summary.maxLines, isNull);
  });

  libraryTest('the Study defaults row opens screen 23a and reflects a '
      'stored change (D8)', (tester, env) async {
    await tester.runAsync(
      () => SettingsRepositoryImpl(env.db)
          .saveStudyDefaults(cardLimit: 35, newCardOrder: NewCardOrder.random),
    );
    await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).setSpeechAutoPlay(isOn: false),
    );
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenStudyDefaults: () => opened++),
    );

    expect(
      find.text(
        _en.settingsStudyDefaultsSummary(35, _en.settingsOrderRandom, 'false'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.settingsStudyDefaults));
    expect(opened, 1);
  });

  libraryTest('the reminder row names the time when on, and opens screen 24', (
    tester,
    env,
  ) async {
    await SettingsRepositoryImpl(env.db).saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 21 * 60),
    );
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenReminder: () => opened++),
    );

    expect(find.text(_en.settingsReminderOn('21:00')), findsOneWidget);
    await tester.tap(find.text(_en.settingsReminder));
    expect(opened, 1);
  });

  libraryTest('reset runs the reset app/ composed; a failure says so and '
      'the next confirm runs it again', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    final reset = ResetAppSettingsUseCase(store);
    var resets = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(
        resetAppOptions: () {
          resets++;
          return reset();
        },
      ),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );

    store.isFailing = true;
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    // M3-B3: the dialog's footer is the stock MxSheetActions pair.
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).confirmLabel,
      _en.settingsResetConfirm,
    );
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(resets, 1);
    expect(find.text(_en.settingsResetFailed), findsOneWidget);

    store.isFailing = false;
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(resets, 2);
    expect(find.text(_en.settingsResetBody), findsNothing, reason: 'closed');
    expect(find.text(_en.settingsResetDone), findsOneWidget);
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

    // Shaped as its sections (critique 2026-09-30 part 3d-2, E12).
    expect(find.byType(SettingsSkeletonWidget), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SettingsSkeletonWidget),
        matching: find.byType(MxCard),
      ),
      findsNWidgets(4),
    );
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
        cardLimit: 50,
        newCardOrder: NewCardOrder.random,
      );
    });
    await pumpLibraryScreen(
      tester,
      env,
      _screen(resetAppOptions: ResetAppSettingsUseCase(repository).call),
    );

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

  libraryTest('the account row and the Sync row share one section, the '
      'banner above its overline (settings hub spec D7)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SettingsScreen(
        onOpenStudyDefaults: () {},
        onOpenTheme: () {},
        onOpenLanguage: () {},
        onOpenReminder: () {},
        resetAppOptions: () async => const Ok(null),
        onOpenSync: () {},
        accountBanner: const Text('banner'),
        accountRow: const Text('account row'),
      ),
      overrides: syncOverrides(const SyncStatus()),
    );

    final overline = find.text(_en.settingsAccountSync.toUpperCase());
    expect(overline, findsOneWidget);
    expect(
      tester.getTopLeft(find.text('banner')).dy,
      lessThan(tester.getTopLeft(overline).dy),
    );
    expect(
      tester.getTopLeft(find.text('account row')).dy,
      lessThan(tester.getTopLeft(find.text(_en.settingsSync)).dy),
    );
  });
}
