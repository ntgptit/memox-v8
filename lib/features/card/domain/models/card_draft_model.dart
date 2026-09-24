import 'package:characters/characters.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';

/// What the add and edit forms submit (card `ui.md`): the content, the flag
/// and the tag names. The per-field rules are static so a form can show each
/// error at its own field (UC-CARD-001 E1, E2).
final class CardDraft {
  const CardDraft({
    required this.front,
    required this.back,
    this.example,
    this.hint,
    this.pronunciation,
    this.isFlagged = false,
    this.tagNames = const [],
  });

  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;
  final bool isFlagged;
  final List<String> tagNames;

  /// BR-CARD-002 and BR-CARD-003, in characters as a person sees them.
  static const maxFrontLength = 60;
  static const maxBackLength = 240;
  static const maxOptionalLength = 240;

  /// BR-CARD-001, BR-CARD-002.
  static Outcome<void, CardRejection> checkFront(String front) =>
      _checkSide(front, maxFrontLength, CardRejection.frontTooLong);

  /// BR-CARD-001, BR-CARD-002.
  static Outcome<void, CardRejection> checkBack(String back) =>
      _checkSide(back, maxBackLength, CardRejection.backTooLong);

  /// BR-CARD-003: an absent or blank example, hint or pronunciation is fine.
  static Outcome<void, CardRejection> checkOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.characters.length > maxOptionalLength) {
      return const Rejected(CardRejection.optionalFieldTooLong);
    }
    return const Ok(null);
  }

  /// BR-TAG-001, BR-TAG-002: every name passes the tag rule, and at most
  /// [TagEntity.maxPerCard] of them are distinct once folded.
  static Outcome<void, CardRejection> checkTagNames(List<String> names) {
    for (final name in names) {
      if (TagEntity.checkName(name) case Rejected()) {
        return const Rejected(CardRejection.invalidTagName);
      }
    }
    if (names.map(TagEntity.fold).toSet().length > TagEntity.maxPerCard) {
      return const Rejected(CardRejection.tooManyTags);
    }
    return const Ok(null);
  }

  /// The first failing field, in form order: front, back, example, hint,
  /// pronunciation, tags.
  Outcome<void, CardRejection> check() {
    final checks = [
      () => checkFront(front),
      () => checkBack(back),
      () => checkOptional(example),
      () => checkOptional(hint),
      () => checkOptional(pronunciation),
      () => checkTagNames(tagNames),
    ];
    for (final check in checks) {
      final result = check();
      if (result case Rejected()) return result;
    }
    return const Ok(null);
  }

  static Outcome<void, CardRejection> _checkSide(
    String side,
    int maxLength,
    CardRejection tooLong,
  ) {
    final trimmed = side.trim();
    if (trimmed.isEmpty) return const Rejected(CardRejection.blankContent);
    if (trimmed.characters.length > maxLength) return Rejected(tooLong);
    return const Ok(null);
  }
}
