import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/mapped_transaction.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/models/card_import_section_model.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// An import keeps the duplicate policy and writes the drafts it keeps
/// through [CardRepository.insertCards], inside one transaction: the deck's
/// rules and its content type are the card and deck features' to hold. A
/// sectioned import makes its sub-decks through [DeckRepository.createSubDeck]
/// in that same transaction. An export reads in one transaction and writes
/// nothing.
final class CardTransferRepositoryImpl implements CardTransferRepository {
  CardTransferRepositoryImpl(
    this._db,
    this._cards,
    this._decks, {
    DateTime Function()? now,
  }) : _dao = CardDao(_db),
       _listDao = CardListDao(_db),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final CardRepository _cards;
  final DeckRepository _decks;
  final CardDao _dao;
  final CardListDao _listDao;
  final DateTime Function() _now;

  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) =>
      guardDatabase(() => _dao.foldedPairs(deckId));

  @override
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      // Every draft, the skipped ones too: a draft the rules refuse refuses
      // the batch (BR-TRANSFER-004).
      for (final draft in drafts) {
        if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      }
      final (kept, skipped) = _keep(
        drafts,
        await _dao.foldedPairs(deckId),
        includeDuplicates: includeDuplicates,
      );
      final written = await _cards.insertCards(
        deckId: deckId,
        drafts: kept,
        now: at,
      );
      return switch (written) {
        Rejected(:final reason) => Rejected(reason),
        Ok(:final value) => Ok(
          CardImportResult(written: value.length, skippedIndexes: skipped),
        ),
      };
    });
  }

  /// The drafts the duplicate policy keeps against [taken], which grows as
  /// it goes, and the places of those it drops (BR-TRANSFER-003).
  static (List<CardDraft>, List<int>) _keep(
    List<CardDraft> drafts,
    Set<CardFoldedPair> taken, {
    required bool includeDuplicates,
  }) {
    final kept = <CardDraft>[];
    final skipped = <int>[];
    for (final (index, draft) in drafts.indexed) {
      final pair = (front: foldText(draft.front), back: foldText(draft.back));
      if (!includeDuplicates && taken.contains(pair)) {
        skipped.add(index);
        continue;
      }
      taken.add(pair);
      kept.add(draft);
    }
    return (kept, skipped);
  }

  /// `unset` or a deck of cards (BR-DECK-009, BR-DECK-010).
  static bool _takesCards(String contentType) => DeckEntity.checkCreateCard(
    parentContentType: DeckContentType.values.byName(contentType),
  ) is Ok;

  @override
  Future<CardImportTarget?> importTarget(String deckId) => guardDatabase(
    () => _db.transaction(() async {
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return null;
      final pairsByChild = await _dao.foldedPairsUnder(deckId);
      return CardImportTarget(
        isDeckOfCards: deck.contentType == DeckContentType.card.name,
        canHoldCards: _takesCards(deck.contentType),
        hasRoomBelow: deck.depth < DeckEntity.maxDepth,
        pairs: await _dao.foldedPairs(deckId),
        children: [
          for (final child in await _dao.childDecks(deckId))
            CardImportChild(
              id: child.id,
              name: child.name,
              canHoldCards: _takesCards(child.contentType),
              pairs: pairsByChild[child.id] ?? {},
            ),
        ],
      );
    }),
  );

  @override
  Future<Outcome<List<CardImportSectionResult>, CardRejection>> importSections({
    required String targetDeckId,
    required List<CardImportSection> sections,
    required bool includeDuplicates,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      // Every check before the first write, so a refusal leaves nothing
      // behind (BR-TRANSFER-004).
      if (await _sectionsRefusal(targetDeckId, sections) case final reason?) {
        return Rejected(reason);
      }
      final results = <CardImportSectionResult>[];
      for (final section in sections) {
        results.add(
          await _writeSection(
            targetDeckId,
            section,
            includeDuplicates: includeDuplicates,
            at: at,
          ),
        );
      }
      return Ok(results);
    });
  }

  /// Why [sections] cannot go under [targetDeckId], or null: a draft the
  /// card rules refuse, a gone target, one that cannot take sub-decks, or a
  /// chosen existing deck that is no longer a live child taking cards
  /// (BR-TRANSFER-001, BR-DECK-001).
  Future<CardRejection?> _sectionsRefusal(
    String targetDeckId,
    List<CardImportSection> sections,
  ) async {
    for (final section in sections) {
      for (final draft in section.drafts) {
        if (draft.check() case Rejected(:final reason)) return reason;
      }
    }
    final target = await _dao.deckRow(targetDeckId);
    if (target == null) return CardRejection.notFound;
    final takesDecks = DeckEntity.checkCreateSubDeck(
      parentDepth: target.depth,
      parentContentType: DeckContentType.values.byName(target.contentType),
    );
    if (takesDecks case Rejected(:final reason)) {
      return reason == DeckRejection.depthExceeded
          ? CardRejection.depthExceeded
          : CardRejection.notADeckContainer;
    }
    final children = {
      for (final child in await _dao.childDecks(targetDeckId)) child.id: child,
    };
    for (final section in sections) {
      final id = section.existingDeckId;
      if (id == null) continue;
      final child = children[id];
      if (child == null || !_takesCards(child.contentType)) {
        return CardRejection.sectionTargetChanged;
      }
    }
    return null;
  }

  /// One checked section: its duplicates dropped against its deck as it is
  /// now, its sub-deck made only when a draft is kept, its drafts written.
  Future<CardImportSectionResult> _writeSection(
    String targetDeckId,
    CardImportSection section, {
    required bool includeDuplicates,
    required DateTime at,
  }) async {
    final existingId = section.existingDeckId;
    final (kept, skipped) = _keep(
      section.drafts,
      existingId == null ? {} : await _dao.foldedPairs(existingId),
      includeDuplicates: includeDuplicates,
    );
    if (kept.isEmpty) {
      return CardImportSectionResult(
        deckId: existingId,
        written: 0,
        skippedIndexes: skipped,
      );
    }
    final deckId =
        existingId ?? await _newSubDeck(targetDeckId, section.name, at);
    final written = await _cards.insertCards(
      deckId: deckId,
      drafts: kept,
      now: at,
    );
    if (written case Rejected(:final reason)) {
      // Checked before the first write, so this is a bug; throwing rolls
      // the batch back.
      throw StateError('import section refused after its check: $reason');
    }
    return CardImportSectionResult(
      deckId: deckId,
      written: kept.length,
      skippedIndexes: skipped,
    );
  }

  /// A sub-deck the preview named and the target was checked for; a refusal
  /// here is a bug, and throwing rolls the batch back.
  Future<String> _newSubDeck(String parentId, String name, DateTime at) async =>
      switch (await _decks.createSubDeck(
        parentId: parentId,
        name: name,
        now: at,
      )) {
        Ok(:final value) => value.id,
        Rejected(:final reason) => throw StateError(
          'import section deck refused: $reason',
        ),
      };

  @override
  Future<int> countCards(String deckId) =>
      guardDatabase(() => _dao.liveCount(deckId));

  @override
  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
    required String deckId,
    Set<String>? cardIds,
  }) => guardDatabase(
    () => _db.transaction(() async {
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return const Rejected(CardRejection.notFound);
      final rows = await _dao.exportRows(deckId, cardIds);
      if (cardIds != null && rows.length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      final tags = await _listDao.tagsOf([for (final row in rows) row.id]);
      return Ok(
        CardExportSnapshot(
          deckName: deck.name,
          rows: [
            for (final row in rows)
              CardExportRow(
                front: row.front,
                back: row.back,
                example: row.example,
                hint: row.hint,
                pronunciation: row.pronunciation,
                tagNames: [
                  for (final tag in tags[row.id] ?? const <Tag>[]) tag.name,
                ],
              ),
          ],
        ),
      );
    }),
  );
}
