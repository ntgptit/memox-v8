import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

import 'test_database.dart';
import 'topik_attempt_fixtures.dart';
import 'topik_content_fixtures.dart';

/// TOPIK I listening: questions 1–30, 1–10 worth 4 and 11–30 worth 3; the
/// answer of question n is (n - 1) % 4 + 1.
final TopikTest topikListeningTest = topikTestFixture(
  level: TopikLevel.topik1,
  section: TopikSection.listening,
);

/// An in-memory database and the attempt repository over it, its clock
/// stopped at [topikT0]. The caller closes `db`.
({AppDatabase db, TopikAttemptRepositoryImpl repository})
openTopikAttemptStore() {
  final db = openTestDatabase();
  return (
    db: db,
    repository: TopikAttemptRepositoryImpl(db, now: () => topikT0),
  );
}
