import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

// A row whose device-clock expiry has passed while the purge clock (the
// earlier of the device and the last server time) has not says when it goes
// (SP2b final 4, owner ruling).
const _ahead = Duration(days: 60);

void main() {
  libraryTest('a device clock 60 days ahead of the last server time keeps the '
      'expired rows and says they go after the next sync, in neutral ink', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    // The server last said "today"; the device now says 60 days later.
    await SyncStore(env.db).recordServerTime(env.clock.current);
    env.serverTime = SyncStore(env.db).serverTime;
    env.clock.current = env.clock.current.add(_ahead);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    // Places (28 days old) and the other past-expiry rows are still there.
    expect(find.text('Places'), findsOneWidget);
    expect(find.text(_en.trashAwaitingSync), findsWidgets);
    expect(
      find.widgetWithText(MxBadge, _en.trashAwaitingSync),
      findsNothing,
      reason: 'neutral ink, not the warning pill',
    );
    expect(find.text(_en.trashHoursLeft(1)), findsNothing);
  });

  libraryTest('a device that never synced says the same for an expired row', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    env.serverTime = SyncStore(env.db).serverTime;
    env.clock.current = env.clock.current.add(_ahead);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(find.text('Places'), findsOneWidget);
    expect(find.text(_en.trashAwaitingSync), findsWidgets);
  });

  libraryTest('rows not past the device expiry keep their time left', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await SyncStore(env.db).recordServerTime(env.clock.current);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(find.text(_en.trashAwaitingSync), findsNothing);
    expect(find.text(_en.trashDaysLeft(2)), findsOneWidget);
  });

  test('the copy', () {
    expect(_en.trashAwaitingSync, 'Removed after the next sync');
    expect(_vi.trashAwaitingSync, 'Sẽ xoá sau lần đồng bộ tới');
  });
}
