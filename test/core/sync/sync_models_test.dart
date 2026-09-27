import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_models.dart';

void main() {
  test('a command operation leaves the patch fields out', () {
    const op = SyncOperationModel(
      opId: 'o1',
      kind: 'command',
      type: 'RENAME_DECK',
      payload: {'deckId': 'R', 'name': 'n'},
      affected: [
        {'entityType': 'deck', 'entityId': 'R'},
      ],
    );
    expect(op.toJson(), {
      'opId': 'o1',
      'kind': 'command',
      'type': 'RENAME_DECK',
      'payload': {'deckId': 'R', 'name': 'n'},
      'affected': [
        {'entityType': 'deck', 'entityId': 'R'},
      ],
    });
  });

  test('a rejection carries the list of current copies', () {
    final result = OperationResultModel.fromJson({
      'opId': 'o1',
      'status': 'rejected',
      'serverVersion': null,
      'code': 'DECK_TREE_CYCLE',
      'current': [
        {
          'entityType': 'deck',
          'entityId': 'R',
          'serverVersion': 3,
          'deleted': false,
          'row': {'id': 'R'},
        },
        {
          'entityType': 'deck',
          'entityId': 'N',
          'serverVersion': 0,
          'deleted': true,
          'row': null,
        },
      ],
    });
    expect(result.isApplied, isFalse);
    expect(result.current!.map((c) => c.isAbsent), [false, true]);
  });
}
