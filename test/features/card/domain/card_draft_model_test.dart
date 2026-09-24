import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

CardRejection? _reasonOf(Outcome<void, CardRejection> result) =>
    switch (result) {
      Ok() => null,
      Rejected(:final reason) => reason,
    };

List<String> _tags(int count) => [for (var i = 0; i < count; i++) 'tag $i'];

void main() {
  group('checkFront (BR-CARD-001, BR-CARD-002)', () {
    test('a blank front is refused', () {
      expect(_reasonOf(CardDraft.checkFront('  ')), CardRejection.blankContent);
    });
    test('60 characters is the longest front, counted after trim', () {
      expect(_reasonOf(CardDraft.checkFront(' ${'a' * 60} ')), isNull);
      expect(
        _reasonOf(CardDraft.checkFront('a' * 61)),
        CardRejection.frontTooLong,
      );
    });
    test('a character is what a person sees, not a code unit', () {
      expect(_reasonOf(CardDraft.checkFront('e\u0301' * 60)), isNull);
      expect(
        _reasonOf(CardDraft.checkFront('e\u0301' * 61)),
        CardRejection.frontTooLong,
      );
    });
  });

  group('checkBack (BR-CARD-001, BR-CARD-002)', () {
    test('a blank back is refused', () {
      expect(_reasonOf(CardDraft.checkBack('')), CardRejection.blankContent);
    });
    test('240 characters is the longest back', () {
      expect(_reasonOf(CardDraft.checkBack('a' * 240)), isNull);
      expect(
        _reasonOf(CardDraft.checkBack('a' * 241)),
        CardRejection.backTooLong,
      );
    });
  });

  group('checkOptional (BR-CARD-003)', () {
    test('an absent or blank field is fine', () {
      expect(_reasonOf(CardDraft.checkOptional(null)), isNull);
      expect(_reasonOf(CardDraft.checkOptional('   ')), isNull);
    });
    test('240 characters is the longest optional field', () {
      expect(_reasonOf(CardDraft.checkOptional('a' * 240)), isNull);
      expect(
        _reasonOf(CardDraft.checkOptional('a' * 241)),
        CardRejection.optionalFieldTooLong,
      );
    });
  });

  group('checkTagNames (BR-TAG-001, BR-TAG-002)', () {
    test('ten distinct names are fine, eleven are too many', () {
      expect(_reasonOf(CardDraft.checkTagNames(_tags(10))), isNull);
      expect(
        _reasonOf(CardDraft.checkTagNames(_tags(11))),
        CardRejection.tooManyTags,
      );
    });
    test('names that fold alike count once', () {
      expect(
        _reasonOf(CardDraft.checkTagNames([..._tags(10), 'TAG 0', ' tag 1 '])),
        isNull,
      );
    });
    test('a name the tag rule refuses is an invalid tag name', () {
      expect(
        _reasonOf(CardDraft.checkTagNames(['ok', '  '])),
        CardRejection.invalidTagName,
      );
      expect(
        _reasonOf(CardDraft.checkTagNames(['a\u0007b'])),
        CardRejection.invalidTagName,
      );
    });
  });

  group('check', () {
    test('a valid draft passes', () {
      const draft = CardDraft(front: 'f', back: 'b', tagNames: ['noun']);
      expect(_reasonOf(draft.check()), isNull);
    });
    test(
      'the first failing field answers, front before back before the rest',
      () {
        expect(
          _reasonOf(const CardDraft(front: '', back: '').check()),
          CardRejection.blankContent,
        );
        expect(
          _reasonOf(
            CardDraft(front: 'f', back: 'b' * 241, hint: 'h' * 241).check(),
          ),
          CardRejection.backTooLong,
        );
        expect(
          _reasonOf(CardDraft(front: 'f', back: 'b', hint: 'h' * 241).check()),
          CardRejection.optionalFieldTooLong,
        );
        expect(
          _reasonOf(
            CardDraft(front: 'f', back: 'b', tagNames: _tags(11)).check(),
          ),
          CardRejection.tooManyTags,
        );
      },
    );
  });
}
