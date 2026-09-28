import 'package:flutter/foundation.dart';
import 'package:memox/core/sync/sync_failure.dart';

/// How long a change may wait for the server before Study home says so
/// (sync status spec R2).
const Duration syncAttentionAge = Duration(hours: 24);

/// The last failed run, shown only while no success came after it.
@immutable
final class LastSyncFailure {
  const LastSyncFailure(this.kind, this.at);

  final SyncFailureKind kind;
  final DateTime at;
}

/// What sync has done, read from Drift (sync status spec §4). Times are UTC.
@immutable
final class SyncStatus {
  const SyncStatus({
    this.lastSuccessAt,
    this.lastFailure,
    this.pendingCount = 0,
    this.oldestPendingAt,
    this.rejectedCount = 0,
  });

  final DateTime? lastSuccessAt;
  final LastSyncFailure? lastFailure;

  /// Outbox entries not yet acknowledged.
  final int pendingCount;

  /// When the longest-waiting of them first went unsent.
  final DateTime? oldestPendingAt;

  /// Rows the server refused and never saw (`sync_rejection`).
  final int rejectedCount;
}

/// Study home shows its banner (R2): a refused row, or a change that has
/// waited longer than [syncAttentionAge].
bool needsAttention(SyncStatus status, DateTime now) {
  if (status.rejectedCount > 0) return true;
  final oldest = status.oldestPendingAt;
  if (oldest == null) return false;
  return now.difference(oldest) > syncAttentionAge;
}
