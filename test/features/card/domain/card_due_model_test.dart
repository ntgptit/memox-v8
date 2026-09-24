import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';

// The start of the local day the list reads at (BR-STUDY-068).
final _today = DateTime(2026, 9, 23);

CardDue _due(DateTime? dueAt, {bool isLearned = true}) =>
    CardDue.of(isLearned: isLearned, dueAt: dueAt, startOfToday: _today);

void main() {
  test('a card not learned yet is new, whatever its due date', () {
    expect(_due(null, isLearned: false).kind, CardDueKind.newCard);
    expect(
      _due(DateTime(2026, 9, 1), isLearned: false).kind,
      CardDueKind.newCard,
    );
  });

  test('due at the start of today, or later today, is today', () {
    expect(_due(DateTime(2026, 9, 23)), const CardDue.today());
    expect(_due(DateTime(2026, 9, 23, 18)), const CardDue.today());
  });

  test('due before today is overdue by calendar days', () {
    expect(_due(DateTime(2026, 9, 22)), const CardDue.overdue(1));
    expect(_due(DateTime(2026, 9, 20)), const CardDue.overdue(3));
  });

  test('due after today is later by calendar days', () {
    expect(_due(DateTime(2026, 9, 24)), const CardDue.later(1));
    expect(_due(DateTime(2026, 10, 10)), const CardDue.later(17));
  });

  test('a learned card without a due date reads as new', () {
    expect(_due(null).kind, CardDueKind.newCard);
  });
}
