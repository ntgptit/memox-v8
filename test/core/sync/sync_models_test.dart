import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_models.dart';

void main() {
  test('reads a push response with a rejection carrying the server copy', () {
    final response = PushResponseModel.fromJson({
      'results': [
        {
          'opId': 'a',
          'status': 'applied',
          'serverVersion': 3,
          'code': null,
          'current': null,
        },
        {
          'opId': 'b',
          'status': 'rejected',
          'serverVersion': null,
          'code': 'DECK_TREE_CYCLE',
          'current': {
            'entityType': 'deck',
            'entityId': 'x',
            'serverVersion': 2,
            'deleted': false,
            'row': {'id': 'x', 'name': 'X'},
          },
        },
      ],
    });

    expect(response.results.first.serverVersion, 3);
    expect(response.results.last.code, 'DECK_TREE_CYCLE');
    expect(response.results.last.current!.row!['name'], 'X');
  });
}
