import 'package:memox/core/error/failure.dart';

/// Why a Monitoring read failed, as the screens tell it apart (monitoring
/// spec §3.4): not an admin, offline, or anything else.
enum MonitoringLoadFailure {
  notAdmin,
  offline,
  other;

  /// The kind of [error], which is a `Failure` from the repository.
  static MonitoringLoadFailure of(Object error) => switch (error) {
    NotAdminFailure() => notAdmin,
    OfflineFailure() => offline,
    _ => other,
  };
}
