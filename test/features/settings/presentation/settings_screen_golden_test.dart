@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

final _screen = SettingsScreen(onOpenTheme: () {}, onOpenLanguage: () {});

/// A toast or dialog in, its entrance done.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// One step up, settled into its save.
Future<void> _stepAndSettle(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.settingsMoreCards));
  await tester.pump(cardLimitSettle);
  await _settle(tester);
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('settings, loaded, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_loaded_$theme.png',
        );
      });
    });

    libraryTest('settings, loading, $theme', (tester, env) async {
      final never = StreamController<AppSettingsEntity>();
      addTearDown(never.close);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [appSettingsProvider.overrideWith((ref) => never.stream)],
        );
        await expectBoundaryGolden(
          tester,
          'goldens/settings_loading_$theme.png',
        );
      });
    });

    libraryTest('settings, saving, $theme', (tester, env) async {
      final gate = Completer<void>();
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..hold = gate;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump(cardLimitSettle);
        await tester.pump();
        await expectBoundaryGolden(
          tester,
          'goldens/settings_saving_$theme.png',
        );
      });
      store.hold = null;
      gate.complete();
      await _settle(tester);
    });

    libraryTest('settings, saved, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await _stepAndSettle(tester);
        await expectBoundaryGolden(tester, 'goldens/settings_saved_$theme.png');
      });
    });

    libraryTest('settings, invalid limit, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.byKey(const ValueKey('mx-stepper-value')));
        await tester.pump();
        await tester.enterText(find.byType(TextField), '250');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_invalid_limit_$theme.png',
        );
      });
    });

    libraryTest('settings, save failed, $theme', (tester, env) async {
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..isFailing = true;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await _stepAndSettle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_save_failed_$theme.png',
        );
      });
    });

    libraryTest('settings, reset confirm, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.text(_en.settingsResetRow));
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_reset_confirm_$theme.png',
        );
      });
    });

    libraryTest('settings, reset done, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.text(_en.settingsResetRow));
        await _settle(tester);
        await tester.tap(find.text(_en.settingsResetConfirm));
        await _settle(tester);
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_reset_done_$theme.png',
        );
      });
    });
  }
}
