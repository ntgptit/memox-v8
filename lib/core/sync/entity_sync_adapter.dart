/// How one synced table is read for push and written from the server. The
/// coordinator never names a table (app deck-sync spec §5).
abstract mixin class EntitySyncAdapter {
  String get entityType;

  /// The row in wire shape (camelCase keys, ISO-8601 UTC times), or null when
  /// it no longer exists.
  Future<Map<String, Object?>?> readRow(String id);

  /// Writes a server row. Called only inside `SyncStore.applyingRemote`.
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion);

  /// Deletes a row the server tombstoned; local cascades follow.
  Future<void> deleteFromServer(String id);

  /// Records the version the server gave to the pushed state.
  Future<void> markAcknowledged(String id, int serverVersion);

  /// Runs once at the end of a pull that applied at least one change, in
  /// list order, still under `applying_remote`: the place for a rule that
  /// needs every pulled row, such as giving new cards their schedule
  /// (BR-CARD-004). A pull with nothing to apply skips it (DEV-210). None
  /// by default.
  Future<void> afterPull() async {}
}

/// Wire time: ISO-8601 in UTC (ADR-008).
String? toWireTime(DateTime? value) => value?.toUtc().toIso8601String();

DateTime? fromWireTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();
