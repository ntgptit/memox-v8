import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';

// The moment the list reads at, and the start of its local day
// (BR-STUDY-068, BR-STUDY-074).
final _now = DateTime(2026, 9, 23, 10);
final _today = DateTime(2026, 9, 23);
final _learned = DateTime(2026, 9, 1);

CardDue _due(DateTime? dueAt, {bool isLearned = true}) => CardDue.of(
  learnedAt: isLearned ? _learned : null,
  dueAt: dueAt,
  now: _now,
  startOfToday: _today,
);

void main() {
  test('a card not learned yet is new, whatever its due date', () {
    expect(_due(null, isLearned: false).kind, CardDueKind.newCard);
    expect(
      _due(DateTime(2026, 9, 1), isLearned: false).kind,
      CardDueKind.newCard,
    );
  });

  test('due from the start of today up to now is today', () {
    expect(_due(DateTime(2026, 9, 23)), const CardDue.today());
    expect(_due(_now), const CardDue.today());
  });

  test('due before today is overdue by calendar days', () {
    expect(_due(DateTime(2026, 9, 22)), const CardDue.overdue(1));
    expect(_due(DateTime(2026, 9, 20)), const CardDue.overdue(3));
  });

  test('due after now is later by calendar days (BR-STUDY-068); a due date '
      'is anchored at the start of its day (BR-STUDY-074), so later today '
      'counts as 0 days', () {
    expect(_due(DateTime(2026, 9, 24)), const CardDue.later(1));
    expect(_due(DateTime(2026, 10, 10)), const CardDue.later(17));
    expect(_due(DateTime(2026, 9, 23, 18)), const CardDue.later(0));
  });

  test('a learned card without a due date rests, as the counts place it '
      '(DEV-221)', () {
    expect(_due(null), const CardDue.later(0));
  });
}
