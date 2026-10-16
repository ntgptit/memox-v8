import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/widgets/items/settings_sync_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// The hub's Sync row: a failed sync's hint keeps each dot on the phrase before
// it, and the phrases wrap as words (The Wrap Rule).
void main() {
  libraryTest('a failed sync names the cause, the dot kept on its phrase', (
    tester,
    env,
  ) async {
    final now = DateTime.utc(2026, 10, 16, 9);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: SettingsSyncRowWidget(
          status: SyncStatus(
            lastFailure: LastSyncFailure(SyncFailureKind.network, now),
          ),
          now: now,
          onOpenSync: () {},
        ),
      ),
    );

    expect(find.text(metaDots(_en.syncStatusFailedNetwork)), findsOneWidget);
  });
}
