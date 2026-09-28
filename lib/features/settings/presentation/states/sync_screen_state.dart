import 'package:flutter/foundation.dart';

/// Screen 27's commands (sync status spec §5.2); one runs at a time.
enum SyncTask { syncNow, retry, keep }

/// What screen 27 says when a command ends. Each is a new object, so a
/// listener sees two of the same kind in a row.
sealed class SyncNotice {}

final class SyncSucceeded extends SyncNotice {}

final class SyncNotSucceeded extends SyncNotice {}

final class SyncKeptOnDevice extends SyncNotice {}

/// Try again or Keep on this device could not write (spec §6).
final class SyncChangeFailed extends SyncNotice {
  SyncChangeFailed(this.task);

  final SyncTask task;
}

/// Screen 27's own state: the command running and the last notice. What
/// sync did lives in the status stream.
@immutable
final class SyncScreenState {
  const SyncScreenState({this.task, this.notice});

  /// The command running, or null.
  final SyncTask? task;
  final SyncNotice? notice;
}
