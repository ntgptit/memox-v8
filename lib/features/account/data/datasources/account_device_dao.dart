import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'account_device_dao.g.dart';

/// Row access for the account screens' device-only reads
/// (`account_device_queries.drift`). It returns plain values and runs inside
/// the caller's guard.
@DriftAccessor(
  include: {'package:memox/core/database/queries/account_device_queries.drift'},
)
final class AccountDeviceDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDeviceDaoMixin {
  AccountDeviceDao(super.attachedDatabase);

  Future<bool> welcomeSeen() async =>
      await welcomeSeenFlag(appSettingsRowId).getSingle() == 1;

  Future<void> setWelcomeSeen() => markWelcomeSeen(appSettingsRowId);

  Future<(int, int)> liveCounts() async {
    final row = await liveLibraryCounts().getSingle();
    return (row.decks, row.cards);
  }
}
