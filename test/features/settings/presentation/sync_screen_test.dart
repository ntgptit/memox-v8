import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/features/settings/presentation/widgets/sections/sync_status_section_widget.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';
import '../../../shared/expect_one_primary.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  libraryTest('Sync now runs and says Synced', (tester, env) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );
    await tester.tap(find.text('Sync now'));
    await _settle(tester);
    expect(commands.syncs, 1);
    expect(find.text('Synced'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('refused rows offer Try again and Keep on device', (
    tester,
    env,
  ) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 3), commands),
    );
    expect(find.text("3 changes weren't accepted"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await _settle(tester);
    expect(commands.retries, 1);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('while a Retry reloads, the error stays and its Retry spins', (
    tester,
    env,
  ) async {
    var reads = 0;
    final pending = StreamController<SyncStatus>();
    addTearDown(pending.close);
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: [
        syncCommandsProvider.overrideWithValue(FakeSyncCommands()),
        syncStatusProvider.overrideWith((ref) {
          reads++;
          return reads == 1
              ? Stream<SyncStatus>.error(StateError('read failed'))
              : pending.stream;
        }),
      ],
    );
    await _settle(tester);
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(find.byType(MxErrorState), findsOneWidget);
    final retry = find.descendant(
      of: find.byType(MxErrorState),
      matching: find.byType(MxButton),
    );
    expect(tester.widget<MxButton>(retry).isLoading, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a build without sync says so, neutrally and with no Retry '
      '(audit 2026-10-17 SET-10)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: [
        syncStatusProvider.overrideWith(
          (ref) => Stream<SyncStatus?>.value(null),
        ),
        syncCommandsProvider.overrideWithValue(FakeSyncCommands()),
      ],
    );
    await _settle(tester);

    expect(find.byType(MxErrorState), findsNothing);
    expect(find.text("Couldn't open Sync"), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Sync now'), findsNothing);
    expect(find.text("Sync isn't available"), findsOneWidget);
    expect(find.textContaining('Nothing is lost'), findsOneWidget);
  });

  libraryTest('a second command waits for the first', (tester, env) async {
    final commands = FakeSyncCommands()..hold = Completer<bool>();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 1), commands),
    );
    await tester.tap(find.text('Sync now'));
    await tester.pump();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(commands.retries, 0);
    commands.hold!.complete(true);
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 200));
  });

  // Sync now steps back when nothing waits and leads while changes wait
  // (critique 2026-09-30).
  final syncNowTones = [
    (
      name: 'steps back when nothing waits',
      status: const SyncStatus(),
      tone: MxButtonTone.outline,
    ),
    (
      name: 'leads while changes wait',
      status: const SyncStatus(pendingCount: 3),
      tone: MxButtonTone.primary,
    ),
  ];
  for (final c in syncNowTones) {
    libraryTest('Sync now ${c.name} (critique 2026-09-30)', (
      tester,
      env,
    ) async {
      await pumpLibraryScreen(
        tester,
        env,
        const SyncScreen(),
        overrides: syncOverrides(c.status, FakeSyncCommands()),
      );
      await _settle(tester);
      expect(
        tester.widget<MxButton>(find.widgetWithText(MxButton, 'Sync now')).tone,
        c.tone,
      );
    });
  }

  libraryTest('a problem sits under the status, above Sync now, not in a '
      'floating notice (critique 2026-09-30)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(
          pendingCount: 2,
          lastFailure: LastSyncFailure(SyncFailureKind.server, env.clock.now()),
        ),
      ),
    );
    await _settle(tester);

    expect(find.byType(MxFloatingNotice), findsNothing);
    final banner = find.byType(MxInlineBanner);
    expect(banner, findsOneWidget);
    expect(
      tester.getBottomLeft(banner).dy,
      lessThan(tester.getTopLeft(find.text('Sync now')).dy),
    );
    expect(
      tester.getTopLeft(banner).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(find.byType(SyncStatusSectionWidget)).dy,
      ),
    );
  });

  libraryTest('refused rows: Try again is the one primary; Sync now is '
      'outline; the waiting row does not contradict the banner', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        const SyncStatus(rejectedCount: 2),
        FakeSyncCommands(),
      ),
    );
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Sync now')).tone,
      MxButtonTone.outline,
    );
    expect(find.text('No other changes waiting'), findsOneWidget);
    expect(find.text('Nothing waiting'), findsNothing);
    expect(
      find.textContaining("they won't sync to your other devices"),
      findsOneWidget,
    );
    expectOnePrimaryPerDecision(tester);
  });

  libraryTest('Keep asks first and keeps only on confirm', (tester, env) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 3), commands),
    );
    await tester.tap(find.text('Keep on device'));
    await tester.pumpAndSettle();
    expect(find.text('Keep 3 changes on this device only?'), findsOneWidget);
    expect(commands.keeps, 0);
    await tester.tap(find.text('Keep'));
    await _settle(tester);
    expect(commands.keeps, 1);
    expect(find.text('Kept on this device'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('dismissing the Keep dialog keeps the refused rows', (
    tester,
    env,
  ) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 3), commands),
    );
    await tester.tap(find.text('Keep on device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(commands.keeps, 0);
    await tester.tap(find.text('Keep on device'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(commands.keeps, 0);
    expect(find.text("3 changes weren't accepted"), findsOneWidget);
  });

  libraryTest('refused rows and a failure: one primary', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(
          rejectedCount: 1,
          lastFailure: LastSyncFailure(
            SyncFailureKind.network,
            env.clock.now(),
          ),
        ),
        FakeSyncCommands(),
      ),
    );
    expect(find.text('Try again'), findsOneWidget);
    expectOnePrimaryPerDecision(tester);
  });

  libraryTest('one refused change reads in the singular (R3)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        const SyncStatus(rejectedCount: 1),
        FakeSyncCommands(),
      ),
    );
    expect(find.text("1 change wasn't accepted"), findsOneWidget);
  });

  Finder syncCheck() => find.descendant(
    of: find.byType(SyncStatusSectionWidget),
    matching: find.byIcon(AppIcons.check),
  );

  libraryTest('settled sync ends the waiting row with a success check '
      '(critique 2026-09-30 tone pass, T3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(SyncStatus(lastSuccessAt: env.clock.now())),
    );
    expect(syncCheck(), findsOneWidget);
    expect(
      tester.widget<Icon>(syncCheck()).color,
      tester.element(syncCheck()).status.success,
    );
  });

  libraryTest('changes still waiting show no success check (T3)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(lastSuccessAt: env.clock.now(), pendingCount: 2),
      ),
    );
    expect(find.byType(SyncStatusSectionWidget), findsOneWidget);
    expect(syncCheck(), findsNothing);
  });

  libraryTest('while Sync now runs the screen says Syncing…; the button comes '
      'back after (critique 2026-09-30 part 3d-1, D5)', (tester, env) async {
    final commands = FakeSyncCommands()..hold = Completer<bool>();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );
    await tester.tap(find.text('Sync now'));
    await _settle(tester);

    expect(find.text('Syncing…'), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);

    commands.hold!.complete(true);
    await _settle(tester);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Syncing…'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a sync that fails while Syncing… shows brings the button and '
      'the failure back (Review Focus 5)', (tester, env) async {
    final commands = FakeSyncCommands()..hold = Completer<bool>();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );
    await tester.tap(find.text('Sync now'));
    await _settle(tester);

    commands.hold!.complete(false);
    await _settle(tester);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Syncing…'), findsNothing);
    expect(find.text("Couldn't sync. Nothing was lost."), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
