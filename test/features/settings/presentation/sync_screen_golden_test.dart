@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';

import '../../../support/account_harness.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> golden(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      SyncStatus status, {
      FakeSyncCommands? commands,
      List<Override> overrides = const [],
      Future<void> Function()? act,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          SyncScreen(onSignIn: () {}),
          brightness,
          overrides: [...syncOverrides(status, commands), ...overrides],
        );
        await act?.call();
        await expectBoundaryGolden(tester, 'goldens/sync_${state}_$theme.png');
      });
    }

    DateTime minutesAgo(LibraryEnv env, int minutes) =>
        env.clock.now().subtract(Duration(minutes: minutes));

    libraryTest('sync, synced, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'synced',
        SyncStatus(lastSuccessAt: minutesAgo(env, 5)),
      );
    });

    libraryTest('sync, never synced, $theme', (tester, env) async {
      await golden(tester, env, 'never_synced', const SyncStatus());
    });

    libraryTest('sync, pending, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'pending',
        SyncStatus(
          lastSuccessAt: minutesAgo(env, 5),
          pendingCount: 12,
          oldestPendingAt: minutesAgo(env, 1),
        ),
      );
    });

    libraryTest('sync, failed network, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'failed_network',
        SyncStatus(
          lastSuccessAt: minutesAgo(env, 90),
          pendingCount: 3,
          oldestPendingAt: minutesAgo(env, 30),
          lastFailure: LastSyncFailure(
            SyncFailureKind.network,
            minutesAgo(env, 1),
          ),
        ),
      );
    });

    // SP2b 2.37: the session was refused; Sign in leads.
    libraryTest('sync, failed sign-in, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'failed_sign_in',
        SyncStatus(
          lastSuccessAt: minutesAgo(env, 90),
          pendingCount: 3,
          oldestPendingAt: minutesAgo(env, 30),
          lastFailure: LastSyncFailure(
            SyncFailureKind.signIn,
            minutesAgo(env, 1),
          ),
        ),
        overrides: [
          authStateOf(
            const ReauthRequired(
              AccountUser(
                id: 'x',
                email: 'a@example.com',
                isAnonymous: false,
                role: AccountRole.user,
              ),
            ),
          ),
        ],
        act: () async {
          await tester.pump();
          expect(find.text('Sign in'), findsOneWidget);
        },
      );
    });

    libraryTest('sync, failed server, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'failed_server',
        SyncStatus(
          lastSuccessAt: minutesAgo(env, 90),
          lastFailure: LastSyncFailure(
            SyncFailureKind.server,
            minutesAgo(env, 1),
          ),
        ),
      );
    });

    libraryTest('sync, rejected, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'rejected',
        SyncStatus(lastSuccessAt: minutesAgo(env, 5), rejectedCount: 2),
      );
    });

    // Critique 2026-09-30 part 1 (R4): Keep asks first.
    libraryTest('sync, keep dialog, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'keep_dialog',
        SyncStatus(lastSuccessAt: minutesAgo(env, 5), rejectedCount: 2),
        act: () async {
          await tester.tap(find.text('Keep on this device'));
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('sync, syncing, $theme', (tester, env) async {
      final commands = FakeSyncCommands()..hold = Completer<bool>();
      await golden(
        tester,
        env,
        'syncing',
        const SyncStatus(),
        commands: commands,
        act: () async {
          await tester.tap(find.text('Sync now'));
          await tester.pump();
        },
      );
      commands.hold!.complete(true);
      await tester.pump();
    });
  }
}
