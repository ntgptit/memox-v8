# Every query in `.drift`, P1 (tags, settings, starter, notes) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `StarterDao`, `DismissedNoteStore`, `SettingsDao` and `TagDao` to `@DriftAccessor`s whose every query lives in `.drift`, and take them off the guard's temporary exclude.

**Architecture:** This follows the pattern P0 set (ADR-020; `TrashDao` and `AccountDeviceDao` are the reference shape):
- each DAO includes one topic file under `lib/core/database/queries/`;
- the constructor stays `XDao(db)`;
- public method names stay as they are, so repositories change only where a return type has to: `TagDao.countRows` now returns a typed row, not a `QueryRow`.

A partial settings write keeps taking an `AppSettingsCompanion` through `UPDATE app_settings SET $values` (spiked on Drift 2.35: `Insertable<AppSetting>`, `updates: {appSettings}`).

**Tech Stack:** Flutter 3.47.5, Drift 2.35 (`.drift`, `drift_dev`), Python 3.13 guard.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P1; D1–D7, D11). ADR-020.

## Global Constraints

- Behaviour-preserving: no schema change, no `schemaVersion` bump, no index change, same SQL semantics.
- Generated `*.g.dart` is not committed; run `dart run build_runner build --delete-conflicting-outputs` after each `.drift` / accessor change.
- Guard commands use `python3.13`, not `/usr/local/bin/python3`, which lacks pytest and typer.
- Each task's red step is the guard: removing the file from the temporary exclude makes `queries_in_drift` fail on it. The existing feature tests are the behaviour net. Every task names the tests that cover its DAO.
- A query name must not collide with a DAO method name (the mixin and the class share a namespace).
- Every new `queries/*.drift` file gets an owner row in `.claude/skills/flutter-workflow/scripts/verification_impact_map.json` (`database_query_features`), or `ci_tooling` fails.
- Commit messages: `type(scope): summary`, ending with the session attribution lines.

## Review Focus

1. **A partial settings write leaves the other columns alone.** `$values` must emit only the Companion's present columns: `recordReminderDelivered` touches no `updated_at`, and a theme save touches no card limit. Pinned by `app_settings_repository_test` ("each save changes only its own value") and `reminder_settings_repository_test` (line 110). Task 3 runs both.
2. **An empty Companion.** `UPDATE … SET` with no columns would be invalid SQL. No caller sends one today: every caller sets at least `updated_at` or `reminder_last_delivered_at`. Task 3 Step 1 pins that `updateRow` with an empty Companion is a no-op that does not throw, matching the builder.
3. **Study options re-emit when the settings row or the root deck changes.** `watchRootAndSettings` must keep `readsFrom {deck, app_settings}`. Pinned by `root_study_options_repository_test` ("the options in force follow the override and the app defaults").
4. **Tag counts, with and without a deck, never counting the Trash.** Pinned by `tag_counts_test` (7 tests).
5. **Chunked reads past the bind limit.** `liveCardCount`, `cardsCarrying`, `tagCounts` and `unlink` must still chunk. Pinned by `tag_batch_limit_test`.

---

### Task 1: `StarterDao`

**Files:**
- Create: `lib/core/database/queries/starter_queries.drift`
- Modify: `lib/features/starter_decks/data/datasources/starter_dao.dart` (whole file)
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`, `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py` (`MIGRATED_TO_DRIFT`), `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`
- Tests (existing): `test/features/starter_decks/data/watch_starter_library_test.dart`, `add_starter_deck_test.dart`

**Interfaces:**
- Produces: `StarterDao(AppDatabase)` with unchanged `copyChanges()`, `copies() -> Future<Set<(String, int)>>` and `hasCopy(String, int) -> Future<bool>`.

- [ ] **Step 1: Red — take the file off the exclude**

Delete `      - lib/features/starter_decks/data/datasources/starter_dao.dart` from `scopes.yaml`, and append `"lib/features/starter_decks/data/datasources/starter_dao.dart",` to `MIGRATED_TO_DRIFT`.

Run: `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: exit 1, with `memox.data_model.queries_in_drift` errors in `starter_dao.dart`.

- [ ] **Step 2: Queries**

Create `lib/core/database/queries/starter_queries.drift`:

```sql
import '../tables/deck.drift';

-- Spec §6: the (template id, version) of every copy outside the Trash.
starterCopies:
SELECT source_template_id AS template_id,
  source_template_version AS template_version
FROM deck
WHERE source_template_id IS NOT NULL AND source_template_version IS NOT NULL
  AND delete_batch_id IS NULL;

-- Starter decks spec D7: whether a deck outside the Trash copies
-- :template_id at :version.
starterCopyExists(:template_id AS TEXT, :version AS INTEGER):
SELECT EXISTS (
  SELECT 1 FROM deck
  WHERE source_template_id = :template_id
    AND source_template_version = :version
    AND delete_batch_id IS NULL
);
```

- [ ] **Step 3: DAO**

Replace `starter_dao.dart` with:

```dart
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
```

- [ ] **Step 4: Generate, analyze, guard green, tests**

Run: `dart run build_runner build --delete-conflicting-outputs`. Then confirm the row's field types with `grep -n "templateId\|templateVersion" lib/features/starter_decks/data/datasources/starter_dao.g.dart`:
- If Drift typed them non-null (it may, given the `IS NOT NULL` filter), drop the two `!` in `copies()`.
- `flutter analyze` flags an unnecessary `!` as a warning, so this matters.

Add `"starter_queries": ["starter_decks"],` to `database_query_features` in `verification_impact_map.json`, in alphabetical order.

Run, in order:
- `flutter analyze --no-fatal-infos lib/features/starter_decks` → no issues.
- `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` → passed.
- `(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/test_memox_v8_data_model_guard_rules.py)` → passed.
- `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'` → OK.
- `TZ=UTC flutter test test/features/starter_decks/` → all passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/queries/starter_queries.drift lib/features/starter_decks/data/datasources/starter_dao.dart code-verification-guard-v2 .claude/skills/flutter-workflow/scripts/verification_impact_map.json
git commit -m "refactor(starter): StarterDao reads through .drift (ADR-020 P1)"
```

---

### Task 2: `DismissedNoteStore`

**Files:**
- Create: `lib/core/database/queries/dismissed_note_queries.drift`
- Modify: `lib/core/notes/dismissed_note_store.dart` (whole file), guard scope, `MIGRATED_TO_DRIFT`, impact map
- Tests (existing): `test/core/notes/dismissed_note_store_test.dart` (4 tests: empty, dismiss twice, second store sees it, never syncs)

**Interfaces:**
- Produces: `DismissedNoteStore(AppDatabase db, {DateTime Function()? now})` with unchanged `watchDismissed() -> Stream<Set<String>>` and `dismiss(String) -> Future<void>`.

- [ ] **Step 1: Red** — delete `      - lib/core/notes/dismissed_note_store.dart` from `scopes.yaml` and add `"lib/core/notes/dismissed_note_store.dart",` to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on `dismissed_note_store.dart`.

- [ ] **Step 2: Queries**

Create `lib/core/database/queries/dismissed_note_queries.drift`:

```sql
import '../tables/ui_state.drift';

-- The note keys dismissed on this device (never synced).
dismissedNoteKeys:
SELECT note_key FROM dismissed_note ORDER BY note_key;

-- Hides :note_key from now on; dismissing it again changes nothing.
insertDismissedNote(:note_key AS TEXT, :dismissed_at AS DATETIME):
INSERT OR IGNORE INTO dismissed_note (note_key, dismissed_at)
VALUES (:note_key, :dismissed_at);
```

- [ ] **Step 3: Store**

Replace `dismissed_note_store.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'dismissed_note_store.g.dart';

/// The notes dismissed on this device (`dismissed_note`, never synced;
/// `dismissed_note_queries.drift`).
@DriftAccessor(
  include: {'package:memox/core/database/queries/dismissed_note_queries.drift'},
)
class DismissedNoteStore extends DatabaseAccessor<AppDatabase>
    with _$DismissedNoteStoreMixin {
  DismissedNoteStore(super.attachedDatabase, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// The keys dismissed so far, re-read whenever one is added.
  Stream<Set<String>> watchDismissed() =>
      dismissedNoteKeys().watch().map((keys) => keys.toSet());

  /// Hides [key] from now on; dismissing it again changes nothing.
  Future<void> dismiss(String key) => insertDismissedNote(key, _now().toUtc());
}
```

- [ ] **Step 4: Generate and verify** — run build_runner. Add `"dismissed_note_queries": ["starter_decks", "trash", "transfer"],` to the impact map: those are the three features whose screens show a dismissible note. Then run analyze on `lib/core/notes`, the guard, the guard tests, the CI tooling tests and `TZ=UTC flutter test test/core/notes/`. Expected: all green.

- [ ] **Step 5: Commit** — `refactor(notes): DismissedNoteStore reads and writes through .drift (ADR-020 P1)`, with the same file set as Task 1 for this store.

---

### Task 3: `SettingsDao`

**Files:**
- Create: `lib/core/database/queries/settings_queries.drift`
- Modify: `lib/features/settings/data/datasources/settings_dao.dart` (whole file), guard scope, `MIGRATED_TO_DRIFT`, impact map
- Test: `test/features/settings/data/settings_dao_test.dart` (create, Step 1)
- Tests (existing): `test/features/settings/data/*` (34 tests), `test/core/sync/` (the account-settings sync trigger)

**Interfaces:**
- Produces: `SettingsDao(AppDatabase)` with unchanged `watchRow()`, `row()`, `updateRow(AppSettingsCompanion)`, `watchRootAndSettings(String) -> Stream<(Deck, AppSetting)?>`, `rootAndSettings(String)`, `deckRow(String) -> Future<Deck?>`, `setStudyConfig(String, String?, DateTime)`.

- [ ] **Step 1: Characterization test for an empty write**

Create `test/features/settings/data/settings_dao_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/datasources/settings_dao.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('a write with no column changes nothing and does not throw', () async {
    final dao = SettingsDao(db);
    final before = await dao.row();

    await dao.updateRow(const AppSettingsCompanion());

    expect(await dao.row(), before);
  });
}
```

Run: `TZ=UTC flutter test test/features/settings/data/settings_dao_test.dart`
Expected: PASS against the current builder code, which skips an empty write.

- [ ] **Step 2: Red** — delete `      - lib/features/settings/data/datasources/settings_dao.dart` from `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on `settings_dao.dart`.

- [ ] **Step 3: Queries**

Create `lib/core/database/queries/settings_queries.drift`:

```sql
import '../tables/settings.drift';
import '../tables/deck.drift';

-- BR-SETTINGS-001: the one settings row.
appSettingsRow(:row_id AS INTEGER):
SELECT * FROM app_settings WHERE id = :row_id;

-- BR-SETTINGS-007: each save writes only its own columns.
updateAppSettings(:row_id AS INTEGER):
UPDATE app_settings SET $values WHERE id = :row_id;

-- The root of :deck_id and the settings row; nothing when the deck or its
-- root is missing or in the Trash. The root is reached through root_id
-- (BR-DECK-003).
rootAndSettingsOf(:deck_id AS TEXT, :row_id AS INTEGER):
SELECT root.**, settings.**
FROM deck d
INNER JOIN deck root ON root.id = d.root_id AND root.delete_batch_id IS NULL
INNER JOIN app_settings settings ON settings.id = :row_id
WHERE d.id = :deck_id AND d.delete_batch_id IS NULL;

-- The deck :deck_id names, unless it is in the Trash.
liveDeckRow(:deck_id AS TEXT):
SELECT * FROM deck WHERE id = :deck_id AND delete_batch_id IS NULL;

-- The study override of a root; NULL removes it.
setDeckStudyConfig(:deck_id AS TEXT, :study_config AS TEXT OR NULL,
  :now AS DATETIME):
UPDATE deck SET study_config = :study_config, updated_at = :now
WHERE id = :deck_id;
```

- [ ] **Step 4: DAO**

Replace `settings_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'settings_dao.g.dart';

/// Row access for the one `app_settings` row and for the study options a
/// root deck keeps in `deck.study_config` (`settings_queries.drift`). It
/// returns Drift rows, never domain values, and runs inside the caller's
/// transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/settings_queries.drift'},
)
final class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Stream<AppSetting> watchRow() =>
      appSettingsRow(appSettingsRowId).watchSingle();

  /// [watchRow] read once.
  Future<AppSetting> row() => appSettingsRow(appSettingsRowId).getSingle();

  /// Writes the columns [values] holds; one with none writes nothing, as
  /// an `UPDATE … SET` with no column is not SQL.
  Future<void> updateRow(AppSettingsCompanion values) async {
    if (values.toColumns(false).isEmpty) return;
    await updateAppSettings(values, appSettingsRowId);
  }

  /// The root of [deckId] and the settings row, in one statement, again when
  /// either changes; null when [deckId] or its root does not exist or is in
  /// the Trash. The root is reached through `root_id` (BR-DECK-003).
  Stream<(Deck, AppSetting)?> watchRootAndSettings(String deckId) =>
      rootAndSettingsOf(deckId, appSettingsRowId).watchSingleOrNull().map(
        (row) => row == null ? null : (row.root, row.settings),
      );

  /// [watchRootAndSettings] read once.
  Future<(Deck, AppSetting)?> rootAndSettings(String deckId) async {
    final row = await rootAndSettingsOf(
      deckId,
      appSettingsRowId,
    ).getSingleOrNull();
    return row == null ? null : (row.root, row.settings);
  }

  /// The deck [id] names, unless it is in the Trash.
  Future<Deck?> deckRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// Writes the override of the root [rootId]; null removes it.
  Future<void> setStudyConfig(
    String rootId,
    String? studyConfig,
    DateTime now,
  ) => setDeckStudyConfig(rootId, studyConfig, now);
}
```

- [ ] **Step 5: Generate and check the signatures**

Run build_runner. Then run: `grep -n "updateAppSettings\|rootAndSettingsOf\|class RootAndSettingsOfResult\|final Deck root\|final AppSetting settings\|readsFrom\|updates:" lib/features/settings/data/datasources/settings_dao.g.dart`
Expected:
- `updateAppSettings(Insertable<AppSetting> values, int rowId)` with `updates: {this.appSettings}`;
- `rootAndSettingsOf` with `readsFrom` covering `deck` and `appSettings`;
- a result class with `Deck root` and `AppSetting settings`.

If the generated parameter order differs, follow the generated signature in `updateRow`.

- [ ] **Step 6: Verify** — add `"settings_queries": ["settings", "reminders", "study"],` to the impact map. `reminders` is what the impact map already gives `settings` as dependents, and the study entry screen reads the effective options through this DAO's providers. Then run:
- analyze on `lib/features/settings`;
- the guard and its tests;
- the CI tooling tests;
- `TZ=UTC flutter test test/features/settings/ test/features/study/ test/core/sync/`.

Expected: all green, including Step 1's test.

- [ ] **Step 7: Commit** — `refactor(settings): SettingsDao reads and writes through .drift (ADR-020 P1)`.

---

### Task 4: `TagDao`

**Files:**
- Create: `lib/core/database/queries/tag_queries.drift`
- Modify: `lib/features/tags/data/datasources/tag_dao.dart` (whole file)
- Modify: `lib/features/tags/data/repositories/tag_repository_impl.dart:121-131`, where `countRows` returns a typed row now
- Modify: guard scope, `MIGRATED_TO_DRIFT`, impact map
- Tests (existing): `test/features/tags/data/*` (44 tests), `test/features/search/`, `test/features/transfer/`

**Interfaces:**
- Produces: `TagDao(AppDatabase)` with unchanged names. `countRows({String? deckId, required String foldedTerm})` now returns `Future<List<TagCountRow>>`, where `TagCountRow` has `id`, `name` and `cardCount`.

- [ ] **Step 1: Red** — delete `      - lib/features/tags/data/datasources/tag_dao.dart` from `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on `tag_dao.dart`.

- [ ] **Step 2: Queries**

Create `lib/core/database/queries/tag_queries.drift`:

```sql
import '../tables/tags.drift';
import '../tables/card.drift';

-- The local profile's tag (owner_id NULL, schema.md) with :name_folded.
localTagByFoldedName(:name_folded AS TEXT):
SELECT * FROM tags WHERE owner_id IS NULL AND name_folded = :name_folded;

-- Tag management spec D13: the local profile's tag :tag_id.
localTagById(:tag_id AS TEXT):
SELECT * FROM tags WHERE owner_id IS NULL AND id = :tag_id;

createTag: INSERT INTO tags $row;

-- BE-C2: how many of :card_ids are live cards; read one chunk at a time.
liveCardCountIn:
SELECT COUNT(*) FROM card WHERE id IN :card_ids AND delete_batch_id IS NULL;

tagIdsOfCard(:card_id AS TEXT):
SELECT tag_id FROM card_tags WHERE card_id = :card_id ORDER BY tag_id;

cardsCarryingTagIn(:tag_id AS TEXT):
SELECT card_id FROM card_tags WHERE card_id IN :card_ids AND tag_id = :tag_id
ORDER BY card_id;

tagCountsOfCardsIn:
SELECT card_id, COUNT(tag_id) AS tag_count FROM card_tags
WHERE card_id IN :card_ids GROUP BY card_id ORDER BY card_id;

linkCardTag(:card_id AS TEXT, :tag_id AS TEXT):
INSERT INTO card_tags (card_id, tag_id) VALUES (:card_id, :tag_id);

unlinkCardsFromTagIn(:tag_id AS TEXT):
DELETE FROM card_tags WHERE card_id IN :card_ids AND tag_id = :tag_id;

-- Tag management spec §5: every local tag whose folded name holds
-- :folded_term, with its active cards, in :deck_id when given; by folded
-- name then id. instr finds an empty term everywhere.
tagCountRows(:deck_id AS TEXT OR NULL, :folded_term AS TEXT) AS TagCountRow:
SELECT t.id, t.name, (
  SELECT COUNT(*) FROM card_tags ct JOIN card c ON c.id = ct.card_id
  WHERE ct.tag_id = t.id AND c.delete_batch_id IS NULL
    AND (:deck_id IS NULL OR c.deck_id = :deck_id)
) AS card_count
FROM tags t
WHERE t.owner_id IS NULL AND instr(t.name_folded, :folded_term) > 0
ORDER BY t.name_folded, t.id;

-- BR-TAG-010: the distinct active cards carrying any of :tag_ids.
activeCardCountOfTags:
SELECT COUNT(DISTINCT ct.card_id) FROM card_tags ct
INNER JOIN card c ON c.id = ct.card_id
WHERE ct.tag_id IN :tag_ids AND c.delete_batch_id IS NULL;

-- BR-TAG-006: a rename keeps the id and the links.
renameTagRow(:tag_id AS TEXT, :name AS TEXT, :name_folded AS TEXT):
UPDATE tags SET name = :name, name_folded = :name_folded WHERE id = :tag_id;

-- BR-TAG-007, BR-TAG-010: every card of :source_id, in the Trash or not,
-- carries :target_id; one that already did keeps it once (OR IGNORE).
mergeTagLinks(:target_id AS TEXT, :source_id AS TEXT):
INSERT OR IGNORE INTO card_tags (card_id, tag_id)
SELECT card_id, :target_id FROM card_tags WHERE tag_id = :source_id;

-- The links go by the cascade of card_tags, and its update rule tells the
-- watchers of card_tags as well.
deleteTagRow(:tag_id AS TEXT):
DELETE FROM tags WHERE id = :tag_id;
```

- [ ] **Step 3: DAO**

Replace `tag_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/id_chunks.dart';
import 'package:memox/core/database/table_changes.dart';

part 'tag_dao.g.dart';

/// Row access for `tags` and `card_tags`, plus the existence check of `card`
/// rows (`tag_queries.drift`). It returns Drift rows, never domain
/// entities, and runs inside the caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/tag_queries.drift'},
)
final class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.attachedDatabase);

  /// The local profile's tag with [nameFolded]: `owner_id` is NULL for it
  /// (schema.md), as the unique index `COALESCE(owner_id, '')` reads it.
  Future<Tag?> findByFoldedName(String nameFolded) =>
      localTagByFoldedName(nameFolded).getSingleOrNull();

  /// The local profile's tag [id] (tag management spec D13).
  Future<Tag?> findById(String id) => localTagById(id).getSingleOrNull();

  Future<void> insertTag(TagsCompanion row) => createTag(row);

  /// How many of [cardIds] exist as live cards; tombstones do not count.
  /// Counted in chunks (BE-C2).
  Future<int> liveCardCount(Set<String> cardIds) async {
    var total = 0;
    for (final chunk in idChunks(cardIds)) {
      total += await liveCardCountIn(chunk).getSingle();
    }
    return total;
  }

  /// The tag ids [cardId] carries.
  Future<Set<String>> tagIdsOf(String cardId) async =>
      (await tagIdsOfCard(cardId).get()).toSet();

  /// The cards of [cardIds] that already carry [tagId], read in chunks
  /// (BE-C2).
  Future<Set<String>> cardsCarrying(Set<String> cardIds, String tagId) async =>
      {
        for (final chunk in idChunks(cardIds))
          ...await cardsCarryingTagIn(tagId, chunk).get(),
      };

  /// How many tags each of [cardIds] carries; a card with none is absent.
  /// Read in chunks of cards, which never share a card (BE-C2).
  Future<Map<String, int>> tagCounts(Set<String> cardIds) async => {
    for (final chunk in idChunks(cardIds))
      for (final row in await tagCountsOfCardsIn(chunk).get())
        row.cardId: row.tagCount,
  };

  Future<void> link(String cardId, String tagId) => linkCardTag(cardId, tagId);

  /// Unlinks [tagId] from [cardIds], in chunks (BE-C2).
  Future<void> unlink(Set<String> cardIds, String tagId) async {
    for (final chunk in idChunks(cardIds)) {
      await unlinkCardsFromTagIn(tagId, chunk);
    }
  }

  /// Every tag of the local profile whose folded name holds [foldedTerm],
  /// with the active cards carrying it, in [deckId] when given; by folded
  /// name then id. One statement (tag management spec §5).
  Future<List<TagCountRow>> countRows({
    String? deckId,
    required String foldedTerm,
  }) => tagCountRows(deckId, foldedTerm).get();

  /// Fires once, then after every write to the tags, their links or the
  /// cards: a card entering the Trash or moving decks changes a count.
  Stream<void> countChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.tags,
    attachedDatabase.cardTags,
    attachedDatabase.card,
  ]);

  /// The distinct active cards carrying any of [tagIds]: a card in the Trash
  /// is not counted (BR-TAG-010).
  Future<int> activeCardCount(Set<String> tagIds) =>
      activeCardCountOfTags(tagIds.toList()).getSingle();

  /// Renames [tagId] in place: its id and links stay (BR-TAG-006).
  Future<void> rename(
    String tagId, {
    required String name,
    required String nameFolded,
  }) => renameTagRow(tagId, name, nameFolded);

  /// Links every card of [sourceId], in the Trash or not, to [targetId],
  /// then deletes [sourceId] (BR-TAG-007, BR-TAG-010).
  Future<void> merge({
    required String sourceId,
    required String targetId,
  }) async {
    await mergeTagLinks(targetId, sourceId);
    await deleteTag(sourceId);
  }

  /// Deletes [tagId]. Its links go by the cascade of `card_tags`, and drift's
  /// update rule for that key tells the watchers of `card_tags` as well.
  Future<void> deleteTag(String tagId) => deleteTagRow(tagId);
}
```

- [ ] **Step 4: Generate and match the signatures**

Run build_runner. Then run: `grep -nE "^  (Selectable|Future)<[^>]+> (liveCardCountIn|cardsCarryingTagIn|tagCountsOfCardsIn|unlinkCardsFromTagIn|activeCardCountOfTags|createTag|mergeTagLinks|deleteTagRow)\(" lib/features/tags/data/datasources/tag_dao.g.dart`

Generated parameters follow the order in which a variable first appears in the SQL. Where that differs from the calls in Step 3, change the calls in `tag_dao.dart`, not the SQL. For example, `cardsCarryingTagIn(cardIds, tagId)` if `:card_ids` comes first.

Check the generated `mergeTagLinks` declares `updates: {this.cardTags}` and `deleteTagRow` declares `updates: {this.tags}` with `UpdateKind.delete`.

- [ ] **Step 5: Repository mapping**

In `lib/features/tags/data/repositories/tag_repository_impl.dart`, the `watchTagCounts` map becomes:

```dart
        .map(
          (rows) => [
            for (final row in rows)
              TagCount(id: row.id, name: row.name, cardCount: row.cardCount),
          ],
        )
```

- [ ] **Step 6: Verify** — add `"tag_queries": ["tags", "search", "transfer"],` to the impact map. These are the owners the impact map already gives the `tags` feature's dependents. Then run:
- analyze on `lib/features/tags`;
- the guard and its tests;
- the CI tooling tests;
- `TZ=UTC flutter test test/features/tags/ test/features/search/ test/features/transfer/ test/core/sync/`.

Expected: all green.

- [ ] **Step 7: Commit** — `refactor(tags): TagDao reads and writes through .drift (ADR-020 P1)`.

---

### Task 5: WBS and gate

**Files:** `docs/wbs_FE.md` (row FE-D9), `docs/_generated/*` (regenerated if the docs check asks).

- [ ] **Step 1: Full gate.** Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed` and all tests passed.
- [ ] **Step 2: `check_drift`.** Run `bash .claude/skills/flutter-drift/scripts/check_drift.sh | tail -1`. Record the count, which should be at most 40, in the PR description.
- [ ] **Step 3: No goldens, no presentation.** Run `git diff --stat <P1 base>...HEAD -- 'test/**/goldens/*.png' 'lib/features/*/presentation/**'`. Expected: empty.
- [ ] **Step 4: WBS.** Set FE-D9 to `xong`. Its evidence is the plan link and "`dod_check.sh` xanh". Then run `python3 tools/docs/generate.py && python3 tools/docs/check.py` and expect PASS. Commit `docs(wbs): FE-D9 done`.
