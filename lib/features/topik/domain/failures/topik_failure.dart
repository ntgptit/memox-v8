/// Why the topik feature refuses an attempt write (ADR-011 D6). A refusal
/// writes nothing.
enum TopikRejection {
  /// The attempt is gone: deleted on another screen, or by an account switch
  /// (BR-TOPIK-018, BR-TOPIK-027).
  notFound,

  /// The test already has an attempt in progress on this device; the person
  /// chooses Continue or Start new (BR-TOPIK-011).
  inProgressExists,

  /// The attempt was submitted and no longer changes (BR-TOPIK-010).
  attemptCompleted,

  /// The question number is not one of the attempt's.
  unknownQuestion,

  /// The option is not one of ①–④ (BR-TOPIK-003).
  invalidOption,

  /// The content given is not the attempt's test, or no longer has the
  /// attempt's questions (BR-TOPIK-019).
  contentMismatch,
}
