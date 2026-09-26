/// Why the Starter library refuses to add a template (starter decks spec
/// D11). A write that fails is a `Failure`, not a reason.
enum StarterRejection {
  /// No template in the library has that id: the library changed since it
  /// was read.
  templateNotFound,

  /// A copy of the template, at this version, is in the library, and a
  /// second copy was not confirmed (BR-STARTER-007, BR-STARTER-008).
  alreadyInLibrary,
}
