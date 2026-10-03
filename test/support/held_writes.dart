import 'dart:async';

import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_attach_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// A write a test holds in flight, so it can press Back or tap the scrim
/// meanwhile, then lets through ([open]) or fails ([failNext]) (SP2b 2.26).
final class WriteHold {
  /// What a failing write throws unless the test names another error.
  static const failure = DatabaseLockedFailure(cause: 'locked');

  final _gate = Completer<void>();
  final _errors = <Object>[];

  /// Writes that reached the gate.
  int calls = 0;

  void open() {
    if (!_gate.isCompleted) _gate.complete();
  }

  /// The next write that passes the gate throws [error].
  void failNext([Object error = failure]) => _errors.add(error);

  Future<void> pass() async {
    calls++;
    await _gate.future;
    if (_errors.isNotEmpty) throw _errors.removeAt(0);
  }
}

/// The real decks, each write behind [hold].
final class HeldDecks implements DeckRepository {
  HeldDecks(this._inner, this.hold);

  final DeckRepository _inner;
  final WriteHold hold;

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.renameDeck(deckId: deckId, name: name, now: now);
  }

  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.deleteDeck(deckId: deckId, now: now);
  }

  @override
  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.moveDeck(deckId: deckId, newParentId: newParentId, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real cards, a move, a delete and a restore behind [hold].
final class HeldCards implements CardRepository {
  HeldCards(this._inner, this.hold);

  final CardRepository _inner;
  final WriteHold hold;

  @override
  Future<Outcome<BulkOutcome, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.moveCards(
      cardIds: cardIds,
      targetDeckId: targetDeckId,
      now: now,
    );
  }

  @override
  Future<Outcome<BulkOutcome, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.deleteCards(cardIds: cardIds, now: now);
  }

  @override
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.restoreCards(batchIds: batchIds, deckId: deckId, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real tags, attaching by name behind [hold].
final class HeldTags implements TagRepository {
  HeldTags(this._inner, this.hold);

  final TagRepository _inner;
  final WriteHold hold;

  @override
  Future<Outcome<TagAttach, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  }) async {
    await hold.pass();
    return _inner.attachByName(cardIds: cardIds, name: name, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real Trash, a purge behind [hold]; the screen's list reads through.
final class HeldTrash implements TrashRepository {
  HeldTrash(this._inner, this.hold);

  final TrashRepository _inner;
  final WriteHold hold;

  @override
  Stream<List<TrashEntry>> watchEntries() => _inner.watchEntries();

  @override
  Future<PurgeReport> purge({
    required Set<String> batchIds,
    required DateTime now,
  }) async {
    await hold.pass();
    return _inner.purge(batchIds: batchIds, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
