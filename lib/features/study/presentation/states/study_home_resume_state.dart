/// How a Resume from Study Home ended (FE-A8 H3).
sealed class StudyHomeResumeResult {
  const StudyHomeResumeResult();
}

/// The session was taken up: its route opens.
final class ResumeOpened extends StudyHomeResumeResult {
  const ResumeOpened(this.sessionId);

  final String sessionId;
}

/// The session can no longer be taken up (it ended, went stale or its deck
/// left); the stream already shows why the card is gone.
final class ResumeRefused extends StudyHomeResumeResult {
  const ResumeRefused();
}

/// The write failed; nothing changed.
final class ResumeFailed extends StudyHomeResumeResult {
  const ResumeFailed();
}
