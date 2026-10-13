import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// BR-STUDY-078: the modes that show the term as the prompt read it aloud.

void main() {
  test('browse, self_assess, guess and recall read the term aloud', () {
    for (final mode in [
      StudyMode.browse,
      StudyMode.selfAssess,
      StudyMode.guess,
      StudyMode.recall,
    ]) {
      expect(mode.handler.readsTermAloud, isTrue, reason: mode.code);
    }
  });

  test('fill (the term is the answer) and match (no one card) do not', () {
    expect(StudyMode.fill.handler.readsTermAloud, isFalse);
    expect(StudyMode.match.handler.readsTermAloud, isFalse);
  });
}
