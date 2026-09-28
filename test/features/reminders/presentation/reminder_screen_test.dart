import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// Screen 24, Daily reminder: UC-REMINDER-001; FE-B5 spec §5.1.

final _en = lookupAppLocalizations(const Locale('en'));

/// The preview is the notification's own sentence (FE-B5 Task 2 ruling).
final _sample = _en.reminderPreviewQuoted(
  _en.reminderBodyWithOthers(
    _en.reminderDueCards(86),
    _en.reminderPreviewDeck,
    _en.reminderOtherDecks(2),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<({FakeReminderPlatform platform, FlakySettingsRepository store})> _pump(
  WidgetTester tester,
  LibraryEnv env, {
  FakeReminderPlatform? platform,
}) async {
  final fake = platform ?? FakeReminderPlatform();
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  await pumpLibraryScreen(
    tester,
    env,
    const ReminderScreen(),
    overrides: [
      reminderPlatformRepositoryProvider.overrideWithValue(fake),
      settingsRepositoryProvider.overrideWithValue(store),
    ],
  );
  await _settle(tester);
  return (platform: fake, store: store);
}

Future<void> _toggle(WidgetTester tester) async {
  await tester.tap(find.byType(MxToggle));
  await _settle(tester);
}

void main() {
  libraryTest('off: toggle off, time row disabled, note and preview (main 1)', (
    tester,
    env,
  ) async {
    final s = await _pump(tester, env);

    expect(find.text(_en.reminderOffHint), findsOneWidget);
    expect(find.text(_en.reminderTimeOffHint), findsOneWidget);
    expect(find.text(_en.reminderNote), findsOneWidget);
    expect(find.text(_sample), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);
    expect(
      s.platform.calls,
      isNot(contains(PlatformCall.requestPermission)),
      reason: 'BR-REMINDER-011: nothing is asked on open',
    );
  });

  libraryTest(
    'on: the toggle asks for the permission, then the time row opens (main 2-3)',
    (tester, env) async {
      final s = await _pump(tester, env);
      await _toggle(tester);

      expect(
        s.platform.calls.where((c) => c == PlatformCall.requestPermission),
        hasLength(1),
      );
      expect(find.text(_en.reminderOnHint), findsOneWidget);
      expect(find.text(_en.reminderTimeOnHint), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
    },
  );

  libraryTest(
    'busy: the toggle becomes a spinner, the permission is asked once',
    (tester, env) async {
      final s = await _pump(tester, env);
      final hold = Completer<void>();
      s.store.hold = hold;

      await tester.tap(find.byType(MxToggle));
      await tester.pump();
      expect(find.byType(MxSpinner), findsOneWidget);
      expect(find.byType(MxToggle), findsNothing);

      hold.complete();
      await _settle(tester);
      expect(
        s.platform.calls.where((c) => c == PlatformCall.requestPermission),
        hasLength(1),
      );
    },
  );

  libraryTest('permDenied: the guidance and Try again, which asks again (E1)', (
    tester,
    env,
  ) async {
    final s = await _pump(
      tester,
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    await _toggle(tester);

    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
    expect(find.text(_en.reminderDeniedBody), findsOneWidget);
    expect(find.text(_en.reminderDeniedHint), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);

    s.platform.permission = ReminderPermission.granted;
    await tester.tap(find.text(_en.reminderTryAgain));
    await _settle(tester);
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
  });

  libraryTest('couldNotSchedule on Enable: danger banner, Retry enables (E3)', (
    tester,
    env,
  ) async {
    final platform = FakeReminderPlatform()
      ..refusing.add(PlatformCall.schedule);
    await _pump(tester, env, platform: platform);
    await _toggle(tester);

    expect(find.text(_en.reminderCouldNotTurnOnTitle), findsOneWidget);
    platform.refusing.clear();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
  });

  libraryTest(
    'offMayShow: off, the warning and Try again, which only cancels (E6)',
    (tester, env) async {
      final s = await _pump(tester, env);
      await _toggle(tester);
      s.platform.refusing.add(PlatformCall.cancel);
      await _toggle(tester);

      expect(find.text(_en.reminderMayStillShow), findsOneWidget);
      expect(find.text(_en.reminderOffHint), findsOneWidget);
      s.platform.refusing.clear();
      final writes = s.store.writes;
      await tester.tap(find.text(_en.reminderTryAgain));
      await _settle(tester);
      expect(find.text(_en.reminderMayStillShow), findsNothing);
      expect(s.store.writes, writes);
    },
  );

  libraryTest('unavailable: one row, no toggle, no time, no preview (E2)', (
    tester,
    env,
  ) async {
    await _pump(
      tester,
      env,
      platform: FakeReminderPlatform(
        capabilityValue: ReminderCapability.unsupported,
      ),
    );

    expect(find.text(_en.reminderUnavailable), findsOneWidget);
    expect(find.byType(MxToggle), findsNothing);
    expect(find.text(_en.reminderTime), findsNothing);
    expect(find.text(_en.reminderPreviewTitle), findsNothing);
  });

  libraryTest('E4: a failed save says so with Retry; the toggle stays off', (
    tester,
    env,
  ) async {
    final s = await _pump(tester, env);
    s.store.isFailing = true;
    await _toggle(tester);

    expect(find.text(_en.reminderSaveFailed), findsOneWidget);
    expect(find.textContaining('/data/'), findsNothing, reason: 'BR-CORE-005');
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);

    s.store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
  });

  libraryTest('loading: the list skeleton', (tester, env) async {
    final never = StreamController<ReminderStatus>();
    addTearDown(never.close);
    await pumpLibraryScreen(
      tester,
      env,
      const ReminderScreen(),
      overrides: [reminderStatusProvider.overrideWith((ref) => never.stream)],
    );
    await tester.pump();
    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('E7: a failed read replaces the body, Retry reads again', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const ReminderScreen(),
      overrides: [
        reminderStatusProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );
    await _settle(tester);

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.reminderReadErrorTitle), findsOneWidget);
    expect(find.byType(MxToggle), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);
  });
}
