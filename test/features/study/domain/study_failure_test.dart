import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';

void main() {
  test('a mode refusal keeps its meaning, and its name, in the session '
      '(spec §9; graded modes spec §7.8)', () {
    for (final reason in StudyModeRejection.values) {
      expect(StudyRejection.ofModeRefusal(reason).name, reason.name);
    }
    expect(StudyModeRejection.values, hasLength(8));
  });

  test('srs refusals a session can meet keep their meaning; the others are '
      'bugs (spec §7.3 step 4)', () {
    expect(
      StudyRejection.ofTurnRefusal(SrsRejection.notFound),
      StudyRejection.notFound,
    );
    expect(
      StudyRejection.ofTurnRefusal(SrsRejection.staleGeneration),
      StudyRejection.staleGeneration,
    );
    expect(
      StudyRejection.ofTurnRefusal(SrsRejection.unsupportedAction),
      StudyRejection.unsupportedAction,
    );
    for (final bug in [
      SrsRejection.schedulerLocked,
      SrsRejection.notARootDeck,
    ]) {
      expect(() => StudyRejection.ofTurnRefusal(bug), throwsStateError);
    }
  });
}
