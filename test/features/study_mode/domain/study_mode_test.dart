import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

void main() {
  test('the six modes keep the codes schema.md stores (BR-MODE-002, '
      'BR-MODE-008)', () {
    expect(
      [for (final mode in StudyMode.values) mode.code],
      ['browse', 'self_assess', 'match', 'guess', 'recall', 'fill'],
    );
    for (final mode in StudyMode.values) {
      expect(StudyMode.fromCode(mode.code), mode);
    }
  });

  test('an unknown code is corrupt data, never a default', () {
    expect(() => StudyMode.fromCode('review'), throwsArgumentError);
  });

  test('each algorithm declares its learning chain (BR-MODE-004, '
      'BR-MODE-007; IT-LEARN-001, IT-LEARN-002)', () {
    expect(stageSequenceOf(SchedulerType.eightBox), [
      StudyMode.browse,
      StudyMode.match,
      StudyMode.guess,
      StudyMode.recall,
      StudyMode.fill,
    ]);
    expect(stageSequenceOf(SchedulerType.sm2), [
      StudyMode.browse,
      StudyMode.selfAssess,
    ]);
  });

  test('a review offers the graded stages of the chain, never browse '
      '(BR-STUDY-055; IT-STUDY-004, IT-STUDY-005)', () {
    expect(reviewModesOf(SchedulerType.eightBox), [
      StudyMode.match,
      StudyMode.guess,
      StudyMode.recall,
      StudyMode.fill,
    ]);
    expect(reviewModesOf(SchedulerType.sm2), [StudyMode.selfAssess]);
  });

  test('the one dispatch gives every mode its handler', () {
    final handlers = {for (final mode in StudyMode.values) mode: mode.handler};

    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (!handler.producesAction) mode,
      ],
      [StudyMode.browse],
    );
    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (handler.usesRounds) mode,
      ],
      [StudyMode.match, StudyMode.guess, StudyMode.recall, StudyMode.fill],
    );
    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (!handler.servesInOrder) mode,
      ],
      [StudyMode.match],
    );
    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (handler.takesDirection) mode,
      ],
      [StudyMode.selfAssess],
    );
  });
}
