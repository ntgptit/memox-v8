import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/logging/sql_log_dao.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('watchLogSqlStatements follows the row', () async {
    final dao = SqlLogDao(db);
    final seen = <bool>[];
    final subscription = dao.watchLogSqlStatements().listen(seen.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    // A raw write names its table, or no stream learns of it.
    await db.customUpdate(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
      updates: {db.appSettings},
    );
    await Future<void>.delayed(Duration.zero);
    expect(seen, [true, false]);
  });
}
