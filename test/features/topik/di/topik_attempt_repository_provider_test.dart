import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';

import '../../../support/test_database.dart';

void main() {
  test('provides the Drift implementation on the app database', () {
    final db = openTestDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(topikAttemptRepositoryProvider),
      isA<TopikAttemptRepositoryImpl>(),
    );
  });
}
