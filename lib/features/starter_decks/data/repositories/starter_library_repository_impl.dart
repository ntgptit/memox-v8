import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/models/deck_source_template_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/datasources/starter_dao.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

/// The Starter library over the bundled templates (starter decks spec §6,
/// §7). A copy is written by the features that own each table, through their
/// contracts, inside one transaction (spec D2).
final class StarterLibraryRepositoryImpl implements StarterLibraryRepository {
  StarterLibraryRepositoryImpl(
    this._db,
    this._decks,
    this._cards, {
    required Future<List<StarterTemplate>> Function() templates,
  }) : _dao = StarterDao(_db),
       _loadTemplates = templates;

  final AppDatabase _db;
  final DeckRepository _decks;
  final CardRepository _cards;
  final StarterDao _dao;
  final Future<List<StarterTemplate>> Function() _loadTemplates;

  /// The templates, read once for the life of the repository (spec §5.3).
  late final Future<List<StarterTemplate>> _templates = _loadTemplates();

  @override
  Stream<List<StarterLibraryEntry>> watchLibrary() =>
      _dao.copyChanges().asyncMap((_) async {
        final templates = await _templates;
        final copies = await _dao.copies();
        return [
          for (final template in templates)
            StarterLibraryEntry.of(
              template,
              isInLibrary: copies.contains((
                template.templateId,
                template.version,
              )),
            ),
        ];
      }).mapDatabaseErrors();

  @override
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  }) async {
    final template = (await _templates)
        .where((template) => template.templateId == templateId)
        .firstOrNull;
    if (template == null) {
      return const Rejected(StarterRejection.templateNotFound);
    }
    return _mapped(
      () => _db.transaction(() async {
        final isInLibrary = await _dao.hasCopy(
          template.templateId,
          template.version,
        );
        if (isInLibrary && !allowSecondCopy) {
          return const Rejected(StarterRejection.alreadyInLibrary);
        }
        final root = _written(
          await _decks.createRootDeck(
            name: template.title,
            schedulerType: schedulerType,
            sourceTemplate: DeckSourceTemplate(
              templateId: template.templateId,
              version: template.version,
            ),
            now: now,
          ),
        );
        await _writeDecks(root.id, template.decks, now);
        return Ok(
          AddedStarterDeck(
            rootDeckId: root.id,
            title: template.title,
            schedulerType: schedulerType,
            cardCount: template.cardCount,
          ),
        );
      }),
    );
  }

  /// [decks] under [parentId], depth first, in template order (spec D9).
  Future<void> _writeDecks(
    String parentId,
    List<StarterDeck> decks,
    DateTime? now,
  ) async {
    for (final deck in decks) {
      final written = _written(
        await _decks.createSubDeck(
          parentId: parentId,
          name: deck.name,
          now: now,
        ),
      );
      await _writeDecks(written.id, deck.decks, now);
      for (final card in deck.cards) {
        _written(
          await _cards.createCard(
            deckId: written.id,
            draft: CardDraft(
              front: card.front,
              back: card.back,
              example: card.example,
              hint: card.hint,
              pronunciation: card.pronunciation,
            ),
            now: now,
          ),
        );
      }
    }
  }

  /// A throw rolls every row back and leaves as `mapDatabaseError`'s
  /// [Failure].
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

/// A refusal inside a copy breaks an invariant the library already checked
/// (spec D6, D10): it throws, and the transaction rolls every row back.
T _written<T, R extends Enum>(Outcome<T, R> outcome) => switch (outcome) {
  Ok(:final value) => value,
  Rejected(:final reason) => throw StateError(
    'a starter copy was refused: $reason',
  ),
};
