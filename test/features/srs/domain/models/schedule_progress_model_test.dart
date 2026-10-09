import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/schedule_progress_model.dart';

ScheduleProgress _p({
  int generation = 1,
  String type = 'eight_box',
  DateTime? answered,
  DateTime? learned,
  int answers = 0,
}) => (
  generation: generation,
  schedulerType: type,
  lastAnsweredAt: answered,
  learnedAt: learned,
  answerCount: answers,
);

void main() {
  final t1 = DateTime.utc(2026, 9, 28, 10);
  final t2 = DateTime.utc(2026, 9, 28, 11);

  int cmp(
    ScheduleProgress a,
    ScheduleProgress b, [
    String? root = 'eight_box',
  ]) => compareScheduleProgress(a, b, rootSchedulerType: root);

  test('1: a higher generation wins, over any later answer', () {
    expect(
      cmp(_p(generation: 2), _p(answered: t2, answers: 9)),
      greaterThan(0),
    );
    expect(cmp(_p(answered: t2, answers: 9), _p(generation: 2)), lessThan(0));
  });

  test("2: the root's scheduler wins at one generation", () {
    expect(cmp(_p(type: 'sm2'), _p(answered: t2), 'sm2'), greaterThan(0));
    expect(cmp(_p(answered: t2), _p(type: 'sm2'), 'sm2'), lessThan(0));
  });

  test('3: the later answer wins; no answer is earliest', () {
    expect(cmp(_p(answered: t2), _p(answered: t1)), greaterThan(0));
    expect(cmp(_p(answered: t1), _p()), greaterThan(0));
    expect(cmp(_p(), _p(answered: t1)), lessThan(0));
  });

  test('4: learned wins over not learned', () {
    expect(
      cmp(_p(answered: t1, learned: t1), _p(answered: t1)),
      greaterThan(0),
    );
    expect(cmp(_p(answered: t1), _p(answered: t1, learned: t1)), lessThan(0));
  });

  test('5: more answers win', () {
    expect(
      cmp(_p(answered: t1, answers: 3), _p(answered: t1, answers: 2)),
      greaterThan(0),
    );
  });

  test('a tie is zero, and an unknown root skips rule 2', () {
    expect(cmp(_p(answered: t1, answers: 2), _p(answered: t1, answers: 2)), 0);
    expect(cmp(_p(type: 'sm2'), _p(), null), 0);
  });
}
