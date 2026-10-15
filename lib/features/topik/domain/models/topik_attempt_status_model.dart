/// Where an attempt is in its life (BR-TOPIK-010), stored as a stable text
/// code on `topik_attempt.status`. [completed] is final: the attempt no longer
/// changes.
enum TopikAttemptStatus {
  inProgress('in_progress'),
  completed('completed');

  const TopikAttemptStatus(this.code);

  final String code;

  static TopikAttemptStatus fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    throw ArgumentError.value(code, 'code', 'unknown TOPIK attempt status');
  }
}

/// How an attempt is taken, stored on `topik_attempt.mode`. Exam mode is
/// Phase B (BR-TOPIK-032) and has no value yet.
enum TopikAttemptMode {
  practice('practice');

  const TopikAttemptMode(this.code);

  final String code;

  static TopikAttemptMode fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    throw ArgumentError.value(code, 'code', 'unknown TOPIK attempt mode');
  }
}

/// What a submitted answer was (BR-TOPIK-013). Derived from the snapshot,
/// never stored.
enum TopikAnswerStatus { correct, wrong, unanswered }
