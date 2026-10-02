import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/datasources/settings_dao.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('a write with no column changes nothing and does not throw', () async {
    final dao = SettingsDao(db);
    final before = await dao.row();

    await dao.updateRow(const AppSettingsCompanion());

    expect(await dao.row(), before);
  });
}
