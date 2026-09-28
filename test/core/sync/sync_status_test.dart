import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_status.dart';

void main() {
  final now = DateTime.utc(2026, 9, 28, 12);

  test('nothing pending and nothing refused needs no attention', () {
    expect(needsAttention(const SyncStatus(), now), isFalse);
  });

  test('a change waiting just under a day needs no attention', () {
    final status = SyncStatus(
      pendingCount: 1,
      oldestPendingAt: now.subtract(const Duration(hours: 23, minutes: 59)),
    );
    expect(needsAttention(status, now), isFalse);
  });

  test('a change waiting over a day needs attention', () {
    final status = SyncStatus(
      pendingCount: 1,
      oldestPendingAt: now.subtract(const Duration(hours: 24, minutes: 1)),
    );
    expect(needsAttention(status, now), isTrue);
  });

  test('a refused row needs attention at once', () {
    expect(needsAttention(const SyncStatus(rejectedCount: 1), now), isTrue);
  });
}
