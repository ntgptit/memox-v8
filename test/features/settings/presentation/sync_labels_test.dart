import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('vi');
  });

  final now = DateTime(2026, 9, 28, 0, 30);

  test('today, yesterday by the calendar day, and earlier days', () {
    expect(syncTimeLabel(en, DateTime(2026, 9, 28, 0, 5), now), 'Today, 00:05');
    expect(
      syncTimeLabel(en, DateTime(2026, 9, 27, 23, 50), now),
      'Yesterday, 23:50',
    );
    expect(
      syncTimeLabel(en, DateTime(2026, 9, 26, 14, 32), now),
      'Sep 26, 14:32',
    );
    expect(
      syncTimeLabel(vi, DateTime(2026, 9, 27, 9, 10), now),
      'Hôm qua, 09:10',
    );
  });

  test('the status line: refused, then failure, then success, then never', () {
    final success = DateTime(2026, 9, 28, 0, 10);
    expect(
      syncStatusLine(en, const SyncStatus(rejectedCount: 2), now),
      "2 changes weren't accepted",
    );
    expect(
      syncStatusLine(
        en,
        SyncStatus(
          lastSuccessAt: success,
          lastFailure: LastSyncFailure(SyncFailureKind.network, now),
        ),
        now,
      ),
      "Couldn't sync · no connection",
    );
    expect(
      syncStatusLine(en, SyncStatus(lastSuccessAt: success), now),
      'Synced Today, 00:10',
    );
    expect(syncStatusLine(en, const SyncStatus(), now), 'Not synced yet');
  });

  test('every failure kind has its sentence', () {
    for (final kind in SyncFailureKind.values) {
      expect(syncFailureSentence(en, kind), isNotEmpty);
    }
  });

  test('refused rows read in vi for one and for two (R3)', () {
    for (final count in [1, 2]) {
      expect(vi.syncRejectedTitle(count), contains('chưa được máy chủ nhận'));
      expect(vi.syncStatusRejected(count), contains('chưa được máy chủ nhận'));
      expect(
        vi.studyHomeSyncRejected(count),
        contains('chưa được máy chủ nhận'),
      );
    }
  });

  test('settled: synced once, nothing waiting, refused or failed (critique '
      '2026-09-30 tone pass, T3)', () {
    final success = DateTime(2026, 9, 28, 0, 10);
    expect(syncIsSettled(SyncStatus(lastSuccessAt: success)), isTrue);
    expect(syncIsSettled(const SyncStatus()), isFalse);
    expect(
      syncIsSettled(SyncStatus(lastSuccessAt: success, pendingCount: 1)),
      isFalse,
    );
    expect(
      syncIsSettled(SyncStatus(lastSuccessAt: success, rejectedCount: 1)),
      isFalse,
    );
    expect(
      syncIsSettled(
        SyncStatus(
          lastSuccessAt: success,
          lastFailure: LastSyncFailure(SyncFailureKind.network, success),
        ),
      ),
      isFalse,
    );
  });
}
