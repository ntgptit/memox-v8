import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

const _forbidden = 'FORBIDDEN';

/// The [Failure] a server call's error becomes at the repository boundary
/// (ADR-016 D2). The server's `FORBIDDEN` and a missing session are "not an
/// admin"; the rest is sync's classification: a call that never arrived is
/// offline, anything else is the server's.
Failure mapMonitoringError(Object error) {
  if (error is Failure) return error;
  if (error is MonitoringSessionMissing) return NotAdminFailure(cause: error);
  if (error is PostgrestException && error.message == _forbidden) {
    return NotAdminFailure(cause: error);
  }
  return switch (classifySyncFailure(error)) {
    SyncFailureKind.network => OfflineFailure(cause: error),
    SyncFailureKind.signIn ||
    SyncFailureKind.server ||
    SyncFailureKind.unknown => ServerFailure(cause: error),
  };
}
