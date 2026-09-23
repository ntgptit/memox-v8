import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

TagRejection? _reasonOf(Outcome<void, TagRejection> result) => switch (result) {
  Ok() => null,
  Rejected(:final reason) => reason,
};

void main() {
  group('checkName (BR-TAG-001)', () {
    test('a blank name is refused', () {
      expect(_reasonOf(TagEntity.checkName('   ')), TagRejection.blankName);
    });

    test('50 characters is the longest name', () {
      expect(_reasonOf(TagEntity.checkName('a' * 50)), isNull);
      expect(
        _reasonOf(TagEntity.checkName('a' * 51)),
        TagRejection.nameTooLong,
      );
    });

    test('a character is what a person sees, not a code unit', () {
      expect(_reasonOf(TagEntity.checkName('e\u0301' * 50)), isNull);
      expect(
        _reasonOf(TagEntity.checkName('e\u0301' * 51)),
        TagRejection.nameTooLong,
      );
    });

    test('a control character inside the name is refused', () {
      for (final name in ['a\tb', 'a\u0007b', 'a\u007Fb', 'a\u0085b']) {
        expect(
          _reasonOf(TagEntity.checkName(name)),
          TagRejection.controlCharacter,
          reason: name.runes.toString(),
        );
      }
    });

    test('whitespace around the name is trimmed, not refused', () {
      expect(_reasonOf(TagEntity.checkName('\tNoun\n')), isNull);
    });
  });

  test('fold trims and lowercases, Unicode included', () {
    expect(TagEntity.fold('  Động Từ  '), 'động từ');
    expect(TagEntity.fold('NOUN'), 'noun');
  });
}
