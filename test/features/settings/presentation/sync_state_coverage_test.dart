import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';
import '../../../support/sync_fakes.dart';

// The States rows of screen 27 (Sync) whose detail file cites no executed
// test: "change failed". ("unavailable" is covered by
// sync_screen_test.dart::a build without sync says so, neutrally and with
// no Retry.)

final _en = lookupAppLocalizations(const Locale('en'));

/// Sync now and Try again throw on their first run, as a command that
/// dies does; the next ones go through.
final class _ThrowingOnce extends FakeSyncCommands {
  var _hasThrown = false;

  @override
  Future<bool> syncNow() async {
    if (_hasThrown) return super.syncNow();
    _hasThrown = true;
    syncs++;
    throw StateError('sync died');
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  libraryTest('change failed: a command that throws says nothing was lost '
      'with a toast offering Retry; Retry runs it again', (tester, env) async {
    final commands = _ThrowingOnce();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );

    await tester.tap(find.text(_en.syncNow));
    await _settle(tester);

    expect(commands.syncs, 1);
    expect(find.text(_en.syncChangeFailed), findsOneWidget);
    expect(find.text(_en.syncNotDone), findsNothing);
    expect(find.text(_en.syncDone), findsNothing);
    expect(find.textContaining('sync died'), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);
    // The screen is usable again behind the toast.
    expect(find.text(_en.syncNow), findsOneWidget);

    // The toast slides in before its action can be hit.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(commands.syncs, 2);
    expect(find.text(_en.syncDone), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
