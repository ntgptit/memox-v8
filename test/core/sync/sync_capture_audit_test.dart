import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../support/test_database.dart';

/// BE-E7 spec D2 and §7: every write that changes a deck, a card or a trash
/// batch records an outbox entry whose `affected` (or patch target) covers
/// every id it changed. A test-only copy of the collector records what
/// changed, since the production collector is drained by the outbox.
final _auditStatements = [
  'CREATE TEMP TABLE audit_changed (entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, PRIMARY KEY (entity_type, entity_id))',
  for (final (table, type) in [
    ('deck', 'deck'),
    ('card', 'card'),
    ('delete_batches', 'delete_batch'),
  ])
    for (final (event, row) in [
      ('INSERT', 'new'),
      ('UPDATE', 'new'),
      ('DELETE', 'old'),
    ])
      'CREATE TEMP TRIGGER audit_${table}_${event.toLowerCase()} AFTER $event ON $table BEGIN '
          "INSERT OR IGNORE INTO audit_changed VALUES ('$type', $row.id); END",
];

/// Writes that change synced rows but have no server command yet (spec §8).
/// Each must record nothing, so this list goes stale loudly.
const _knownGaps = <String, String>{
  'restoreDecks': 'Trash restore: API-B3 + BE-E3',
  'restoreCards': 'Trash restore: API-B3 + BE-E3',
};

T _ok<T, R extends Enum>(Outcome<T, R> outcome) => switch (outcome) {
  Ok(:final value) => value,
  Rejected(:final reason) => throw StateError('rejected: $reason'),
};

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late String root;
  late String sub;

  setUp(() async {
    db = openTestDatabase();
    for (final statement in _auditStatements) {
      await db.customStatement(statement);
    }
    decks = DeckRepositoryImpl(db);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db),
      TagRepositoryImpl(db),
    );
    root = _ok(
      await decks.createRootDeck(
        name: 'Root',
        schedulerType: SchedulerType.sm2,
      ),
    ).id;
    sub = _ok(await decks.createSubDeck(parentId: root, name: 'Sub')).id;
  });
  tearDown(() => db.close());

  /// Runs [write] and returns the new outbox entries and the ids it changed.
  Future<(List<SyncOutboxEntry>, Set<SyncEntityRef>)> audited(
    Future<void> Function() write,
  ) async {
    final before = (await db.select(db.syncOutbox).get())
        .map((e) => e.opId)
        .toSet();
    await db.customStatement('DELETE FROM audit_changed');
    await write();
    final entries = (await db.select(db.syncOutbox).get())
        .where((e) => !before.contains(e.opId))
        .toList();
    final changed = {
      for (final row
          in await db
              .customSelect('SELECT entity_type, entity_id FROM audit_changed')
              .get())
        SyncEntityRef(
          row.read<String>('entity_type'),
          row.read<String>('entity_id'),
        ),
    };
    return (entries, changed);
  }

  Future<void> expectCaptured(
    String type,
    Future<void> Function() write,
  ) async {
    final (entries, changed) = await audited(write);
    expect(entries, isNotEmpty, reason: '$type recorded nothing');
    expect(
      entries.map((e) => e.commandType ?? '${e.entityType}/${e.patchGroup}'),
      contains(type),
    );
    final covered = <SyncEntityRef>{
      for (final entry in entries) ...[
        if (entry.entityType != null)
          SyncEntityRef(entry.entityType!, entry.entityId!),
        for (final item in jsonDecode(entry.affected) as List)
          SyncEntityRef.fromJson(item as Map<String, Object?>),
      ],
    };
    expect(
      covered.containsAll(changed),
      isTrue,
      reason: '$type left out ${changed.difference(covered)}',
    );
  }

  Future<String> card(String deckId) async => _ok(
    await cards.createCard(
      deckId: deckId,
      draft: const CardDraft(front: 'a', back: 'b'),
    ),
  ).id;

  test(
    'createRootDeck',
    () => expectCaptured(
      'CREATE_ROOT_DECK',
      () async => decks.createRootDeck(
        name: 'X',
        schedulerType: SchedulerType.eightBox,
      ),
    ),
  );
  test(
    'createSubDeck',
    () => expectCaptured(
      'CREATE_SUB_DECK',
      () async => decks.createSubDeck(parentId: sub, name: 'X'),
    ),
  );
  test(
    'renameDeck',
    () => expectCaptured(
      'RENAME_DECK',
      () async => decks.renameDeck(deckId: sub, name: 'Y'),
    ),
  );
  test('moveDeck', () async {
    final other = _ok(await decks.createSubDeck(parentId: root, name: 'Other'))
        .id;
    await expectCaptured(
      'MOVE_DECK',
      () async => decks.moveDeck(deckId: sub, newParentId: other),
    );
  });
  test('reorderDeck', () async {
    final other = _ok(await decks.createSubDeck(parentId: root, name: 'Other'))
        .id;
    await expectCaptured(
      'REORDER_DECK',
      () async => decks.reorderDeck(
        deckId: other,
        anchorId: sub,
        placement: DeckPlacement.before,
      ),
    );
  });
  test('deleteDeck', () async {
    await card(sub);
    await expectCaptured(
      'DELETE_DECK',
      () async => decks.deleteDeck(deckId: sub),
    );
  });
  test('undoDeckDeletion', () async {
    await card(sub);
    final batch = _ok(await decks.deleteDeck(deckId: sub));
    await expectCaptured(
      'UNDO_DECK_DELETION',
      () async => decks.undoDeckDeletion(batchId: batch),
    );
  });
  test(
    'createCard',
    () => expectCaptured('CREATE_CARD', () async => card(sub)),
  );
  test('editCard', () async {
    final id = await card(sub);
    await expectCaptured(
      'card/content',
      () async => cards.editCard(
        cardId: id,
        draft: const CardDraft(front: 'c', back: 'd'),
      ),
    );
  });
  test('setFlagged', () async {
    final id = await card(sub);
    await expectCaptured(
      'card/flag',
      () async => cards.setFlagged(cardIds: {id}, isFlagged: true),
    );
  });
  test('moveCards', () async {
    final id = await card(sub);
    final other = _ok(await decks.createSubDeck(parentId: root, name: 'Other'))
        .id;
    await expectCaptured(
      'MOVE_CARDS',
      () async => cards.moveCards(cardIds: {id}, targetDeckId: other),
    );
  });
  test('deleteCards', () async {
    final id = await card(sub);
    await expectCaptured(
      'DELETE_CARDS',
      () async => cards.deleteCards(cardIds: {id}),
    );
  });
  test('undoCardDeletion', () async {
    final id = await card(sub);
    final batch = _ok(await cards.deleteCards(cardIds: {id})).single;
    await expectCaptured(
      'UNDO_CARD_DELETION',
      () async => cards.undoCardDeletion(batchId: batch),
    );
  });
  test('importCards', () async {
    final transfer = CardTransferRepositoryImpl(db, cards);
    await expectCaptured(
      'CREATE_CARD',
      () async => transfer.importCards(
        deckId: sub,
        drafts: const [
          CardDraft(front: 'x', back: 'y'),
          CardDraft(front: 'z', back: 'w'),
        ],
        includeDuplicates: false,
      ),
    );
  });
  test('saveRootStudyOptions and clearRootStudyOptions', () async {
    final settings = SettingsRepositoryImpl(db);
    await expectCaptured(
      'deck/study_options',
      () async => settings.saveRootStudyOptions(
        rootDeckId: root,
        options: StudyOptions.defaults,
      ),
    );
    await expectCaptured(
      'deck/study_options',
      () async => settings.clearRootStudyOptions(rootDeckId: root),
    );
  });

  group('known gaps record nothing', () {
    test('restoreDecks', () async {
      final batch = _ok(await decks.deleteDeck(deckId: sub));
      final (entries, _) = await audited(
        () async => decks.restoreDecks(batchIds: {batch}, parentId: root),
      );
      expect(entries, isEmpty, reason: _knownGaps['restoreDecks']);
    });
    test('restoreCards', () async {
      final id = await card(sub);
      final batch = _ok(await cards.deleteCards(cardIds: {id})).single;
      final (entries, _) = await audited(
        () async => cards.restoreCards(batchIds: {batch}, deckId: sub),
      );
      expect(entries, isEmpty, reason: _knownGaps['restoreCards']);
    });
  });
}
