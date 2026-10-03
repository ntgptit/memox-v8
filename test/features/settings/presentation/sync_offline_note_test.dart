import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

// Screen 27 (critique 2026-10-02, F8): no connection is a fact to wait out,
// not a warning; keeping refused changes on the device is warned before.
void main() {
  libraryTest('a network failure is a neutral note, and Sync now steps down '
      'to outline even with changes waiting', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () {}),
      overrides: syncOverrides(
        SyncStatus(
          pendingCount: 2,
          lastFailure: LastSyncFailure(
            SyncFailureKind.network,
            env.clock.now(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxInlineBanner), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MxNote),
        matching: find.textContaining('No connection.'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Sync now')).tone,
      MxButtonTone.outline,
    );
  });

  libraryTest('a server failure stays a warning and Sync now leads', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () {}),
      overrides: syncOverrides(
        SyncStatus(
          lastFailure: LastSyncFailure(SyncFailureKind.server, env.clock.now()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Sync now')).tone,
      MxButtonTone.primary,
    );
  });

  libraryTest('the Keep dialog confirms in warning', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SyncScreen(onSignIn: () {}),
      overrides: syncOverrides(
        const SyncStatus(rejectedCount: 3),
        FakeSyncCommands(),
      ),
    );
    await tester.tap(find.text('Keep on this device'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).isWarning,
      isTrue,
    );
  });
}
