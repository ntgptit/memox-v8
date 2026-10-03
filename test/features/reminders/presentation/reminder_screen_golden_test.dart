@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/study_entry_fixtures.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<FlakySettingsRepository> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state, {
      FakeReminderPlatform? platform,
      Future<void> Function(FlakySettingsRepository store)? act,
      List<Override> overrides = const [],
    }) async {
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const ReminderScreen(),
          brightness,
          overrides: [
            reminderPlatformRepositoryProvider.overrideWithValue(
              platform ?? FakeReminderPlatform(),
            ),
            settingsRepositoryProvider.overrideWithValue(store),
            ...overrides,
          ],
        );
        await _settle(tester);
        if (act != null) await act(store);
        await expectBoundaryGolden(
          tester,
          'goldens/reminder_${state}_$theme.png',
        );
      });
      return store;
    }

    // The tap's ink ripple fades over a second; a golden shows the rest.
    Future<void> toggle(WidgetTester tester) async {
      await tester.tap(find.byType(MxToggle));
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));
    }

    libraryTest(
      'reminder, off, $theme',
      (tester, env) => shoot(tester, env, 'off'),
    );

    libraryTest('reminder, on, $theme', (tester, env) async {
      await shoot(tester, env, 'on', act: (_) => toggle(tester));
    });

    // Critique 2026-09-30 part 1: the preview reads the live workload.
    libraryTest('reminder, preview due, $theme', (tester, env) async {
      await sm2Leaf(env.db, env.decks, dueCards: 3);
      await shoot(tester, env, 'preview_due');
    });

    libraryTest('reminder, turning on, $theme', (tester, env) async {
      final hold = Completer<void>();
      await shoot(
        tester,
        env,
        'turning_on',
        act: (store) async {
          store.hold = hold;
          await tester.tap(find.byType(MxToggle));
          await tester.pump();
        },
      );
      hold.complete();
      await _settle(tester);
    });

    libraryTest('reminder, changing time, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'changing_time',
        act: (_) async {
          await toggle(tester);
          await tester.tap(find.text('20:00'));
          await _settle(tester);
        },
      );
    });

    libraryTest('reminder, permission denied, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'perm_denied',
        platform: FakeReminderPlatform(permission: ReminderPermission.denied),
        act: (_) => toggle(tester),
      );
    });

    // SP2b 2.34: the reminder is on and Android blocks its notifications.
    libraryTest('reminder, permission revoked, $theme', (tester, env) async {
      final platform = FakeReminderPlatform();
      await shoot(
        tester,
        env,
        'perm_revoked',
        platform: platform,
        act: (_) async {
          await toggle(tester);
          platform.permission = ReminderPermission.denied;
          await resumeReminderApp(tester);
          expect(
            find.text('Notifications are blocked for MemoX'),
            findsOneWidget,
          );
        },
      );
    });

    libraryTest('reminder, could not schedule, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'could_not_schedule',
        platform: FakeReminderPlatform()..refusing.add(PlatformCall.schedule),
        act: (_) => toggle(tester),
      );
    });

    libraryTest('reminder, off may show, $theme', (tester, env) async {
      final platform = FakeReminderPlatform();
      await shoot(
        tester,
        env,
        'off_may_show',
        platform: platform,
        act: (_) async {
          await toggle(tester);
          platform.refusing.add(PlatformCall.cancel);
          await toggle(tester);
        },
      );
    });

    libraryTest('reminder, unavailable, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'unavailable',
        platform: FakeReminderPlatform(
          capabilityValue: ReminderCapability.unsupported,
        ),
      );
    });

    libraryTest('reminder, loading, $theme', (tester, env) async {
      final never = StreamController<ReminderStatus>();
      addTearDown(never.close);
      await shoot(
        tester,
        env,
        'loading',
        overrides: [reminderStatusProvider.overrideWith((ref) => never.stream)],
      );
    });

    libraryTest('reminder, read error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'read_error',
        overrides: [
          reminderStatusProvider.overrideWith(
            (ref) => Stream.error(FlakySettingsRepository.failure),
          ),
        ],
      );
    });
  }
}
