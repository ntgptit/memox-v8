import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_preview_section_widget.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/reminder_screen_harness.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/forui_expect.dart';

// Screen 24, Daily reminder: UC-REMINDER-001; FE-B5 spec §5.1.

final _en = lookupAppLocalizations(const Locale('en'));

/// The screen with the permission denied and the toggle tapped: the guidance
/// banner is up. [platform] defaults to one that denies.
Future<({FakeReminderPlatform platform, FlakySettingsRepository store})>
_pumpDenied(
  WidgetTester tester,
  LibraryEnv env, {
  FakeReminderPlatform? platform,
}) async {
  final pumped = await pumpReminderScreen(
    tester,
    env,
    platform:
        platform ?? FakeReminderPlatform(permission: ReminderPermission.denied),
  );
  await tapReminderToggle(tester);
  return pumped;
}

/// The guidance banner's buttons, in order.
List<MxButton> _bannerButtons(WidgetTester tester) => tester
    .widgetList<MxButton>(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.byType(MxButton),
      ),
    )
    .toList();

void main() {
  libraryTest('off: toggle off, time row disabled, note and preview (main 1)', (
    tester,
    env,
  ) async {
    final s = await pumpReminderScreen(tester, env);

    expect(find.text(metaDots(_en.reminderOffHint)), findsOneWidget);
    expect(find.text(metaDots(_en.reminderTimeOffHint)), findsOneWidget);
    expect(find.text(_en.reminderNote), findsOneWidget);
    expect(find.text(_en.reminderPreviewNothingDue), findsOneWidget);
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
      final s = await pumpReminderScreen(tester, env);
      await tapReminderToggle(tester);

      expect(
        s.platform.calls.where((c) => c == PlatformCall.requestPermission),
        hasLength(1),
      );
      expect(find.text(metaDots(_en.reminderOnHint)), findsOneWidget);
      expect(find.text(metaDots(_en.reminderTimeOnHint)), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
    },
  );

  libraryTest(
    'busy: the toggle becomes a spinner, the permission is asked once',
    (tester, env) async {
      final s = await pumpReminderScreen(tester, env);
      final hold = Completer<void>();
      s.store.hold = hold;

      await tester.tap(find.byType(MxToggle));
      await tester.pump();
      expect(find.byType(MxSpinner), findsOneWidget);
      expect(find.byType(MxToggle), findsNothing);

      hold.complete();
      await settleReminderScreen(tester);
      expect(
        s.platform.calls.where((c) => c == PlatformCall.requestPermission),
        hasLength(1),
      );
    },
  );

  libraryTest('the gap before What it says is one section gap without a banner '
      'and one more under a banner (audit 2026-10-17 SET-3)', (
    tester,
    env,
  ) async {
    await pumpReminderScreen(
      tester,
      env,
      platform: FakeReminderPlatform(permission: ReminderPermission.denied),
    );
    final settings = find.byType(ReminderSettingsSectionWidget);
    final preview = find.byType(ReminderPreviewSectionWidget);
    final gap = tester.element(preview).dimens.space16;
    // The section carries its own bottom space; nothing is added on top.
    expect(
      tester.getTopLeft(preview).dy - tester.getBottomLeft(settings).dy,
      0,
    );

    await tapReminderToggle(tester);
    final banner = find.byType(MxInlineBanner);
    expect(banner, findsOneWidget);
    expect(
      tester.getTopLeft(preview).dy - tester.getBottomLeft(banner).dy,
      gap,
    );
  });

  libraryTest('permDenied: the guidance and Try again, which asks again (E1)', (
    tester,
    env,
  ) async {
    final s = await _pumpDenied(tester, env);

    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
    expect(find.text(_en.reminderDeniedBody), findsOneWidget);
    expect(find.text(metaDots(_en.reminderDeniedHint)), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);

    s.platform.permission = ReminderPermission.granted;
    await tester.tap(find.text(_en.reminderTryAgain));
    await settleReminderScreen(tester);
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(metaDots(_en.reminderOnHint)), findsOneWidget);
  });

  libraryTest('permDenied: Try again outlined, then Open system settings '
      'last and primary (R5, amends FE-B6)', (tester, env) async {
    await _pumpDenied(tester, env);

    final buttons = _bannerButtons(tester);
    expect(buttons.map((b) => b.label), [
      _en.reminderTryAgain,
      _en.reminderOpenSystemSettings,
    ]);
    expect(buttons.map((b) => b.tone), [
      MxButtonTone.outline,
      MxButtonTone.primary,
    ]);
  });

  libraryTest('permDenied: while Try again runs the banner steps aside, '
      'then returns in the same order', (tester, env) async {
    final platform = FakeReminderPlatform(
      permission: ReminderPermission.denied,
    );
    await _pumpDenied(tester, env, platform: platform);
    platform.permissionHold = Completer<void>();
    await tester.tap(find.text(_en.reminderTryAgain));
    await tester.pump();
    expect(find.byType(MxInlineBanner), findsNothing);

    platform.permissionHold!.complete();
    await settleReminderScreen(tester);
    final buttons = _bannerButtons(tester);
    expect(buttons.map((b) => b.label), [
      _en.reminderTryAgain,
      _en.reminderOpenSystemSettings,
    ]);
  });

  libraryTest('permDenied: Open system settings opens them and changes nothing '
      'else: no permission asked, nothing written, the banner stays '
      '(FE-B6; BR-REMINDER-011)', (tester, env) async {
    final s = await _pumpDenied(tester, env);
    final asked = s.platform.calls
        .where((c) => c == PlatformCall.requestPermission)
        .length;
    final writes = s.store.writes;

    await tester.tap(find.text(_en.reminderOpenSystemSettings));
    await settleReminderScreen(tester);

    expect(s.platform.calls.last, PlatformCall.openSettings);
    expect(
      s.platform.calls.where((c) => c == PlatformCall.requestPermission),
      hasLength(asked),
    );
    expect(s.store.writes, writes);
    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
  });

  libraryTest('permDenied: settings that cannot open leave the guidance as it '
      'is (FE-B6)', (tester, env) async {
    final platform = FakeReminderPlatform(permission: ReminderPermission.denied)
      ..refusing.add(PlatformCall.openSettings);
    await _pumpDenied(tester, env, platform: platform);

    await tester.tap(find.text(_en.reminderOpenSystemSettings));
    await settleReminderScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
    expect(find.text(_en.reminderDeniedBody), findsOneWidget);
  });

  libraryTest('couldNotSchedule on Enable: danger banner, Retry enables (E3)', (
    tester,
    env,
  ) async {
    final platform = FakeReminderPlatform()
      ..refusing.add(PlatformCall.schedule);
    await pumpReminderScreen(tester, env, platform: platform);
    await tapReminderToggle(tester);

    expect(find.text(_en.reminderCouldNotTurnOnTitle), findsOneWidget);
    platform.refusing.clear();
    await tester.tap(find.text(_en.commonRetry));
    await settleReminderScreen(tester);
    expect(find.text(metaDots(_en.reminderOnHint)), findsOneWidget);
  });

  libraryTest(
    'offMayShow: off, the warning and Try again, which only cancels (E6)',
    (tester, env) async {
      final s = await pumpReminderScreen(tester, env);
      await tapReminderToggle(tester);
      s.platform.refusing.add(PlatformCall.cancel);
      await tapReminderToggle(tester);

      expect(find.text(_en.reminderMayStillShow), findsOneWidget);
      expect(find.text(metaDots(_en.reminderOffHint)), findsOneWidget);
      s.platform.refusing.clear();
      final writes = s.store.writes;
      await tester.tap(find.text(_en.reminderTryAgain));
      await settleReminderScreen(tester);
      expect(find.text(_en.reminderMayStillShow), findsNothing);
      expect(s.store.writes, writes);
    },
  );

  libraryTest('unavailable: one row, no toggle, no time, no preview (E2)', (
    tester,
    env,
  ) async {
    await pumpReminderScreen(
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
    final s = await pumpReminderScreen(tester, env);
    s.store.isFailing = true;
    await tapReminderToggle(tester);

    expect(find.text(_en.reminderSaveFailed), findsOneWidget);
    expect(find.textContaining('/data/'), findsNothing, reason: 'BR-CORE-005');
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);

    s.store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await settleReminderScreen(tester);
    expect(find.text(metaDots(_en.reminderOnHint)), findsOneWidget);
  });

  libraryTest('E4: the failed-save toast leaves with the screen, so its Retry '
      'never reads a disposed one (audit LIB-1, same mechanism)', (
    tester,
    env,
  ) async {
    final s = await pumpReminderScreen(tester, env);
    s.store.isFailing = true;
    await tapReminderToggle(tester);
    expect(find.text(_en.commonRetry), findsOneWidget);

    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const SizedBox()),
          ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ReminderScreen), findsNothing);
    expect(find.text(_en.commonRetry), findsNothing);
    await tester.pump(const Duration(seconds: 10));
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
    await settleReminderScreen(tester);

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.reminderReadErrorTitle), findsOneWidget);
    expect(find.byType(MxToggle), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);
  });

  libraryTest('off: the time row is disabled', (tester, env) async {
    await pumpReminderScreen(tester, env);
    // The row is disabled and ignores pointers: the tap is meant to miss.
    await tester.tap(find.text('20:00'), warnIfMissed: false);
    await settleReminderScreen(tester);
    expect(find.text(_en.reminderTimeDialogTitle), findsNothing);
  });

  libraryTest(
    'A1: Cancel changes nothing; Save stores and schedules the new minute',
    (tester, env) async {
      final s = await pumpReminderScreen(tester, env);
      await tapReminderToggle(tester);
      final scheduledBefore = s.platform.pending;

      await tester.tap(find.text('20:00'));
      await settleReminderScreen(tester);
      await tester.tap(byControlLabel(_en.reminderLaterHour));
      await tester.pump();
      await tester.tap(find.text(_en.commonCancel));
      await settleReminderScreen(tester);
      expect(find.text('20:00'), findsOneWidget);
      expect(s.platform.pending, scheduledBefore);

      await tester.tap(find.text('20:00'));
      await settleReminderScreen(tester);
      await tester.tap(byControlLabel(_en.reminderLaterHour));
      await tester.pump();
      expect(
        find.text('21:00'),
        findsOneWidget,
        reason: 'the dialog reads the chosen time',
      );
      await tester.tap(find.text(_en.reminderTimeSave));
      await settleReminderScreen(tester);
      expect(find.text('21:00'), findsOneWidget);
      expect(s.platform.pending, isNot(scheduledBefore));
    },
  );

  libraryTest(
    'couldNotChangeTime: the old time stands, the banner names it (E3)',
    (tester, env) async {
      final s = await pumpReminderScreen(tester, env);
      await tapReminderToggle(tester);
      s.platform.refusing.add(PlatformCall.schedule);

      await tester.tap(find.text('20:00'));
      await settleReminderScreen(tester);
      await tester.tap(byControlLabel(_en.reminderLaterHour));
      await tester.tap(find.text(_en.reminderTimeSave));
      await settleReminderScreen(tester);

      expect(find.text(_en.reminderCouldNotChangeTimeTitle), findsOneWidget);
      expect(
        find.text(_en.reminderCouldNotChangeTimeBody('20:00')),
        findsOneWidget,
      );
    },
  );

  libraryTest('off: the time button draws its own disabled state, dimmed '
      'once (critique 2026-09-30 part 3a)', (tester, env) async {
    await pumpReminderScreen(tester, env);
    final time = find.descendant(
      of: find.byType(MxButton),
      matching: find.text('20:00'),
    );
    final context = tester.element(time);
    // ForUI's own disabled paint dims it, once; no Opacity wraps it as well.
    expect(
      textColor(tester, time),
      context.colors.disable(context.colors.secondaryForeground),
    );
    expect(
      find.ancestor(of: time, matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  // SW-REV-005: the time button reads its full label and keeps its tap.
  libraryTest('TalkBack reads the time button and can press it', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpReminderScreen(tester, env);
    await tapReminderToggle(tester);

    expect(
      tester.getSemantics(
        find.bySemanticsLabel(_en.reminderTimeButton('20:00')),
      ),
      isSemantics(hasTapAction: true, hasEnabledState: true, isEnabled: true),
    );
    handle.dispose();
  });
}
