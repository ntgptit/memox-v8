/// The two kinds of study session, stored by name on
/// `study_session.session_kind` (BR-STUDY-051). They never share cards.
enum SessionKind {
  /// Cards not learned yet, through the algorithm's stage chain
  /// (BR-MODE-003).
  learning,

  /// Learned cards that are due, through the one mode the person picks
  /// (BR-STUDY-055).
  reviewing,
}
