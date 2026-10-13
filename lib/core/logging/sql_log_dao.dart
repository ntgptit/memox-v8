import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'sql_log_dao.g.dart';

/// Reads the SQL log switch's column for the feeder (SQL log switch spec
/// §4.3), the way `core/auth`'s `AccountDeviceDao` reads its flags: `core`
/// never imports a feature's DAO.
@DriftAccessor(
  include: {'package:memox/core/database/queries/sql_log_queries.drift'},
)
final class SqlLogDao extends DatabaseAccessor<AppDatabase>
    with _$SqlLogDaoMixin {
  SqlLogDao(super.attachedDatabase);

  /// The switch, again after every write of the row.
  Stream<bool> watchLogSqlStatements() =>
      logSqlStatementsFlag(appSettingsRowId)
          .watchSingle()
          .map((flag) => flag == 1);
}
