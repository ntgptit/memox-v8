@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

final _screen = SettingsScreen(
  onOpenStudyDefaults: () {},
  onOpenAdmin: () {},
  onOpenTheme: () {},
  onOpenLanguage: () {},
  onOpenReminder: () {},
  resetAppOptions: () async => const Ok(null),
  onOpenSync: () {},
);

/// A toast or dialog in, its entrance done.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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
    libraryTest('settings, admin row, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          SettingsScreen(
            onOpenStudyDefaults: () {},
            onOpenAdmin: () {},
            onOpenTheme: () {},
            onOpenLanguage: () {},
            onOpenReminder: () {},
            resetAppOptions: () async => const Ok(null),
            onOpenSync: () {},
          ),
          brightness,
          overrides: [isAdminProvider.overrideWithValue(true)],
        );
        await expectBoundaryGolden(
          tester,
          'goldens/settings_admin_row_$theme.png',
        );
      });
    });

    for (final (state, status) in <(String, SyncStatus Function(LibraryEnv))>[
      (
        'synced',
        (env) => SyncStatus(
          lastSuccessAt: env.clock.now().subtract(const Duration(minutes: 5)),
        ),
      ),
      (
        'failed',
        (env) => SyncStatus(
          lastFailure: LastSyncFailure(
            SyncFailureKind.network,
            env.clock.now(),
          ),
        ),
      ),
      ('rejected', (env) => const SyncStatus(rejectedCount: 2)),
    ]) {
      libraryTest('settings, sync $state, $theme', (tester, env) async {
        await withRealShadows(() async {
          await pumpLibraryGolden(
            tester,
            env,
            _screen,
            brightness,
            overrides: syncOverrides(status(env)),
          );
          await expectBoundaryGolden(
            tester,
            'goldens/settings_sync_${state}_$theme.png',
          );
        });
      });
    }
  }
}
