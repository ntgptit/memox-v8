/// Where a session is in its life, stored as a stable text code on
/// `study_session.status` (BR-STUDY-010). Every status but [inProgress] is
/// final.
enum SessionStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned'),
  invalidated('invalidated'),
  failed('failed');

  const SessionStatus(this.code);

  final String code;

  static SessionStatus fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    throw ArgumentError.value(code, 'code', 'unknown session status');
  }
}

/// Why a session ended other than by finishing its queue, stored on
/// `study_session.end_reason` (BR-STUDY-012; schema.md's status matrix).
enum SessionEndReason {
  userExit('user_exit'),
  interrupted('interrupted'),
  schedulerReset('scheduler_reset'),
  schedulerChanged('scheduler_changed'),
  staleGeneration('stale_generation'),
  persistenceError('persistence_error'),
  contentDeleted('content_deleted');

  const SessionEndReason(this.code);

  final String code;

  static SessionEndReason fromCode(String code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    throw ArgumentError.value(code, 'code', 'unknown session end reason');
  }
}
