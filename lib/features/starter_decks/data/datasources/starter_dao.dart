import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for the Starter library: the decks that are starter copies.
/// It returns plain values and runs inside the caller's transaction.
final class StarterDao {
  StarterDao(this._db);

  final AppDatabase _db;

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
