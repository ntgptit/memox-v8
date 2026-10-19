import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/tag_outcomes.dart';

void main() {
  group('checkName (BR-TAG-001)', () {
    test('a blank name is refused', () {
      expect(tagReasonOf(TagEntity.checkName('   ')), TagRejection.blankName);
    });

    test('50 characters is the longest name', () {
      expect(tagReasonOf(TagEntity.checkName('a' * 50)), isNull);
      expect(
        tagReasonOf(TagEntity.checkName('a' * 51)),
        TagRejection.nameTooLong,
      );
    });

    test('a character is what a person sees, not a code unit', () {
      expect(tagReasonOf(TagEntity.checkName('e\u0301' * 50)), isNull);
      expect(
        tagReasonOf(TagEntity.checkName('e\u0301' * 51)),
        TagRejection.nameTooLong,
      );
    });

    test('a control character inside the name is refused', () {
      for (final name in ['a\tb', 'a\u0007b', 'a\u007Fb', 'a\u0085b']) {
        expect(
          tagReasonOf(TagEntity.checkName(name)),
          TagRejection.controlCharacter,
          reason: name.runes.toString(),
        );
      }
    });

    test('whitespace around the name is trimmed, not refused', () {
      expect(tagReasonOf(TagEntity.checkName('\tNoun\n')), isNull);
    });
  });

  test('fold trims and lowercases, Unicode included', () {
    expect(TagEntity.fold('  Động Từ  '), 'động từ');
    expect(TagEntity.fold('NOUN'), 'noun');
  });
}
