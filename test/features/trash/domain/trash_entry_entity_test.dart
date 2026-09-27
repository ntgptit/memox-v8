import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

// BR-TRASH-009: a batch stays in the Trash for 720 hours, the boundary
// included (trash spec D13).

void main() {
  final deletedAt = DateTime(2026, 9, 1, 8);

  test('the retention is 720 hours', () {
    expect(trashRetention, const Duration(hours: 720));
  });

  test('an entry expires 720 hours after it was deleted', () {
    final entry = TrashCardEntry(
      batchId: 'b',
      deletedAt: deletedAt,
      origin: const [],
      cardId: 'c',
      front: 'f',
      back: 'b',
    );

    expect(entry.expiresAt, deletedAt.add(const Duration(hours: 720)));
  });

  test('a batch deleted at the cutoff has expired; one a millisecond later '
      'has not', () {
    final now = deletedAt.add(trashRetention);

    expect(trashCutoff(now), deletedAt);
    expect(
      trashCutoff(now.subtract(const Duration(milliseconds: 1))),
      isNot(deletedAt),
    );
    expect(
      trashCutoff(now.subtract(const Duration(milliseconds: 1)))
          .isBefore(deletedAt),
      isTrue,
    );
  });
}
