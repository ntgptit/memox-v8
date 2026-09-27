import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:uuid/uuid.dart';

/// Command types of the sync protocol (API-A2 spec §5).
abstract final class SyncCommandType {
  static const createRootDeck = 'CREATE_ROOT_DECK';
  static const createSubDeck = 'CREATE_SUB_DECK';
  static const renameDeck = 'RENAME_DECK';
  static const moveDeck = 'MOVE_DECK';
  static const reorderDeck = 'REORDER_DECK';
  static const deleteDeck = 'DELETE_DECK';
  static const undoDeckDeletion = 'UNDO_DECK_DELETION';
  static const createCard = 'CREATE_CARD';
  static const moveCards = 'MOVE_CARDS';
  static const deleteCards = 'DELETE_CARDS';
  static const undoCardDeletion = 'UNDO_CARD_DELETION';
}

/// Patch field groups of the sync protocol (API-A2 spec §5).
abstract final class SyncPatchGroup {
  static const studyOptions = 'study_options';
  static const content = 'content';
  static const flag = 'flag';
}

/// Outbox kinds (BE-E7 spec §3).
abstract final class SyncKind {
  static const command = 'command';
  static const patch = 'patch';
}

/// Where a repository records the command or patch that describes its write
/// (BE-E7 spec §4.1). Call it inside the write's transaction, after the rows
/// change: `affected` is every id the write changed (the TEMP collector of
/// D2), plus [subject].
final class SyncOutboxWriter {
  SyncOutboxWriter(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  static const _uuid = Uuid();

  Future<void> command(
    String type,
    Map<String, Object?> payload, {
    SyncEntityRef? subject,
    bool drainChanges = true,
  }) async {
    final affected = {if (drainChanges) ...await _drainChanges(), ?subject};
    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            opId: _uuid.v4(),
            kind: SyncKind.command,
            commandType: Value(type),
            payload: Value(jsonEncode(payload)),
            affected: Value(
              jsonEncode([for (final ref in affected) ref.toJson()]),
            ),
            createdAt: _now(),
          ),
        );
  }

  /// One pending patch per field group: a second one keeps the first seq and
  /// gets a new op id, so an acknowledgement of the older push cannot remove
  /// it. The values are read at push time.
  Future<void> patch(
    String entityType,
    String entityId,
    String group, {
    bool drainChanges = true,
  }) async {
    if (drainChanges) {
      await _drainChanges();
    }
    await _db.customInsert(
      'INSERT INTO sync_outbox (op_id, kind, entity_type, entity_id, patch_group, created_at) '
      "VALUES (?, 'patch', ?, ?, ?, ?) "
      'ON CONFLICT (entity_type, entity_id, patch_group) '
      "WHERE kind = 'patch' DO UPDATE SET op_id = excluded.op_id",
      variables: [
        Variable<String>(_uuid.v4()),
        Variable<String>(entityType),
        Variable<String>(entityId),
        Variable<String>(group),
        Variable<DateTime>(_now()),
      ],
      updates: {_db.syncOutbox},
    );
  }

  Future<Set<SyncEntityRef>> _drainChanges() async {
    final rows = await _db
        .customSelect('SELECT entity_type, entity_id FROM sync_changed')
        .get();
    await _db.customStatement('DELETE FROM sync_changed');
    return {
      for (final row in rows)
        SyncEntityRef(
          row.read<String>('entity_type'),
          row.read<String>('entity_id'),
        ),
    };
  }
}
