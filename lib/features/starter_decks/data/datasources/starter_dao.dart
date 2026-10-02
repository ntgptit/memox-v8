import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

part 'starter_dao.g.dart';

/// Row access for the Starter library: the decks that are starter copies
/// (`starter_queries.drift`). It returns plain values and runs inside the
/// caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/starter_queries.drift'},
)
final class StarterDao extends DatabaseAccessor<AppDatabase>
    with _$StarterDaoMixin {
  StarterDao(super.attachedDatabase);

  /// Fires once, then after every write to the decks: a copy added, sent to
  /// the Trash, restored or purged (spec D12).
  Stream<void> copyChanges() =>
      tableChanges(attachedDatabase, [attachedDatabase.deck]);

  /// The (template id, version) of every copy outside the Trash, in one
  /// statement (spec §6).
  Future<Set<(String, int)>> copies() async => {
    for (final row in await starterCopies().get())
      (row.templateId!, row.templateVersion!),
  };

  /// Whether a deck outside the Trash is a copy of [templateId] at
  /// [version] (starter decks spec D7).
  Future<bool> hasCopy(String templateId, int version) =>
      starterCopyExists(templateId, version).getSingle();
}
