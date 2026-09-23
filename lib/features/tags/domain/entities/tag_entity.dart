import 'package:characters/characters.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

/// A tag, as a card carries it (BR-TAG-001).
final class TagEntity {
  const TagEntity({required this.id, required this.name});

  final String id;

  /// The canonical name, as the user first spelled it (trimmed).
  final String name;

  /// BR-TAG-001, in characters as a person sees them (grapheme clusters).
  static const maxNameLength = 50;

  /// BR-TAG-002.
  static const maxPerCard = 10;

  /// BR-TAG-001: not blank after trim, at most [maxNameLength] characters, no
  /// control character.
  static Outcome<void, TagRejection> checkName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Rejected(TagRejection.blankName);
    if (trimmed.characters.length > maxNameLength) {
      return const Rejected(TagRejection.nameTooLong);
    }
    if (trimmed.runes.any(_isControl)) {
      return const Rejected(TagRejection.controlCharacter);
    }
    return const Ok(null);
  }

  /// The form uniqueness is judged on (BR-TAG-001): trim, then lowercase, the
  /// same fold schema.md defines for `front_folded`. Written in Dart because
  /// SQLite's `lower()` is ASCII-only.
  static String fold(String name) => name.trim().toLowerCase();
}

/// Unicode category Cc: C0 controls, DEL and C1 controls.
bool _isControl(int rune) => rune < 0x20 || (rune >= 0x7F && rune <= 0x9F);
