# G1 — BE-C5: Unicode NFC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** give every stored and folded text one Unicode form (NFC), so that
precomposed and decomposed spellings of the same word store, fold, search,
de-duplicate and judge alike, before the sync slice pushes text to the
server.

**Architecture:**

- One file, `lib/core/text/unicode_form.dart`, wraps `unorm_dart`; nothing
  else imports the package, and a guard rule enforces that.
- `storedText` (in `lib/core/text/stored_text.dart`) and `foldText` (in
  `lib/core/text/folded_text.dart`) build on it.
- The six data-layer write sites use `storedText`.
- Fill's comparison version rises to 2.
- A data-only Drift migration v3 → v4 re-stores the text, recomputes the
  folded columns and merges tags that collide.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Drift 2.35 (`stepByStep`, `SchemaVerifier`), `unorm_dart` 0.3.x.

**Spec:** [2026-09-27-local-backend-completion-design.md](../specs/2026-09-27-local-backend-completion-design.md) §2 (D2), §4. Approved by the owner; this plan needs no further approval.

## Global Constraints

- `storedText(raw)` = NFC(trim(raw)).
- `foldText(raw)` = NFC(lower(NFC(trim(raw)))).
- `unorm_dart` is imported by `lib/core/text/unicode_form.dart` only.
- `fillComparisonVersion` goes from 1 to 2. Turns already recorded keep 1
  (BR-STUDY-027: "Đổi chính sách MUST tăng phiên bản, MUST NOT sửa lại các
  lượt cũ").
- The migration changes data, not structure, and runs in the step's
  transaction.
- It never calls application queries: raw SQL only, per
  `.claude/skills/flutter-drift/references/migrations.md`.
- A released migration never changes.
- When tags collide, the oldest tag wins (by `created_at`, then `id`). Its
  links are the union of all the colliding tags' links, and no link is lost.
- Contract documents this plan may edit, and no others:
  - `docs/shared/data/schema.md` (the `*_folded` definitions);
  - `docs/features/tags/rules/BR-TAG-001-*.md` (the Rule paragraph);
  - `docs/superpowers/specs/2026-09-27-server-sync-design.md` (one line in
    §8);
  - `docs/wbs_BE.md` (rows BE-C5 and the update log).
- Tests never read the wall clock.
- Commits end with the two trailers of this session.

## Review Focus

1. **A tag typed in the other form.** Creating a tag from the card editor,
   in NFD, when the NFC tag exists reuses the existing tag. It never makes a
   second tag and never hits the unique index. Pinned in Task 2 (tags).
2. **Colliding tags on the same card.** The migration's link move must not
   violate `card_tags`' primary key. Pinned in Task 4.
3. **A folded value that changes and would clash for a moment.** The
   migration must not trip the unique index while it re-folds, including
   when tag A's new folded value equals tag B's old one. Pinned in Task 4
   with a two-phase update.
4. **Hangul typed as conjoining jamo.** Search and Fill match the NFC
   syllable. Pinned in Tasks 2 and 3.
5. **Text that is already NFC.** The migration writes nothing, so a big
   library upgrades fast and its `updated_at` values stay. Pinned in Task 4.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `pubspec.yaml` | modify | add `unorm_dart` |
| `lib/core/text/unicode_form.dart` | create | `nfc(String)`, the only `unorm_dart` import |
| `lib/core/text/stored_text.dart` | create | `storedText`, `storedTextOrNull` |
| `lib/core/text/folded_text.dart` | modify | `foldText` with NFC |
| `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml` | modify | rule: `unorm_dart` only in `unicode_form.dart` |
| `lib/features/card/data/datasources/card_dao.dart` | modify | `_contentOf` uses `storedText` / `storedTextOrNull` |
| `lib/features/deck/data/repositories/deck_repository_impl.dart` | modify | 3 name writes |
| `lib/features/tags/data/repositories/tag_repository_impl.dart` | modify | create, rename, the "unchanged" check |
| `lib/features/study_mode/domain/models/fill_mode.dart` | modify | `fillComparisonVersion = 2`, doc |
| `lib/core/database/migrations/nfc_text_migration.dart` | create | the v3 → v4 data step |
| `lib/core/database/app_database.dart` | modify | `schemaVersion 4`, `from3To4` |
| `drift_schemas/drift_schema_v4.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/*` | generate | v4 snapshot and helpers |
| tests | modify/create | see each task |
| docs | modify | Task 5 |

---

### Task 1: The Unicode core

**Files:**
- Modify: `pubspec.yaml`, `lib/core/text/folded_text.dart`,
  `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`
- Create: `lib/core/text/unicode_form.dart`, `lib/core/text/stored_text.dart`
- Test: `test/core/text/folded_text_test.dart`,
  `test/core/text/stored_text_test.dart` (create)

**Interfaces — Produces:**
- `String nfc(String text)`
- `String storedText(String raw)`
- `String? storedTextOrNull(String? raw)`: null or blank gives `null`.
- `String foldText(String text)`: the signature is unchanged.

- [ ] **Step 1: Add the dependency.**

  Run: `flutter pub add unorm_dart`

  Expected: `pubspec.yaml` gains `unorm_dart: ^0.3.2`, and `pubspec.lock`
  updates.

  Then read the package's public API (the Dart file under
  `~/.pub-cache/hosted/pub.dev/unorm_dart-*/lib/`) and note the exact name
  of its NFC function. The API is expected to be `unorm.nfc(String)`.

- [ ] **Step 2: Write the failing tests.**

  `test/core/text/stored_text_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:memox/core/text/stored_text.dart';

  // BE-C5: one stored form whatever form the text arrives in (spec §4).
  const _congNfc = 'công'; // công, precomposed
  const _congNfd = 'công'; // c + o + combining circumflex + ng
  const _babNfc = '밥'; // 밥, one syllable
  const _babJamo = '밥'; // ㅂ ㅏ ㅂ as conjoining jamo

  void main() {
    test('stored text is trimmed and in NFC, whatever form it arrives in', () {
      expect(storedText('  $_congNfd '), _congNfc);
      expect(storedText(_congNfc), _congNfc);
      expect(storedText(_babJamo), _babNfc);
    });

    test('a blank optional field is stored as null', () {
      expect(storedTextOrNull(null), isNull);
      expect(storedTextOrNull('  '), isNull);
      expect(storedTextOrNull(' $_congNfd'), _congNfc);
    });
  }
  ```

  Add to `test/core/text/folded_text_test.dart`, inside `main`:

  ```dart
    test('folding gives one form for precomposed and decomposed text, '
        'Vietnamese and Hangul alike (BE-C5)', () {
      expect(foldText('  CÔNG '), foldText('công'));
      expect(foldText('CÔNG'), 'công');
      expect(foldText('밥'), '밥');
      expect(foldText('Ệ'), 'ệ'); // Ệ decomposed → ệ
    });
  ```

- [ ] **Step 3: Run the tests.**

  Run: `flutter test test/core/text/`

  Expected: FAIL. `stored_text.dart` does not exist yet, and the fold test
  fails on the decomposed input.

- [ ] **Step 4: Implement.**

  `lib/core/text/unicode_form.dart` (use the function name noted in Step 1):

  ```dart
  import 'package:unorm_dart/unorm_dart.dart' as unorm;

  /// The one door to Unicode normalisation (BE-C5): text is stored and folded
  /// in NFC, so a word typed precomposed and one typed decomposed (Vietnamese
  /// marks, Hangul pasted as conjoining jamo) are the same string. No other
  /// file imports `unorm_dart` (guard rule).
  String nfc(String text) => unorm.nfc(text);
  ```

  `lib/core/text/stored_text.dart`:

  ```dart
  import 'package:memox/core/text/unicode_form.dart';

  /// The stored form of a text a person typed: trimmed, then NFC (BE-C5).
  /// Every write of user text goes through it, so the store holds one form.
  String storedText(String raw) => nfc(raw.trim());

  /// [storedText] for an optional field: absent or blank is stored as null.
  String? storedTextOrNull(String? raw) {
    if (raw == null) return null;
    final stored = storedText(raw);
    return stored.isEmpty ? null : stored;
  }
  ```

  `lib/core/text/folded_text.dart`:

  ```dart
  import 'package:memox/core/text/unicode_form.dart';

  /// The folded form of a text: trimmed, NFC, lowercased, then NFC again,
  /// since lowercasing can leave a string outside NFC. schema.md defines
  /// `front_folded`, `back_folded` and `tags.name_folded` this way, and every
  /// search term, name sort and fill answer folds the same way so they
  /// compare alike (BE-C5). Written in Dart because SQLite's `lower()` and
  /// `NOCASE` fold ASCII only, and SQLite has no NFC.
  String foldText(String text) => nfc(nfc(text.trim()).toLowerCase());
  ```

- [ ] **Step 5: Add the guard rule.**

  In `memox-architecture-rules.yaml`, append this rule after the last rule,
  in the file's own format:

  ```yaml
    # BE-C5: Unicode normalisation has one door, so the stored and folded
    # forms cannot drift apart.
    - id: memox_v8.architecture.unicode_normalisation_has_one_door
      type: regex
      severity: error
      enabled: true
      message: >-
        Import `unorm_dart` only in `lib/core/text/unicode_form.dart`; call
        `nfc`, `storedText` or `foldText` instead.
      scopes:
        - dart_lib
      exclude:
        - lib/core/text/unicode_form.dart
      patterns:
        - "^\\s*import\\s+'package:unorm_dart/"
      tags:
        - memox-v8
        - architecture
  ```

- [ ] **Step 6: Run the tests and the guard.**

  Run:
  `flutter test test/core/text/ && python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`

  Expected: PASS, and the guard reports no violations.

  Then prove the rule fires:
  1. Add `import 'package:unorm_dart/unorm_dart.dart';` to
     `stored_text.dart`.
  2. Run the guard. Expected: ERROR naming that file.
  3. Remove the import.

- [ ] **Step 7: Commit.**

  `feat(core): NFC through one door — storedText, foldText in NFC (BE-C5 G1)`

---

### Task 2: Every write of user text in NFC

**Files:**
- Modify:
  - `lib/features/card/data/datasources/card_dao.dart` (`_contentOf`,
    `_trimmedOrNull`);
  - `lib/features/deck/data/repositories/deck_repository_impl.dart`
    (lines with `name: name.trim()` ×2, `_dao.rename(deckId, name.trim(), at)`);
  - `lib/features/tags/data/repositories/tag_repository_impl.dart`
    (`renameTag`'s `name.trim()`, `_planRename`'s
    `name.trim() == source.name`, `_createTag`'s `name.trim()`).
- Test:
  - `test/features/card/data/card_repository_impl_test.dart`;
  - `test/features/deck/data/deck_repository_impl_test.dart`;
  - `test/features/tags/data/tag_repository_impl_test.dart`;
  - `test/features/card/data/card_transfer_test.dart`;
  - `test/features/search/data/search_cards_test.dart`.

**Interfaces — Consumes:** `storedText`, `storedTextOrNull` and `foldText`
(Task 1).

- [ ] **Step 1: Write the failing tests.** Each goes into its file's `main`
  and uses that file's setup.

  In `tag_repository_impl_test.dart`, inside `group('attachByName', …)`:

  ```dart
    test('a name typed decomposed reuses the tag stored precomposed, and a '
        'new tag is stored in NFC (BE-C5)', () async {
      await _cards(db, ['c1', 'c2']);
      await tags.attachByName(cardIds: {'c1'}, name: 'Công việc');

      await tags.attachByName(cardIds: {'c2'}, name: 'công việc');

      expect(await _count(db, 'tags'), 1);
      expect(await _tagNamesOf(db, 'c1'), ['Công việc']);
      expect(await _tagNamesOf(db, 'c2'), ['Công việc']);
    });
  ```

  In `deck_repository_impl_test.dart` (use its repository variable, which is
  `decks` in the other tests):

  ```dart
    test('a deck name is stored in NFC on create and rename (BE-C5)', () async {
      final root = await decks.root('Tiếng Việt');
      expect(root.name, 'Tiếng Việt');
      await decks.rename(deckId: root.id, name: ' 밥 ');
      final row = await db
          .customSelect('SELECT name FROM deck WHERE id = ?',
              variables: [Variable(root.id)])
          .getSingle();
      expect(row.read<String>('name'), '밥');
    });
  ```

  Adapt `decks.rename(...)` to that repository's rename method as its other
  tests call it. Add `import 'package:drift/drift.dart' show Variable;` if it
  is missing.

  In `card_repository_impl_test.dart`, using the file's card repository
  (create path):

  ```dart
    test('a card is stored in NFC with its folded faces, optional fields '
        'too (BE-C5)', () async {
      final created = await cards.card(
        leafId,
        const CardDraft(
          front: 'công',
          back: '밥',
          example: ' vị̂c ',
        ),
      );
      final id = (created as Ok).value.id as String;
      final row = await db
          .customSelect(
            'SELECT front, back, front_folded, back_folded, example FROM card '
            'WHERE id = ?',
            variables: [Variable(id)],
          )
          .getSingle();
      expect(row.data, {
        'front': 'công',
        'back': '밥',
        'front_folded': 'công',
        'back_folded': '밥',
        'example': 'việc',
      });
    });
  ```

  Match the file's names for the repository, the leaf deck id and how it
  reads a created card's id.

  In `card_transfer_test.dart`, next to the duplicates test:

  ```dart
    test('a draft written in the other Unicode form is a duplicate (BE-C5, '
        'BR-TRANSFER-003)', () async {
      await CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: _now),
        TagRepositoryImpl(db, now: _now),
        now: _now,
      ).card(leaf.id, const CardDraft(front: 'công', back: 'work'));

      final result = _ok(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [CardDraft(front: 'công', back: 'work')],
          includeDuplicates: false,
        ),
      );

      expect((result.written, result.skippedDuplicates), (0, 1));
    });
  ```

  In `search_cards_test.dart`:

  ```dart
    test('a term typed decomposed finds a card written precomposed, and '
        'Hangul typed as jamo finds its syllable (BE-C5)', () async {
      final repo = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: () => now),
        tags,
        now: () => now,
      );
      final cong = await repo.card(
        lessonId,
        const CardDraft(front: 'công', back: 'work'),
      );
      final bab = await repo.card(
        lessonId,
        const CardDraft(front: '밥', back: 'rice'),
      );

      expect(
        ids(await read(foldText('CÔNG'))),
        [(cong as Ok).value.id],
      );
      expect(
        ids(await read(foldText('밥'))),
        [(bab as Ok).value.id],
      );
    });
  ```

  Import `package:memox/core/text/folded_text.dart`, and match how the file
  reads a created card's id.

- [ ] **Step 2: Run them.**

  Run:
  `flutter test test/features/tags/data test/features/deck/data test/features/card/data test/features/search/data`

  Expected: the new tests FAIL, because names and faces are stored
  decomposed. The fold-based tests (tag reuse, import duplicate, search)
  already pass through Task 1's `foldText`, except where the stored form is
  compared.

  Ledger which tests failed, and a `Ruling:` line for any that already
  passed.

- [ ] **Step 3: Implement.**

  `card_dao.dart`:

  ```dart
  /// The columns a draft sets: sides in their stored form (trimmed, NFC) with
  /// their folded forms computed in Dart (schema.md), blank optional fields
  /// stored as null (BE-C5).
  CardCompanion _contentOf(CardDraft draft) => CardCompanion(
    front: Value(storedText(draft.front)),
    back: Value(storedText(draft.back)),
    frontFolded: Value(foldText(draft.front)),
    backFolded: Value(foldText(draft.back)),
    example: Value(storedTextOrNull(draft.example)),
    hint: Value(storedTextOrNull(draft.hint)),
    pronunciation: Value(storedTextOrNull(draft.pronunciation)),
    isFlagged: Value(draft.isFlagged ? 1 : 0),
  );
  ```

  Delete `_trimmedOrNull`, which has no caller left.

  `deck_repository_impl.dart`: each `name.trim()` becomes
  `storedText(name)`.

  `tag_repository_impl.dart`:
  - in `renameTag` and `_createTag`, each `name: name.trim()` becomes
    `name: storedText(name)`;
  - in `_planRename`, the check becomes
    `if (storedText(name) == source.name) return const Ok(TagRenameUnchanged());`.

  Add `import 'package:memox/core/text/stored_text.dart';` to the three
  files.

- [ ] **Step 4: Run.**

  Run:
  `flutter test test/features/tags test/features/deck test/features/card test/features/search test/features/transfer test/features/starter_decks`

  Expected: PASS.

- [ ] **Step 5: Commit.**

  `feat(data): every write of user text stores NFC (BE-C5 G1)`

---

### Task 3: Fill judges under comparison version 2

**Files:**
- Modify: `lib/features/study_mode/domain/models/fill_mode.dart`
- Test:
  - `test/features/study_mode/domain/turn_judging_test.dart` (the 4 fill
    verdicts);
  - `test/features/study/data/recall_fill_turns_test.dart` (line with
    `comparison_version'), 1`).

**Interfaces — Consumes:** `foldText` (Task 1).

- [ ] **Step 1: Write the failing tests.**

  In `turn_judging_test.dart`:
  - replace `comparisonVersion: 1` in the four fill verdicts with
    `comparisonVersion: 2`;
  - add this test inside `group('fill', …)`:

  ```dart
    test('a term typed in the other Unicode form is right, under comparison '
        'version 2 (BE-C5, BR-STUDY-027)', () {
      expect(
        _judge(StudyMode.fill, const FillAnswer('công')),
        _verdict(
          action: EightBoxAction.remembered,
          isCorrect: true,
          comparisonVersion: 2,
          usedHint: false,
        ),
      );
    });
  ```

  The file's `_context()` must give the card `frontFolded: 'công'` in
  precomposed form, as the existing test with `'  cÔnG  '` shows. Check its
  literal: if it is precomposed, nothing else changes.

  In `recall_fill_turns_test.dart`, the expectation
  `log.read<int>('comparison_version'), 1` becomes `2`.

- [ ] **Step 2: Run.**

  Run:
  `flutter test test/features/study_mode/domain/turn_judging_test.dart test/features/study/data/recall_fill_turns_test.dart`

  Expected: FAIL on version 1 ≠ 2. The new form test already passes through
  Task 1's `foldText`; ledger that it is pinned rather than red.

- [ ] **Step 3: Implement** in `fill_mode.dart`:

  ```dart
  /// The comparison policy a `fill` turn is judged by, stored on the turn: the
  /// typed term folded (trimmed, NFC, lower-cased, accents kept) against
  /// `front_folded`. Version 2 added NFC (BE-C5); version 1 had no Unicode
  /// normalisation. A change to the policy raises it and never touches the
  /// turns already recorded (BR-STUDY-026, BR-STUDY-027).
  const fillComparisonVersion = 2;
  ```

- [ ] **Step 4: Run.**

  Run: `flutter test test/features/study_mode test/features/study test/features/srs`

  Expected: PASS. The `record_turn_test` literal `1` is a turn it builds
  itself and stays.

- [ ] **Step 5: Commit.**

  `feat(study-mode): fill comparison version 2 — NFC (BE-C5 G1, BR-STUDY-027)`

---

### Task 4: Migration v3 → v4 — the store in NFC

**Files:**
- Create: `lib/core/database/migrations/nfc_text_migration.dart`
- Modify: `lib/core/database/app_database.dart`
- Generate:
  - `drift_schemas/drift_schema_v4.json`;
  - `lib/core/database/schema_versions.dart`;
  - `test/drift/generated/schema.dart` and `schema_v4.dart`.
- Test: `test/drift/migration_test.dart`

**Interfaces — Produces:**
`Future<void> normalizeStoredText(DatabaseConnectionUser db)`. It uses only
`db.customSelect` and `db.customStatement`, with raw SQL.

- [ ] **Step 1: Bump the version and generate the snapshot.**

  In `app_database.dart`, `schemaVersion` becomes 4, and `stepByStep` gains
  a `from3To4` that is empty for now: `from3To4: (m, schema) async {},`.

  Run:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
  dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
  dart run drift_dev schema generate drift_schemas/ test/drift/generated/
  ```

  Expected: `drift_schema_v4.json` exists. Its tables equal v3's
  (`diff <(jq -S .entities drift_schemas/drift_schema_v3.json) <(jq -S .entities drift_schemas/drift_schema_v4.json)`
  prints nothing), and `schema_versions.dart` has `from3To4`.

- [ ] **Step 2: Update the existing tests.**

  In `migration_test.dart`, every `migrateAndValidate(db, 3)` becomes `4`,
  and the three schema test names say "v4". Add:

  ```dart
  test('v3 upgrades to the schema of v4', () async {
    final db = AppDatabase(await verifier.startAt(3));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);
  });
  ```

  Run: `flutter test test/drift/migration_test.dart`

  Expected: PASS. The v1 and v2 row tests keep every value, because their
  text is already NFC.

- [ ] **Step 3: Write the failing data tests.** Append this group to
  `migration_test.dart`:

  ```dart
  group('a v3 database with text in mixed Unicode forms (BE-C5)', () {
    late AppDatabase db;
    late Map<String, Object?> untouchedCard;

    setUp(() async {
      final schema = await verifier.schemaAt(3);
      final raw = schema.rawDatabase;
      for (final statement in [
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('R', 'Tiếng Việt', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('L', 'Bài 1', 'R', 'R', 2, 'card', 0, 0, 0)",
        "INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, example, hint, pronunciation, created_at, updated_at) VALUES "
            "('d', 'L', 'Công', '밥', 'công', '밥', 'việc', NULL, NULL, 1, 1), "
            "('n', 'L', 'công', 'work', 'công', 'work', NULL, NULL, NULL, 2, 2)",
        // Three tags that are one name once in NFC; 't-old' is the oldest.
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES "
            "('t-old', 'Công việc', 'công việc', 10), "
            "('t-mid', 'Công việc', 'công việc', 20), "
            "('t-new', 'CÔNG VIỆC', 'công việc ', 30), "
            "('t-solo', 'Hàn', 'hàn', 40)",
        // 'd' carries two of the colliding tags; 'n' carries the newest only.
        "INSERT INTO card_tags (card_id, tag_id) VALUES ('d', 't-old'), ('d', 't-mid'), ('n', 't-new'), ('n', 't-solo')",
      ]) {
        raw.execute(statement);
      }
      untouchedCard = raw.select("SELECT * FROM card WHERE id = 'n'").single;
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);
    });
    tearDown(() => db.close());

    Future<List<Map<String, Object?>>> rows(String sql) async => [
      for (final row in await db.customSelect(sql).get()) row.data,
    ];

    test('user text is stored in NFC and the folded columns are recomputed',
        () async {
      expect(await rows("SELECT name FROM deck WHERE id = 'R'"), [
        {'name': 'Tiếng Việt'},
      ]);
      expect(
        await rows(
          "SELECT front, back, front_folded, back_folded, example FROM card WHERE id = 'd'",
        ),
        [
          {
            'front': 'Công',
            'back': '밥',
            'front_folded': 'công',
            'back_folded': '밥',
            'example': 'việc',
          },
        ],
      );
      expect(await rows("SELECT name, name_folded FROM tags WHERE id = 't-solo'"), [
        {'name': 'Hàn', 'name_folded': 'hàn'},
      ]);
    });

    test('a row already in NFC is not written, updated_at included', () async {
      expect((await rows("SELECT * FROM card WHERE id = 'n'")).single, untouchedCard);
    });

    test('colliding tags merge into the oldest, keeping every card link once',
        () async {
      expect(await rows('SELECT id, name, name_folded FROM tags ORDER BY id'), [
        {'id': 't-old', 'name': 'Công việc', 'name_folded': 'công việc'},
        {'id': 't-solo', 'name': 'Hàn', 'name_folded': 'hàn'},
      ]);
      expect(
        await rows('SELECT card_id, tag_id FROM card_tags ORDER BY card_id, tag_id'),
        [
          {'card_id': 'd', 'tag_id': 't-old'},
          {'card_id': 'n', 'tag_id': 't-old'},
          {'card_id': 'n', 'tag_id': 't-solo'},
        ],
      );
    });

    test('passes the integrity and foreign key checks', () async {
      final integrity = await db.customSelect('PRAGMA integrity_check').get();
      expect([for (final row in integrity) row.data.values.single], ['ok']);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });

  test('two tags whose folded values swap do not trip the unique index '
      '(BE-C5)', () async {
    final schema = await verifier.schemaAt(3);
    // 'a' re-folds to 'b''s stored value, and 'b' re-folds to another.
    schema.rawDatabase.execute(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES "
      "('a', 'É', 'x', 1), ('b', 'X', 'é', 2)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);

    final tags = await db.customSelect('SELECT id, name_folded FROM tags ORDER BY id').get();
    expect([for (final row in tags) row.data], [
      {'id': 'a', 'name_folded': 'é'},
      {'id': 'b', 'name_folded': 'x'},
    ]);
  });
  ```

  The `'t-new'` folded value carries a trailing space on purpose. It is a
  stale fold, and re-folding from `name` fixes it.

  Run: `flutter test test/drift/migration_test.dart`

  Expected: the new group FAILS, because the step is empty.

- [ ] **Step 4: Implement the step.**

  `lib/core/database/migrations/nfc_text_migration.dart`:

  ```dart
  import 'package:drift/drift.dart';
  import 'package:memox/core/text/folded_text.dart';
  import 'package:memox/core/text/stored_text.dart';

  // Migration v3 → v4 (BE-C5, spec 2026-09-27 local backend §4). Released
  // once, then never changed. Raw SQL only: a step never calls application
  // queries (flutter-drift migrations.md).

  /// Puts every user text in its stored form (trimmed, NFC), recomputes the
  /// folded columns from it, and merges tags that become one name. A row
  /// already in that form is not written.
  Future<void> normalizeStoredText(DatabaseConnectionUser db) async {
    await _normalizeDecks(db);
    await _normalizeCards(db);
    await _normalizeTags(db);
  }

  Future<void> _normalizeDecks(DatabaseConnectionUser db) async {
    for (final row in await db.customSelect('SELECT id, name FROM deck').get()) {
      final name = row.read<String>('name');
      final stored = storedText(name);
      if (stored == name) continue;
      await db.customStatement('UPDATE deck SET name = ? WHERE id = ?', [
        stored,
        row.read<String>('id'),
      ]);
    }
  }

  Future<void> _normalizeCards(DatabaseConnectionUser db) async {
    final cards = await db
        .customSelect(
          'SELECT id, front, back, front_folded, back_folded, example, hint, '
          'pronunciation FROM card',
        )
        .get();
    for (final row in cards) {
      final before = [
        row.read<String>('front'),
        row.read<String>('back'),
        row.read<String>('front_folded'),
        row.read<String>('back_folded'),
        row.readNullable<String>('example'),
        row.readNullable<String>('hint'),
        row.readNullable<String>('pronunciation'),
      ];
      final after = [
        storedText(before[0]!),
        storedText(before[1]!),
        foldText(before[0]!),
        foldText(before[1]!),
        storedTextOrNull(before[4]),
        storedTextOrNull(before[5]),
        storedTextOrNull(before[6]),
      ];
      if (_same(before, after)) continue;
      await db.customStatement(
        'UPDATE card SET front = ?, back = ?, front_folded = ?, '
        'back_folded = ?, example = ?, hint = ?, pronunciation = ? '
        'WHERE id = ?',
        [...after, row.read<String>('id')],
      );
    }
  }

  /// Tags group by owner and new folded name. The oldest of a group (by
  /// `created_at`, then `id`) keeps its id and takes every link of the
  /// others, which are then deleted: the semantics of a rename that merges
  /// (BR-TAG-005, BE-B2). The folded values change in two phases, so no
  /// intermediate state trips the unique index.
  Future<void> _normalizeTags(DatabaseConnectionUser db) async {
    final tags = await db
        .customSelect(
          'SELECT id, name, name_folded, owner_id FROM tags '
          'ORDER BY created_at, id',
        )
        .get();
    final keptByKey = <String, String>{};
    final updates = <String, ({String name, String folded})>{};
    for (final row in tags) {
      final id = row.read<String>('id');
      final name = row.read<String>('name');
      final folded = foldText(name);
      final key = '${row.readNullable<String>('owner_id') ?? ''}\u0000$folded';
      final kept = keptByKey[key];
      if (kept != null) {
        await db.customStatement(
          'INSERT OR IGNORE INTO card_tags (card_id, tag_id) '
          'SELECT card_id, ? FROM card_tags WHERE tag_id = ?',
          [kept, id],
        );
        await db.customStatement('DELETE FROM tags WHERE id = ?', [id]);
        continue;
      }
      keptByKey[key] = id;
      final stored = storedText(name);
      if (stored != name || folded != row.read<String>('name_folded')) {
        updates[id] = (name: stored, folded: folded);
      }
    }
    // Phase 1: move every changing folded value out of the way.
    for (final id in updates.keys) {
      await db.customStatement(
        "UPDATE tags SET name_folded = char(0) || id WHERE id = ?",
        [id],
      );
    }
    // Phase 2: set the final values, now unique by construction.
    for (final MapEntry(key: id, value: (:name, :folded)) in updates.entries) {
      await db.customStatement(
        'UPDATE tags SET name = ?, name_folded = ? WHERE id = ?',
        [name, folded, id],
      );
    }
  }

  bool _same(List<String?> a, List<String?> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  ```

  Check the BR id named in the tag comment against
  `docs/features/tags/rules/` (the merge rule of BE-B2), and correct it if it
  differs. Deleting the tag cascades its own `card_tags` rows (`ON DELETE
  CASCADE`).

  In `app_database.dart`:

  ```dart
        from3To4: (m, schema) async {
          // G1 (BE-C5): user text in NFC, folded columns recomputed, tags
          // that become one name merged; no structure changes (local backend
          // spec 2026-09-27 §4).
          await normalizeStoredText(this);
        },
  ```

  plus `import 'package:memox/core/database/migrations/nfc_text_migration.dart';`.

- [ ] **Step 5: Run.**

  Run: `flutter test test/drift test/database`

  Expected: PASS, both the new group and every earlier test.

- [ ] **Step 6: Commit.**

  `feat(db): migration v3 → v4 — the store in NFC, colliding tags merged (BE-C5 G1)`

---

### Task 5: Records and the gate

**Files:**
- `docs/shared/data/schema.md`: lines 185–186 (`front_folded`,
  `back_folded`) and 243 (`name_folded`).
- `docs/features/tags/rules/BR-TAG-001-*.md`: the Rule paragraph.
- `docs/superpowers/specs/2026-09-27-server-sync-design.md`: §8.
- `docs/wbs_BE.md`.

- [ ] **Step 1: Edit.**
  - **`schema.md`:**
    - `front_folded`: "`front` đã trim, chuẩn hoá NFC rồi hạ hoa bằng Dart
      (`foldText`, BE-C5). Search so trên cột này".
    - `name_folded`: "`foldText(name)`: trim, NFC, hạ hoa (BE-C5). Cột để
      **cưỡng chế** unique".
    - Add one sentence after the paragraph that starts "**Hai cột
      `_folded`…**": "Mọi text người dùng lưu ở dạng NFC (`storedText`), và
      migration v3 → v4 đưa dữ liệu cũ về dạng đó (BE-C5)."
  - **BR-TAG-001:** "…và MUST là duy nhất không phân biệt hoa thường" becomes
    "…và MUST là duy nhất không phân biệt hoa thường hay dạng Unicode (so
    trên dạng NFC)".
  - **Sync spec §8:** add a bullet: "Text pushed is already NFC: migration
    v3 → v4 and every write normalise it (BE-C5), so the server compares
    strings as stored."
  - **`wbs_BE.md`:**
    - BE-C5 → `xong`, with this plan as evidence, and next step "—";
    - remove its row from "Điểm chặn";
    - add an update-log line for 2026-09-27;
    - the blockers table loses the BE-C5 row.
- [ ] **Step 2: Run the docs check.**

  Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`

  Expected: PASS, 0 errors.
- [ ] **Step 3: Run the gate.**

  Run: `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh`,
  then `TZ=UTC flutter test --tags golden`.

  Expected: both green.
- [ ] **Step 4: Commit.**

  `docs(be): BE-C5 done — schema.md, BR-TAG-001, sync spec §8, WBS (G1)`
