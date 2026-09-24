import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

const _k2m = QuestionDirection.koreanToMeaning;
const _m2k = QuestionDirection.meaningToKorean;

void main() {
  test('the choices and the directions keep their stored codes '
      '(BR-MODE-014, BR-MODE-015)', () {
    expect(
      [for (final choice in DirectionChoice.values) choice.code],
      ['korean_to_meaning', 'meaning_to_korean', 'mixed'],
    );
    expect(
      [for (final direction in QuestionDirection.values) direction.code],
      ['korean_to_meaning', 'meaning_to_korean'],
    );
    for (final choice in DirectionChoice.values) {
      expect(DirectionChoice.fromCode(choice.code), choice);
    }
    for (final direction in QuestionDirection.values) {
      expect(QuestionDirection.fromCode(direction.code), direction);
    }
  });

  test('only a review of an sm2 deck in self_assess takes a direction '
      '(BR-MODE-013)', () {
    final accepted = [
      for (final kind in SessionKind.values)
        for (final type in SchedulerType.values)
          for (final mode in StudyMode.values)
            if (acceptsDirection(kind, type, mode)) (kind, type, mode),
    ];

    expect(accepted, [
      (SessionKind.reviewing, SchedulerType.sm2, StudyMode.selfAssess),
    ]);
  });

  test('a fixed choice gives every card that direction (BR-MODE-015)', () {
    expect(assignDirections(3, DirectionChoice.meaningToKorean, Random(1)), [
      _m2k,
      _m2k,
      _m2k,
    ]);
    expect(assignDirections(2, DirectionChoice.koreanToMeaning, Random(1)), [
      _k2m,
      _k2m,
    ]);
  });

  test('mixed splits the cards evenly, an odd card going to either side '
      '(BR-MODE-015)', () {
    for (final count in [0, 1, 2, 7, 20]) {
      for (var seed = 0; seed < 20; seed++) {
        final directions = assignDirections(
          count,
          DirectionChoice.mixed,
          Random(seed),
        );
        final koreanFirst = directions.where((d) => d == _k2m).length;
        expect(directions, hasLength(count));
        expect(
          (koreanFirst - (count - koreanFirst)).abs(),
          lessThanOrEqualTo(1),
        );
      }
    }
    final oddSides = {
      for (var seed = 0; seed < 20; seed++)
        assignDirections(1, DirectionChoice.mixed, Random(seed)).single,
    };
    expect(oddSides, {_k2m, _m2k});
  });

  test('mixed deals the directions across the cards, not in two blocks '
      '(BR-MODE-015)', () {
    final orders = {
      for (var seed = 0; seed < 20; seed++)
        assignDirections(6, DirectionChoice.mixed, Random(seed)).join(','),
    };

    expect(orders.length, greaterThan(1));
  });
}
