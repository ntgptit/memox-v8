@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/study_defaults_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/fake_speech_synthesizer.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// Screen 23a (settings hub spec §5.2): the study rows' states, as the tab
// showed them before the hub.

final _en = lookupAppLocalizations(const Locale('en'));

const _screen = StudyDefaultsScreen();

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

    libraryTest('study defaults, loaded, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/study_defaults_loaded_$theme.png',
        );
      });
    });

    libraryTest('study defaults, loading, $theme', (tester, env) async {
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
          'goldens/study_defaults_loading_$theme.png',
        );
      });
    });

    libraryTest('study defaults, saving, $theme', (tester, env) async {
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
          'goldens/study_defaults_saving_$theme.png',
        );
      });
      store.hold = null;
      gate.complete();
      await _settle(tester);
    });

    // Study speech spec D5, D12: the sheet with three voices on the device.
    libraryTest('study defaults, speech language sheet, $theme', (
      tester,
      env,
    ) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [
            speechSynthesizerProvider.overrideWithValue(
              FakeSpeechSynthesizer(available: {'en-US', 'vi-VN', 'ko-KR'}),
            ),
          ],
        );
        await tester.tap(find.text(_en.settingsSpeechLanguage));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_defaults_speech_language_sheet_$theme.png',
        );
      });
    });

    // Owner 2026-10-07: the new-card order opens its sheet.
    libraryTest('study defaults, new-card order sheet, $theme', (
      tester,
      env,
    ) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.text(_en.settingsNewCardOrder));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_defaults_order_sheet_$theme.png',
        );
      });
    });

    libraryTest('study defaults, saved, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await _stepAndSettle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/study_defaults_saved_$theme.png',
        );
      });
    });

    libraryTest('study defaults, invalid limit, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen, brightness);
        await tester.tap(find.byKey(const ValueKey('mx-stepper-value')));
        await tester.pump();
        await tester.enterText(find.byType(TextField), '250');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/study_defaults_invalid_limit_$theme.png',
        );
      });
    });

    libraryTest('study defaults, save failed, $theme', (tester, env) async {
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
          'goldens/study_defaults_save_failed_$theme.png',
        );
      });
    });
  }
}
