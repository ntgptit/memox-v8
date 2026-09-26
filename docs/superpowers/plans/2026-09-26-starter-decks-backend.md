# MemoX V8 Starter Decks Backend Implementation Plan (package 10)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-B4 of [`docs/wbs_BE.md`](../../wbs_BE.md), the store side of the
Starter library (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010), as domain, data and
use-case code in a new `starter_decks` feature, two bundled fixture templates and one
optional parameter on the deck contract, so FE-B4 can build screen 03 on two use cases.

**Architecture:** A new feature, `lib/features/starter_decks` (domain, data, di), that
imports the domain of `deck`, `card` and `srs`. Templates are JSON assets listed by
`assets/templates/manifest.json`: `TemplateAssetDataSource` reads them through an
`AssetBundle`, and `starterTemplateOf` leaves out every template a copy could not write
(spec D6). `StarterLibraryRepositoryImpl.watchLibrary` joins the templates, read once, with
the copies outside the Trash, and reads again after every write to `deck`.
`addStarterDeck` opens one transaction, checks "in library" inside it, and writes the tree
through `DeckRepository.createRootDeck` (which now records the source template),
`createSubDeck` and `CardRepository.createCard`, whose own transactions join it; a refusal
inside it throws, and everything rolls back. No schema change.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `drift` 2.35, `flutter_riverpod` 3 with
`riverpod_generator`, Flutter's `AssetBundle`. No dependency is added; the one generated
output a task needs is the new provider's (`build_runner`, Task 4).

**Spec:**
[`docs/superpowers/specs/2026-09-26-starter-decks-backend-design.md`](../specs/2026-09-26-starter-decks-backend-design.md),
approved 2026-09-26 and amended the same day to name the result of a copy
`AddedStarterDeck` (Clarification 1). Business rules:
`docs/features/starter-decks/rules/` (BR-STARTER-001…BR-STARTER-010); use case:
`docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md`;
data model: [`shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `claude/be-starter-decks` holds the spec (`0ec9aec`), its approval
(`83b3068`), its amendment (`f7066c4`) and this plan, on `master` at `047fa2c`
(#74). The plan runs on that branch, from this plan's commit; the gate passes there
with 1795 tests. Generated code is not committed: in a fresh working tree, run
`flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first (root `README.md`,
"Commands").

**How this plan was checked:** every code block below was written and run first, in
a scratch copy of the repository, task by task, test first. Each task's tests failed
as its "Expected" line says, then passed, and after every task the gate passed. Each
rule the tests pin was also broken on purpose in the scratch copy, one at a time: in
Task 1, the source template not written; the version not written; in Task 2, a blank
field taken; a version below 1 taken; an unknown scheduler taken as eight boxes; a
title the deck rules refuse taken; cards at the top level taken; a tree one level
deeper taken; a deck with sub-decks and cards taken; a deck with neither read as an
empty deck; an empty list of decks taken; a deck name the deck rules refuse taken; a
card the card rules refuse taken; an empty list of cards taken; in Task 3, templates
sorted by id, not manifest order; a repeated id kept; a missing file that stops the
load; a malformed file that stops the load; a manifest whose list is not a list
read; the fixtures not bundled; in Task 4, the in-library check outside the
transaction; a copy in the Trash in the library, for the add; a copy of another
version in the library, for the add; no second copy, ever; the root without its
template; the template's scheduler, not the chosen one; sub-decks written flat; a
card refusal ignored; a pronunciation left behind; an example left behind; a wrong
card count; an unknown id added as the first template; a sub-deck one level short of
the limit refused; in Task 5, the library read once; a copy in the Trash in the
library, for the watch; the version ignored by the watch; a copy known by its name;
the counts swapped; a database error left unmapped; in Task 6, the second copy not
passed on; the scheduler not passed on. That is 41 breaks. Every break compiled and
failed at least one test. After the first pass, the four tests of the Review Focus
below were added to their tasks; all four passed on the code as it stood. This
document was then applied, step by step as written, onto a clean checkout of this
plan's commit: each task's files matched the scratch commit's, no other file moved,
and the outputs and counts below are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: no screen, no route, no copy text, no provider but the repository's.
  Screen 03, the first-launch route and the Study Home CTA are FE-B4's (spec §12).
- No schema change, no migration, no dependency (D1). The package adds assets under
  `assets/templates/` and declares them in `pubspec.yaml`.
- `starter_decks` imports the domain of `deck`, `card` and `srs` and nothing else of
  another feature: the import map gains `'starter_decks': {'deck', 'card', 'srs'}` (D2,
  ADR-011). Its domain is pure Dart; `data/` touches Flutter (`AssetBundle`) and drift,
  and `di/` passes `rootBundle`.
- Every table is written by the feature that owns it: the copy goes through
  `DeckRepository.createRootDeck`, `DeckRepository.createSubDeck` and
  `CardRepository.createCard`, inside one transaction the starter repository opens (D2).
  Transactions stay in the data layer (guard `no_transaction_outside_data_layer`).
- `createRootDeck` takes an optional `DeckSourceTemplate`, written on the root only; a
  deck made by hand keeps both source columns NULL (D3).
- A template is read by spec §5: the manifest, then each listed file, once per
  repository, through the `AssetBundle` it is given. A template that breaks D6 is left
  out, the others stay, and reading never throws for content (D4, D6, §5.3).
- "In library" is a root outside the Trash with the template's
  `(source_template_id, source_template_version)` (D7). The add checks it inside its
  transaction; a copy there and no `allowSecondCopy` writes nothing (D8).
- `enum StarterRejection { templateNotFound, alreadyInLibrary }`, in that order (D11). A
  refusal from the deck or card repository inside the copy throws, the transaction rolls
  back, and the caller gets a `Failure` (D10).
- The library is a watch over `tableChanges(db, [deck])`: the copies in one statement a
  firing; a database error reaches the stream as its `Failure` (D12, §6).
- No filtering by `locale` (D13); card order inside a sub-deck is not kept (D9, §12).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing `call`
  (AD-12).
- Every statement on `card` or `deck` filters `delete_batch_id` (BR-TRASH-002);
  `tombstone_filter_test.dart` checks the SQL text.
- No file name holds "copy": the guard's `common.no_temp_file_name` fails the gate on it
  (Clarification 1).
- After every task the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. It runs the host suite with
  `TZ=UTC` and `--exclude-tags golden`. Its generated-code check asks every source under
  `lib/` to be in git, so each task stages its files, runs the gate, then commits.
- Docs and code change in the same commit (`docs/README.md`). A task whose tests name a
  use case id runs `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- The contract documents change only as spec §11 says, with the two WBS counts of
  Clarification 7.
- Code, identifiers, test names and commit messages are in English; `docs/` keeps its
  Vietnamese. Every commit message ends with the session's attribution trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan. Each is decided
here and implemented as described; say so if one is wrong.

1. **The result of a copy is `AddedStarterDeck`** (Task 4; spec §4, §7, §9). The spec
   first named it `StarterCopy` in `starter_copy_model.dart`; the guard's
   `common.no_temp_file_name` fails the gate on any file name holding "copy", so the spec
   was amended (`f7066c4`) to `AddedStarterDeck` in `added_starter_deck_model.dart`, and
   the test of the copy is `add_starter_deck_test.dart`. Nothing else changed.
2. **The repository takes the templates as a loader** (Tasks 4 and 5; spec §5.3).
   `StarterLibraryRepositoryImpl(db, decks, cards, templates: …)` calls the loader on
   first use and keeps its future for its lifetime; the provider passes
   `TemplateAssetDataSource(rootBundle).load`, and the tests pass the templates they
   build.
3. **A refusal inside the copy leaves as `UnknownDatabaseFailure`** (Task 4; D10).
   `_written` throws a `StateError` naming the reason; `mapDatabaseError` turns it into
   `UnknownDatabaseFailure`, as it does any error that is not SQLite's. FE-B4 shows
   `addFailed` for any `Failure`.
4. **Where "in library" is read** (Tasks 4 and 5; D7, D8, §6). `StarterDao.hasCopy`
   reads one row (`LIMIT 1`) inside the add's transaction; `StarterDao.copies` reads the
   `(id, version)` pairs of every copy outside the Trash in one statement for the watch.
   Only a root carries the source columns (D3), so neither filters on `parent_id`.
5. **The mapper checks the title as a deck name** (Task 2; D6, D9). The copy's root takes
   the title, so a title that `DeckEntity.checkName` refuses leaves the template out, as a
   bad deck name does. `defaultScheduler` in a file is `suggestedScheduler` in the model
   and the entry (spec §5.1, §9); keys the spec does not name are ignored.
6. **The fixture content** (Task 3; D5, §5.2). Written for this package and small enough
   to read line by line in the pull request (spec §13): Everyday is four sub-decks of ten
   English words with their Vietnamese meaning. Hangul basics is the fourteen basic
   consonants, each with its Revised Romanization at the start of a syllable and its name
   as `hint` (`기역 (giyeok)`), then the ten basic vowels. ㄱ, ㄷ, ㄹ and ㅂ also carry the
   spelling the romanization gives them elsewhere (`g / k`), and ㅇ says it is silent at
   the start; the final `t` of ㅅ, ㅈ, ㅊ and ㅎ is left out of these basics.
7. **Two WBS counts that no longer held** (Task 6). `wbs_BE.md` counted tests naming
   18 of 22 UC ids and said Given/When/Then was missing from every UC; since #72,
   UC-TRANSFER-001 and UC-TRANSFER-002 have code, tests and acceptance criteria. With
   UC-STARTER-001, the tests name 21 of 22 (UC-REMINDER-001 has no code yet), and 19 UC
   lack Given/When/Then.
8. **Card order is never asserted** (Tasks 4 and 5; D9). The tests pass one clock to
   every repository, so the cards of a copy share their `created_at`, and their order
   falls to their UUIDs; the tests order rows by name or front.
9. **The plan's date.** The plan is written on 2026-09-26, the spec's day.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person, beyond
what spec §10 already lists, each pinned by a test in the task that owns the code:

1. **A double tap on "Add to library"**: two adds of one template at once make one copy,
   and the other says `alreadyInLibrary` (D8) — Task 4, "two adds at once, as a double
   tap sends them, make one copy".
2. **The deepest template the library lists**: ten levels with the root, cards on the
   tenth. The mapper lets it through (Task 2), so the copy must write it whole, and not
   fail on the depth rule of `createSubDeck` — Task 4, "the deepest template the library
   lists copies whole".
3. **A card with every optional field**: its example, hint and pronunciation reach the
   copy, not only its two sides — Task 4, "a copy is an ordinary deck tree of its own",
   which now reads all five fields.
4. **A copy its owner renamed**: still in the library, since a template is known by its id
   and version (D7), so screen 03 keeps its "In library" badge and offers "Add another
   copy" — Task 5, "a copy its owner renamed is still in the library".

The other inputs that could bite — a copy in the Trash, a restored one, a new version, a
broken manifest or file, a failure half-way, a stale entry — are spec §10's, and their
tests are in Tasks 3–5.

## File Structure

```
lib/features/deck/
├── domain/models/deck_source_template_model.dart   DeckSourceTemplate (1)
├── domain/repositories/deck_repository.dart        createRootDeck(sourceTemplate:) (1)
└── data/repositories/deck_repository_impl.dart     the two source columns (1)

lib/features/starter_decks/                          (new)
├── domain/
│   ├── models/starter_template_model.dart           StarterTemplate, StarterDeck,
│   │                                                StarterCard (2)
│   ├── failures/starter_failure.dart                StarterRejection (4)
│   ├── models/added_starter_deck_model.dart         AddedStarterDeck (4)
│   ├── models/starter_library_entry_model.dart      StarterLibraryEntry (5)
│   ├── repositories/starter_library_repository.dart addStarterDeck (4); watchLibrary (5)
│   └── usecases/                                    watch_starter_library,
│                                                    add_starter_deck (6)
├── data/
│   ├── mappers/starter_template_mapper.dart         starterTemplateOf, the D6 checks (2)
│   ├── datasources/template_asset_data_source.dart  TemplateAssetDataSource (3)
│   ├── datasources/starter_dao.dart                 hasCopy (4); copyChanges, copies (5)
│   └── repositories/starter_library_repository_impl.dart   (4, 5)
└── di/starter_library_repository_provider.dart      starterLibraryRepositoryProvider (4)

assets/templates/manifest.json, en/everyday_en_vi.json, en/hangul_basics.json (3)
pubspec.yaml                                         assets/templates/ and en/ (3)

test/architecture/boundary_rules.dart                'starter_decks': {'deck', 'card', 'srs'} (2)
test/features/deck/…                                 the source columns (1), and the two
                                                     fakes of DeckRepository (1)
test/features/starter_decks/data/                    starter_template_mapper_test (2),
                                                     template_asset_data_source_test,
                                                     starter_fixtures_test (3),
                                                     add_starter_deck_test (4),
                                                     watch_starter_library_test (5)
test/features/starter_decks/domain/                  starter_library_use_cases_test (6)
```

Other changed files: `docs/_generated/` where a task's tests name a use case id (Tasks
3–6), and in Task 6 UC-STARTER-001, the starter-decks README and `data.md`, `wbs_BE.md`
and `wbs_FE.md`.

---


### Task 1: A root deck records the starter template it was copied from

**Files:**
- Create: `lib/features/deck/domain/models/deck_source_template_model.dart`
- Modify: `lib/features/deck/data/repositories/deck_repository_impl.dart`, `lib/features/deck/domain/repositories/deck_repository.dart`
- Test (modify): `test/features/deck/data/deck_repository_impl_test.dart`, `test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`

**Interfaces:**
- Consumes: `DeckRepositoryImpl.createRootDeck` as it stands; the `deck` table's
  `source_template_id` and `source_template_version` columns (schema.md).
- Produces:
  - `final class DeckSourceTemplate { const DeckSourceTemplate({required String templateId, required int version}); }`
    (`deck/domain/models/deck_source_template_model.dart`).
  - `Future<Outcome<DeckEntity, DeckRejection>> DeckRepository.createRootDeck({required String name, required SchedulerType schedulerType, DeckSourceTemplate? sourceTemplate, DateTime? now})`.

Spec D3. The contract change touches the two fakes of `DeckRepository` in the
create-root-deck dialog's widget test.

- [ ] **Step 1: Write the failing tests**

In `test/features/deck/data/deck_repository_impl_test.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_source_template_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart
    },
  );

  test('createRootDeck rejects a blank name and writes nothing', () async {
```

with

```dart
    },
  );

  test('createRootDeck records the starter template a root is copied from, and '
      'nothing for a deck made by hand (BR-STARTER-004)', () async {
    final copy = ((await repo.createRootDeck(
      name: 'Everyday',
      schedulerType: SchedulerType.eightBox,
      sourceTemplate: const DeckSourceTemplate(
        templateId: 'fixture.everyday-en-vi',
        version: 2,
      ),
    )) as Ok<DeckEntity, DeckRejection>).value;
    final own = ((await repo.createRootDeck(
      name: 'Mine',
      schedulerType: SchedulerType.sm2,
    )) as Ok<DeckEntity, DeckRejection>).value;

    Future<(String?, int?)> sourceOf(String id) async {
      final row = await db
          .customSelect(
            'SELECT source_template_id, source_template_version FROM deck '
            'WHERE id = ?',
            variables: [Variable.withString(id)],
          )
          .getSingle();
      return (
        row.read<String?>('source_template_id'),
        row.read<int?>('source_template_version'),
      );
    }

    expect(await sourceOf(copy.id), ('fixture.everyday-en-vi', 2));
    expect(await sourceOf(own.id), (null, null));
  });

  test('createRootDeck rejects a blank name and writes nothing', () async {
```

In `test/features/deck/presentation/create_root_deck_dialog_widget_test.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
```

with

```dart
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_source_template_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
```

Replace

```dart
    required String name,
    required SchedulerType schedulerType,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
```

with

```dart
    required String name,
    required SchedulerType schedulerType,
    DeckSourceTemplate? sourceTemplate,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
```

Replace

```dart
    required String name,
    required SchedulerType schedulerType,
    DateTime? now,
  }) async {
```

with

```dart
    required String name,
    required SchedulerType schedulerType,
    DeckSourceTemplate? sourceTemplate,
    DateTime? now,
  }) async {
```

Replace

```dart
      schedulerType: schedulerType,
      now: now,
```

with

```dart
      schedulerType: schedulerType,
      sourceTemplate: sourceTemplate,
      now: now,
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/deck/data/deck_repository_impl_test.dart \
  test/features/deck/presentation/create_root_deck_dialog_widget_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: Error when reading 'lib/features/deck/domain/models/deck_source_template_model.dart': No such file or directory`,
then `Error: No named parameter with the name 'sourceTemplate'.` and, for the two fakes
of the widget test, `Error: Type 'DeckSourceTemplate' not found.` The tool may then print `Error: The Dart compiler exited unexpectedly.`
and a stack trace; the run still ends as above.

- [ ] **Step 3: Name the template a deck was copied from**

Create `lib/features/deck/domain/models/deck_source_template_model.dart`:

```dart
/// The starter template a root deck was copied from (BR-STARTER-004): its
/// stable id and its version at the time of the copy.
final class DeckSourceTemplate {
  const DeckSourceTemplate({required this.templateId, required this.version});

  final String templateId;
  final int version;
}
```

- [ ] **Step 4: Take it on createRootDeck and write its two columns**

In `lib/features/deck/domain/repositories/deck_repository.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/models/deck_source_template_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
```

Replace

```dart
abstract interface class DeckRepository {
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
```

with

```dart
abstract interface class DeckRepository {
  /// A [sourceTemplate] marks the root as a starter template's copy
  /// (BR-STARTER-004); a deck made by hand has none.
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
```

Replace

```dart
    required SchedulerType schedulerType,
    DateTime? now,
```

with

```dart
    required SchedulerType schedulerType,
    DeckSourceTemplate? sourceTemplate,
    DateTime? now,
```

In `lib/features/deck/data/repositories/deck_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/models/deck_source_template_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
```

Replace

```dart
    required SchedulerType schedulerType,
    DateTime? now,
```

with

```dart
    required SchedulerType schedulerType,
    DeckSourceTemplate? sourceTemplate,
    DateTime? now,
```

Replace

```dart
          generation: const Value(1),
          siblingPosition: await _dao.nextSiblingPosition(null),
```

with

```dart
          generation: const Value(1),
          sourceTemplateId: Value(sourceTemplate?.templateId),
          sourceTemplateVersion: Value(sourceTemplate?.version),
          siblingPosition: await _dao.nextSiblingPosition(null),
```

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/deck/data/deck_repository_impl_test.dart \
  test/features/deck/presentation/create_root_deck_dialog_widget_test.dart
```

Expected: `+25: All tests passed!`

- [ ] **Step 6: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/deck/data/repositories/deck_repository_impl.dart \
  lib/features/deck/domain/models/deck_source_template_model.dart \
  lib/features/deck/domain/repositories/deck_repository.dart \
  test/features/deck/data/deck_repository_impl_test.dart \
  test/features/deck/presentation/create_root_deck_dialog_widget_test.dart
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 7: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 49 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1796: All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git commit -F - <<'EOF'
feat(deck): a root deck records the starter template it was copied from

createRootDeck takes an optional DeckSourceTemplate and writes its id and
version to source_template_id and source_template_version (BR-STARTER-004);
a deck made by hand keeps both NULL.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: Read a starter template, and leave out one that could not be copied

**Files:**
- Create: `lib/features/starter_decks/data/mappers/starter_template_mapper.dart`, `lib/features/starter_decks/domain/models/starter_template_model.dart`
- Test (create): `test/features/starter_decks/data/starter_template_mapper_test.dart`
- Test (modify): `test/architecture/boundary_rules.dart`

**Interfaces:**
- Consumes: `DeckEntity.checkName` and `DeckEntity.maxDepth`; `CardDraft.check()`;
  `SchedulerType` and its `code`.
- Produces:
  - `StarterTemplate({required String templateId, required int version, required String locale, required String title, required String contentSource, required String frontLanguage, required String backLanguage, required SchedulerType suggestedScheduler, required List<StarterDeck> decks})`
    with `cardCount` and `subDeckCount`;
    `StarterDeck({required String name, List<StarterDeck> decks = const [], List<StarterCard> cards = const []})`
    with `cardCount` and `deckCount`;
    `StarterCard({required String front, required String back, String? example, String? hint, String? pronunciation})`
    (`starter_decks/domain/models/starter_template_model.dart`).
  - `StarterTemplate? starterTemplateOf(Object? json)`
    (`starter_decks/data/mappers/starter_template_mapper.dart`).

Spec §5.1, D6; Clarification 5. The import map lets `starter_decks` import the
domain of `deck`, `card` and `srs` from here on.

- [ ] **Step 1: Write the failing tests**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'transfer': {'card'},
};
```

with

```dart
  'transfer': {'card'},
  'starter_decks': {'deck', 'card', 'srs'},
};
```

Create `test/features/starter_decks/data/starter_template_mapper_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/mappers/starter_template_mapper.dart';

const _card = {'front': 'hello', 'back': 'xin chào'};

Map<String, Object?> _template() => {
  'templateId': 'fixture.test',
  'version': 1,
  'locale': 'en',
  'title': 'Test template',
  'contentSource': 'Development fixture',
  'frontLanguage': 'en',
  'backLanguage': 'vi',
  'defaultScheduler': 'sm2',
  'decks': [
    {
      'name': 'Words',
      'decks': [
        {
          'name': 'Greetings',
          'cards': [
            {'front': 'hello', 'back': 'xin chào', 'hint': 'a greeting'},
          ],
        },
      ],
    },
    {
      'name': 'Travel',
      'cards': [
        {'front': 'ticket', 'back': 'vé'},
        {'front': 'map', 'back': 'bản đồ'},
      ],
    },
  ],
};

/// The template with [decks] as the root's sub-decks.
Map<String, Object?> _withDecks(List<Object?> decks) =>
    _template()..['decks'] = decks;

/// [levels] decks, one inside the other under the root; the last holds a
/// card.
Map<String, Object?> _nested(int levels) {
  Object? deck = {
    'name': 'Level $levels',
    'cards': [_card],
  };
  for (var level = levels - 1; level >= 1; level--) {
    deck = {
      'name': 'Level $level',
      'decks': [deck],
    };
  }
  return _withDecks([deck]);
}

void main() {
  test(
    'a template reads with its fields, its tree in order and its counts',
    () {
      final template = starterTemplateOf(_template())!;

      expect(template.templateId, 'fixture.test');
      expect(template.version, 1);
      expect(template.locale, 'en');
      expect(template.title, 'Test template');
      expect(template.contentSource, 'Development fixture');
      expect(template.frontLanguage, 'en');
      expect(template.backLanguage, 'vi');
      expect(template.suggestedScheduler, SchedulerType.sm2);
      expect(
        [for (final deck in template.decks) deck.name],
        ['Words', 'Travel'],
      );
      expect(template.decks.first.decks.single.cards.single.hint, 'a greeting');
      expect(template.decks.last.cards.last.back, 'bản đồ');
      expect(template.cardCount, 3);
      expect(template.subDeckCount, 3);
    },
  );

  test('a template without a field BR-STARTER-002 needs, or with a blank one, '
      'is left out (D6)', () {
    for (final field in [
      'templateId',
      'version',
      'locale',
      'title',
      'contentSource',
      'frontLanguage',
      'backLanguage',
      'defaultScheduler',
      'decks',
    ]) {
      expect(
        starterTemplateOf(_template()..remove(field)),
        isNull,
        reason: field,
      );
      expect(
        starterTemplateOf(_template()..[field] = '  '),
        isNull,
        reason: '$field blank',
      );
    }
  });

  test('a version below 1 or not a whole number, and a scheduler the app does '
      'not have, are left out (D6)', () {
    expect(starterTemplateOf(_template()..['version'] = 0), isNull);
    expect(starterTemplateOf(_template()..['version'] = 1.5), isNull);
    expect(
      starterTemplateOf(_template()..['defaultScheduler'] = 'leitner'),
      isNull,
    );
  });

  test('a deck with both sub-decks and cards, or neither, and cards at the top '
      'level are left out (D6)', () {
    expect(
      starterTemplateOf(
        _withDecks([
          {
            'name': 'Both',
            'decks': [
              {
                'name': 'Inner',
                'cards': [_card],
              },
            ],
            'cards': [_card],
          },
        ]),
      ),
      isNull,
    );
    expect(
      starterTemplateOf(
        _withDecks([
          {'name': 'Neither'},
        ]),
      ),
      isNull,
    );
    expect(
      starterTemplateOf(
        _withDecks([
          {'name': 'Empty', 'cards': <Object?>[]},
        ]),
      ),
      isNull,
    );
    expect(starterTemplateOf(_withDecks([])), isNull);
    expect(starterTemplateOf(_template()..['cards'] = [_card]), isNull);
  });

  test('a tree deeper than a deck may go is left out; the tenth level is the '
      'last (D6, BR-DECK-001)', () {
    expect(starterTemplateOf(_nested(9)), isNotNull);
    expect(starterTemplateOf(_nested(10)), isNull);
  });

  test('a title, a deck name or a card that breaks the deck and card rules is '
      'left out (D6)', () {
    Map<String, Object?> withCard(Map<String, Object?> card) => _withDecks([
      {
        'name': 'Deck',
        'cards': [card],
      },
    ]);

    expect(starterTemplateOf(_template()..['title'] = 'x' * 201), isNull);
    expect(
      starterTemplateOf(
        _withDecks([
          {
            'name': ' ',
            'cards': [_card],
          },
        ]),
      ),
      isNull,
    );
    expect(
      starterTemplateOf(
        _withDecks([
          {
            'name': 'x' * 201,
            'cards': [_card],
          },
        ]),
      ),
      isNull,
    );
    expect(starterTemplateOf(withCard({'front': ' ', 'back': 'b'})), isNull);
    expect(
      starterTemplateOf(withCard({'front': 'x' * 61, 'back': 'b'})),
      isNull,
    );
    expect(
      starterTemplateOf(withCard({'front': 'a', 'back': 'x' * 241})),
      isNull,
    );
    expect(starterTemplateOf(withCard({'front': 'a'})), isNull);
    expect(
      starterTemplateOf(withCard({'front': 'a', 'back': 'b', 'hint': 5})),
      isNull,
    );
    expect(
      starterTemplateOf(
        withCard({'front': 'a', 'back': 'b', 'example': 'x' * 241}),
      ),
      isNull,
    );
  });

  test('anything but an object is left out', () {
    expect(starterTemplateOf(null), isNull);
    expect(starterTemplateOf([_template()]), isNull);
    expect(starterTemplateOf('template'), isNull);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/starter_decks/data/starter_template_mapper_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/starter_decks/data/mappers/starter_template_mapper.dart': No such file or directory`
and `Error: Method not found: 'starterTemplateOf'.`

- [ ] **Step 3: Model a template as a tree of decks**

Create `lib/features/starter_decks/domain/models/starter_template_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A starter template (BR-STARTER-001, BR-STARTER-002): content bundled with
/// the app that becomes the person's own deck tree only when they add it.
final class StarterTemplate {
  const StarterTemplate({
    required this.templateId,
    required this.version,
    required this.locale,
    required this.title,
    required this.contentSource,
    required this.frontLanguage,
    required this.backLanguage,
    required this.suggestedScheduler,
    required this.decks,
  });

  /// Stable across app versions (BR-STARTER-002).
  final String templateId;

  /// Grows when the content changes; a copy records the one it was made from
  /// (BR-STARTER-004).
  final int version;

  /// The language of the template's own text: its title and deck names.
  final String locale;

  /// The name the copy's root takes.
  final String title;

  /// Where the content comes from; the fixtures say "Development fixture"
  /// (BR-STARTER-010).
  final String contentSource;

  /// BCP 47 tags of the two sides of every card.
  final String frontLanguage;
  final String backLanguage;

  /// Only a suggestion: the person picks the scheduler (BR-STARTER-004).
  final SchedulerType suggestedScheduler;

  /// The root's sub-decks, in order.
  final List<StarterDeck> decks;

  /// Every card of the tree.
  int get cardCount => decks.fold(0, (sum, deck) => sum + deck.cardCount);

  /// Every deck under the root.
  int get subDeckCount => decks.fold(0, (sum, deck) => sum + deck.deckCount);
}

/// A deck of a template: it holds sub-decks or cards, never both (spec D6).
final class StarterDeck {
  const StarterDeck({
    required this.name,
    this.decks = const [],
    this.cards = const [],
  });

  final String name;
  final List<StarterDeck> decks;
  final List<StarterCard> cards;

  /// The cards of this deck and of every deck under it.
  int get cardCount =>
      cards.length + decks.fold(0, (sum, deck) => sum + deck.cardCount);

  /// This deck and every deck under it.
  int get deckCount => 1 + decks.fold(0, (sum, deck) => sum + deck.deckCount);
}

/// A card of a template; it passes the card rules (BR-CARD-001…BR-CARD-003).
final class StarterCard {
  const StarterCard({
    required this.front,
    required this.back,
    this.example,
    this.hint,
    this.pronunciation,
  });

  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;
}
```

- [ ] **Step 4: Read a template file, with the checks of spec D6**

Create `lib/features/starter_decks/data/mappers/starter_template_mapper.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';

/// The depth of the root a copy writes; the template's decks start below it.
const _rootDepth = 1;

/// The template a file's JSON describes (starter decks spec §5.1), or null
/// when it breaks a rule of spec D6: the library leaves such a template out
/// (UC-STARTER-001 E3), so every template it lists can be copied.
StarterTemplate? starterTemplateOf(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final templateId = _textOf(json['templateId']);
  final version = json['version'];
  final locale = _textOf(json['locale']);
  final title = _textOf(json['title']);
  final contentSource = _textOf(json['contentSource']);
  final frontLanguage = _textOf(json['frontLanguage']);
  final backLanguage = _textOf(json['backLanguage']);
  final scheduler = _schedulerOf(json['defaultScheduler']);
  if (templateId == null || locale == null || title == null) return null;
  if (contentSource == null || frontLanguage == null) return null;
  if (backLanguage == null || scheduler == null) return null;
  if (version is! int || version < 1) return null;
  // The copy's root is named after the title, and a root holds decks only.
  if (!_isDeckName(title) || json.containsKey('cards')) return null;
  final decks = _decksOf(json['decks'], depth: _rootDepth + 1);
  if (decks == null) return null;
  return StarterTemplate(
    templateId: templateId,
    version: version,
    locale: locale,
    title: title,
    contentSource: contentSource,
    frontLanguage: frontLanguage,
    backLanguage: backLanguage,
    suggestedScheduler: scheduler,
    decks: decks,
  );
}

/// [value] when it is text with something in it.
String? _textOf(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}

SchedulerType? _schedulerOf(Object? code) {
  for (final type in SchedulerType.values) {
    if (type.code == code) return type;
  }
  return null;
}

bool _isDeckName(String name) => switch (DeckEntity.checkName(name)) {
  Ok() => true,
  Rejected() => false,
};

/// The decks of [value], a list with something in it, each at [depth].
List<StarterDeck>? _decksOf(Object? value, {required int depth}) {
  if (value is! List<Object?> || value.isEmpty) return null;
  if (depth > DeckEntity.maxDepth) return null;
  final decks = <StarterDeck>[];
  for (final item in value) {
    final deck = _deckOf(item, depth: depth);
    if (deck == null) return null;
    decks.add(deck);
  }
  return decks;
}

/// A deck holds sub-decks or cards: both or neither breaks spec D6.
StarterDeck? _deckOf(Object? json, {required int depth}) {
  if (json is! Map<String, Object?>) return null;
  final name = json['name'];
  if (name is! String || !_isDeckName(name)) return null;
  final hasDecks = json.containsKey('decks');
  if (hasDecks == json.containsKey('cards')) return null;
  if (!hasDecks) return _cardDeckOf(name, json['cards']);
  final decks = _decksOf(json['decks'], depth: depth + 1);
  if (decks == null) return null;
  return StarterDeck(name: name, decks: decks);
}

StarterDeck? _cardDeckOf(String name, Object? value) {
  if (value is! List<Object?> || value.isEmpty) return null;
  final cards = <StarterCard>[];
  for (final item in value) {
    final card = _cardOf(item);
    if (card == null) return null;
    cards.add(card);
  }
  return StarterDeck(name: name, cards: cards);
}

/// A card passes exactly what a card written by hand passes
/// (BR-CARD-001…BR-CARD-003).
StarterCard? _cardOf(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final front = json['front'];
  final back = json['back'];
  final example = json['example'];
  final hint = json['hint'];
  final pronunciation = json['pronunciation'];
  if (front is! String || back is! String) return null;
  if (example is! String? || hint is! String?) return null;
  if (pronunciation is! String?) return null;
  final draft = CardDraft(
    front: front,
    back: back,
    example: example,
    hint: hint,
    pronunciation: pronunciation,
  );
  if (draft.check() case Rejected()) return null;
  return StarterCard(
    front: front,
    back: back,
    example: example,
    hint: hint,
    pronunciation: pronunciation,
  );
}
```

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/starter_decks/data/starter_template_mapper_test.dart
```

Expected: `+7: All tests passed!`

- [ ] **Step 6: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/starter_decks/data/mappers/starter_template_mapper.dart \
  lib/features/starter_decks/domain/models/starter_template_model.dart \
  test/architecture/boundary_rules.dart \
  test/features/starter_decks/data/starter_template_mapper_test.dart
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 7: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 49 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1803: All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git commit -F - <<'EOF'
feat(starter): read a starter template, and leave out one that could not be copied

The starter_decks feature starts with its template model (a tree of decks
that hold sub-decks or cards) and the mapper from a template file's JSON
(spec §5.1). A template missing a field BR-STARTER-002 needs, with an
unknown scheduler, a deck holding both sub-decks and cards or neither, cards
at the top level, a tree deeper than ten levels, or a name or card the deck
and card rules refuse, reads as none (spec D6). The import map gains
'starter_decks': {deck, card, srs}.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: Bundle two fixture templates and read them from the assets

**Files:**
- Create: `assets/templates/en/everyday_en_vi.json`, `assets/templates/en/hangul_basics.json`, `assets/templates/manifest.json`, `lib/features/starter_decks/data/datasources/template_asset_data_source.dart`
- Modify: `pubspec.yaml`
- Test (create): `test/features/starter_decks/data/starter_fixtures_test.dart`, `test/features/starter_decks/data/template_asset_data_source_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's `starterTemplateOf` and `StarterTemplate`.
- Produces:
  - `TemplateAssetDataSource(AssetBundle bundle)` with
    `static const manifestPath = 'assets/templates/manifest.json'` and
    `Future<List<StarterTemplate>> load()`
    (`starter_decks/data/datasources/template_asset_data_source.dart`).
  - The assets `assets/templates/manifest.json`,
    `assets/templates/en/everyday_en_vi.json` (`fixture.everyday-en-vi`) and
    `assets/templates/en/hangul_basics.json` (`fixture.hangul-basics`).

Spec §5, D4, D5; Clarification 6. The data source's tests use a fake
`AssetBundle`; the fixtures' test reads the real assets through `rootBundle`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/starter_decks/data/starter_fixtures_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/datasources/template_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the bundled fixtures load, each whole, as spec D5 describes them',
    () async {
      final templates = await TemplateAssetDataSource(rootBundle).load();

      expect(
        [
          for (final t in templates)
            (
              t.templateId,
              t.title,
              t.cardCount,
              t.subDeckCount,
              t.suggestedScheduler,
              t.contentSource,
            ),
        ],
        [
          (
            'fixture.everyday-en-vi',
            'English → Vietnamese · Everyday',
            40,
            4,
            SchedulerType.eightBox,
            'Development fixture',
          ),
          (
            'fixture.hangul-basics',
            'Korean → Romanisation · Hangul basics',
            24,
            2,
            SchedulerType.sm2,
            'Development fixture',
          ),
        ],
      );
      expect(
        [for (final deck in templates.last.decks) deck.name],
        ['Consonants', 'Vowels'],
      );
      expect(templates.last.decks.first.cards.first.hint, '기역 (giyeok)');
    },
  );
}
```

Create `test/features/starter_decks/data/template_asset_data_source_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/starter_decks/data/datasources/template_asset_data_source.dart';

/// Assets from [files], by path; any other path is missing, as in the app.
final class _Bundle extends CachingAssetBundle {
  _Bundle(this._files);

  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    final text = _files[key];
    if (text == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(utf8.encode(text));
  }
}

const _manifest = 'assets/templates/manifest.json';

String _manifestOf(List<String> files) => jsonEncode({'templates': files});

/// A template file with [id] and one card.
String _templateOf(String id) => jsonEncode({
  'templateId': id,
  'version': 1,
  'locale': 'en',
  'title': 'Template $id',
  'contentSource': 'Development fixture',
  'frontLanguage': 'en',
  'backLanguage': 'vi',
  'defaultScheduler': 'sm2',
  'decks': [
    {
      'name': 'Deck',
      'cards': [
        {'front': 'hello', 'back': 'xin chào'},
      ],
    },
  ],
});

Future<List<String>> _loadedIds(Map<String, String> files) async => [
  for (final template in await TemplateAssetDataSource(_Bundle(files)).load())
    template.templateId,
];

void main() {
  test('the templates load in the order of the manifest', () async {
    expect(
      await _loadedIds({
        _manifest: _manifestOf(['b.json', 'a.json']),
        'assets/templates/a.json': _templateOf('a'),
        'assets/templates/b.json': _templateOf('b'),
      }),
      ['b', 'a'],
    );
  });

  test(
    'a missing or malformed manifest is no template (UC-STARTER-001 E2)',
    () async {
      final template = {'assets/templates/a.json': _templateOf('a')};

      expect(await _loadedIds(template), isEmpty);
      expect(await _loadedIds({...template, _manifest: 'not json'}), isEmpty);
      expect(
        await _loadedIds({...template, _manifest: '{"templates": "a.json"}'}),
        isEmpty,
      );
    },
  );

  test('a missing, malformed or invalid file is left out and the others '
      'load (UC-STARTER-001 E3)', () async {
    expect(
      await _loadedIds({
        _manifest: _manifestOf([
          'missing.json',
          'malformed.json',
          'invalid.json',
          'good.json',
        ]),
        'assets/templates/malformed.json': '{"templateId": ',
        'assets/templates/invalid.json': '{"templateId": "invalid"}',
        'assets/templates/good.json': _templateOf('good'),
      }),
      ['good'],
    );
  });

  test('a file whose id an earlier file has is left out (spec D6)', () async {
    final templates = await TemplateAssetDataSource(
      _Bundle({
        _manifest: _manifestOf(['first.json', 'second.json']),
        'assets/templates/first.json': _templateOf('same'),
        'assets/templates/second.json': _templateOf('same')
            .replaceFirst('Template same', 'Another title'),
      }),
    ).load();

    expect([for (final t in templates) t.title], ['Template same']);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/starter_decks/data/starter_fixtures_test.dart \
  test/features/starter_decks/data/template_asset_data_source_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: Error when reading 'lib/features/starter_decks/data/datasources/template_asset_data_source.dart': No such file or directory`
and `Error: Method not found: 'TemplateAssetDataSource'.` The tool may then print `Error: The Dart compiler exited unexpectedly.`
and a stack trace; the run still ends as above.

- [ ] **Step 3: Bundle the manifest and the two fixtures**

Flutter bundles the files of a listed folder, not of its sub-folders, so
`pubspec.yaml` lists `assets/templates/` and `assets/templates/en/` both.

Create `assets/templates/manifest.json`:

```json
{
  "templates": ["en/everyday_en_vi.json", "en/hangul_basics.json"]
}
```

Create `assets/templates/en/everyday_en_vi.json`:

```json
{
  "templateId": "fixture.everyday-en-vi",
  "version": 1,
  "locale": "en",
  "title": "English → Vietnamese · Everyday",
  "contentSource": "Development fixture",
  "frontLanguage": "en",
  "backLanguage": "vi",
  "defaultScheduler": "eight_box",
  "decks": [
    {
      "name": "Greetings",
      "cards": [
        {
          "front": "hello",
          "back": "xin chào"
        },
        {
          "front": "goodbye",
          "back": "tạm biệt"
        },
        {
          "front": "thank you",
          "back": "cảm ơn"
        },
        {
          "front": "sorry",
          "back": "xin lỗi"
        },
        {
          "front": "please",
          "back": "làm ơn"
        },
        {
          "front": "yes",
          "back": "vâng"
        },
        {
          "front": "no",
          "back": "không"
        },
        {
          "front": "good morning",
          "back": "chào buổi sáng"
        },
        {
          "front": "good night",
          "back": "chúc ngủ ngon"
        },
        {
          "front": "see you later",
          "back": "hẹn gặp lại"
        }
      ]
    },
    {
      "name": "Food & drink",
      "cards": [
        {
          "front": "rice",
          "back": "cơm"
        },
        {
          "front": "water",
          "back": "nước"
        },
        {
          "front": "coffee",
          "back": "cà phê"
        },
        {
          "front": "tea",
          "back": "trà"
        },
        {
          "front": "bread",
          "back": "bánh mì"
        },
        {
          "front": "noodles",
          "back": "mì"
        },
        {
          "front": "fish",
          "back": "cá"
        },
        {
          "front": "chicken",
          "back": "thịt gà"
        },
        {
          "front": "fruit",
          "back": "trái cây"
        },
        {
          "front": "vegetables",
          "back": "rau"
        }
      ]
    },
    {
      "name": "Travel",
      "cards": [
        {
          "front": "airport",
          "back": "sân bay"
        },
        {
          "front": "ticket",
          "back": "vé"
        },
        {
          "front": "hotel",
          "back": "khách sạn"
        },
        {
          "front": "map",
          "back": "bản đồ"
        },
        {
          "front": "train",
          "back": "tàu hỏa"
        },
        {
          "front": "bus",
          "back": "xe buýt"
        },
        {
          "front": "passport",
          "back": "hộ chiếu"
        },
        {
          "front": "luggage",
          "back": "hành lý"
        },
        {
          "front": "station",
          "back": "nhà ga"
        },
        {
          "front": "beach",
          "back": "bãi biển"
        }
      ]
    },
    {
      "name": "Home",
      "cards": [
        {
          "front": "house",
          "back": "ngôi nhà"
        },
        {
          "front": "room",
          "back": "căn phòng"
        },
        {
          "front": "kitchen",
          "back": "nhà bếp"
        },
        {
          "front": "bed",
          "back": "giường"
        },
        {
          "front": "table",
          "back": "cái bàn"
        },
        {
          "front": "chair",
          "back": "cái ghế"
        },
        {
          "front": "door",
          "back": "cửa ra vào"
        },
        {
          "front": "window",
          "back": "cửa sổ"
        },
        {
          "front": "lamp",
          "back": "đèn"
        },
        {
          "front": "key",
          "back": "chìa khóa"
        }
      ]
    }
  ]
}
```

Create `assets/templates/en/hangul_basics.json`:

```json
{
  "templateId": "fixture.hangul-basics",
  "version": 1,
  "locale": "en",
  "title": "Korean → Romanisation · Hangul basics",
  "contentSource": "Development fixture",
  "frontLanguage": "ko",
  "backLanguage": "ko-Latn",
  "defaultScheduler": "sm2",
  "decks": [
    {
      "name": "Consonants",
      "cards": [
        {
          "front": "ㄱ",
          "back": "g / k",
          "hint": "기역 (giyeok)"
        },
        {
          "front": "ㄴ",
          "back": "n",
          "hint": "니은 (nieun)"
        },
        {
          "front": "ㄷ",
          "back": "d / t",
          "hint": "디귿 (digeut)"
        },
        {
          "front": "ㄹ",
          "back": "r / l",
          "hint": "리을 (rieul)"
        },
        {
          "front": "ㅁ",
          "back": "m",
          "hint": "미음 (mieum)"
        },
        {
          "front": "ㅂ",
          "back": "b / p",
          "hint": "비읍 (bieup)"
        },
        {
          "front": "ㅅ",
          "back": "s",
          "hint": "시옷 (siot)"
        },
        {
          "front": "ㅇ",
          "back": "ng; silent at the start of a syllable",
          "hint": "이응 (ieung)"
        },
        {
          "front": "ㅈ",
          "back": "j",
          "hint": "지읒 (jieut)"
        },
        {
          "front": "ㅊ",
          "back": "ch",
          "hint": "치읓 (chieut)"
        },
        {
          "front": "ㅋ",
          "back": "k",
          "hint": "키읔 (kieuk)"
        },
        {
          "front": "ㅌ",
          "back": "t",
          "hint": "티읕 (tieut)"
        },
        {
          "front": "ㅍ",
          "back": "p",
          "hint": "피읖 (pieup)"
        },
        {
          "front": "ㅎ",
          "back": "h",
          "hint": "히읗 (hieut)"
        }
      ]
    },
    {
      "name": "Vowels",
      "cards": [
        {
          "front": "ㅏ",
          "back": "a"
        },
        {
          "front": "ㅑ",
          "back": "ya"
        },
        {
          "front": "ㅓ",
          "back": "eo"
        },
        {
          "front": "ㅕ",
          "back": "yeo"
        },
        {
          "front": "ㅗ",
          "back": "o"
        },
        {
          "front": "ㅛ",
          "back": "yo"
        },
        {
          "front": "ㅜ",
          "back": "u"
        },
        {
          "front": "ㅠ",
          "back": "yu"
        },
        {
          "front": "ㅡ",
          "back": "eu"
        },
        {
          "front": "ㅣ",
          "back": "i"
        }
      ]
    }
  ]
}
```

In `pubspec.yaml`:

Replace

```yaml
    - assets/fonts/OFL.txt
  fonts:
```

with

```yaml
    - assets/fonts/OFL.txt
    # The starter templates (starter decks spec §5); Flutter reads a folder's
    # files, not its subfolders, so each folder is listed.
    - assets/templates/
    - assets/templates/en/
  fonts:
```

- [ ] **Step 4: Read the templates through an AssetBundle**

Create `lib/features/starter_decks/data/datasources/template_asset_data_source.dart`:

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:memox/features/starter_decks/data/mappers/starter_template_mapper.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';

/// The starter templates bundled with the app (starter decks spec §5): the
/// manifest lists the template files, and each file is one template.
final class TemplateAssetDataSource {
  const TemplateAssetDataSource(this._bundle);

  final AssetBundle _bundle;

  static const manifestPath = 'assets/templates/manifest.json';
  static const _folder = 'assets/templates/';

  /// The templates that pass spec D6, in manifest order. A missing or
  /// malformed manifest is no template (UC-STARTER-001 E2); a missing,
  /// malformed or invalid file, or one whose id an earlier file has, is left
  /// out while the others load (E3). It never throws for content.
  Future<List<StarterTemplate>> load() async {
    final templates = <StarterTemplate>[];
    final ids = <String>{};
    for (final file in await _manifestFiles()) {
      final template = starterTemplateOf(await _jsonAt('$_folder$file'));
      if (template == null || !ids.add(template.templateId)) continue;
      templates.add(template);
    }
    return templates;
  }

  Future<List<String>> _manifestFiles() async {
    final json = await _jsonAt(manifestPath);
    if (json is! Map<String, Object?>) return const [];
    final files = json['templates'];
    if (files is! List<Object?>) return const [];
    return [
      for (final file in files)
        if (file is String) file,
    ];
  }

  /// The JSON of the asset at [path]; null when it is missing or is not JSON.
  Future<Object?> _jsonAt(String path) async {
    try {
      return jsonDecode(await _bundle.loadString(path));
    } on FlutterError {
      // A missing asset: the bundle says so with a FlutterError.
      return null;
    } on FormatException {
      return null;
    }
  }
}
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 48 warning(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/starter_decks/data/starter_fixtures_test.dart \
  test/features/starter_decks/data/template_asset_data_source_test.dart
```

Expected: `+5: All tests passed!`

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add assets/templates/en/everyday_en_vi.json \
  assets/templates/en/hangul_basics.json \
  assets/templates/manifest.json \
  lib/features/starter_decks/data/datasources/template_asset_data_source.dart \
  pubspec.yaml \
  test/features/starter_decks/data/starter_fixtures_test.dart \
  test/features/starter_decks/data/template_asset_data_source_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 48 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1808: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(starter): bundle two fixture templates and read them from the assets

TemplateAssetDataSource reads assets/templates/manifest.json and the files it
lists, through the AssetBundle it is given, and returns the templates that
pass spec D6 in manifest order. A missing or malformed manifest is no
template (UC-STARTER-001 E2); a missing, malformed or invalid file, or one
repeating an earlier id, is left out (E3). Two fixtures ship, both marked
"Development fixture" (spec D5, BR-STARTER-010): English → Vietnamese ·
Everyday (4 sub-decks of 10) and Korean → Romanisation · Hangul basics (14
consonants with their names as hints, 10 vowels).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: Copy a template into the library in one transaction

**Files:**
- Create: `lib/features/starter_decks/data/datasources/starter_dao.dart`, `lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart`, `lib/features/starter_decks/di/starter_library_repository_provider.dart`, `lib/features/starter_decks/domain/failures/starter_failure.dart`, `lib/features/starter_decks/domain/models/added_starter_deck_model.dart`, `lib/features/starter_decks/domain/repositories/starter_library_repository.dart`
- Test (create): `test/features/starter_decks/data/add_starter_deck_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's `DeckSourceTemplate` and `createRootDeck(sourceTemplate:)`;
  `DeckRepository.createSubDeck` and `CardRepository.createCard`; Task 2's model; Task
  3's `TemplateAssetDataSource`; `mapDatabaseError`; `databaseProvider`,
  `deckRepositoryProvider`, `cardRepositoryProvider`; `totalChanges` and
  `invariantQueries` of `test/support/`.
- Produces:
  - `enum StarterRejection { templateNotFound, alreadyInLibrary }`
    (`starter_decks/domain/failures/starter_failure.dart`).
  - `AddedStarterDeck({required String rootDeckId, required String title, required SchedulerType schedulerType, required int cardCount})`
    (`starter_decks/domain/models/added_starter_deck_model.dart`).
  - `StarterLibraryRepository` with
    `Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({required String templateId, required SchedulerType schedulerType, bool allowSecondCopy = false, DateTime? now})`.
  - `StarterDao(AppDatabase)` with `Future<bool> hasCopy(String templateId, int version)`.
  - `StarterLibraryRepositoryImpl(AppDatabase db, DeckRepository decks, CardRepository cards, {required Future<List<StarterTemplate>> Function() templates})`;
    `starterLibraryRepositoryProvider`.

Spec §7, D2, D7, D8, D10, D11; Clarifications 1–4 and 8; Review Focus 1–3. The
rollback test is the proof spec §13 asks for: a card the card rules refuse, after a good
deck, leaves nothing.

- [ ] **Step 1: Write the failing tests**

Create `test/features/starter_decks/data/add_starter_deck_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/invariant_queries.dart';
import '../../../support/test_database.dart';

DateTime _clock() => DateTime.utc(2026, 9, 26, 9);

const _id = 'fixture.test';

StarterTemplate _template({
  int version = 1,
  String title = 'Everyday',
  List<StarterDeck> decks = const [
    StarterDeck(
      name: 'Words',
      decks: [
        StarterDeck(
          name: 'Greetings',
          cards: [
            StarterCard(front: 'hello', back: 'xin chào'),
            StarterCard(
              front: 'goodbye',
              back: 'tạm biệt',
              example: 'Goodbye, see you tomorrow.',
              hint: 'leaving',
              pronunciation: 'ɡʊdˈbaɪ',
            ),
          ],
        ),
      ],
    ),
    StarterDeck(
      name: 'Travel',
      cards: [StarterCard(front: 'ticket', back: 'vé')],
    ),
  ],
}) => StarterTemplate(
  templateId: _id,
  version: version,
  locale: 'en',
  title: title,
  contentSource: 'Development fixture',
  frontLanguage: 'en',
  backLanguage: 'vi',
  suggestedScheduler: SchedulerType.eightBox,
  decks: decks,
);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _clock);
  });
  tearDown(() => db.close());

  /// The library over [templates], as a build of the app would read them.
  StarterLibraryRepositoryImpl library(List<StarterTemplate> templates) =>
      StarterLibraryRepositoryImpl(
        db,
        decks,
        CardRepositoryImpl(
          db,
          ScheduleRepositoryImpl(db, now: _clock),
          TagRepositoryImpl(db, now: _clock),
          now: _clock,
        ),
        templates: () async => templates,
      );

  Future<Outcome<AddedStarterDeck, StarterRejection>> add(
    StarterLibraryRepositoryImpl repo, {
    SchedulerType schedulerType = SchedulerType.sm2,
    bool allowSecondCopy = false,
  }) => repo.addStarterDeck(
    templateId: _id,
    schedulerType: schedulerType,
    allowSecondCopy: allowSecondCopy,
  );

  Future<AddedStarterDeck> added(
    StarterLibraryRepositoryImpl repo, {
    bool allowSecondCopy = false,
  }) async => switch (await add(repo, allowSecondCopy: allowSecondCopy)) {
    Ok(:final value) => value,
    Rejected(:final reason) => throw StateError('refused: $reason'),
  };

  Future<List<Map<String, Object?>>> rows(
    String sql, [
    List<String> args = const [],
  ]) async => [
    for (final row
        in await db
            .customSelect(sql, variables: [for (final a in args) Variable(a)])
            .get())
      row.data,
  ];

  Future<int> count(String table) async =>
      (await rows('SELECT COUNT(*) AS n FROM $table')).single['n']! as int;

  test('a copy is an ordinary deck tree of its own: the root, the sub-decks '
      'in template order, the cards, and one fresh schedule row per card '
      'under the chosen scheduler (BR-STARTER-003, BR-STARTER-004)', () async {
    final copy = await added(library([_template()]));

    expect(
      (copy.title, copy.schedulerType, copy.cardCount),
      ('Everyday', SchedulerType.sm2, 3),
    );
    expect(
      await rows(
        'SELECT d.name, p.name AS parent, d.root_id = ? AS in_copy, d.depth, '
        'd.content_type, d.scheduler_type, d.generation, d.first_answered_at, '
        'd.source_template_id, d.source_template_version '
        'FROM deck d LEFT JOIN deck p ON p.id = d.parent_id '
        'ORDER BY d.depth, d.sibling_position',
        [copy.rootDeckId],
      ),
      [
        {
          'name': 'Everyday',
          'parent': null,
          'in_copy': 1,
          'depth': 1,
          'content_type': 'deck',
          'scheduler_type': 'sm2',
          'generation': 1,
          'first_answered_at': null,
          'source_template_id': _id,
          'source_template_version': 1,
        },
        for (final (name, parent, depth, type) in [
          ('Words', 'Everyday', 2, 'deck'),
          ('Travel', 'Everyday', 2, 'card'),
          ('Greetings', 'Words', 3, 'card'),
        ])
          {
            'name': name,
            'parent': parent,
            'in_copy': 1,
            'depth': depth,
            'content_type': type,
            'scheduler_type': null,
            'generation': null,
            'first_answered_at': null,
            'source_template_id': null,
            'source_template_version': null,
          },
      ],
    );
    expect(
      await rows(
        'SELECT d.name AS deck, c.front, c.back, c.example, c.hint, '
        'c.pronunciation, s.scheduler_type, '
        's.generation, s.learned_at IS NULL AS is_new '
        'FROM card c JOIN deck d ON d.id = c.deck_id '
        'JOIN card_schedule s ON s.card_id = c.id ORDER BY d.name, c.front',
      ),
      [
        for (final (deck, front, back, example, hint, pronunciation) in [
          (
            'Greetings',
            'goodbye',
            'tạm biệt',
            'Goodbye, see you tomorrow.',
            'leaving',
            'ɡʊdˈbaɪ',
          ),
          ('Greetings', 'hello', 'xin chào', null, null, null),
          ('Travel', 'ticket', 'vé', null, null, null),
        ])
          {
            'deck': deck,
            'front': front,
            'back': back,
            'example': example,
            'hint': hint,
            'pronunciation': pronunciation,
            'scheduler_type': 'sm2',
            'generation': 1,
            'is_new': 1,
          },
      ],
    );
    expect(await count('card_schedule'), 3);
    expect(await count('review_log'), 0);
    for (final MapEntry(key: number, value: query)
        in invariantQueries.entries) {
      expect(await rows(query), isEmpty, reason: 'invariant $number');
    }
  });

  test('the deepest template the library lists copies whole: ten levels '
      'with the root, cards on the tenth (BR-DECK-001, spec D6)', () async {
    var deepest = const StarterDeck(
      name: 'Level 10',
      cards: [StarterCard(front: 'deep', back: 'sâu')],
    );
    for (var level = 9; level >= 2; level--) {
      deepest = StarterDeck(name: 'Level $level', decks: [deepest]);
    }

    final copy = await added(
      library([
        _template(decks: [deepest]),
      ]),
    );

    expect(
      await rows(
        'SELECT MAX(depth) AS depth, COUNT(*) AS decks FROM deck '
        'WHERE root_id = ?',
        [copy.rootDeckId],
      ),
      [
        {'depth': 10, 'decks': 10},
      ],
    );
    expect(await count('card'), 1);
  });

  test('a copy under eight boxes writes eight-box schedule rows', () async {
    await add(library([_template()]), schedulerType: SchedulerType.eightBox);

    expect(await rows('SELECT DISTINCT scheduler_type FROM card_schedule'), [
      {'scheduler_type': 'eight_box'},
    ]);
  });

  test('a template already in the library is not copied again: the add '
      'writes nothing and says so (BR-STARTER-007)', () async {
    final repo = library([_template()]);
    await added(repo);
    final before = await totalChanges(db);

    final again = await add(repo);

    expect(
      (again as Rejected<AddedStarterDeck, StarterRejection>).reason,
      StarterRejection.alreadyInLibrary,
    );
    expect(await totalChanges(db), before);
  });

  test('two adds at once, as a double tap sends them, make one copy: the '
      'second finds the first inside its transaction (spec D8)', () async {
    final repo = library([_template()]);

    final results = await Future.wait([add(repo), add(repo)]);

    expect([
      for (final result in results)
        switch (result) {
          Ok() => 'added',
          Rejected(:final reason) => reason.name,
        },
    ], unorderedEquals(['added', 'alreadyInLibrary']));
    expect(
      await rows('SELECT id FROM deck WHERE parent_id IS NULL'),
      hasLength(1),
    );
  });

  test('a confirmed second copy is a separate tree of its own, with the same '
      'name (BR-STARTER-008)', () async {
    final repo = library([_template()]);
    final first = await added(repo);

    final second = await added(repo, allowSecondCopy: true);

    expect(second.rootDeckId, isNot(first.rootDeckId));
    expect(await rows('SELECT name FROM deck WHERE parent_id IS NULL'), [
      {'name': 'Everyday'},
      {'name': 'Everyday'},
    ]);
    expect(await count('card'), 6);
    expect(await count('card_schedule'), 6);
  });

  test('a copy in the Trash is not in the library, and a restored one is '
      'again (UC-STARTER-001 A4, spec D7)', () async {
    final repo = library([_template()]);
    final first = await added(repo);
    Future<String> trash(String deckId) async =>
        switch (await decks.deleteDeck(deckId: deckId)) {
          Ok(:final value) => value,
          Rejected(:final reason) => throw StateError('$reason'),
        };

    final batchId = await trash(first.rootDeckId);
    await decks.restoreDecks(batchIds: {batchId}, parentId: null);
    final whileRestored = await add(repo);
    await trash(first.rootDeckId);
    final again = await added(repo);

    expect(
      (whileRestored as Rejected<AddedStarterDeck, StarterRejection>).reason,
      StarterRejection.alreadyInLibrary,
    );
    expect(again.rootDeckId, isNot(first.rootDeckId));
  });

  test('a new version of a template is not in the library: it copies without '
      'asking and leaves the old version\'s copy as it was (BR-STARTER-006, '
      'UC-STARTER-001 A3)', () async {
    const tree =
        'SELECT d.name, d.content_type, c.front, c.back FROM deck d '
        'LEFT JOIN card c ON c.deck_id = d.id WHERE d.root_id = ? '
        'ORDER BY d.depth, d.sibling_position, c.front';
    final old = await added(library([_template()]));
    final oldTree = await rows(tree, [old.rootDeckId]);
    final update = _template(
      version: 2,
      title: 'Everyday, updated',
      decks: const [
        StarterDeck(
          name: 'Food',
          cards: [StarterCard(front: 'rice', back: 'cơm')],
        ),
      ],
    );

    final copy = await added(library([update]));

    expect(copy.rootDeckId, isNot(old.rootDeckId));
    expect(
      await rows(
        'SELECT source_template_version AS v FROM deck '
        'WHERE parent_id IS NULL ORDER BY v',
      ),
      [
        {'v': 1},
        {'v': 2},
      ],
    );
    expect(await rows(tree, [old.rootDeckId]), oldTree);
  });

  test('a copy that fails half-way writes nothing: no root, deck, card or '
      'schedule row (BR-STARTER-009, UC-STARTER-001 E4)', () async {
    // A card the card rules refuse: only a template that skipped the
    // library's checks (spec D6) could hold it, after a good deck.
    final broken = _template(
      decks: const [
        StarterDeck(
          name: 'Good',
          cards: [StarterCard(front: 'hello', back: 'xin chào')],
        ),
        StarterDeck(
          name: 'Bad',
          cards: [StarterCard(front: ' ', back: 'blank')],
        ),
      ],
    );

    await expectLater(add(library([broken])), throwsA(isA<Failure>()));
    expect(await count('deck'), 0);
    expect(await count('card'), 0);
    expect(await count('card_schedule'), 0);
  });

  test('a template the library does not have is refused and nothing is '
      'written', () async {
    final before = await totalChanges(db);

    final result = await library([_template()]).addStarterDeck(
      templateId: 'fixture.other',
      schedulerType: SchedulerType.sm2,
    );

    expect(
      (result as Rejected<AddedStarterDeck, StarterRejection>).reason,
      StarterRejection.templateNotFound,
    );
    expect(await totalChanges(db), before);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/starter_decks/data/add_starter_deck_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/starter_decks/domain/failures/starter_failure.dart': No such file or directory`,
the same for `added_starter_deck_model.dart` and `starter_library_repository_impl.dart`,
then `Error: 'AddedStarterDeck' isn't a type.` and
`Error: 'StarterLibraryRepositoryImpl' isn't a type.`

- [ ] **Step 3: Name the refusals, the result and the contract**

Create `lib/features/starter_decks/domain/failures/starter_failure.dart`:

```dart
/// Why the Starter library refuses to add a template (starter decks spec
/// D11). A write that fails is a `Failure`, not a reason.
enum StarterRejection {
  /// No template in the library has that id: the library changed since it
  /// was read.
  templateNotFound,

  /// A copy of the template, at this version, is in the library, and a
  /// second copy was not confirmed (BR-STARTER-007, BR-STARTER-008).
  alreadyInLibrary,
}
```

Create `lib/features/starter_decks/domain/models/added_starter_deck_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A template just added to the library (UC-STARTER-001 step 8): what the
/// confirmation says and where Open goes (starter decks spec §9).
final class AddedStarterDeck {
  const AddedStarterDeck({
    required this.rootDeckId,
    required this.title,
    required this.schedulerType,
    required this.cardCount,
  });

  final String rootDeckId;
  final String title;
  final SchedulerType schedulerType;

  /// Every card of the copy, all of them new (UC-STARTER-001 step 9).
  final int cardCount;
}
```

Create `lib/features/starter_decks/domain/repositories/starter_library_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';

/// The Starter library (UC-STARTER-001). The one implementation is
/// `StarterLibraryRepositoryImpl`; the contract keeps `domain/`
/// framework-free and lets tests substitute a fake (ADR-010).
abstract interface class StarterLibraryRepository {
  /// UC-STARTER-001 step 8: the template [templateId] becomes a deck tree of
  /// the person's own under [schedulerType], in one transaction
  /// (BR-STARTER-003, BR-STARTER-009). A copy of it in the library refuses
  /// with `alreadyInLibrary` unless [allowSecondCopy] (BR-STARTER-007,
  /// BR-STARTER-008).
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  });
}
```

- [ ] **Step 4: Find a copy outside the Trash, and write one through the deck and card repositories**

The provider's `part` file does not exist until the next step generates it.

Create `lib/features/starter_decks/data/datasources/starter_dao.dart`:

```dart
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
```

Create `lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart`:

```dart
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
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

/// The Starter library over the bundled templates (starter decks spec §7). A
/// copy is written by the features that own each table, through their
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
```

Create `lib/features/starter_decks/di/starter_library_repository_provider.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/starter_decks/data/datasources/template_asset_data_source.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'starter_library_repository_provider.g.dart';

/// The library over the templates bundled with the app (starter decks spec
/// §5).
@riverpod
StarterLibraryRepository starterLibraryRepository(Ref ref) =>
    StarterLibraryRepositoryImpl(
      ref.watch(databaseProvider),
      ref.watch(deckRepositoryProvider),
      ref.watch(cardRepositoryProvider),
      templates: TemplateAssetDataSource(rootBundle).load,
    );
```

- [ ] **Step 5: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: it prints `Built with build_runner/aot in …; wrote … outputs.`, and
`lib/features/starter_decks/di/starter_library_repository_provider.g.dart` now exists.
Like every `*.g.dart` file, it is not committed.

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 48 warning(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/starter_decks/data/add_starter_deck_test.dart
```

Expected: `+10: All tests passed!`

- [ ] **Step 8: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/starter_decks/data/datasources/starter_dao.dart \
  lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart \
  lib/features/starter_decks/di/starter_library_repository_provider.dart \
  lib/features/starter_decks/domain/failures/starter_failure.dart \
  lib/features/starter_decks/domain/models/added_starter_deck_model.dart \
  lib/features/starter_decks/domain/repositories/starter_library_repository.dart \
  test/features/starter_decks/data/add_starter_deck_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 9: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 48 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1818: All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git commit -F - <<'EOF'
feat(starter): copy a starter template into the library in one transaction

StarterLibraryRepositoryImpl.addStarterDeck writes the template as an
ordinary deck tree of the person's own: a root named after the template,
carrying its id and version, through DeckRepository.createRootDeck; the
sub-decks in template order through createSubDeck; each card, with its
schedule row under the chosen scheduler, through CardRepository.createCard
(BR-STARTER-003, BR-STARTER-004). One transaction holds it all: a refusal
from either repository throws, and nothing is left (BR-STARTER-009). A
copy of the template at its version outside the Trash refuses with
alreadyInLibrary unless a second copy is confirmed (BR-STARTER-007,
BR-STARTER-008, spec D7, D8), and two adds at once make one copy; an
unknown id refuses with templateNotFound.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: Watch the library and whether each template is in it

**Files:**
- Create: `lib/features/starter_decks/domain/models/starter_library_entry_model.dart`
- Modify: `lib/features/starter_decks/data/datasources/starter_dao.dart`, `lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart`, `lib/features/starter_decks/domain/repositories/starter_library_repository.dart`
- Test (create): `test/features/starter_decks/data/watch_starter_library_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 4's repository, DAO and `addStarterDeck`; `tableChanges`
  (`lib/core/database/table_changes.dart`); `mapDatabaseErrors`;
  `DeckRepository.deleteDeck`, `restoreDecks` and `renameDeck` in the tests.
- Produces:
  - `StarterLibraryEntry({required String templateId, required int version, required String title, required String locale, required String frontLanguage, required String backLanguage, required String contentSource, required SchedulerType suggestedScheduler, required int cardCount, required int subDeckCount, required bool isInLibrary})`
    with `factory StarterLibraryEntry.of(StarterTemplate template, {required bool isInLibrary})`
    (`starter_decks/domain/models/starter_library_entry_model.dart`).
  - `Stream<List<StarterLibraryEntry>> StarterLibraryRepository.watchLibrary()`.
  - In `StarterDao`: `Stream<void> copyChanges()` and
    `Future<Set<(String, int)>> copies()`.

Spec §6, D7, D12; Clarifications 2, 4 and 8; Review Focus 4. The failing read
opens the database first, so the error the stream carries is the watch's own.

- [ ] **Step 1: Write the failing tests**

Create `test/features/starter_decks/data/watch_starter_library_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/test_database.dart';

// UC-STARTER-001 steps 4-5 and A4: what the Starter library lists, and how
// it follows the copies (starter decks spec §6, D7, D12).

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (the kit's `loadFailed`).
final class _FailingSelects extends QueryInterceptor {
  bool isArmed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isArmed) {
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}

DateTime _clock() => DateTime.utc(2026, 9, 26, 9);

StarterTemplate _template(String id, {int version = 1}) => StarterTemplate(
  templateId: id,
  version: version,
  locale: 'en',
  title: 'Template $id',
  contentSource: 'Development fixture',
  frontLanguage: 'en',
  backLanguage: 'vi',
  suggestedScheduler: SchedulerType.eightBox,
  decks: const [
    StarterDeck(
      name: 'Words',
      decks: [
        StarterDeck(
          name: 'Greetings',
          cards: [
            StarterCard(front: 'hello', back: 'xin chào'),
            StarterCard(front: 'goodbye', back: 'tạm biệt'),
          ],
        ),
      ],
    ),
    StarterDeck(
      name: 'Travel',
      cards: [
        StarterCard(front: 'ticket', back: 'vé'),
        StarterCard(front: 'map', back: 'bản đồ'),
      ],
    ),
  ],
);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: _clock);
  }

  tearDown(() => db.close());

  StarterLibraryRepositoryImpl library(List<StarterTemplate> templates) =>
      StarterLibraryRepositoryImpl(
        db,
        decks,
        CardRepositoryImpl(
          db,
          ScheduleRepositoryImpl(db, now: _clock),
          TagRepositoryImpl(db, now: _clock),
          now: _clock,
        ),
        templates: () async => templates,
      );

  Future<String> add(StarterLibraryRepositoryImpl repo, String id) async =>
      switch (await repo.addStarterDeck(
        templateId: id,
        schedulerType: SchedulerType.sm2,
      )) {
        Ok(:final value) => value.rootDeckId,
        Rejected(:final reason) => throw StateError('refused: $reason'),
      };

  test(
    'the library lists every template in manifest order with what its '
    'card shows, none of them in the library yet (UC-STARTER-001 step 5)',
    () async {
      open();
      final entries = await library([_template('b'), _template('a')])
          .watchLibrary()
          .first;

      expect(
        [
          for (final StarterLibraryEntry e in entries)
            (
              e.templateId,
              e.version,
              e.title,
              e.locale,
              e.frontLanguage,
              e.backLanguage,
              e.contentSource,
              e.suggestedScheduler,
              e.cardCount,
              e.subDeckCount,
              e.isInLibrary,
            ),
        ],
        [
          for (final id in ['b', 'a'])
            (
              id,
              1,
              'Template $id',
              'en',
              'en',
              'vi',
              'Development fixture',
              SchedulerType.eightBox,
              4,
              3,
              false,
            ),
        ],
      );
    },
  );

  test('a template is in the library while a copy of it at its version is '
      'outside the Trash, and only that template (spec D7)', () async {
    open();
    final first = library([_template('a'), _template('b')]);
    await add(first, 'a');
    final update = library([_template('a', version: 2), _template('b')]);

    expect(
      [
        for (final e in await first.watchLibrary().first)
          (e.templateId, e.isInLibrary),
      ],
      [('a', true), ('b', false)],
    );
    expect(
      [
        for (final e in await update.watchLibrary().first)
          (e.templateId, e.version, e.isInLibrary),
      ],
      [('a', 2, false), ('b', 1, false)],
    );
  });

  test('a copy its owner renamed is still in the library: a template is known '
      'by its id and version, not by a name (spec D7)', () async {
    open();
    final repo = library([_template('a')]);
    final rootId = await add(repo, 'a');
    await decks.renameDeck(deckId: rootId, name: 'My words');

    expect(
      [for (final e in await repo.watchLibrary().first) e.isInLibrary],
      [true],
    );
  });

  test('the library follows a copy added, sent to the Trash and restored '
      '(UC-STARTER-001 A4, spec D12)', () async {
    open();
    final repo = library([_template('a')]);
    final isInLibrary = repo.watchLibrary().map(
      (entries) => entries.single.isInLibrary,
    );

    final followed = expectLater(
      isInLibrary,
      emitsInOrder([
        false,
        emitsThrough(true),
        emitsThrough(false),
        emitsThrough(true),
      ]),
    );
    await pumpEventQueue();
    final rootId = await add(repo, 'a');
    await pumpEventQueue();
    final batch = switch (await decks.deleteDeck(deckId: rootId)) {
      Ok(:final value) => value,
      Rejected(:final reason) => throw StateError('$reason'),
    };
    await pumpEventQueue();
    await decks.restoreDecks(batchIds: {batch}, parentId: null);
    await followed;
  });

  test('a database error reaches the library as its Failure (the kit\'s '
      'loadFailed)', () async {
    final failing = _FailingSelects();
    open(failing);
    final repo = library([_template('a')]);
    await add(repo, 'a');
    failing.isArmed = true;

    await expectLater(repo.watchLibrary(), emitsError(isA<Failure>()));
    failing.isArmed = false;
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/starter_decks/data/watch_starter_library_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/starter_decks/domain/models/starter_library_entry_model.dart': No such file or directory`
and `Error: The method 'watchLibrary' isn't defined for the type 'StarterLibraryRepositoryImpl'.`

- [ ] **Step 3: Name what an entry of the library shows**

Create `lib/features/starter_decks/domain/models/starter_library_entry_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';

/// A template as the Starter library lists it (kit screen 03, starter decks
/// spec §9): what its card shows, and whether it is already in the library.
final class StarterLibraryEntry {
  const StarterLibraryEntry({
    required this.templateId,
    required this.version,
    required this.title,
    required this.locale,
    required this.frontLanguage,
    required this.backLanguage,
    required this.contentSource,
    required this.suggestedScheduler,
    required this.cardCount,
    required this.subDeckCount,
    required this.isInLibrary,
  });

  /// The entry of [template]; [isInLibrary] when a copy of it at its version
  /// is outside the Trash (spec D7).
  factory StarterLibraryEntry.of(
    StarterTemplate template, {
    required bool isInLibrary,
  }) => StarterLibraryEntry(
    templateId: template.templateId,
    version: template.version,
    title: template.title,
    locale: template.locale,
    frontLanguage: template.frontLanguage,
    backLanguage: template.backLanguage,
    contentSource: template.contentSource,
    suggestedScheduler: template.suggestedScheduler,
    cardCount: template.cardCount,
    subDeckCount: template.subDeckCount,
    isInLibrary: isInLibrary,
  );

  final String templateId;
  final int version;
  final String title;
  final String locale;
  final String frontLanguage;
  final String backLanguage;
  final String contentSource;

  /// The scheduler the add sheet selects first (BR-STARTER-004).
  final SchedulerType suggestedScheduler;
  final int cardCount;
  final int subDeckCount;

  /// "In library" on the card, and "Add another copy" for its action
  /// (BR-STARTER-008).
  final bool isInLibrary;
}
```

- [ ] **Step 4: Watch the library**

In `lib/features/starter_decks/domain/repositories/starter_library_repository.dart`:

Replace

```dart
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';

```

with

```dart
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';

```

Replace

```dart
abstract interface class StarterLibraryRepository {
  /// UC-STARTER-001 step 8: the template [templateId] becomes a deck tree of
```

with

```dart
abstract interface class StarterLibraryRepository {
  /// UC-STARTER-001 steps 4-5: every bundled template, in manifest order,
  /// each with whether it is in the library; again after every write to the
  /// decks (spec §6, D12). A database error arrives as the stream's
  /// `Failure`.
  Stream<List<StarterLibraryEntry>> watchLibrary();

  /// UC-STARTER-001 step 8: the template [templateId] becomes a deck tree of
```

In `lib/features/starter_decks/data/datasources/starter_dao.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';

```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

```

Replace

```dart
  final AppDatabase _db;

```

with

```dart
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

```

In `lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
```

with

```dart
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
```

Replace

```dart

/// The Starter library over the bundled templates (starter decks spec §7). A
/// copy is written by the features that own each table, through their
/// contracts, inside one transaction (spec D2).
```

with

```dart

/// The Starter library over the bundled templates (starter decks spec §6,
/// §7). A copy is written by the features that own each table, through their
/// contracts, inside one transaction (spec D2).
```

Replace

```dart
  late final Future<List<StarterTemplate>> _templates = _loadTemplates();

```

with

```dart
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

```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 48 warning(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/starter_decks/data/watch_starter_library_test.dart
```

Expected: `+5: All tests passed!`

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/starter_decks/data/datasources/starter_dao.dart \
  lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart \
  lib/features/starter_decks/domain/models/starter_library_entry_model.dart \
  lib/features/starter_decks/domain/repositories/starter_library_repository.dart \
  test/features/starter_decks/data/watch_starter_library_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 48 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1823: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(starter): watch the Starter library and whether each template is in it

watchLibrary lists every bundled template in manifest order with what
screen 03 shows for it (title, languages, content source, suggested
scheduler, card and sub-deck counts) and whether a copy of it at its
version is outside the Trash (UC-STARTER-001 steps 4-5, A3, A4; spec
§6, D7). It reads again after every write to deck (D12); a database
error reaches the stream as its Failure.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: The use cases, and the package's documents

**Files:**
- Create: `lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart`, `lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart`
- Modify: `docs/features/starter-decks/README.md`, `docs/features/starter-decks/data.md`, `docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`
- Test (create): `test/features/starter_decks/domain/starter_library_use_cases_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 4's `addStarterDeck` and Task 5's `watchLibrary`.
- Produces:
  - `WatchStarterLibraryUseCase(StarterLibraryRepository)` with
    `Stream<List<StarterLibraryEntry>> call()`.
  - `AddStarterDeckUseCase(StarterLibraryRepository)` with
    `Future<Outcome<AddedStarterDeck, StarterRejection>> call({required String templateId, required SchedulerType schedulerType, bool allowSecondCopy = false})`.
  - The documents of spec §11.

Spec §9, §11; Clarification 7.

- [ ] **Step 1: Write the failing tests**

Create `test/features/starter_decks/domain/starter_library_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';
import 'package:memox/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart';
import 'package:memox/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart';

const _entry = StarterLibraryEntry(
  templateId: 'fixture.test',
  version: 1,
  title: 'Everyday',
  locale: 'en',
  frontLanguage: 'en',
  backLanguage: 'vi',
  contentSource: 'Development fixture',
  suggestedScheduler: SchedulerType.eightBox,
  cardCount: 3,
  subDeckCount: 2,
  isInLibrary: false,
);

const _added = AddedStarterDeck(
  rootDeckId: 'root',
  title: 'Everyday',
  schedulerType: SchedulerType.sm2,
  cardCount: 3,
);

/// A library that records what it is asked and answers [_entry] and [_added].
final class _Library implements StarterLibraryRepository {
  final adds = <(String, SchedulerType, bool)>[];

  @override
  Stream<List<StarterLibraryEntry>> watchLibrary() => Stream.value([_entry]);

  @override
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  }) async {
    adds.add((templateId, schedulerType, allowSecondCopy));
    return const Ok(_added);
  }
}

void main() {
  test('WatchStarterLibraryUseCase hands on the library as the repository '
      'reads it (UC-STARTER-001 step 5)', () async {
    expect(await WatchStarterLibraryUseCase(_Library()).call().first, [_entry]);
  });

  test('AddStarterDeckUseCase adds with the chosen scheduler and asks for a '
      'second copy only when told to (UC-STARTER-001 A2)', () async {
    final library = _Library();
    final add = AddStarterDeckUseCase(library);

    final first = await add(
      templateId: 'fixture.test',
      schedulerType: SchedulerType.sm2,
    );
    await add(
      templateId: 'fixture.test',
      schedulerType: SchedulerType.eightBox,
      allowSecondCopy: true,
    );

    expect((first as Ok<AddedStarterDeck, StarterRejection>).value, _added);
    expect(library.adds, [
      ('fixture.test', SchedulerType.sm2, false),
      ('fixture.test', SchedulerType.eightBox, true),
    ]);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/starter_decks/domain/starter_library_use_cases_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart': No such file or directory`,
the same for `add_starter_deck_use_case.dart`, and
`Error: Method not found: 'WatchStarterLibraryUseCase'.`

- [ ] **Step 3: Write the two use cases**

Create `lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart`:

```dart
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

/// UC-STARTER-001 steps 4-5: the templates bundled with the app, each with
/// whether it is already in the library, again after every change.
final class WatchStarterLibraryUseCase {
  const WatchStarterLibraryUseCase(this._library);

  final StarterLibraryRepository _library;

  Stream<List<StarterLibraryEntry>> call() => _library.watchLibrary();
}
```

Create `lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

/// UC-STARTER-001 steps 6-8 and A2: a template becomes a deck tree of the
/// person's own under the scheduler they chose; a second copy only when they
/// confirm one (BR-STARTER-008).
final class AddStarterDeckUseCase {
  const AddStarterDeckUseCase(this._library);

  final StarterLibraryRepository _library;

  Future<Outcome<AddedStarterDeck, StarterRejection>> call({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
  }) => _library.addStarterDeck(
    templateId: templateId,
    schedulerType: schedulerType,
    allowSecondCopy: allowSecondCopy,
  );
}
```

- [ ] **Step 4: Record the package in the starter documents and both WBS**

Replace the whole of `docs/features/starter-decks/README.md` with:

```markdown
---
feature: starter-decks
code: [lib/features/starter_decks/domain, lib/features/starter_decks/data, lib/features/starter_decks/di]
depends_on: [card, deck]
---
## Phạm vi

**Phạm vi:** Starter library, phần store (BE-B4,
[spec](../../superpowers/specs/2026-09-26-starter-decks-backend-design.md)). Màn 03 thuộc FE-B4.

Starter deck / template: thư viện starter và sao chép một template vào dữ liệu cá nhân.
Template là asset JSON đi kèm bản build (xem [`data.md`](data.md)); bản sao được ghi bởi
chính các feature sở hữu bảng (deck, card, srs) trong một transaction.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Thư viện starter (child flow trong tab Thư viện; empty state khi chưa có deck) | UC-STARTER-001 |

Nguồn: trigger của UC-STARTER-001 ("Mở app lần đầu sau khi cài"); [`shared/ui/navigation.md`](../../shared/ui/navigation.md) mục "Điều hướng top-level" ("Thư viện starter (M6) là child flow bên trong tab Thư viện").

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Nội dung từ vựng production | Dự án chưa có nguồn nội dung có bản quyền rõ ràng (BR-STARTER-010) |
```

Replace the whole of `docs/features/starter-decks/data.md` with:

````markdown
# Starter decks — dữ liệu

Bảng riêng của feature. Bảng dùng chung và mọi invariant nằm ở [`shared/data/schema.md`](../../shared/data/schema.md).

## `deck_templates`

**Phạm vi:** Starter library, phần store (BE-B4, [spec](../../superpowers/specs/2026-09-26-starter-decks-backend-design.md) §5).

**Đây không phải bảng runtime** — template là asset JSON đi kèm bản build:

```
assets/templates/
├── manifest.json            {"templates": ["en/everyday_en_vi.json", …]}
└── en/
    ├── everyday_en_vi.json
    └── hangul_basics.json
```

`manifest.json` liệt kê các file template theo thứ tự thư viện hiện chúng. Mỗi file là
một template:

| Trường JSON | Ghi chú |
|---|---|
| `templateId` | ổn định giữa các phiên bản app (BR-STARTER-002) |
| `version` | số nguyên từ 1, tăng khi nội dung đổi; bản sao ghi version tại thời điểm sao chép (BR-STARTER-004) |
| `locale` | ngôn ngữ của chữ trong template (tên và tên deck): `en`, `vi`, … |
| `title` | tên hiển thị, cũng là tên root deck của bản sao |
| `contentSource` | nguồn gốc nội dung, cho ghi công và kiểm tra bản quyền |
| `frontLanguage`, `backLanguage` | thẻ BCP 47 của hai mặt card (`en`, `vi`, `ko`, `ko-Latn`) |
| `defaultScheduler` | `eight_box` hoặc `sm2`: scheduler gợi ý; người dùng chọn khi thêm (BR-STARTER-004), đổi được trước lượt học đầu |
| `decks` | các deck con của root, theo thứ tự |

Template mô tả **cả cây deck**, không chỉ một danh sách card, vì bản sao phải
dựng lại đúng cấu trúc `content_type` và `root_id`. Mỗi deck có `name` và **hoặc**
`decks` **hoặc** `cards`, không cả hai và không danh sách rỗng; cây sâu tối đa 10 cấp kể
cả root (BR-DECK-001). Mỗi card có `front`, `back` và có thể có `example`, `hint`,
`pronunciation`, theo đúng luật card (BR-CARD-001…BR-CARD-003).

Manifest thiếu hoặc hỏng thì thư viện rỗng (UC-STARTER-001 E2). Một file thiếu, hỏng,
sai một luật trên, hoặc trùng `templateId` với file trước, thì bị bỏ qua và các template
khác vẫn hiện (E3).

## Fixture hiện có

| Template | `templateId` | Deck con | Card | Gợi ý |
|---|---|---|---|---|
| English → Vietnamese · Everyday | `fixture.everyday-en-vi` | Greetings, Food & drink, Travel, Home (mỗi deck 10) | 40 | Eight boxes |
| Korean → Romanisation · Hangul basics | `fixture.hangul-basics` | Consonants (14, tên chữ ở `hint`), Vowels (10) | 24 | SM-2 |

Nội dung starter hiện tại là **fixture do dự án tự tạo, chỉ phục vụ development
và test** (BR-STARTER-010); `contentSource` của cả hai là "Development fixture". Không mô
tả nó như nội dung production ở bất kỳ đâu — UI, store listing, hay tài liệu.
````

In `docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md`:

Replace

```markdown
rules: [BR-CARD-004, BR-DECK-002, BR-STARTER-001, BR-STARTER-002, BR-STARTER-003, BR-STARTER-004, BR-STARTER-005, BR-STARTER-006, BR-STARTER-007, BR-STARTER-008, BR-STARTER-009, BR-STARTER-010, BR-STUDY-077]
code: []
---
```

with

```markdown
rules: [BR-CARD-004, BR-DECK-002, BR-STARTER-001, BR-STARTER-002, BR-STARTER-003, BR-STARTER-004, BR-STARTER-005, BR-STARTER-006, BR-STARTER-007, BR-STARTER-008, BR-STARTER-009, BR-STARTER-010, BR-STUDY-077]
code: [lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart, lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart]
---
```

Replace

```markdown

**Phạm vi:** sub-project sau — Starter decks (spec §2).

```

with

```markdown

**Phạm vi:** Starter library, phần store (BE-B4, [spec](../../../superpowers/specs/2026-09-26-starter-decks-backend-design.md)). Màn 03
thuộc FE-B4.

```

Replace

```markdown

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
```

with

```markdown

- [ ] **Given** thư viện starter có template "English → Vietnamese · Everyday" và chưa có bản sao nào của nó, **when** người dùng thêm nó với SM-2, **then** có một root deck mới mang tên template, `source_template_id` và `source_template_version` của nó, `generation = 1`, `first_answered_at` NULL; bốn sub-deck theo đúng thứ tự; 40 card chưa học, mỗi card đúng một study state SM-2 (BR-STARTER-003, BR-STARTER-004).
- [ ] **Given** đã có một bản sao của đúng template và version đó nằm ngoài Trash, **when** người dùng thêm lại mà không xác nhận, **then** không có gì được ghi và lý do là `alreadyInLibrary`; khi người dùng xác nhận thêm bản sao thứ hai, có một cây deck thứ hai độc lập (BR-STARTER-007, BR-STARTER-008, A2).
- [ ] **Given** bản sao duy nhất của một template nằm trong Trash, **when** người dùng thêm template đó, **then** một bản sao mới được tạo mà không hỏi (A4).
- [ ] **Given** bản app mới nâng version của một template đã có bản sao, **when** thư viện hiện, **then** template được coi là chưa có trong thư viện, và thêm nó không đụng bản sao của version cũ (BR-STARTER-006, A3).
- [ ] **Given** manifest thiếu hoặc hỏng, **when** mở thư viện, **then** thư viện rỗng; **given** một file template hỏng, **then** chỉ template đó bị bỏ qua (E2, E3).
- [ ] **Given** một lần ghi thất bại giữa chừng khi sao chép, **when** thêm template, **then** không có root, deck, card hay study state nào được ghi (BR-STARTER-009, E4).
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | xong | BE-04, BE-05 | M–L | [spec](superpowers/specs/2026-09-26-card-transfer-design.md) và [plan](superpowers/plans/2026-09-26-card-transfer-backend.md); test trong `test/features/transfer/` và `test/features/card/data/card_transfer_test.dart` | FE-B3 dựng màn 11 và sheet 12 trên năm use case này |
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | chưa bắt đầu | BE-03, BE-04 | M | Cột `source_template_id` và `source_template_version` đã có trong `deck` | — |
| BE-B5 | Nhắc học hằng ngày (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012) | chưa bắt đầu | BE-03, BE-A4 | M | Các cột `reminder_*` trong `app_settings` đã có | Cần quyết định dependency thông báo cục bộ (xem Điểm chặn) |
```

with

```markdown
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | xong | BE-04, BE-05 | M–L | [spec](superpowers/specs/2026-09-26-card-transfer-design.md) và [plan](superpowers/plans/2026-09-26-card-transfer-backend.md); test trong `test/features/transfer/` và `test/features/card/data/card_transfer_test.dart` | FE-B3 dựng màn 11 và sheet 12 trên năm use case này |
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | xong | BE-03, BE-04 | M | [spec](superpowers/specs/2026-09-26-starter-decks-backend-design.md) và [plan](superpowers/plans/2026-09-26-starter-decks-backend.md); test trong `test/features/starter_decks/` | FE-B4 dựng màn 03 trên hai use case của `starter_decks` |
| BE-B5 | Nhắc học hằng ngày (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012) | chưa bắt đầu | BE-03, BE-A4 | M | Các cột `reminder_*` trong `app_settings` đã có | Cần quyết định dependency thông báo cục bộ (xem Điểm chặn) |
```

Replace

```markdown
| BE-C1 | Sắp tên theo thứ tự tiếng Việt. Hiện tên được so theo code unit, nên tên bắt đầu bằng Ă, Đ, Ơ… đứng sau "z" | bị chặn | — | S | `DeckLevelSort.name`; Clarification 13 của [plan backend deck/card](superpowers/plans/2026-09-23-deck-card-backend.md) | Chủ dự án quyết có thêm dependency collation hay không |
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
```

with

```markdown
| BE-C1 | Sắp tên theo thứ tự tiếng Việt. Hiện tên được so theo code unit, nên tên bắt đầu bằng Ă, Đ, Ơ… đứng sau "z" | bị chặn | — | S | `DeckLevelSort.name`; Clarification 13 của [plan backend deck/card](superpowers/plans/2026-09-23-deck-card-backend.md) | Chủ dự án quyết có thêm dependency collation hay không |
| BE-C5 | Chuẩn hoá Unicode (NFC) cho text trên toàn ứng dụng. Cùng một chữ có thể đến ở dạng dựng sẵn hoặc dạng tổ hợp (ví dụ `é` và `e` + U+0301), và `foldText` chỉ trim và hạ chữ thường, nên kiểm trùng (BR-TRANSFER-003), tên tag (BR-TAG-001) và tìm kiếm coi hai dạng là hai chuỗi khác nhau | bị chặn | — | S–M | Quyết định D17 của gói 9a (spec trên nhánh `claude/be-transfer`, không merge vì #72 đã làm BE-B3); dòng này mất theo gói đó và được thêm lại trong gói 10 | Chủ dự án quyết có chuẩn hoá ở mọi đường ghi text và ở phép fold hay không; Dart không có sẵn chuẩn hoá Unicode (xem Điểm chặn) |
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
```

Replace

```markdown
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở mọi UC | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D5 | Tỉa phần chỉ phục vụ CI của `build_verification_plan.py` (shard, `--github-output`, cờ Widgetbook và memox-api) cùng test của nó; sửa lời giúp của `dod_check.sh`, nơi `--changed` và `--fast` còn được tả theo CI của V7 | chưa bắt đầu | BE-D2 | M | CI của V8 chạy gate đầy đủ, không dùng planner ([spec gói 6](superpowers/specs/2026-09-25-ci-gate-design.md) D2, D11); planner vẫn phục vụ `dod_check.sh --changed` | Giữ phần `--changed` dùng, bỏ phần chỉ CI của V7 cần, kèm test |
```

with

```markdown
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 19 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D5 | Tỉa phần chỉ phục vụ CI của `build_verification_plan.py` (shard, `--github-output`, cờ Widgetbook và memox-api) cùng test của nó; sửa lời giúp của `dod_check.sh`, nơi `--changed` và `--fast` còn được tả theo CI của V7 | chưa bắt đầu | BE-D2 | M | CI của V8 chạy gate đầy đủ, không dùng planner ([spec gói 6](superpowers/specs/2026-09-25-ci-gate-design.md) D2, D11); planner vẫn phục vụ `dod_check.sh --changed` | Giữ phần `--changed` dùng, bỏ phần chỉ CI của V7 cần, kèm test |
```

Replace

```markdown
  task, final review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

with

```markdown
  task, final review toàn nhánh trước khi mở PR.
- **BE-B4** (gói 10, [spec](superpowers/specs/2026-09-26-starter-decks-backend-design.md),
  [plan](superpowers/plans/2026-09-26-starter-decks-backend.md)): gate xanh sau mỗi task,
  final review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

Replace

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 18/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRASH-001).
  4 UC còn lại chưa có code.

```

with

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 21/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
  UC còn lại (UC-REMINDER-001) chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 8 (BE-B2).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 10 (BE-B4).

```

Replace

```markdown
| BE-C1 | Chưa chốt có thêm dependency collation hay không | Thứ tự sort tên deck | Chủ dự án quyết |
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
```

with

```markdown
| BE-C1 | Chưa chốt có thêm dependency collation hay không | Thứ tự sort tên deck | Chủ dự án quyết |
| BE-C5 | Chưa chốt có chuẩn hoá Unicode (NFC) hay không, và nếu có thì bằng dependency nào | Kiểm trùng khi import, tên tag, tìm kiếm | Chủ dự án quyết; đổi phép fold là đổi dữ liệu đã lưu (`front_folded`, `back_folded`, `name_folded`), cần migration |
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
```

Replace

```markdown
| BE-B5 | BR-SETTINGS-008 ghi `Reset to defaults` đưa toàn bộ giá trị của `app_settings` về mặc định; BE-A1 (spec D6) chỉ đưa về mặc định bốn giá trị người dùng đặt được ở V8.0, chưa đụng `reminder_enabled`, `reminder_minute_of_day` | `Reset to defaults` khi nhắc học đã có giao diện | Quyết trong spec của BE-B5; sửa câu chữ BR-SETTINGS-008 cần chủ dự án cho phép |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | Cả 22 UC | Chủ dự án nêu phạm vi file được sửa |

```

with

```markdown
| BE-B5 | BR-SETTINGS-008 ghi `Reset to defaults` đưa toàn bộ giá trị của `app_settings` về mặc định; BE-A1 (spec D6) chỉ đưa về mặc định bốn giá trị người dùng đặt được ở V8.0, chưa đụng `reminder_enabled`, `reminder_minute_of_day` | `Reset to defaults` khi nhắc học đã có giao diện | Quyết trong spec của BE-B5; sửa câu chữ BR-SETTINGS-008 cần chủ dự án cho phép |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | 19 UC còn thiếu | Chủ dự án nêu phạm vi file được sửa |

```

Replace

```markdown

1. BE-B3…BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của chúng đọc `card` hoặc `deck` sẽ
   gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
```

with

```markdown

1. BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của nó đọc `card` hoặc `deck` sẽ
   gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
```

Replace

```markdown
  gộp, xoá tag, lọc card list theo tag; không đổi schema.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  gộp, xoá tag, lọc card list theo tag; không đổi schema.
- **Cập nhật ngày 2026-09-26:** BE-B4 xong trong gói 10: thư viện starter với hai
  fixture, sao chép trong một transaction qua repository của deck và card; không đổi
  schema. Thêm lại BE-C5 (Unicode NFC), dòng gói 9a đã thêm nhưng không merge.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | xong | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [plan export](superpowers/plans/2026-09-26-card-export-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md), [màn 12](shared/ui/screen-handoff/12-card-export.md); test trong `test/features/transfer/presentation/` | — |
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
| FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5, FE-A3 | S–M | [README reminders](features/reminders/README.md) | Sau BE-B5 |
```

with

```markdown
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | xong | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [plan export](superpowers/plans/2026-09-26-card-export-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md), [màn 12](shared/ui/screen-handoff/12-card-export.md); test trong `test/features/transfer/presentation/` | — |
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | BE-B4 xong: hợp đồng cho UI ở §9 của [spec gói 10](superpowers/specs/2026-09-26-starter-decks-backend-design.md); [ui.md](features/starter-decks/ui.md) | Màn 03 trên 2 use case của `starter_decks`: `WatchStarterLibraryUseCase` cho `loading`, `list`, `none`, `loadFailed`; `AddStarterDeckUseCase` cho `adding`, `added` (Open tới `rootDeckId`), `alreadyPresent` (`alreadyInLibrary`), `secondCopy` (xác nhận rồi gọi lại với `allowSecondCopy`) và `addFailed`; sheet chọn scheduler chọn sẵn `suggestedScheduler`; tên ngôn ngữ lấy từ thẻ BCP 47; note "Development fixture" theo BR-STARTER-010 |
| FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5, FE-A3 | S–M | [README reminders](features/reminders/README.md) | Sau BE-B5 |
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 47 warning(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/starter_decks/domain/starter_library_use_cases_test.dart
```

Expected: `+2: All tests passed!`

- [ ] **Step 6: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add docs/features/starter-decks/README.md \
  docs/features/starter-decks/data.md \
  docs/features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md \
  lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart \
  lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart \
  test/features/starter_decks/domain/starter_library_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 7: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 47 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1825: All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git commit -F - <<'EOF'
feat(starter): the Starter library's use cases, and the package's documents

WatchStarterLibraryUseCase and AddStarterDeckUseCase are what FE-B4 builds
screen 03 on (spec §9). UC-STARTER-001 and the starter-decks README name
their code and scope; the use case gets Given/When/Then for its main flow,
A2, A3, A4, E2, E3 and E4 in place of the open question, and data.md
describes the template files and the two fixtures (spec §11). wbs_BE.md:
BE-B4 done, BE-C5 back (spec D14), the traceability and BE-D4 counts as
they now stand. wbs_FE.md: FE-B4 points at spec §9. docs/_generated.
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-starter-decks` and open its pull request against `master`, then subscribe
to its activity.

Expected: CI is paused during active development (root `README.md`, "CI"), so no check
runs on the pull request; it merges on the local gate.

- [ ] **Step 2: Merge**

Merge `master` into `claude/be-starter-decks` if it moved, run the gate once more on the
branch head, and squash-merge only while it ends with `✓ mechanical gates passed`. Then
unsubscribe from the pull request's activity.


## Plan self-review

- **Spec coverage.** D1: no task touches the schema. D2: Tasks 2 and 4. D3: Task 1. D4,
  §5.3: Task 3. D5, §5.2: Task 3. D6, §5.1: Task 2, and Task 3 for the repeated id. D7,
  D8: Tasks 4 and 5. D9, D10, D11, §7: Task 4. D12, §6: Task 5. D13: no filter anywhere.
  D14: Task 6. §9: Tasks 5 and 6. §10: every line has its test in Tasks 2–6. §11: Task 6.
- **Placeholders.** None: every step carries its code or its command and its expected
  output.
- **Type consistency.** The Interfaces blocks name each signature once; the dry run
  compiled every task on top of the previous one.
- **Review Focus.** Each of the four lines has its test in the task that owns the code.
