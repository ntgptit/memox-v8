import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

/// Row access for the Starter library: the decks that are starter copies.
/// It returns plain values and runs inside the caller's transaction.
final class StarterDao {
  StarterDao(this._db);

  final AppDatabase _db;

  /// Fires once, then after every write to the decks: a copy added, sent to
  /// the Trash, restored or purged (spec D12).
  Stream<void> copyChanges() => tableChanges(_db, [_db.deck]);

  /// The (template id, version) of every copy outside the Trash, in one
  /// statement (spec §6).
  Future<Set<(String, int)>> copies() async {
    final deck = _db.deck;
    final query = _db.selectOnly(deck)
      ..addColumns([deck.sourceTemplateId, deck.sourceTemplateVersion])
      ..where(
        deck.sourceTemplateId.isNotNull() &
            deck.sourceTemplateVersion.isNotNull() &
            deck.deleteBatchId.isNull(),
      );
    return {
      for (final row in await query.get())
        (
          row.read(deck.sourceTemplateId)!,
          row.read(deck.sourceTemplateVersion)!,
        ),
    };
  }

  /// Whether a deck outside the Trash is a copy of [templateId] at
  /// [version] (starter decks spec D7).
  Future<bool> hasCopy(String templateId, int version) async {
    final query = _db.select(_db.deck)
      ..where(
        (deck) =>
            deck.sourceTemplateId.equals(templateId) &
            deck.sourceTemplateVersion.equals(version) &
            deck.deleteBatchId.isNull(),
      )
      ..limit(1);
    return await query.getSingleOrNull() != null;
  }
}
