/// How one synced table is written from the server and read for a patch. The
/// coordinator never names a table (BE-E7 spec §5).
abstract class EntitySyncAdapter {
  String get entityType;

  /// Writes a server row. Called only inside `SyncStore.applyingServer`.
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion);

  /// Deletes a row the server tombstoned; local cascades follow.
  Future<void> deleteFromServer(String id);

  /// The current fields of [group] for a patch, or null when the entity is
  /// gone or has no such group.
  Future<Map<String, Object?>?> readPatch(String id, String group) async =>
      null;
}

/// Wire time: ISO-8601 in UTC (ADR-008).
String? toWireTime(DateTime? value) => value?.toUtc().toIso8601String();

DateTime? fromWireTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();
