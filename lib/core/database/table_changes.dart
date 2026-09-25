import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Fires once when listened to, then after every write to one of [tables];
/// a flat transaction fires once, but a transaction nested in another fires
/// on its own (Progress spec §6.4). It listens to the tables before it fires
/// the first time, so a write that lands right after the first read is seen
/// (Study Home spec D7, Progress spec D8). A read model maps each firing to
/// one read.
Stream<void> tableChanges(
  AppDatabase db,
  Iterable<ResultSetImplementation<Object?, Object?>> tables,
) => Stream.multi((listener) {
  final updates = db
      .tableUpdates(TableUpdateQuery.onAllTables(tables))
      .listen((_) => listener.add(null), onError: listener.addError);
  listener
    ..add(null)
    ..onCancel = updates.cancel;
});
