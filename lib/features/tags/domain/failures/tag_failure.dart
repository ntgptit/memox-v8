/// Why the tags feature refuses a write (ADR-011 D6).
enum TagRejection {
  /// BR-TAG-001: the name is blank after trim.
  blankName,

  /// BR-TAG-001: the name is longer than 50 characters.
  nameTooLong,

  /// BR-TAG-001: the name holds a control character.
  controlCharacter,

  /// BR-TAG-002: a card would carry more than 10 tags.
  tooManyTags,

  /// A card or tag no longer exists.
  notFound,

  /// BR-TAG-007, tag management spec D5: the rename would merge into a tag
  /// the caller did not confirm. The data moved since the plan: plan again.
  mergeNotConfirmed,
}
