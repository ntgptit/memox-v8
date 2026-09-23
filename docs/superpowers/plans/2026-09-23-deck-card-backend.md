# MemoX V8 Deck and Card Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the deck and card backend of MemoX V8 on the foundation: the
twelve deck and twelve card use cases of the spec's §6, with their models,
rules, queries and repository methods, so the UI session can wire screens to
them. No UI.

**Architecture:** ADR-011 layout, as the foundation built it. Each interaction
is one `<Name>UseCase` class in `lib/features/<f>/domain/usecases/` (AD-12)
that calls a repository contract; the repository implementations in `data/`
run every write in one Drift transaction and check write-time rules on rows
read inside it. Reads are Drift `watch()` streams, or one keyset page. The
read models whose cost matters — a deck level, the card counts, a history
page, the move targets, a deck search — are named queries in
`lib/core/database/queries/*.drift`; the card list builds its predicate in
one Dart function. The new `tags` feature has no use case: the card data
layer calls its repository inside the card's transaction, as it already calls
`ScheduleRepository.initializeCard`. A `DayClock` in `lib/core/clock/`
restarts the day-dependent watches at every local midnight.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4). Unchanged from the foundation:
`flutter_riverpod` 3.4.3 + `riverpod_generator` 4.0.9, `drift` / `drift_dev`
2.35.0, `sqlite3` 3.6.0, `uuid` 4.6.0, `build_runner` 2.16.1. New:
`characters` ^1.4.1 (already in `pubspec.lock` through Flutter, now a direct
dependency) and, for tests, `fake_async` ^1.3.3.

**Spec:** [`docs/superpowers/specs/2026-09-23-deck-card-backend-design.md`](../specs/2026-09-23-deck-card-backend-design.md),
stage 2 (§5–§11). Business rules: `docs/features/{deck,card,tags}/rules/`;
data model: [`docs/shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** [`2026-09-23-memox-v8-foundation.md`](2026-09-23-memox-v8-foundation.md)
Tasks 2–10 are done (stage 1 of the spec included). This plan runs on
`claude/project-folder-architecture-gbsw4r`, from the commit that adds it; the
code before it is `3b7e9d6`.

**How this plan was checked:** every code block below was written and run in a
scratch copy of the repository, task by task, test first. Each task's tests
failed as its "Expected" line says, then passed; after every task the
five-command gate passed and `tools/docs/check.py` reported 0 errors. The
"Expected" counts are the ones that run produced.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/` or the theme (spec §13). A parallel session builds the UI on
  `claude/flutter-ui-base-architecture-b55542`; `lib/main.dart`, `lib/app/`,
  `pubspec.yaml`, the guard's `overrides.yaml` and
  `test/architecture/boundary_rules.dart` are shared with it, so edits there stay
  small and additive (spec §12).
- A write returns `Future<Outcome<T, R>>`, with `R` the feature's rejection
  enum. A read returns a `Stream` fed by Drift's `watch()`, or one keyset page.
  A bulk operation takes a `Set<String>` of ids and is all or nothing in one
  transaction (BR-CARD-011). Each use case is a class `<Name>UseCase` in
  `<name>_use_case.dart`, exposing `call` (spec §6).
- Every write runs in one `db.transaction`. A rule that needs the data as it is
  at write time is checked on rows read inside that transaction. A rejection
  writes nothing (spec §9).
- Every read and every write filters `delete_batch_id IS NULL` on `deck` and
  `card`: a row in the Trash is out of reach (spec §8).
- `now` and `startOfToday` come from Dart and reach SQL as parameters;
  `startOfLocalDay` in `srs/domain/models/due_date_model.dart` is the one
  definition of the start of today (BR-STUDY-068).
- New is `learned_at IS NULL`. Due is `learned_at IS NOT NULL AND due_at <= now`,
  split into Overdue (`due_at < startOfToday`) and Due today
  (`due_at >= startOfToday`). Scheduled is `total − New − Due` (spec §8).
- "Characters" are grapheme clusters. Limits: deck name 200 (BR-DECK-020);
  `front` 60, `back` 240 (BR-CARD-002); `example`, `hint`, `pronunciation` 240
  (BR-CARD-003); tag name 50 and at most 10 tags per card (BR-TAG-001,
  BR-TAG-002).
- The folded form of a card side, a tag name, a deck name and a search term is
  `trim()` then `toLowerCase()` in Dart — `foldText` — never SQLite's `lower()`,
  which folds ASCII only.
- The Dart import map in `test/architecture/boundary_rules.dart`: `srs → ∅`,
  `tags → ∅`, `deck → {srs}`, `card → {deck, srs, tags}`. A feature never imports
  another feature's `data/` or `di/`.
- One statement per emission for a deck level; one statement for the card
  counts; one statement per history page (spec §11). Tests count them with
  `SelectCounter`.
- Drift writes that a watch must see go through the typed API or
  `customInsert` / `customUpdate` with `updates:`; `customStatement` does not
  notify watchers (foundation Global Constraints).
- Generated code (`*.g.dart`) is not committed. After a change to a `.drift`
  file or a `@riverpod` provider, run
  `dart run build_runner build --delete-conflicting-outputs`.
- After every task, the phased gate of the root `README.md` passes: the five
  commands of the "Run the phased gate" step.
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a use case id makes `docs/_generated/traceability.md` stale, so it runs
  `python3 tools/docs/generate.py` and `python3 tools/docs/check.py` (0 errors)
  and commits `docs/_generated/`.
- Code, identifiers, test names and commit messages are in English; the docs
  under `docs/` keep their Vietnamese.

## Clarifications to confirm during plan review

The spec is silent on these, or the code showed a better reading. Each is
decided here and implemented as described; say so if one is wrong.

1. **Deck search folds in Dart** (Task 6). `deck` has no folded-name column, so
   the query returns the decks in scope and Dart keeps those whose
   `foldText(name)` holds the folded term; spec §8 describes an SQL `instr`.
   The search looks strictly below the scope deck (the scope itself is not a
   hit), and a blank term finds nothing.
2. **The level summary counts every deck of the level, whatever the filter**
   (Task 5): filtering to Due decks does not shrink Overdue, Due today, New and
   Scheduled.
3. **`DeckTile` carries `startOfToday`** (Task 5), and `scheduleStatus` and
   `overdueDays` are getters on it: the derivation stays in the domain, on the
   day the use case asked for, without a second tile type.
4. **`DeckEntity.createOptions` offers no deck at the deepest level** (Task 6):
   an `unset` deck at depth 10 offers `{card}` (BR-DECK-001), beyond the list in
   spec §7.
5. **`CardMoveTarget` carries a path** like `DeckMoveTarget` (Task 9): deck names
   may repeat (BR-DECK-021), so a flat name list cannot tell targets apart. The
   tree walk that builds paths is domain code,
   `deck/domain/models/deck_tree_model.dart` (Task 6), so both features share it.
6. **`setFlagged` writes only the cards whose flag changes** (Task 7): a card
   already at the value keeps its `updated_at`, as reorder does (BR-SRS-007).
7. **One fold function, `lib/core/text/folded_text.dart`** (Task 5). Four
   features fold text; `core/text` joins the backend's core folders of spec §12.
8. **Watches map database errors** like one-shot reads, through the
   `mapDatabaseErrors()` stream extension in `core/error/failure.dart` (Task 5).
9. **Thin use cases are tested through scenarios over the real repositories**
   (Tasks 4, 6, 7, 9), not through fakes that only prove a call was forwarded
   (spec §11 mentions fakes). The watching use cases get a `FakeDayClock` and
   the real repositories, so their tests show what a person sees at midnight.
10. **The card list reads its counts after each window emission** (Task 8): one
    emission per change, two statements (the window and the counts).
11. **A missing card is told apart from an empty history in the same statement**
    (Task 9): the card is the left side of a `LEFT JOIN` onto `review_log`.
12. **Stored codes that belong to later sub-projects stay codes**:
    `ReviewHistoryEntry.mode` is the stored mode string (the study feature owns
    modes); `action` is typed as `EightBoxAction` or `Sm2Action`.
13. **Names sort by folded text in code-unit order**: `Ăn…` and `Đ…` sort after
    `z`. Locale-aware collation needs a dependency no spec asks for.
14. **Foundation code this plan changes**: the deck and card DAOs' `findRow`
    read active rows only; `CardRepository.createCard` takes a `CardDraft`,
    `deleteCard` becomes `deleteCards(Set)`, and `CardEntity.checkContent`
    gives way to `CardDraft.check`; `CardRepositoryImpl` takes a
    `TagRepository`; the srs row-to-state mapping moves into
    `CardScheduleState.fromColumns`.
15. **`verification_impact_map.json` names the owner of each query file**
    (Tasks 4 and 9): its test requires every `lib/core/database/queries/*.drift`
    to have one. The file is shared tooling outside spec §12's list.
16. **Not built, for the UI session and the spec owner**: the progress panel of
    IT-ORG-010 (`Mastered 1/4 (25%)`), which no read model in the spec covers;
    and the "progress" deck sort UC-DECK-006 names but no document defines.
    Batches use `IN (...)`, so one batch is capped at SQLite's 32,766 bound
    variables.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a
person, each pinned by a test in the task that owns the code:

1. **Two answers stored in the same second across a history page boundary**
   (`answered_at` has one-second resolution): the keyset tie-break on `id`
   repeats no row and loses none — Task 9, "answers in the same second".
2. **An empty selection reaching a batch write**: nothing is written, an `unset`
   target stays `unset`, no orphan tag is created — Task 3, "an empty batch
   writes nothing"; Task 7, "an empty batch writes nothing".
3. **A deck or card in the Trash**: invisible to every read, unreachable by every
   write — Tasks 4, 5, 6, 7, 8 and 9, the tests named "Trash".
4. **Local midnight passing while a screen is open**: Due today becomes Overdue
   and tomorrow's cards fall Due with no database write — Task 5 and Task 8, the
   "new local day" tests; the day count across a clock change — Task 2.
5. **Text beyond ASCII, and search terms holding `%` or `_`**: limits count
   graphemes, Vietnamese letters fold, and wildcards match literally — Task 1
   (graphemes), Task 6 (`ăn`), Task 8 (`NHÂN TỪ`, `%`).

## File Structure

New folders and files, each created by the task that first needs it (ADR-011
buckets; nothing is scaffolded ahead):

```
lib/core/clock/day_clock.dart                 DayClock, SystemDayClock, watchEachLocalDay   (Task 2)
lib/core/clock/di/day_clock_provider.dart     dayClockProvider                              (Task 2)
lib/core/text/folded_text.dart                foldText, the one fold                        (Task 5)
lib/core/database/queries/deck_queries.drift  deletion summary (4), level (5), view,
                                              move targets, search scope (6)
lib/core/database/queries/card_queries.drift  detail, history page, move targets            (Task 9)
lib/features/tags/                            TagEntity, TagRejection (1); TagRepository,
                                              TagDao, TagRepositoryImpl, provider (3)
lib/features/deck/domain/models/              schedule status (2); placement, deletion
                                              summary (4); level, level query (5); create
                                              option, path, tree, view, move target, search
                                              hit (6)
lib/features/deck/domain/usecases/            the 12 deck use cases (4, 5, 6)
lib/features/card/domain/models/              draft (1), display status (2); list query,
                                              list view (8); detail, history, move target (9)
lib/features/card/domain/usecases/            the 12 card use cases (7, 8, 9)
lib/features/card/data/datasources/           card_list_dao (8), card_detail_dao (9)
lib/features/card/data/mappers/card_mapper.dart  rows to entities and views       (8, 9)
test/support/                                 fake_day_clock (2), totalChanges (3),
                                              deck_fixtures (4), card_fixtures (5, 7),
                                              SelectCounter (5)
```

Changed foundation files: the deck and card rejection enums, `DeckEntity`,
`CardEntity`, the deck and card repositories, DAOs and contracts,
`due_date_model.dart`, `card_schedule_state_model.dart`,
`schedule_repository_impl.dart`, `failure.dart`, `app_database.dart`,
`card_repository_provider.dart`, `pubspec.yaml`, `boundary_rules.dart`,
`verification_impact_map.json`, the deck/card/tags docs, and the tests that
cover them.

---

### Task 1: Validation rules and rejection reasons

**Files:**
- Create: `lib/features/tags/domain/failures/tag_failure.dart`, `lib/features/tags/domain/entities/tag_entity.dart`, `lib/features/card/domain/models/card_draft_model.dart`
- Modify: `pubspec.yaml`, `lib/features/deck/domain/failures/deck_failure.dart`, `lib/features/deck/domain/entities/deck_entity.dart`, `lib/features/card/domain/failures/card_failure.dart`, `test/architecture/boundary_rules.dart`
- Test (create): `test/features/tags/domain/tag_entity_test.dart`, `test/features/card/domain/card_draft_model_test.dart`
- Test (modify): `test/features/deck/domain/deck_entity_test.dart`
- Regenerate: `pubspec.lock` (`flutter pub get`)

**Interfaces:**
- Consumes: `Outcome<T, R>` with `Ok(value)` and `Rejected(reason)`
  (`lib/core/error/outcome.dart`); `DeckEntity`, `DeckRejection`, `CardRejection`
  (foundation Tasks 6 and 9).
- Produces:
  - `DeckEntity.maxNameLength = 200`; `DeckEntity.checkName(String name)` now
    also answers `Rejected(DeckRejection.nameTooLong)` when the trimmed name has
    more than 200 grapheme clusters.
  - New reasons: `DeckRejection.{nameTooLong, notSiblings, sameParent}`;
    `CardRejection.{frontTooLong, backTooLong, optionalFieldTooLong,
    invalidTagName, tooManyTags, targetNotFound, targetIsRoot, targetHoldsDecks,
    sameDeck, crossRootMove}`.
  - `enum TagRejection { blankName, nameTooLong, controlCharacter, tooManyTags,
    notFound }` in `lib/features/tags/domain/failures/tag_failure.dart`.
  - `final class TagEntity({required String id, required String name})` with
    `maxNameLength = 50`, `maxPerCard = 10`,
    `static Outcome<void, TagRejection> checkName(String name)` and
    `static String fold(String name)`.
  - `final class CardDraft({required String front, required String back,
    String? example, String? hint, String? pronunciation, bool isFlagged = false,
    List<String> tagNames = const []})` with `maxFrontLength = 60`,
    `maxBackLength = 240`, `maxOptionalLength = 240`; static per-field rules
    `checkFront`, `checkBack`, `checkOptional`, `checkTagNames`, each
    `Outcome<void, CardRejection>`; and `check()`, the first failing field in
    form order.
  - Import map: `'tags': {}` and `'card': {'deck', 'srs', 'tags'}`.

Spec §7 "Validation" and "Rejection reasons". Every limit counts grapheme
clusters (`package:characters`), so `e` plus a combining accent is one
character. The per-field rules are static so a form can show each error at its
own field (UC-CARD-001 E1, E2); `check()` is what the repository runs.

- [ ] **Step 1: Write the failing tests**

In `test/features/deck/domain/deck_entity_test.dart`:

Replace

```dart
      expect(DeckEntity.checkName('Korean 101'), isA<_Allowed>());
```

with

```dart
      expect(DeckEntity.checkName('Korean 101'), isA<_Allowed>());
    });
    test('200 characters is the longest name (BR-DECK-020)', () {
      expect(DeckEntity.checkName('a' * 200), isA<_Allowed>());
      expect(
        _reasonOf(DeckEntity.checkName('a' * 201)),
        DeckRejection.nameTooLong,
      );
    });
    test('a character is what a person sees, not a code unit', () {
      // e + combining acute accent: one character, two code units.
      expect(DeckEntity.checkName('e\u0301' * 200), isA<_Allowed>());
      expect(
        _reasonOf(DeckEntity.checkName('e\u0301' * 201)),
        DeckRejection.nameTooLong,
      );
    });
    test('spaces around the name do not count', () {
      expect(DeckEntity.checkName(' ${'a' * 200} '), isA<_Allowed>());
```

Create `test/features/tags/domain/tag_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

TagRejection? _reasonOf(Outcome<void, TagRejection> result) => switch (result) {
  Ok() => null,
  Rejected(:final reason) => reason,
};

void main() {
  group('checkName (BR-TAG-001)', () {
    test('a blank name is refused', () {
      expect(_reasonOf(TagEntity.checkName('   ')), TagRejection.blankName);
    });

    test('50 characters is the longest name', () {
      expect(_reasonOf(TagEntity.checkName('a' * 50)), isNull);
      expect(
        _reasonOf(TagEntity.checkName('a' * 51)),
        TagRejection.nameTooLong,
      );
    });

    test('a character is what a person sees, not a code unit', () {
      expect(_reasonOf(TagEntity.checkName('e\u0301' * 50)), isNull);
      expect(
        _reasonOf(TagEntity.checkName('e\u0301' * 51)),
        TagRejection.nameTooLong,
      );
    });

    test('a control character inside the name is refused', () {
      for (final name in ['a\tb', 'a\u0007b', 'a\u007Fb', 'a\u0085b']) {
        expect(
          _reasonOf(TagEntity.checkName(name)),
          TagRejection.controlCharacter,
          reason: name.runes.toString(),
        );
      }
    });

    test('whitespace around the name is trimmed, not refused', () {
      expect(_reasonOf(TagEntity.checkName('\tNoun\n')), isNull);
    });
  });

  test('fold trims and lowercases, Unicode included', () {
    expect(TagEntity.fold('  Động Từ  '), 'động từ');
    expect(TagEntity.fold('NOUN'), 'noun');
  });
}
```

Create `test/features/card/domain/card_draft_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

CardRejection? _reasonOf(Outcome<void, CardRejection> result) =>
    switch (result) {
      Ok() => null,
      Rejected(:final reason) => reason,
    };

List<String> _tags(int count) => [for (var i = 0; i < count; i++) 'tag $i'];

void main() {
  group('checkFront (BR-CARD-001, BR-CARD-002)', () {
    test('a blank front is refused', () {
      expect(_reasonOf(CardDraft.checkFront('  ')), CardRejection.blankContent);
    });
    test('60 characters is the longest front, counted after trim', () {
      expect(_reasonOf(CardDraft.checkFront(' ${'a' * 60} ')), isNull);
      expect(
        _reasonOf(CardDraft.checkFront('a' * 61)),
        CardRejection.frontTooLong,
      );
    });
    test('a character is what a person sees, not a code unit', () {
      expect(_reasonOf(CardDraft.checkFront('e\u0301' * 60)), isNull);
      expect(
        _reasonOf(CardDraft.checkFront('e\u0301' * 61)),
        CardRejection.frontTooLong,
      );
    });
  });

  group('checkBack (BR-CARD-001, BR-CARD-002)', () {
    test('a blank back is refused', () {
      expect(_reasonOf(CardDraft.checkBack('')), CardRejection.blankContent);
    });
    test('240 characters is the longest back', () {
      expect(_reasonOf(CardDraft.checkBack('a' * 240)), isNull);
      expect(
        _reasonOf(CardDraft.checkBack('a' * 241)),
        CardRejection.backTooLong,
      );
    });
  });

  group('checkOptional (BR-CARD-003)', () {
    test('an absent or blank field is fine', () {
      expect(_reasonOf(CardDraft.checkOptional(null)), isNull);
      expect(_reasonOf(CardDraft.checkOptional('   ')), isNull);
    });
    test('240 characters is the longest optional field', () {
      expect(_reasonOf(CardDraft.checkOptional('a' * 240)), isNull);
      expect(
        _reasonOf(CardDraft.checkOptional('a' * 241)),
        CardRejection.optionalFieldTooLong,
      );
    });
  });

  group('checkTagNames (BR-TAG-001, BR-TAG-002)', () {
    test('ten distinct names are fine, eleven are too many', () {
      expect(_reasonOf(CardDraft.checkTagNames(_tags(10))), isNull);
      expect(
        _reasonOf(CardDraft.checkTagNames(_tags(11))),
        CardRejection.tooManyTags,
      );
    });
    test('names that fold alike count once', () {
      expect(
        _reasonOf(CardDraft.checkTagNames([..._tags(10), 'TAG 0', ' tag 1 '])),
        isNull,
      );
    });
    test('a name the tag rule refuses is an invalid tag name', () {
      expect(
        _reasonOf(CardDraft.checkTagNames(['ok', '  '])),
        CardRejection.invalidTagName,
      );
      expect(
        _reasonOf(CardDraft.checkTagNames(['a\u0007b'])),
        CardRejection.invalidTagName,
      );
    });
  });

  group('check', () {
    test('a valid draft passes', () {
      const draft = CardDraft(front: 'f', back: 'b', tagNames: ['noun']);
      expect(_reasonOf(draft.check()), isNull);
    });
    test(
      'the first failing field answers, front before back before the rest',
      () {
        expect(
          _reasonOf(const CardDraft(front: '', back: '').check()),
          CardRejection.blankContent,
        );
        expect(
          _reasonOf(
            CardDraft(front: 'f', back: 'b' * 241, hint: 'h' * 241).check(),
          ),
          CardRejection.backTooLong,
        );
        expect(
          _reasonOf(CardDraft(front: 'f', back: 'b', hint: 'h' * 241).check()),
          CardRejection.optionalFieldTooLong,
        );
        expect(
          _reasonOf(
            CardDraft(front: 'f', back: 'b', tagNames: _tags(11)).check(),
          ),
          CardRejection.tooManyTags,
        );
      },
    );
  });
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/features/deck/domain/deck_entity_test.dart \
  test/features/tags/domain/tag_entity_test.dart \
  test/features/card/domain/card_draft_model_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/features/deck/domain/deck_entity_test.dart` — `Error: Member not found: 'nameTooLong'.`
- `test/features/tags/domain/tag_entity_test.dart` — `Error when reading 'lib/features/tags/domain/entities/tag_entity.dart': No such file or directory`
- `test/features/card/domain/card_draft_model_test.dart` — `Error when reading 'lib/features/card/domain/models/card_draft_model.dart': No such file or directory`

- [ ] **Step 3: Add `characters` as a direct dependency**

In `pubspec.yaml`:

Replace

```yaml

dependencies:
  drift: ^2.35.0
```

with

```yaml

dependencies:
  characters: ^1.4.1
  drift: ^2.35.0
```

Then run `flutter pub get`. Expected: `Got dependencies!`, and `pubspec.lock` changes.

- [ ] **Step 4: Create the tag rejection reasons**

Create `lib/features/tags/domain/failures/tag_failure.dart`:

```dart
/// Why the tags feature refuses a write (ADR-011 D6).
enum TagRejection {
  /// BR-TAG-001: the name is blank after trim.
  blankName,

  /// BR-TAG-001: the name is longer than 50 characters.
  nameTooLong,

  /// BR-TAG-001: the name holds a control character.
  controlCharacter,

  /// BR-TAG-002: a card would carry more than 10 tags.
  tooManyTags,

  /// A card or tag no longer exists.
  notFound,
}
```

- [ ] **Step 5: Create `TagEntity` and the tag name rule**

Create `lib/features/tags/domain/entities/tag_entity.dart`:

```dart
import 'package:characters/characters.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

/// A tag, as a card carries it (BR-TAG-001).
final class TagEntity {
  const TagEntity({required this.id, required this.name});

  final String id;

  /// The canonical name, as the user first spelled it (trimmed).
  final String name;

  /// BR-TAG-001, in characters as a person sees them (grapheme clusters).
  static const maxNameLength = 50;

  /// BR-TAG-002.
  static const maxPerCard = 10;

  /// BR-TAG-001: not blank after trim, at most [maxNameLength] characters, no
  /// control character.
  static Outcome<void, TagRejection> checkName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Rejected(TagRejection.blankName);
    if (trimmed.characters.length > maxNameLength) {
      return const Rejected(TagRejection.nameTooLong);
    }
    if (trimmed.runes.any(_isControl)) {
      return const Rejected(TagRejection.controlCharacter);
    }
    return const Ok(null);
  }

  /// The form uniqueness is judged on (BR-TAG-001): trim, then lowercase, the
  /// same fold schema.md defines for `front_folded`. Written in Dart because
  /// SQLite's `lower()` is ASCII-only.
  static String fold(String name) => name.trim().toLowerCase();
}

/// Unicode category Cc: C0 controls, DEL and C1 controls.
bool _isControl(int rune) => rune < 0x20 || (rune >= 0x7F && rune <= 0x9F);
```

- [ ] **Step 6: Add the deck rejection reasons**

In `lib/features/deck/domain/failures/deck_failure.dart`:

Replace

```dart
  notFound,
```

with

```dart
  notFound,

  /// BR-DECK-020: the name is longer than 200 characters.
  nameTooLong,

  /// BR-SRS-007: the deck and its anchor no longer share a parent.
  notSiblings,

  /// A move to the parent the deck already has.
  sameParent,
```

- [ ] **Step 7: Count the deck name in characters**

In `lib/features/deck/domain/entities/deck_entity.dart`:

Replace

```dart
import 'package:memox/core/error/outcome.dart';
```

with

```dart
import 'package:characters/characters.dart';
import 'package:memox/core/error/outcome.dart';
```

Replace

```dart
  bool get isRoot => parentId == null;

  static Outcome<void, DeckRejection> checkName(String name) =>
      name.trim().isEmpty
      ? const Rejected(DeckRejection.blankName)
      : const Ok(null);
```

with

```dart
  /// BR-DECK-020, in characters as a person sees them (grapheme clusters).
  static const maxNameLength = 200;

  bool get isRoot => parentId == null;

  /// BR-DECK-020: not blank after trim, at most [maxNameLength] characters.
  static Outcome<void, DeckRejection> checkName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Rejected(DeckRejection.blankName);
    if (trimmed.characters.length > maxNameLength) {
      return const Rejected(DeckRejection.nameTooLong);
    }
    return const Ok(null);
  }
```

- [ ] **Step 8: Add the card rejection reasons**

Replace the whole of `lib/features/card/domain/failures/card_failure.dart` with:

```dart
/// Why the card feature refuses a write (ADR-011 D6).
enum CardRejection {
  /// BR-CARD-001: front or back is blank.
  blankContent,

  /// BR-DECK-004, BR-DECK-009: the target deck is a root or holds sub-decks.
  notACardContainer,

  /// The target deck, or the card, no longer exists.
  notFound,

  /// BR-CARD-002: the front is longer than 60 characters.
  frontTooLong,

  /// BR-CARD-002: the back is longer than 240 characters.
  backTooLong,

  /// BR-CARD-003: an example, hint or pronunciation longer than 240 characters.
  optionalFieldTooLong,

  /// BR-TAG-001: a tag name the tag rule refuses.
  invalidTagName,

  /// BR-TAG-002: more than 10 distinct tags on one card.
  tooManyTags,

  /// BR-CARD-010: the move target no longer exists.
  targetNotFound,

  /// BR-CARD-010, BR-DECK-004: the move target is a root deck.
  targetIsRoot,

  /// BR-CARD-010, BR-DECK-010: the move target holds sub-decks.
  targetHoldsDecks,

  /// BR-CARD-010: a card is already in the move target.
  sameDeck,

  /// BR-CARD-010: a card and the move target belong to different roots.
  crossRootMove,
}
```

- [ ] **Step 9: Create `CardDraft` and the card rules**

Create `lib/features/card/domain/models/card_draft_model.dart`:

```dart
import 'package:characters/characters.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';

/// What the add and edit forms submit (card `ui.md`): the content, the flag
/// and the tag names. The per-field rules are static so a form can show each
/// error at its own field (UC-CARD-001 E1, E2).
final class CardDraft {
  const CardDraft({
    required this.front,
    required this.back,
    this.example,
    this.hint,
    this.pronunciation,
    this.isFlagged = false,
    this.tagNames = const [],
  });

  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;
  final bool isFlagged;
  final List<String> tagNames;

  /// BR-CARD-002 and BR-CARD-003, in characters as a person sees them.
  static const maxFrontLength = 60;
  static const maxBackLength = 240;
  static const maxOptionalLength = 240;

  /// BR-CARD-001, BR-CARD-002.
  static Outcome<void, CardRejection> checkFront(String front) =>
      _checkSide(front, maxFrontLength, CardRejection.frontTooLong);

  /// BR-CARD-001, BR-CARD-002.
  static Outcome<void, CardRejection> checkBack(String back) =>
      _checkSide(back, maxBackLength, CardRejection.backTooLong);

  /// BR-CARD-003: an absent or blank example, hint or pronunciation is fine.
  static Outcome<void, CardRejection> checkOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.characters.length > maxOptionalLength) {
      return const Rejected(CardRejection.optionalFieldTooLong);
    }
    return const Ok(null);
  }

  /// BR-TAG-001, BR-TAG-002: every name passes the tag rule, and at most
  /// [TagEntity.maxPerCard] of them are distinct once folded.
  static Outcome<void, CardRejection> checkTagNames(List<String> names) {
    for (final name in names) {
      if (TagEntity.checkName(name) case Rejected()) {
        return const Rejected(CardRejection.invalidTagName);
      }
    }
    if (names.map(TagEntity.fold).toSet().length > TagEntity.maxPerCard) {
      return const Rejected(CardRejection.tooManyTags);
    }
    return const Ok(null);
  }

  /// The first failing field, in form order: front, back, example, hint,
  /// pronunciation, tags.
  Outcome<void, CardRejection> check() {
    final checks = [
      () => checkFront(front),
      () => checkBack(back),
      () => checkOptional(example),
      () => checkOptional(hint),
      () => checkOptional(pronunciation),
      () => checkTagNames(tagNames),
    ];
    for (final check in checks) {
      final result = check();
      if (result case Rejected()) return result;
    }
    return const Ok(null);
  }

  static Outcome<void, CardRejection> _checkSide(
    String side,
    int maxLength,
    CardRejection tooLong,
  ) {
    final trimmed = side.trim();
    if (trimmed.isEmpty) return const Rejected(CardRejection.blankContent);
    if (trimmed.characters.length > maxLength) return Rejected(tooLong);
    return const Ok(null);
  }
}
```

- [ ] **Step 10: Let `card` import `tags`, and give `tags` its empty import set**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'deck': {'srs'},
  'card': {'deck', 'srs'},
```

with

```dart
  'tags': {},
  'deck': {'srs'},
  'card': {'deck', 'srs', 'tags'},
```

- [ ] **Step 11: Run the task's tests**

```bash
flutter test test/features/deck/domain/deck_entity_test.dart \
  test/features/tags/domain/tag_entity_test.dart \
  test/features/card/domain/card_draft_model_test.dart
```

Expected: `+35: All tests passed!`

- [ ] **Step 12: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+218: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 13: Commit**

```bash
git add lib/features/card/domain/failures/card_failure.dart \
  lib/features/card/domain/models/card_draft_model.dart \
  lib/features/deck/domain/entities/deck_entity.dart \
  lib/features/deck/domain/failures/deck_failure.dart \
  lib/features/tags/domain/entities/tag_entity.dart \
  lib/features/tags/domain/failures/tag_failure.dart \
  pubspec.lock \
  pubspec.yaml \
  test/architecture/boundary_rules.dart \
  test/features/card/domain/card_draft_model_test.dart \
  test/features/deck/domain/deck_entity_test.dart \
  test/features/tags/domain/tag_entity_test.dart
git commit -m "feat(domain): add name, card and tag limits with their rejection reasons"
```


### Task 2: Day clock, local day and the two statuses

**Files:**
- Create: `lib/core/clock/day_clock.dart`, `lib/core/clock/di/day_clock_provider.dart`, `lib/features/deck/domain/models/deck_schedule_status_model.dart`, `lib/features/card/domain/models/card_display_status_model.dart`
- Modify: `pubspec.yaml`, `lib/features/srs/domain/models/due_date_model.dart`
- Test (create): `test/support/fake_day_clock.dart`, `test/core/clock/day_clock_test.dart`, `test/features/deck/domain/deck_schedule_status_model_test.dart`, `test/features/card/domain/card_display_status_model_test.dart`
- Test (modify): `test/features/srs/domain/due_date_model_test.dart`
- Regenerate: `pubspec.lock` (`flutter pub get`)

**Interfaces:**
- Consumes: `CardScheduleState` with `learnedAt`, `currentBox`, `intervalDays`
  (foundation Task 3); `dueAtLocalMidnight` in `due_date_model.dart`.
- Produces:
  - `abstract interface class DayClock { DateTime now(); Stream<DateTime>
    dayStarts(); }`, `final class SystemDayClock implements DayClock` with
    `const SystemDayClock({DateTime Function() now})` (defaults to
    `DateTime.now`), and `Stream<T> watchEachLocalDay<T>(DayClock clock,
    Stream<T> Function(DateTime now) watch)` — all in
    `lib/core/clock/day_clock.dart`.
  - `dayClockProvider` (`@Riverpod(keepAlive: true)`) in
    `lib/core/clock/di/day_clock_provider.dart`.
  - `DateTime startOfLocalDay(DateTime now)` in `due_date_model.dart`.
  - `enum DeckScheduleStatus { notDue, dueToday, overdue }` with
    `static DeckScheduleStatus of(DateTime? oldestDueAt, DateTime startOfToday)`
    and `static int overdueDays(DateTime? oldestDueAt, DateTime startOfToday)`.
  - `enum CardDisplayStatus { newCard, beginning, reviewing, mastered }` with
    `static CardDisplayStatus of(CardScheduleState state)`.
  - Test support: `FakeDayClock(DateTime current)` with `startDay(DateTime day)`
    in `test/support/fake_day_clock.dart`.

Spec §7 "Local day", "Deck schedule status", "Card display status" and §10.
`watchEachLocalDay` is how a read model changes at midnight with no write: it
follows `watch(clock.now())`, and at each `dayStarts` event it cancels that
watch and follows `watch(dayStart)`. Overdue days count calendar dates, never
hours divided by 24, so a clock change does not shift them (BR-STUDY-067).

- [ ] **Step 1: Write the failing tests**

Create `test/support/fake_day_clock.dart`:

```dart
import 'dart:async';

import 'package:memox/core/clock/day_clock.dart';

/// A day clock a test moves by hand: [startDay] is midnight arriving.
final class FakeDayClock implements DayClock {
  FakeDayClock(this.current);

  DateTime current;
  final _starts = StreamController<DateTime>.broadcast();

  @override
  DateTime now() => current;

  @override
  Stream<DateTime> dayStarts() => _starts.stream;

  void startDay(DateTime day) {
    current = day;
    _starts.add(day);
  }
}
```

Create `test/core/clock/day_clock_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/day_clock.dart';

import '../../support/fake_day_clock.dart';

void main() {
  test('SystemDayClock emits each local midnight, once', () {
    fakeAsync((async) {
      final time = async.getClock(DateTime(2026, 9, 23, 22, 30));
      final starts = <DateTime>[];
      SystemDayClock(now: time.now).dayStarts().listen(starts.add);

      async.elapse(const Duration(hours: 1, minutes: 29));
      expect(starts, isEmpty);
      async.elapse(const Duration(minutes: 2));
      expect(starts, [DateTime(2026, 9, 24)]);
      async.elapse(const Duration(days: 1));
      expect(starts, [DateTime(2026, 9, 24), DateTime(2026, 9, 25)]);
    });
  });

  test('watchEachLocalDay restarts the watch with the new day', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 23, 10));
    final watched = <DateTime>[];
    final values = <String>[];
    final subscription = watchEachLocalDay(clock, (now) {
      watched.add(now);
      return Stream.value('day ${now.day}');
    }).listen(values.add);
    await pumpEventQueue();

    clock.startDay(DateTime(2026, 9, 24));
    await pumpEventQueue();

    expect(watched, [DateTime(2026, 9, 23, 10), DateTime(2026, 9, 24)]);
    expect(values, ['day 23', 'day 24']);
    await subscription.cancel();
  });

  test('watchEachLocalDay stops the previous day watch', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 23, 10));
    final firstDay = StreamController<String>();
    final values = <String>[];
    final subscription = watchEachLocalDay(
      clock,
      (now) => now.day == 23 ? firstDay.stream : const Stream<String>.empty(),
    ).listen(values.add);
    await pumpEventQueue();

    clock.startDay(DateTime(2026, 9, 24));
    await pumpEventQueue();

    expect(firstDay.hasListener, isFalse);
    await subscription.cancel();
  });
}
```

In `test/features/srs/domain/due_date_model_test.dart`:

Replace

```dart
    expect(dueAtLocalMidnight(now, 30), DateTime(2026, 3, 31));
  });
}
```

with

```dart
    expect(dueAtLocalMidnight(now, 30), DateTime(2026, 3, 31));
  });

  test('startOfLocalDay drops the time of day', () {
    expect(
      startOfLocalDay(DateTime(2026, 9, 23, 23, 59)),
      DateTime(2026, 9, 23),
    );
  });
}
```

Create `test/features/deck/domain/deck_schedule_status_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';

void main() {
  final today = DateTime(2026, 9, 23);

  group('DeckScheduleStatus.of (BR-STUDY-067)', () {
    test('no Due card is notDue', () {
      expect(DeckScheduleStatus.of(null, today), DeckScheduleStatus.notDue);
    });
    test('the oldest Due card due today is dueToday', () {
      expect(DeckScheduleStatus.of(today, today), DeckScheduleStatus.dueToday);
    });
    test('the oldest Due card due before today is overdue', () {
      expect(
        DeckScheduleStatus.of(DateTime(2026, 9, 22), today),
        DeckScheduleStatus.overdue,
      );
    });
  });

  group('DeckScheduleStatus.overdueDays (BR-STUDY-067)', () {
    test('counts the local day boundaries crossed', () {
      expect(DeckScheduleStatus.overdueDays(DateTime(2026, 9, 20), today), 3);
    });
    test('is 0 when nothing is overdue', () {
      expect(DeckScheduleStatus.overdueDays(null, today), 0);
      expect(DeckScheduleStatus.overdueDays(today, today), 0);
    });
    test('counts calendar days, not hours / 24, across a clock change', () {
      // Europe moves its clocks on 2026-03-29: these two midnights are 47
      // hours apart there. Run with TZ=Europe/Berlin to see the difference.
      expect(
        DeckScheduleStatus.overdueDays(
          DateTime(2026, 3, 28),
          DateTime(2026, 3, 30),
        ),
        2,
      );
    });
  });
}
```

Create `test/features/card/domain/card_display_status_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

final _learnedAt = DateTime(2026, 9, 1);

CardScheduleState _box(int box) => CardScheduleState.initial(
  SchedulerType.eightBox,
  generation: 1,
).copyWith(learnedAt: _learnedAt, currentBox: box);

CardScheduleState _interval(int days) => CardScheduleState.initial(
  SchedulerType.sm2,
  generation: 1,
).copyWith(learnedAt: _learnedAt, intervalDays: days);

void main() {
  test('an unlearned card is new, whatever its values (BR-CARD-007)', () {
    expect(
      CardDisplayStatus.of(
        CardScheduleState.initial(SchedulerType.eightBox, generation: 1),
      ),
      CardDisplayStatus.newCard,
    );
    expect(
      CardDisplayStatus.of(
        CardScheduleState.initial(SchedulerType.sm2, generation: 1),
      ),
      CardDisplayStatus.newCard,
    );
  });

  test('eight_box: boxes 1-3 beginning, 4-7 reviewing, 8 mastered (BR-CARD-008, BR-SRS-013)', () {
    expect(CardDisplayStatus.of(_box(1)), CardDisplayStatus.beginning);
    expect(CardDisplayStatus.of(_box(3)), CardDisplayStatus.beginning);
    expect(CardDisplayStatus.of(_box(4)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_box(7)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_box(8)), CardDisplayStatus.mastered);
  });

  test('sm2: under 8 days beginning, 8-127 reviewing, 128 and up mastered (BR-CARD-008, BR-SRS-013)', () {
    expect(CardDisplayStatus.of(_interval(7)), CardDisplayStatus.beginning);
    expect(CardDisplayStatus.of(_interval(8)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_interval(127)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_interval(128)), CardDisplayStatus.mastered);
  });
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/core/clock/day_clock_test.dart \
  test/features/srs/domain/due_date_model_test.dart \
  test/features/deck/domain/deck_schedule_status_model_test.dart \
  test/features/card/domain/card_display_status_model_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/core/clock/day_clock_test.dart` — `Error when reading 'lib/core/clock/day_clock.dart': No such file or directory`
- `test/features/srs/domain/due_date_model_test.dart` — `Error: Method not found: 'startOfLocalDay'.`
- `test/features/deck/domain/deck_schedule_status_model_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_schedule_status_model.dart': No such file or directory`
- `test/features/card/domain/card_display_status_model_test.dart` — `Error when reading 'lib/features/card/domain/models/card_display_status_model.dart': No such file or directory`

- [ ] **Step 3: Add `fake_async` as a dev dependency**

In `pubspec.yaml`:

Replace

```yaml
  build_runner: ^2.16.1
```

with

```yaml
  build_runner: ^2.16.1
  fake_async: ^1.3.3
```

Then run `flutter pub get`. Expected: `Got dependencies!`, and `pubspec.lock` changes.

- [ ] **Step 4: Create the day clock and `watchEachLocalDay`**

Create `lib/core/clock/day_clock.dart`:

```dart
import 'dart:async';

/// The app's "now" and its local days (BR-STUDY-067, BR-STUDY-068). An
/// interface because tests drive days by hand — the reason ADR-010 accepts.
abstract interface class DayClock {
  DateTime now();

  /// The start of each new local day, from the next midnight on.
  Stream<DateTime> dayStarts();
}

final class SystemDayClock implements DayClock {
  const SystemDayClock({this._now = DateTime.now});

  final DateTime Function() _now;

  @override
  DateTime now() => _now();

  /// One timer per listener, re-armed after each midnight. The next midnight
  /// is counted from the one just emitted, so a timer that fires a little
  /// early never emits the same day twice.
  @override
  Stream<DateTime> dayStarts() {
    Timer? timer;
    late final StreamController<DateTime> controller;

    void armFor(DateTime midnight) {
      timer = Timer(midnight.difference(_now()), () {
        controller.add(midnight);
        armFor(DateTime(midnight.year, midnight.month, midnight.day + 1));
      });
    }

    controller = StreamController<DateTime>(
      onListen: () {
        final now = _now();
        armFor(DateTime(now.year, now.month, now.day + 1));
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }
}

/// [watch] for the current local day, started again at each new day with
/// that day's start as `now`. A read model whose sets depend on the day (Due,
/// Overdue) so changes at midnight with no database write (BR-STUDY-067,
/// BR-STUDY-068); `due_at` always falls on a local midnight (BR-STUDY-074),
/// so a day's start is as good a `now` as any instant of that day.
Stream<T> watchEachLocalDay<T>(
  DayClock clock,
  Stream<T> Function(DateTime now) watch,
) {
  StreamSubscription<T>? current;
  StreamSubscription<DateTime>? days;
  late final StreamController<T> controller;

  void follow(DateTime now) {
    current?.cancel();
    current = watch(now).listen(controller.add, onError: controller.addError);
  }

  controller = StreamController<T>(
    onListen: () {
      follow(clock.now());
      days = clock.dayStarts().listen(follow);
    },
    onCancel: () async {
      await days?.cancel();
      await current?.cancel();
    },
  );
  return controller.stream;
}
```

- [ ] **Step 5: Provide the day clock**

Create `lib/core/clock/di/day_clock_provider.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_clock_provider.g.dart';

@Riverpod(keepAlive: true)
DayClock dayClock(Ref ref) => const SystemDayClock();
```

- [ ] **Step 6: Add `startOfLocalDay`**

In `lib/features/srs/domain/models/due_date_model.dart`:

Replace

```dart
    DateTime(now.year, now.month, now.day + daysFromNow);
```

with

```dart
    DateTime(now.year, now.month, now.day + daysFromNow);

/// The start of [now]'s local day: the one boundary Due today and Overdue are
/// split on (BR-STUDY-068), computed here and passed to the queries, never in
/// SQL.
DateTime startOfLocalDay(DateTime now) =>
    DateTime(now.year, now.month, now.day);
```

- [ ] **Step 7: Create `DeckScheduleStatus`**

Create `lib/features/deck/domain/models/deck_schedule_status_model.dart`:

```dart
/// Where a deck's reviews stand today (BR-STUDY-067): derived on read, never
/// stored.
enum DeckScheduleStatus {
  notDue,
  dueToday,
  overdue;

  /// From the `due_at` of the subtree's oldest Due card (null when none is
  /// Due) and the start of the local day.
  static DeckScheduleStatus of(DateTime? oldestDueAt, DateTime startOfToday) {
    if (oldestDueAt == null) return notDue;
    if (oldestDueAt.isBefore(startOfToday)) return overdue;
    return dueToday;
  }

  /// The local day boundaries completed between the oldest Due card's
  /// `due_at` and today; 0 when nothing is overdue. Counted on calendar
  /// dates: hours / 24 is wrong across a clock change (BR-STUDY-067).
  static int overdueDays(DateTime? oldestDueAt, DateTime startOfToday) {
    if (oldestDueAt == null || !oldestDueAt.isBefore(startOfToday)) return 0;
    final due = oldestDueAt.toLocal();
    final today = startOfToday.toLocal();
    return DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(due.year, due.month, due.day)).inDays;
  }
}
```

- [ ] **Step 8: Create `CardDisplayStatus`**

Create `lib/features/card/domain/models/card_display_status_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';

/// The one of four states a card shows (BR-CARD-006): derived on read from
/// its schedule, never stored.
enum CardDisplayStatus {
  newCard,
  beginning,
  reviewing,
  mastered;

  // BR-CARD-008: `eight_box` boxes 1-3 are beginning, 4-7 reviewing; `sm2`
  // under 8 days is beginning. BR-SRS-013: mastered is box 8 or 128+ days.
  static const _reviewingFromBox = 4;
  static const _masteredBox = 8;
  static const _reviewingFromDays = 8;
  static const _masteredFromDays = 128;

  static CardDisplayStatus of(CardScheduleState state) {
    // BR-CARD-007: not learned yet is new, in both schedulers.
    if (state.learnedAt == null) return newCard;
    if (state.currentBox case final box?) {
      if (box >= _masteredBox) return mastered;
      return box >= _reviewingFromBox ? reviewing : beginning;
    }
    final days = state.intervalDays!;
    if (days >= _masteredFromDays) return mastered;
    return days >= _reviewingFromDays ? reviewing : beginning;
  }
}
```

- [ ] **Step 9: Generate the Drift and Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `Built with build_runner`, and no `drift_dev` warning.

- [ ] **Step 10: Run the task's tests**

```bash
flutter test test/core/clock/day_clock_test.dart \
  test/features/srs/domain/due_date_model_test.dart \
  test/features/deck/domain/deck_schedule_status_model_test.dart \
  test/features/card/domain/card_display_status_model_test.dart
```

Expected: `+17: All tests passed!`

- [ ] **Step 11: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+231: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 12: Commit**

```bash
git add lib/core/clock/day_clock.dart \
  lib/core/clock/di/day_clock_provider.dart \
  lib/features/card/domain/models/card_display_status_model.dart \
  lib/features/deck/domain/models/deck_schedule_status_model.dart \
  lib/features/srs/domain/models/due_date_model.dart \
  pubspec.lock \
  pubspec.yaml \
  test/core/clock/day_clock_test.dart \
  test/features/card/domain/card_display_status_model_test.dart \
  test/features/deck/domain/deck_schedule_status_model_test.dart \
  test/features/srs/domain/due_date_model_test.dart \
  test/support/fake_day_clock.dart
git commit -m "feat(core): add the day clock, the local day and the deck and card statuses"
```


### Task 3: The tags feature: attach, detach, replace

**Files:**
- Create: `lib/features/tags/domain/repositories/tag_repository.dart`, `lib/features/tags/data/datasources/tag_dao.dart`, `lib/features/tags/data/repositories/tag_repository_impl.dart`, `lib/features/tags/di/tag_repository_provider.dart`
- Modify: `lib/core/error/failure.dart`
- Test (create): `test/features/tags/data/tag_repository_impl_test.dart`
- Test (modify): `test/support/test_database.dart`, `test/core/error/failure_test.dart`

**Interfaces:**
- Consumes: `TagEntity.checkName`, `TagEntity.fold`, `TagEntity.maxPerCard`,
  `TagRejection` (Task 1); `AppDatabase` with `tags`, `card_tags`, `card`;
  `newId()`; `mapDatabaseError` (foundation).
- Produces:
  - `mapDatabaseError(Object error)` returns a `Failure` it is given unchanged:
    a repository running inside another's transaction maps first.
  - `abstract interface class TagRepository` with
    `attachByName({required Set<String> cardIds, required String name, DateTime? now})`,
    `detach({required Set<String> cardIds, required String tagId})` and
    `replaceForCard({required String cardId, required List<String> names, DateTime? now})`,
    each `Future<Outcome<void, TagRejection>>`, each joining the caller's
    transaction.
  - `TagRepositoryImpl(AppDatabase db, {DateTime Function()? now})`, `TagDao`,
    and `tagRepositoryProvider` in `lib/features/tags/di/`.
  - Test support: `Future<int> totalChanges(AppDatabase db)` in
    `test/support/test_database.dart`.

Spec §9 "Tags". Every rule is checked on rows read inside the transaction, and
the tag is created only once every rule has passed, so a refusal writes
nothing. An empty batch writes nothing and answers `Ok`. Tags has no use case
in this spec: the card data layer calls this repository inside the card's own
transaction (Task 7), and the card use cases call it for the selection bar.

- [ ] **Step 1: Write the failing tests**

Replace the whole of `test/support/test_database.dart` with:

```dart
import 'package:drift/native.dart';
import 'package:memox/core/database/app_database.dart';

/// Rows changed since the database opened: a refused write leaves it as it
/// was.
Future<int> totalChanges(AppDatabase db) async =>
    (await db.customSelect('SELECT total_changes() AS n').getSingle())
        .read<int>('n');

AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());
```

In `test/core/error/failure_test.dart`:

Replace

```dart
    },
  );
}
```

with

```dart
    },
  );

  test('a Failure already mapped stays as it is', () {
    const failure = ConstraintFailure(cause: 'x');
    expect(mapDatabaseError(failure), same(failure));
  });
}
```

Create `test/features/tags/data/tag_repository_impl_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/test_database.dart';

// Raw inserts: `tags` imports no feature (ADR-011 import map `tags → ∅`), so
// its tests do not either.

/// A root, a card sub-deck `leaf`, and the cards [cardIds] in it.
Future<void> _cards(AppDatabase db, List<String> cardIds) async {
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, '
    'scheduler_version, generation, sibling_position, created_at, updated_at) '
    "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES ('leaf', 'leaf', 'r', 'r', 2, 'card', 0, 0, 0)",
  );
  for (final id in cardIds) {
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES (?, 'leaf', 'f', 'b', 0, 0)",
      [id],
    );
  }
}

/// Gives [cardId] [count] tags named `own <cardId> <n>`.
Future<void> _tagged(AppDatabase db, String cardId, int count) async {
  for (var n = 0; n < count; n++) {
    final id = '$cardId-tag-$n';
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES (?, ?, ?, 0)",
      [id, 'own $cardId $n', 'own $cardId $n'],
    );
    await db.customStatement(
      'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
      [cardId, id],
    );
  }
}

Future<List<String>> _tagNamesOf(AppDatabase db, String cardId) async {
  final rows = await db
      .customSelect(
        'SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id '
        'WHERE ct.card_id = ? ORDER BY t.name_folded',
        variables: [Variable(cardId)],
      )
      .get();
  return [for (final row in rows) row.read<String>('name')];
}

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

TagRejection? _reasonOf(Outcome<void, TagRejection> result) => switch (result) {
  Ok() => null,
  Rejected(:final reason) => reason,
};

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;
  setUp(() {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  group('attachByName', () {
    test('creates the tag once and links every card (BR-TAG-001)', () async {
      await _cards(db, ['c1', 'c2']);

      final result = await tags.attachByName(
        cardIds: {'c1', 'c2'},
        name: '  Noun ',
      );

      expect(_reasonOf(result), isNull);
      expect(await _tagNamesOf(db, 'c1'), ['Noun']);
      expect(await _tagNamesOf(db, 'c2'), ['Noun']);
      expect(await _count(db, 'tags'), 1);
    });

    test(
      'reuses the tag whose folded name matches, keeping its spelling',
      () async {
        await _cards(db, ['c1', 'c2']);
        await tags.attachByName(cardIds: {'c1'}, name: 'Động Từ');

        await tags.attachByName(cardIds: {'c2'}, name: 'động từ');

        expect(await _count(db, 'tags'), 1);
        expect(await _tagNamesOf(db, 'c2'), ['Động Từ']);
      },
    );

    test(
      'is idempotent for a card that already carries the tag (BR-CARD-011)',
      () async {
        await _cards(db, ['c1']);
        await tags.attachByName(cardIds: {'c1'}, name: 'Noun');

        final result = await tags.attachByName(cardIds: {'c1'}, name: 'noun');

        expect(_reasonOf(result), isNull);
        expect(await _count(db, 'card_tags'), 1);
      },
    );

    test('refuses a name the tag rule refuses, writing nothing', () async {
      await _cards(db, ['c1']);
      final before = await totalChanges(db);

      final result = await tags.attachByName(cardIds: {'c1'}, name: '   ');

      expect(_reasonOf(result), TagRejection.blankName);
      expect(await totalChanges(db), before);
    });

    test('one card at 10 tags refuses the whole batch, writing nothing (BR-TAG-002)', () async {
      await _cards(db, ['full', 'free']);
      await _tagged(db, 'full', 10);
      final before = await totalChanges(db);

      final result = await tags.attachByName(
        cardIds: {'full', 'free'},
        name: 'Noun',
      );

      expect(_reasonOf(result), TagRejection.tooManyTags);
      expect(await totalChanges(db), before);
      expect(await _tagNamesOf(db, 'free'), isEmpty);
    });

    test('a card that already carries the tag is not over the limit', () async {
      await _cards(db, ['full']);
      await _tagged(db, 'full', 9);
      await tags.attachByName(cardIds: {'full'}, name: 'Noun');

      final result = await tags.attachByName(cardIds: {'full'}, name: 'NOUN');

      expect(_reasonOf(result), isNull);
    });

    test('a missing card refuses the batch with notFound', () async {
      await _cards(db, ['c1']);
      final before = await totalChanges(db);

      final result = await tags.attachByName(
        cardIds: {'c1', 'gone'},
        name: 'Noun',
      );

      expect(_reasonOf(result), TagRejection.notFound);
      expect(await totalChanges(db), before);
    });
  });

  group('detach', () {
    test(
      'unlinks the tag from the cards and keeps the tag (BR-TAG-003)',
      () async {
        await _cards(db, ['c1', 'c2']);
        await tags.attachByName(cardIds: {'c1', 'c2'}, name: 'Noun');
        final tagId = (await db.customSelect('SELECT id FROM tags').getSingle())
            .read<String>('id');

        final result = await tags.detach(cardIds: {'c1', 'c2'}, tagId: tagId);

        expect(_reasonOf(result), isNull);
        expect(await _count(db, 'card_tags'), 0);
        expect(await _count(db, 'tags'), 1);
      },
    );

    test('a card without the tag is not an error', () async {
      await _cards(db, ['c1', 'c2']);
      await tags.attachByName(cardIds: {'c1'}, name: 'Noun');
      final tagId = (await db.customSelect('SELECT id FROM tags').getSingle())
          .read<String>('id');

      final result = await tags.detach(cardIds: {'c1', 'c2'}, tagId: tagId);

      expect(_reasonOf(result), isNull);
    });

    test('a missing card or tag answers notFound, writing nothing', () async {
      await _cards(db, ['c1']);
      await tags.attachByName(cardIds: {'c1'}, name: 'Noun');
      final tagId = (await db.customSelect('SELECT id FROM tags').getSingle())
          .read<String>('id');
      final before = await totalChanges(db);

      expect(
        _reasonOf(await tags.detach(cardIds: {'c1', 'gone'}, tagId: tagId)),
        TagRejection.notFound,
      );
      expect(
        _reasonOf(await tags.detach(cardIds: {'c1'}, tagId: 'gone')),
        TagRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
  });

  group('replaceForCard', () {
    test('makes the card carry exactly the names given', () async {
      await _cards(db, ['c1']);
      await tags.replaceForCard(cardId: 'c1', names: ['Noun', 'Food']);

      final result = await tags.replaceForCard(
        cardId: 'c1',
        names: ['food', 'Verb'],
      );

      expect(_reasonOf(result), isNull);
      expect(await _tagNamesOf(db, 'c1'), ['Food', 'Verb']);
      expect(
        await _count(db, 'tags'),
        3,
        reason: 'Noun stays in the catalog (BR-TAG-003)',
      );
    });

    test(
      'more than 10 distinct names answer tooManyTags, writing nothing',
      () async {
        await _cards(db, ['c1']);
        final before = await totalChanges(db);

        final result = await tags.replaceForCard(
          cardId: 'c1',
          names: [for (var n = 0; n < 11; n++) 'tag $n'],
        );

        expect(_reasonOf(result), TagRejection.tooManyTags);
        expect(await totalChanges(db), before);
      },
    );

    test('a missing card answers notFound', () async {
      final result = await tags.replaceForCard(cardId: 'gone', names: ['Noun']);
      expect(_reasonOf(result), TagRejection.notFound);
    });
  });

  test('an empty batch writes nothing', () async {
    final before = await totalChanges(db);

    final attached = await tags.attachByName(cardIds: {}, name: 'Verb');
    final detached = await tags.detach(cardIds: {}, tagId: 'no such tag');

    expect(attached, isA<Ok<void, TagRejection>>());
    expect(detached, isA<Ok<void, TagRejection>>());
    expect(await totalChanges(db), before);
  });
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/core/error/failure_test.dart \
  test/features/tags/data/tag_repository_impl_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/core/error/failure_test.dart` — `Expected: same instance as <Instance of 'ConstraintFailure'>` / `Actual: <Instance of 'UnknownDatabaseFailure'>`
- `test/features/tags/data/tag_repository_impl_test.dart` — `Error when reading 'lib/features/tags/data/repositories/tag_repository_impl.dart': No such file or directory`

- [ ] **Step 3: Leave an already-mapped `Failure` as it is**

In `lib/core/error/failure.dart`:

Replace

```dart
Failure mapDatabaseError(Object error) {
```

with

```dart
/// A [Failure] is already mapped: a repository that runs inside another's
/// transaction maps first, and the outer one must not wrap it again.
Failure mapDatabaseError(Object error) {
  if (error is Failure) return error;
```

- [ ] **Step 4: Declare the tag repository contract**

Create `lib/features/tags/domain/repositories/tag_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

/// The one implementation is `TagRepositoryImpl` (data layer). The contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
///
/// Every method runs in one transaction and joins the caller's when there is
/// one: the card data layer calls it inside the card's own transaction. An
/// empty set of cards writes nothing and answers `Ok`.
abstract interface class TagRepository {
  /// Links the tag named [name] to every card of [cardIds]: the tag with the
  /// same folded name is reused, or created (BR-TAG-001). A card that already
  /// carries it is left as it is. When one card would pass 10 tags, the whole
  /// batch is refused and nothing is written (BR-TAG-002, BR-CARD-011).
  Future<Outcome<void, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  });

  /// Unlinks the tag [tagId] from every card of [cardIds]. A card without the
  /// tag is not an error; the tag itself stays (BR-TAG-003).
  Future<Outcome<void, TagRejection>> detach({
    required Set<String> cardIds,
    required String tagId,
  });

  /// Makes the tags of [cardId] exactly [names], one per folded name, with
  /// the rules of [attachByName].
  Future<Outcome<void, TagRejection>> replaceForCard({
    required String cardId,
    required List<String> names,
    DateTime? now,
  });
}
```

- [ ] **Step 5: Create the tag DAO**

Create `lib/features/tags/data/datasources/tag_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for `tags` and `card_tags`, plus the existence check of `card`
/// rows. It returns Drift rows, never domain entities, and runs inside the
/// caller's transaction.
final class TagDao {
  TagDao(this._db);

  final AppDatabase _db;

  /// The local profile's tag with [nameFolded]: `owner_id` is NULL for it
  /// (schema.md), as the unique index `COALESCE(owner_id, '')` reads it.
  Future<Tag?> findByFoldedName(String nameFolded) =>
      (_db.select(_db.tags)..where(
            (tag) => tag.ownerId.isNull() & tag.nameFolded.equals(nameFolded),
          ))
          .getSingleOrNull();

  Future<Tag?> findById(String id) => (_db.select(
    _db.tags,
  )..where((tag) => tag.id.equals(id))).getSingleOrNull();

  Future<void> insertTag(TagsCompanion row) => _db.into(_db.tags).insert(row);

  /// How many of [cardIds] exist as live cards; tombstones do not count.
  Future<int> liveCardCount(Set<String> cardIds) async {
    final count = _db.card.id.count();
    final query = _db.selectOnly(_db.card)
      ..addColumns([count])
      ..where(_db.card.id.isIn(cardIds) & _db.card.deleteBatchId.isNull());
    return (await query.getSingle()).read(count)!;
  }

  /// The tag ids [cardId] carries.
  Future<Set<String>> tagIdsOf(String cardId) async {
    final rows = await (_db.select(
      _db.cardTags,
    )..where((link) => link.cardId.equals(cardId))).get();
    return {for (final row in rows) row.tagId};
  }

  /// The cards of [cardIds] that already carry [tagId].
  Future<Set<String>> cardsCarrying(Set<String> cardIds, String tagId) async {
    final rows =
        await (_db.select(_db.cardTags)..where(
              (link) => link.cardId.isIn(cardIds) & link.tagId.equals(tagId),
            ))
            .get();
    return {for (final row in rows) row.cardId};
  }

  /// How many tags each of [cardIds] carries; a card with none is absent.
  Future<Map<String, int>> tagCounts(Set<String> cardIds) async {
    final count = _db.cardTags.tagId.count();
    final query = _db.selectOnly(_db.cardTags)
      ..addColumns([_db.cardTags.cardId, count])
      ..where(_db.cardTags.cardId.isIn(cardIds))
      ..groupBy([_db.cardTags.cardId]);
    return {
      for (final row in await query.get())
        row.read(_db.cardTags.cardId)!: row.read(count)!,
    };
  }

  Future<void> link(String cardId, String tagId) => _db
      .into(_db.cardTags)
      .insert(CardTagsCompanion.insert(cardId: cardId, tagId: tagId));

  Future<void> unlink(Set<String> cardIds, String tagId) =>
      (_db.delete(_db.cardTags)..where(
            (link) => link.cardId.isIn(cardIds) & link.tagId.equals(tagId),
          ))
          .go();
}
```

- [ ] **Step 6: Implement the tag repository**

Create `lib/features/tags/data/repositories/tag_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/tags/data/datasources/tag_dao.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// Every method checks its rules on rows read inside its transaction, and
/// writes only once every rule has passed: a refusal writes nothing.
final class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = TagDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final TagDao _dao;
  final DateTime Function() _now;

  @override
  Future<Outcome<void, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (TagEntity.checkName(name) case Rejected(:final reason)) {
        return Rejected(reason);
      }
      if (cardIds.isEmpty) return const Ok(null);
      if (await _dao.liveCardCount(cardIds) != cardIds.length) {
        return const Rejected(TagRejection.notFound);
      }
      final existing = await _dao.findByFoldedName(TagEntity.fold(name));
      final lacking = existing == null
          ? cardIds
          : cardIds.difference(await _dao.cardsCarrying(cardIds, existing.id));
      final counts = await _dao.tagCounts(lacking);
      if (counts.values.any((count) => count >= TagEntity.maxPerCard)) {
        return const Rejected(TagRejection.tooManyTags);
      }

      final tagId = existing?.id ?? await _createTag(name, at);
      for (final cardId in lacking) {
        await _dao.link(cardId, tagId);
      }
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, TagRejection>> detach({
    required Set<String> cardIds,
    required String tagId,
  }) => _write(() async {
    if (cardIds.isEmpty) return const Ok(null);
    if (await _dao.liveCardCount(cardIds) != cardIds.length) {
      return const Rejected(TagRejection.notFound);
    }
    if (await _dao.findById(tagId) == null) {
      return const Rejected(TagRejection.notFound);
    }
    await _dao.unlink(cardIds, tagId);
    return const Ok(null);
  });

  @override
  Future<Outcome<void, TagRejection>> replaceForCard({
    required String cardId,
    required List<String> names,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      for (final name in names) {
        if (TagEntity.checkName(name) case Rejected(:final reason)) {
          return Rejected(reason);
        }
      }
      final byFold = <String, String>{};
      for (final name in names) {
        byFold.putIfAbsent(TagEntity.fold(name), () => name);
      }
      if (byFold.length > TagEntity.maxPerCard) {
        return const Rejected(TagRejection.tooManyTags);
      }
      if (await _dao.liveCardCount({cardId}) != 1) {
        return const Rejected(TagRejection.notFound);
      }

      final wanted = <String>{};
      for (final MapEntry(key: folded, value: name) in byFold.entries) {
        final existing = await _dao.findByFoldedName(folded);
        wanted.add(existing?.id ?? await _createTag(name, at));
      }
      final carried = await _dao.tagIdsOf(cardId);
      for (final tagId in carried.difference(wanted)) {
        await _dao.unlink({cardId}, tagId);
      }
      for (final tagId in wanted.difference(carried)) {
        await _dao.link(cardId, tagId);
      }
      return const Ok(null);
    });
  }

  Future<String> _createTag(String name, DateTime at) async {
    final id = newId();
    await _dao.insertTag(
      TagsCompanion.insert(
        id: id,
        name: name.trim(),
        nameFolded: TagEntity.fold(name),
        createdAt: at,
      ),
    );
    return id;
  }

  /// One transaction, joining the caller's. An unexpected database error
  /// leaves as the [Failure] `mapDatabaseError` makes of it.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

- [ ] **Step 7: Provide the tag repository**

Create `lib/features/tags/di/tag_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_repository_provider.g.dart';

@riverpod
TagRepository tagRepository(Ref ref) =>
    TagRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 8: Generate the Drift and Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `Built with build_runner`, and no `drift_dev` warning.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/core/error/failure_test.dart \
  test/features/tags/data/tag_repository_impl_test.dart
```

Expected: `+18: All tests passed!`

- [ ] **Step 10: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+246: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 11: Commit**

```bash
git add lib/core/error/failure.dart \
  lib/features/tags/data/datasources/tag_dao.dart \
  lib/features/tags/data/repositories/tag_repository_impl.dart \
  lib/features/tags/di/tag_repository_provider.dart \
  lib/features/tags/domain/repositories/tag_repository.dart \
  test/core/error/failure_test.dart \
  test/features/tags/data/tag_repository_impl_test.dart \
  test/support/test_database.dart
git commit -m "feat(tags): add the tag repository that attaches, detaches and replaces tags"
```


### Task 4: Deck writes and the eight deck write use cases

**Files:**
- Create: `lib/core/database/queries/deck_queries.drift`, `lib/features/deck/domain/models/deck_deletion_summary_model.dart`, `lib/features/deck/domain/models/deck_placement_model.dart`, `lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart`, `lib/features/deck/domain/usecases/create_root_deck_use_case.dart`, `lib/features/deck/domain/usecases/create_sub_deck_use_case.dart`, `lib/features/deck/domain/usecases/delete_deck_use_case.dart`, `lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart`, `lib/features/deck/domain/usecases/move_deck_use_case.dart`, `lib/features/deck/domain/usecases/rename_deck_use_case.dart`, `lib/features/deck/domain/usecases/reorder_deck_use_case.dart`
- Modify: `lib/core/database/app_database.dart`, `lib/features/deck/domain/entities/deck_entity.dart`, `lib/features/deck/domain/repositories/deck_repository.dart`, `lib/features/deck/data/datasources/deck_dao.dart`, `lib/features/deck/data/repositories/deck_repository_impl.dart`, `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`
- Test (create): `test/support/deck_fixtures.dart`, `test/features/deck/data/deck_repository_impl_edit_test.dart`, `test/features/deck/domain/deck_write_use_cases_test.dart`
- Test (modify): `test/features/deck/domain/deck_entity_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `DeckEntity.checkName`, `DeckRejection.{nameTooLong, notSiblings,
  sameParent}` (Task 1); `totalChanges` (Task 3); foundation `DeckRepository`,
  `DeckRepositoryImpl`, `DeckDao`, and
  `ScheduleRepository.changeScheduler({required String rootDeckId, required SchedulerType newType})`.
- Produces:
  - `enum DeckPlacement { before, after }`;
    `final class DeckDeletionSummary({required int subDeckCount, required int cardCount})`.
  - `static List<String> DeckEntity.reorder(List<String> siblingIds,
    {required String movingId, required String anchorId, required DeckPlacement placement})`.
  - `DeckRepository.renameDeck({required String deckId, required String name, DateTime? now})`
    and `reorderDeck({required String deckId, required String anchorId,
    required DeckPlacement placement, DateTime? now})`, both
    `Future<Outcome<void, DeckRejection>>`;
    `deletionSummary(String deckId)` →
    `Future<Outcome<DeckDeletionSummary, DeckRejection>>`; `moveDeck` refuses
    `sameParent`.
  - `DeckDao.findRow` reads active decks only; new `siblingRows`, `rename`,
    `setSiblingPosition`, `deletionSummary`.
  - `lib/core/database/queries/deck_queries.drift` in `AppDatabase.include`,
    with `deckDeletionSummary`.
  - Use cases, each `const XUseCase(DeckRepository)` with a named-argument
    `call`: `CreateRootDeckUseCase(name, schedulerType)`,
    `CreateSubDeckUseCase(parentId, name)`, `RenameDeckUseCase(deckId, name)`,
    `GetDeckDeletionSummaryUseCase(deckId)`, `DeleteDeckUseCase(deckId)`,
    `MoveDeckUseCase(deckId, newParentId)`,
    `ReorderDeckUseCase(deckId, anchorId, placement)`; and
    `ChangeDeckSchedulerUseCase(ScheduleRepository)` with
    `call({rootDeckId, schedulerType})` → `Outcome<void, SrsRejection>`.
  - Test support: `extension DeckFixtures on DeckRepository` with
    `root(name, [schedulerType])` and `sub(parentId, name)`.

Spec §6 (deck writes) and §9. Reorder reads the deck and its anchor again inside
the transaction and refuses `notSiblings` when they no longer share a parent;
it numbers the group `0…n−1` and stamps `updated_at` only on the decks whose
position changed (BR-SRS-007). A deck in the Trash is out of reach: the DAO's
`findRow` now reads active rows only. The use cases forward to one repository
call each (AD-12), so they are tested through a scenario over the real
repositories.

- [ ] **Step 1: Write the failing tests**

Create `test/support/deck_fixtures.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// Decks made through the real repository, so every column is as the app
/// leaves it. A refusal here is a broken fixture, so it throws.
extension DeckFixtures on DeckRepository {
  Future<DeckEntity> root(
    String name, [
    SchedulerType type = SchedulerType.eightBox,
  ]) async => _made(await createRootDeck(name: name, schedulerType: type));

  Future<DeckEntity> sub(String parentId, String name) async =>
      _made(await createSubDeck(parentId: parentId, name: name));
}

DeckEntity _made(Outcome<DeckEntity, DeckRejection> result) => switch (result) {
  Ok(:final value) => value,
  Rejected(:final reason) => throw StateError('fixture deck refused: $reason'),
};
```

In `test/features/deck/domain/deck_entity_test.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
```

Replace

```dart
    });
  });
}
```

with

```dart
    });
  });

  group('reorder (BR-SRS-007)', () {
    test('places the deck before or after its anchor', () {
      expect(
        DeckEntity.reorder(
          ['a', 'b', 'c'],
          movingId: 'c',
          anchorId: 'a',
          placement: DeckPlacement.before,
        ),
        ['c', 'a', 'b'],
      );
      expect(
        DeckEntity.reorder(
          ['a', 'b', 'c'],
          movingId: 'a',
          anchorId: 'c',
          placement: DeckPlacement.after,
        ),
        ['b', 'c', 'a'],
      );
    });

    test('a deck anchored on itself keeps the order', () {
      expect(
        DeckEntity.reorder(
          ['a', 'b'],
          movingId: 'a',
          anchorId: 'a',
          placement: DeckPlacement.after,
        ),
        ['a', 'b'],
      );
    });
  });
}
```

Create `test/features/deck/data/deck_repository_impl_edit_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The edits stage 2 adds to the deck repository: rename, reorder, a move to
// the parent a deck already has, the deletion summary, and decks in the Trash.

DeckRejection _reason(Outcome<Object?, DeckRejection> result) =>
    (result as Rejected<Object?, DeckRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  Future<List<(String, int)>> siblings(String? parentId) async {
    final rows = await db
        .customSelect(
          'SELECT name, sibling_position FROM deck WHERE parent_id IS ? '
          'ORDER BY sibling_position, id',
          variables: [Variable<String>(parentId)],
        )
        .get();
    return [
      for (final row in rows)
        (row.read<String>('name'), row.read<int>('sibling_position')),
    ];
  }

  Future<void> insertCard(String id, String deckId, {String? batch}) async {
    await db.customStatement(
      "UPDATE deck SET content_type = 'card' WHERE id = ?",
      [deckId],
    );
    await db.customStatement(
      'INSERT INTO card (id, deck_id, front, back, delete_batch_id, '
      "created_at, updated_at) VALUES (?, ?, 'f', 'b', ?, 0, 0)",
      [id, deckId, batch],
    );
  }

  group('renameDeck', () {
    test(
      'stores the trimmed name and stamps updated_at (BR-DECK-020)',
      () async {
        final r = await repo.root('r');
        final later = DateTime(2026, 9, 24);

        final result = await repo.renameDeck(
          deckId: r.id,
          name: '  Korean  ',
          now: later,
        );

        expect(result, isA<Ok<void, DeckRejection>>());
        final renamed = (await repo.findById(r.id))!;
        expect((renamed.name, renamed.updatedAt), ('Korean', later));
      },
    );

    test(
      'refuses a blank or too long name and a missing deck, writing nothing',
      () async {
        final r = await repo.root('r');
        final before = await totalChanges(db);

        expect(
          _reason(await repo.renameDeck(deckId: r.id, name: ' ')),
          DeckRejection.blankName,
        );
        expect(
          _reason(await repo.renameDeck(deckId: r.id, name: 'a' * 201)),
          DeckRejection.nameTooLong,
        );
        expect(
          _reason(await repo.renameDeck(deckId: 'missing', name: 'x')),
          DeckRejection.notFound,
        );
        expect(await totalChanges(db), before);
      },
    );
  });

  group('reorderDeck (BR-SRS-007)', () {
    test(
      'puts the deck before or after its anchor and numbers the group from 0',
      () async {
        final r = await repo.root('r');
        final a = await repo.sub(r.id, 'a');
        await repo.sub(r.id, 'b');
        final c = await repo.sub(r.id, 'c');

        await repo.reorderDeck(
          deckId: c.id,
          anchorId: a.id,
          placement: DeckPlacement.before,
        );
        expect(await siblings(r.id), [('c', 0), ('a', 1), ('b', 2)]);

        await repo.reorderDeck(
          deckId: c.id,
          anchorId: a.id,
          placement: DeckPlacement.after,
        );
        expect(await siblings(r.id), [('a', 0), ('c', 1), ('b', 2)]);
      },
    );

    test(
      'only the decks whose position changed get a new updated_at',
      () async {
        final r = await repo.root('r');
        final a = await repo.sub(r.id, 'a');
        final b = await repo.sub(r.id, 'b');
        final c = await repo.sub(r.id, 'c');
        final later = DateTime(2026, 9, 24);

        await repo.reorderDeck(
          deckId: b.id,
          anchorId: c.id,
          placement: DeckPlacement.after,
          now: later,
        );

        expect(await siblings(r.id), [('a', 0), ('c', 1), ('b', 2)]);
        expect((await repo.findById(a.id))!.updatedAt, DateTime(2026, 9, 23));
        expect((await repo.findById(b.id))!.updatedAt, later);
        expect((await repo.findById(c.id))!.updatedAt, later);
      },
    );

    test('root decks reorder among the roots', () async {
      final x = await repo.root('x');
      final y = await repo.root('y');

      await repo.reorderDeck(
        deckId: y.id,
        anchorId: x.id,
        placement: DeckPlacement.before,
      );

      expect(await siblings(null), [('y', 0), ('x', 1)]);
    });

    test(
      'decks that no longer share a parent are refused, writing nothing',
      () async {
        final r = await repo.root('r');
        final a = await repo.sub(r.id, 'a');
        final b = await repo.sub(r.id, 'b');
        final inner = await repo.sub(a.id, 'inner');
        final before = await totalChanges(db);

        final result = await repo.reorderDeck(
          deckId: inner.id,
          anchorId: b.id,
          placement: DeckPlacement.before,
        );

        expect(_reason(result), DeckRejection.notSiblings);
        expect(await totalChanges(db), before);
      },
    );

    test('a missing deck or anchor answers notFound', () async {
      final r = await repo.root('r');
      final a = await repo.sub(r.id, 'a');

      final result = await repo.reorderDeck(
        deckId: a.id,
        anchorId: 'missing',
        placement: DeckPlacement.before,
      );

      expect(_reason(result), DeckRejection.notFound);
      expect(await siblings(r.id), [('a', 0)]);
    });
  });

  test('moving a deck to the parent it has is refused as sameParent, writing nothing', () async {
    final r = await repo.root('r');
    final a = await repo.sub(r.id, 'a');
    final before = await totalChanges(db);

    final result = await repo.moveDeck(deckId: a.id, newParentId: r.id);

    expect(_reason(result), DeckRejection.sameParent);
    expect(await totalChanges(db), before);
  });

  group('deletionSummary (BR-DECK-023)', () {
    test('counts every deck below and every card in the subtree', () async {
      final r = await repo.root('r');
      final branch = await repo.sub(r.id, 'branch');
      final leaf = await repo.sub(branch.id, 'leaf');
      await repo.sub(branch.id, 'empty');
      await insertCard('c1', leaf.id);

      final ofRoot = await repo.deletionSummary(r.id);
      final ofLeaf = await repo.deletionSummary(leaf.id);

      final rootSummary =
          (ofRoot as Ok<DeckDeletionSummary, DeckRejection>).value;
      final leafSummary =
          (ofLeaf as Ok<DeckDeletionSummary, DeckRejection>).value;
      expect((rootSummary.subDeckCount, rootSummary.cardCount), (3, 1));
      expect((leafSummary.subDeckCount, leafSummary.cardCount), (0, 1));
    });

    test('a missing deck answers notFound', () async {
      expect(
        _reason(await repo.deletionSummary('missing')),
        DeckRejection.notFound,
      );
    });
  });

  test(
    'a deck in the Trash is out of reach and not counted (spec §8)',
    () async {
      final r = await repo.root('r');
      final kept = await repo.sub(r.id, 'kept');
      final trashed = await repo.sub(r.id, 'trashed');
      await insertCard('c1', kept.id);
      await insertCard('gone', kept.id, batch: 'batch');
      await db.customStatement(
        "UPDATE deck SET delete_batch_id = 'batch' WHERE id = ?",
        [trashed.id],
      );

      expect(await repo.findById(trashed.id), isNull);
      final reorder = await repo.reorderDeck(
        deckId: kept.id,
        anchorId: trashed.id,
        placement: DeckPlacement.after,
      );
      expect(_reason(reorder), DeckRejection.notFound);
      final summary = await repo.deletionSummary(r.id);
      final counts = (summary as Ok<DeckDeletionSummary, DeckRejection>).value;
      expect((counts.subDeckCount, counts.cardCount), (1, 1));
    },
  );
}
```

Create `test/features/deck/domain/deck_write_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/usecases/change_deck_scheduler_use_case.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/create_sub_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/delete_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart';
import 'package:memox/features/deck/domain/usecases/move_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/rename_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/test_database.dart';

// The write use cases forward to one repository call each (AD-12). They are
// exercised here over the real repositories, so the test asserts what a
// person sees in the tree, not that a fake was called.

T _value<T>(Outcome<T, DeckRejection> result) =>
    (result as Ok<T, DeckRejection>).value;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  test('the deck write use cases drive the tree end to end (UC-DECK-001, UC-DECK-002, UC-DECK-004, UC-DECK-005, UC-DECK-006)', () async {
    final root = _value(
      await CreateRootDeckUseCase(decks)(
        name: 'Korean',
        schedulerType: SchedulerType.eightBox,
      ),
    );
    final createSub = CreateSubDeckUseCase(decks);
    final nouns = _value(await createSub(parentId: root.id, name: 'Nouns'));
    final verbs = _value(await createSub(parentId: root.id, name: 'Verbs'));
    final food = _value(await createSub(parentId: nouns.id, name: 'Food'));

    await RenameDeckUseCase(decks)(deckId: nouns.id, name: 'Things');
    await ReorderDeckUseCase(decks)(
      deckId: verbs.id,
      anchorId: nouns.id,
      placement: DeckPlacement.before,
    );
    await MoveDeckUseCase(decks)(deckId: food.id, newParentId: verbs.id);
    final summary = _value<DeckDeletionSummary>(
      await GetDeckDeletionSummaryUseCase(decks)(deckId: root.id),
    );
    await DeleteDeckUseCase(decks)(deckId: verbs.id);

    expect((await decks.findById(nouns.id))!.name, 'Things');
    expect((summary.subDeckCount, summary.cardCount), (3, 0));
    expect(await decks.findById(verbs.id), isNull);
    expect(
      await decks.findById(food.id),
      isNull,
      reason: 'deleted with its parent',
    );
  });

  test(
    'ChangeDeckSchedulerUseCase changes the scheduler of an unlocked root',
    () async {
      final root = _value<DeckEntity>(
        await CreateRootDeckUseCase(decks)(
          name: 'Korean',
          schedulerType: SchedulerType.eightBox,
        ),
      );

      final result = await ChangeDeckSchedulerUseCase(
        ScheduleRepositoryImpl(db),
      )(rootDeckId: root.id, schedulerType: SchedulerType.sm2);

      expect(result, isA<Ok<void, SrsRejection>>());
      expect((await decks.findById(root.id))!.schedulerType, SchedulerType.sm2);
    },
  );
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/features/deck/domain/deck_entity_test.dart \
  test/features/deck/data/deck_repository_impl_edit_test.dart \
  test/features/deck/domain/deck_write_use_cases_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/features/deck/domain/deck_entity_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_placement_model.dart': No such file or directory`
- `test/features/deck/data/deck_repository_impl_edit_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_deletion_summary_model.dart': No such file or directory`
- `test/features/deck/domain/deck_write_use_cases_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_deletion_summary_model.dart': No such file or directory`

- [ ] **Step 3: Create the deck query file with the deletion summary**

Create `lib/core/database/queries/deck_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';

-- BR-DECK-023: the active decks below :deck_id and the active cards of its
-- subtree. No row when :deck_id is not an active deck.
deckDeletionSummary:
WITH RECURSIVE subtree(id) AS (
  SELECT id FROM deck WHERE id = :deck_id AND delete_batch_id IS NULL
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
  WHERE d.delete_batch_id IS NULL
)
SELECT
  (SELECT COUNT(*) - 1 FROM subtree) AS sub_deck_count,
  (SELECT COUNT(*) FROM card c
   WHERE c.deck_id IN (SELECT id FROM subtree) AND c.delete_batch_id IS NULL)
    AS card_count
FROM deck
WHERE id = :deck_id AND delete_batch_id IS NULL;
```

- [ ] **Step 4: Include the deck queries in `AppDatabase`**

In `lib/core/database/app_database.dart`:

Replace

```dart
    'package:memox/core/database/tables/settings.drift',
```

with

```dart
    'package:memox/core/database/tables/settings.drift',
    'package:memox/core/database/queries/deck_queries.drift',
```

- [ ] **Step 5: Create `DeckDeletionSummary`**

Create `lib/features/deck/domain/models/deck_deletion_summary_model.dart`:

```dart
/// What deleting a deck takes with it, told to the person before they
/// confirm (BR-DECK-023).
final class DeckDeletionSummary {
  const DeckDeletionSummary({
    required this.subDeckCount,
    required this.cardCount,
  });

  /// Every deck below the deck, at any depth.
  final int subDeckCount;

  /// Every card in the deck and in the decks below it.
  final int cardCount;
}
```

- [ ] **Step 6: Create `DeckPlacement`**

Create `lib/features/deck/domain/models/deck_placement_model.dart`:

```dart
/// Where a reordered deck lands next to its anchor (UC-DECK-006).
enum DeckPlacement { before, after }
```

- [ ] **Step 7: Add the reorder rule to `DeckEntity`**

In `lib/features/deck/domain/entities/deck_entity.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
```

Replace

```dart
      return const Rejected(DeckRejection.nameTooLong);
    }
    return const Ok(null);
  }
```

with

```dart
      return const Rejected(DeckRejection.nameTooLong);
    }
    return const Ok(null);
  }

  /// BR-SRS-007: the manual order of a sibling group once [movingId] sits
  /// just before or just after [anchorId]. Both ids are in [siblingIds]; the
  /// caller numbers the result from 0.
  static List<String> reorder(
    List<String> siblingIds, {
    required String movingId,
    required String anchorId,
    required DeckPlacement placement,
  }) {
    if (movingId == anchorId) return List.of(siblingIds);
    final order = [
      for (final id in siblingIds)
        if (id != movingId) id,
    ];
    final anchorAt = order.indexOf(anchorId);
    final insertAt = switch (placement) {
      DeckPlacement.before => anchorAt,
      DeckPlacement.after => anchorAt + 1,
    };
    return order..insert(insertAt, movingId);
  }
```

- [ ] **Step 8: Extend the deck repository contract**

In `lib/features/deck/domain/repositories/deck_repository.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
```

with

```dart
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
```

Replace

```dart
  });

  Future<Outcome<void, DeckRejection>> moveDeck({
```

with

```dart
  });

  /// BR-DECK-020: the trimmed name replaces the old one.
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
    DateTime? now,
  });

  /// BR-SRS-007: [deckId] moves just before or after [anchorId], a deck with
  /// the same parent, and the group is numbered again from 0.
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
    DateTime? now,
  });

  /// BR-DECK-023: what deleting [deckId] would take with it.
  Future<Outcome<DeckDeletionSummary, DeckRejection>> deletionSummary(
    String deckId,
  );

  Future<Outcome<void, DeckRejection>> moveDeck({
```

- [ ] **Step 9: Read active decks only, and add the DAO methods**

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart
  Future<Deck?> findRow(String id) => (_db.select(
    _db.deck,
  )..where((deck) => deck.id.equals(id))).getSingleOrNull();
```

with

```dart
  /// An active deck: a deck in the Trash is out of reach of every write
  /// (spec §8).
  Future<Deck?> findRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The active decks under [parentId] in manual order, `(sibling_position,
  /// id)` (BR-SRS-007); a null parent selects the roots.
  Future<List<Deck>> siblingRows(String? parentId) =>
      (_db.select(_db.deck)
            ..where(
              (deck) =>
                  deck.parentId.isExp(Variable<String>(parentId)) &
                  deck.deleteBatchId.isNull(),
            )
            ..orderBy([
              (deck) => OrderingTerm(expression: deck.siblingPosition),
              (deck) => OrderingTerm(expression: deck.id),
            ]))
          .get();

  Future<void> rename(String id, String name, DateTime now) =>
      (_db.update(_db.deck)..where((deck) => deck.id.equals(id))).write(
        DeckCompanion(name: Value(name), updatedAt: Value(now)),
      );

  Future<void> setSiblingPosition(String id, int position, DateTime now) =>
      (_db.update(_db.deck)..where((deck) => deck.id.equals(id))).write(
        DeckCompanion(siblingPosition: Value(position), updatedAt: Value(now)),
      );

  /// One statement (`deck_queries.drift`); null when [id] is not an active
  /// deck.
  Future<DeckDeletionSummaryResult?> deletionSummary(String id) =>
      _db.deckDeletionSummary(id).getSingleOrNull();
```

- [ ] **Step 10: Implement rename, reorder, the deletion summary and `sameParent`**

In `lib/features/deck/data/repositories/deck_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
```

Replace

```dart
        return const Rejected(DeckRejection.rootCannotMove);
      }
      final movingRoot = await _dao.findRow(moving.rootId);
```

with

```dart
        return const Rejected(DeckRejection.rootCannotMove);
      }
      if (oldParentId == newParentId) {
        return const Rejected(DeckRejection.sameParent);
      }
      final movingRoot = await _dao.findRow(moving.rootId);
```

Replace

```dart
      await _refreshContentType(newParentId, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId}) {
```

with

```dart
      await _refreshContentType(newParentId, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (_refusal(DeckEntity.checkName(name)) case final reason?) {
        return Rejected(reason);
      }
      if (await _dao.findRow(deckId) == null) {
        return const Rejected(DeckRejection.notFound);
      }
      await _dao.rename(deckId, name.trim(), at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final deck = await _dao.findRow(deckId);
      final anchor = await _dao.findRow(anchorId);
      if (deck == null || anchor == null) {
        return const Rejected(DeckRejection.notFound);
      }
      if (deck.parentId != anchor.parentId) {
        return const Rejected(DeckRejection.notSiblings);
      }
      final siblings = await _dao.siblingRows(deck.parentId);
      final order = DeckEntity.reorder(
        [for (final row in siblings) row.id],
        movingId: deckId,
        anchorId: anchorId,
        placement: placement,
      );
      final positionOf = {
        for (final row in siblings) row.id: row.siblingPosition,
      };
      for (final (position, id) in order.indexed) {
        if (positionOf[id] == position) continue;
        await _dao.setSiblingPosition(id, position, at);
      }
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<DeckDeletionSummary, DeckRejection>> deletionSummary(
    String deckId,
  ) => _mapped(() async {
    final row = await _dao.deletionSummary(deckId);
    if (row == null) return const Rejected(DeckRejection.notFound);
    return Ok(
      DeckDeletionSummary(
        subDeckCount: row.subDeckCount,
        cardCount: row.cardCount,
      ),
    );
  });

  @override
  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId}) {
```

- [ ] **Step 11: Create `change_deck_scheduler_use_case.dart`**

Create `lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';

/// UC-DECK-002: another scheduler for a root deck no card of which has been
/// answered yet (BR-SRS-002, BR-SRS-004); its open sessions end
/// (BR-STUDY-016).
final class ChangeDeckSchedulerUseCase {
  const ChangeDeckSchedulerUseCase(this._schedules);

  final ScheduleRepository _schedules;

  Future<Outcome<void, SrsRejection>> call({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => _schedules.changeScheduler(
    rootDeckId: rootDeckId,
    newType: schedulerType,
  );
}
```

- [ ] **Step 12: Create `create_root_deck_use_case.dart`**

Create `lib/features/deck/domain/usecases/create_root_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// UC-DECK-001: a new root deck and the scheduler its cards will follow.
final class CreateRootDeckUseCase {
  const CreateRootDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<DeckEntity, DeckRejection>> call({
    required String name,
    required SchedulerType schedulerType,
  }) => _decks.createRootDeck(name: name, schedulerType: schedulerType);
}
```

- [ ] **Step 13: Create `create_sub_deck_use_case.dart`**

Create `lib/features/deck/domain/usecases/create_sub_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-004, deck branch: a new deck at the end of [parentId]'s decks.
final class CreateSubDeckUseCase {
  const CreateSubDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<DeckEntity, DeckRejection>> call({
    required String parentId,
    required String name,
  }) => _decks.createSubDeck(parentId: parentId, name: name);
}
```

- [ ] **Step 14: Create `delete_deck_use_case.dart`**

Create `lib/features/deck/domain/usecases/delete_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-002: the deck and everything below it are gone (BR-DECK-022).
final class DeleteDeckUseCase {
  const DeleteDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({required String deckId}) =>
      _decks.deleteDeck(deckId: deckId);
}
```

- [ ] **Step 15: Create `get_deck_deletion_summary_use_case.dart`**

Create `lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// BR-DECK-023: the decks and cards a delete would take, for the confirmation.
final class GetDeckDeletionSummaryUseCase {
  const GetDeckDeletionSummaryUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<DeckDeletionSummary, DeckRejection>> call({
    required String deckId,
  }) => _decks.deletionSummary(deckId);
}
```

- [ ] **Step 16: Create `move_deck_use_case.dart`**

Create `lib/features/deck/domain/usecases/move_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-005: the deck and its subtree go under [newParentId], at the end
/// of its decks.
final class MoveDeckUseCase {
  const MoveDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required String deckId,
    required String newParentId,
  }) => _decks.moveDeck(deckId: deckId, newParentId: newParentId);
}
```

- [ ] **Step 17: Create `rename_deck_use_case.dart`**

Create `lib/features/deck/domain/usecases/rename_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-002: a new name for a deck (BR-DECK-020).
final class RenameDeckUseCase {
  const RenameDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required String deckId,
    required String name,
  }) => _decks.renameDeck(deckId: deckId, name: name);
}
```

- [ ] **Step 18: Create `reorder_deck_use_case.dart`**

Create `lib/features/deck/domain/usecases/reorder_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-006: the deck moves just before or after a sibling (BR-SRS-007).
final class ReorderDeckUseCase {
  const ReorderDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
  }) => _decks.reorderDeck(
    deckId: deckId,
    anchorId: anchorId,
    placement: placement,
  );
}
```

- [ ] **Step 19: Name the owner of the deck queries**

The workflow tooling test `test_every_database_query_has_a_declared_owner` requires every `lib/core/database/queries/*.drift` file to name its feature.

In `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`:

Replace

```json
  "database_query_features": {},
```

with

```json
  "database_query_features": {
    "deck_queries": ["deck"]
  },
```

- [ ] **Step 20: Regenerate the docs index and check the docs**

`docs/_generated/traceability.md` lists, for each use case, the tests
that name its id, and `docs/README.md` wants docs and code in the same commit;
this task's tests name use case ids.

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `OK docs/_generated: generated 3 files`, then `PASS — 0 error(s), 84 warning(s)`.

- [ ] **Step 21: Generate the Drift and Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `Built with build_runner`, and no `drift_dev` warning.

- [ ] **Step 22: Run the task's tests**

```bash
flutter test test/features/deck/domain/deck_entity_test.dart \
  test/features/deck/data/deck_repository_impl_edit_test.dart \
  test/features/deck/domain/deck_write_use_cases_test.dart
```

Expected: `+32: All tests passed!`

- [ ] **Step 23: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+261: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 24: Commit**

```bash
git add .claude/skills/flutter-workflow/scripts/verification_impact_map.json \
  docs/_generated \
  lib/core/database/app_database.dart \
  lib/core/database/queries/deck_queries.drift \
  lib/features/deck/data/datasources/deck_dao.dart \
  lib/features/deck/data/repositories/deck_repository_impl.dart \
  lib/features/deck/domain/entities/deck_entity.dart \
  lib/features/deck/domain/models/deck_deletion_summary_model.dart \
  lib/features/deck/domain/models/deck_placement_model.dart \
  lib/features/deck/domain/repositories/deck_repository.dart \
  lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart \
  lib/features/deck/domain/usecases/create_root_deck_use_case.dart \
  lib/features/deck/domain/usecases/create_sub_deck_use_case.dart \
  lib/features/deck/domain/usecases/delete_deck_use_case.dart \
  lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart \
  lib/features/deck/domain/usecases/move_deck_use_case.dart \
  lib/features/deck/domain/usecases/rename_deck_use_case.dart \
  lib/features/deck/domain/usecases/reorder_deck_use_case.dart \
  test/features/deck/data/deck_repository_impl_edit_test.dart \
  test/features/deck/domain/deck_entity_test.dart \
  test/features/deck/domain/deck_write_use_cases_test.dart \
  test/support/deck_fixtures.dart
git commit -m "feat(deck): add rename, reorder, deletion summary and the deck write use cases"
```


### Task 5: The deck level read model

**Files:**
- Create: `lib/core/text/folded_text.dart`, `lib/features/deck/domain/models/deck_level_model.dart`, `lib/features/deck/domain/models/deck_level_query_model.dart`, `lib/features/deck/domain/usecases/watch_deck_level_use_case.dart`
- Modify: `lib/core/error/failure.dart`, `lib/core/database/queries/deck_queries.drift`, `lib/features/tags/domain/entities/tag_entity.dart`, `lib/features/deck/domain/repositories/deck_repository.dart`, `lib/features/deck/data/datasources/deck_dao.dart`, `lib/features/deck/data/repositories/deck_repository_impl.dart`, `lib/features/card/data/datasources/card_dao.dart`
- Test (create): `test/support/card_fixtures.dart`, `test/core/text/folded_text_test.dart`, `test/features/deck/domain/deck_level_model_test.dart`, `test/features/deck/data/deck_level_read_test.dart`, `test/features/deck/domain/watch_deck_level_use_case_test.dart`
- Test (modify): `test/support/test_database.dart`, `test/core/error/failure_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `DayClock`, `watchEachLocalDay`, `startOfLocalDay`,
  `DeckScheduleStatus`, `FakeDayClock` (Task 2); `deck_queries.drift` (Task 4);
  `DeckFixtures` (Task 4); `TagEntity.fold` (Task 1).
- Produces:
  - `String foldText(String text)` in `lib/core/text/folded_text.dart`;
    `TagEntity.fold` and the card DAO fold through it.
  - `extension DatabaseErrorStream<T> on Stream<T> { Stream<T> mapDatabaseErrors(); }`
    in `lib/core/error/failure.dart`.
  - `final class DeckTile` (`id`, `name`, `siblingPosition`, `createdAt`,
    `schedulerType`, `subDeckCount`, `cardCount`, `newCount`, `overdueCount`,
    `dueTodayCount`, `oldestDueAt`, `startOfToday`; getters `dueCount`,
    `scheduledCount`, `scheduleStatus`, `overdueDays`) and
    `final class DeckLevel` (`factory DeckLevel.of(List<DeckTile> tiles,
    {DeckLevelSort sort, DeckLevelFilter filter})`; `tiles`, `overdueCount`,
    `dueTodayCount`, `newCount`, `scheduledCount`, `maxOverdueDays`).
  - `enum DeckLevelSort { manual, name, recent, due }` with
    `List<DeckTile> apply(List<DeckTile> tiles)`;
    `enum DeckLevelFilter { all, due }` with `bool keeps(DeckTile tile)`.
  - `DeckRepository.watchLevel({required String? parentId, required DateTime now,
    required DateTime startOfToday})` → `Stream<List<DeckTile>>`, from the named
    queries `deckLevelOfRoots` and `deckLevelOfChildren` (row class
    `DeckTileRow`).
  - `WatchDeckLevelUseCase(DeckRepository, DayClock)` with
    `call({String? parentId, DeckLevelSort sort, DeckLevelFilter filter})` →
    `Stream<DeckLevel>`.
  - Test support: `openTestDatabase({QueryInterceptor? interceptor})` and
    `SelectCounter` (`test/support/test_database.dart`); `insertCard(AppDatabase
    db, {required String id, required String deckId, ...})` writing a card and its
    schedule row in one transaction (`test/support/card_fixtures.dart`).

Spec §8 "A deck level" and §10. One statement per emission: the root level
groups the cards of every tree by `root_id`; a deeper level walks the subtree
of each child with a recursive CTE, cycle-safe (`UNION`) and uncapped. Sort,
filter and summary are pure Dart on the tiles. The use case restarts the watch
at every local midnight, so Due today turns into Overdue with no write. The
fixture of the read test is `S-DUE` of `docs/shared/testing/agent-execution-guide.md`
§6.2, with every `due_at` on a local midnight (BR-STUDY-074).

- [ ] **Step 1: Write the failing tests**

Replace the whole of `test/support/test_database.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:memox/core/database/app_database.dart';

/// Rows changed since the database opened: a refused write leaves it as it
/// was.
Future<int> totalChanges(AppDatabase db) async =>
    (await db.customSelect('SELECT total_changes() AS n').getSingle())
        .read<int>('n');

AppDatabase openTestDatabase({QueryInterceptor? interceptor}) {
  final executor = NativeDatabase.memory();
  return AppDatabase(
    interceptor == null ? executor : executor.interceptWith(interceptor),
  );
}

/// Counts the SELECT statements the database runs, for the reads the spec
/// allows one statement (§11).
final class SelectCounter extends QueryInterceptor {
  int selects = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects++;
    return super.runSelect(executor, statement, args);
  }
}
```

Create `test/support/card_fixtures.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// A card and its schedule row written straight to the tables, in one
/// transaction, so a read test can set any schedule state and the watchers
/// hear of it once. The schedule row follows the root's scheduler, at the
/// root's generation; [learnedAt] null makes the card New.
Future<void> insertCard(
  AppDatabase db, {
  required String id,
  required String deckId,
  String front = 'front',
  String back = 'back',
  bool isFlagged = false,
  DateTime? learnedAt,
  DateTime? dueAt,
  int box = 1,
  int intervalDays = 1,
  String? deleteBatchId,
  DateTime? createdAt,
}) => db.transaction(() async {
  final created = createdAt ?? DateTime(2026, 9, 1);
  await db.customUpdate(
    "UPDATE deck SET content_type = 'card' "
    'WHERE id = ? AND parent_id IS NOT NULL',
    variables: [Variable<String>(deckId)],
    updates: {db.deck},
  );
  await db.customInsert(
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'is_flagged, delete_batch_id, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable<String>(id),
      Variable<String>(deckId),
      Variable<String>(front),
      Variable<String>(back),
      Variable<String>(front.trim().toLowerCase()),
      Variable<String>(back.trim().toLowerCase()),
      Variable<bool>(isFlagged),
      Variable<String>(deleteBatchId),
      Variable<DateTime>(created),
      Variable<DateTime>(created),
    ],
    updates: {db.card},
  );
  await db.customInsert(
    'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, '
    'generation, learned_at, due_at, current_box, ease_factor, '
    'interval_days, repetitions) '
    'SELECT ?, r.scheduler_type, r.scheduler_version, r.generation, ?, ?, '
    "CASE r.scheduler_type WHEN 'eight_box' THEN ? END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN 2.5 END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN ? END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN 1 END "
    'FROM deck d JOIN deck r ON r.id = d.root_id WHERE d.id = ?',
    variables: [
      Variable<String>(id),
      Variable<DateTime>(learnedAt),
      Variable<DateTime>(dueAt),
      Variable<int>(box),
      Variable<int>(intervalDays),
      Variable<String>(deckId),
    ],
    updates: {db.cardSchedule},
  );
});
```

In `test/core/error/failure_test.dart`:

Replace

```dart
    expect(mapDatabaseError(failure), same(failure));
  });
}
```

with

```dart
    expect(mapDatabaseError(failure), same(failure));
  });

  test('a watch reports a database error as its Failure', () async {
    final watch = Stream<int>.error(
      sqlite3.SqliteException(extendedResultCode: 5, message: 'locked'),
    ).mapDatabaseErrors();

    await expectLater(watch, emitsError(isA<DatabaseLockedFailure>()));
  });
}
```

Create `test/core/text/folded_text_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/folded_text.dart';

void main() {
  test('folding trims, then lowercases beyond ASCII', () {
    expect(foldText('  Ăn Uống  '), 'ăn uống');
    expect(foldText('ÉCOLE'), 'école');
  });
}
```

Create `test/features/deck/domain/deck_level_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

final _today = DateTime(2026, 9, 23);

DeckTile _tile(
  String id, {
  String? name,
  int position = 0,
  DateTime? createdAt,
  int cards = 0,
  int newCards = 0,
  int overdue = 0,
  int dueToday = 0,
  DateTime? oldestDueAt,
}) => DeckTile(
  id: id,
  name: name ?? id,
  siblingPosition: position,
  createdAt: createdAt ?? DateTime(2026, 9, 1),
  schedulerType: SchedulerType.eightBox,
  subDeckCount: 0,
  cardCount: cards,
  newCount: newCards,
  overdueCount: overdue,
  dueTodayCount: dueToday,
  oldestDueAt: oldestDueAt,
  startOfToday: _today,
);

List<String> _ids(DeckLevel level) => [for (final tile in level.tiles) tile.id];

void main() {
  group('DeckTile', () {
    test(
      'Due is Overdue plus Due today; Scheduled is the rest after New and Due',
      () {
        final tile = _tile(
          't',
          cards: 10,
          newCards: 3,
          overdue: 2,
          dueToday: 1,
        );
        expect((tile.dueCount, tile.scheduledCount), (3, 4));
      },
    );

    test('its schedule status and overdue days come from the oldest Due card (BR-STUDY-067)', () {
      final overdue = _tile(
        'o',
        overdue: 1,
        oldestDueAt: DateTime(2026, 9, 20),
      );
      final dueToday = _tile('d', dueToday: 1, oldestDueAt: _today);
      final notDue = _tile('n');

      expect(
        (overdue.scheduleStatus, overdue.overdueDays),
        (DeckScheduleStatus.overdue, 3),
      );
      expect(
        (dueToday.scheduleStatus, dueToday.overdueDays),
        (DeckScheduleStatus.dueToday, 0),
      );
      expect(
        (notDue.scheduleStatus, notDue.overdueDays),
        (DeckScheduleStatus.notDue, 0),
      );
    });
  });

  group('DeckLevelSort (UC-DECK-003, IT-DISC-005)', () {
    final beta = _tile(
      'b',
      name: 'beta',
      position: 0,
      createdAt: DateTime(2026, 9, 1),
    );
    final alpha = _tile(
      'a',
      name: 'Alpha',
      position: 1,
      createdAt: DateTime(2026, 9, 2),
    );
    final gamma = _tile(
      'g',
      name: 'gamma',
      position: 2,
      createdAt: DateTime(2026, 9, 3),
    );
    final tiles = [gamma, alpha, beta];

    test('manual follows the sibling position', () {
      expect(_ids(DeckLevel.of(tiles)), ['b', 'a', 'g']);
    });

    test('name ignores case', () {
      expect(_ids(DeckLevel.of(tiles, sort: DeckLevelSort.name)), [
        'a',
        'b',
        'g',
      ]);
    });

    test('recent puts the newest deck first', () {
      expect(_ids(DeckLevel.of(tiles, sort: DeckLevelSort.recent)), [
        'g',
        'a',
        'b',
      ]);
    });

    test('due puts the most Due cards first, then the manual order', () {
      final level = DeckLevel.of([
        _tile('x', position: 0),
        _tile('y', position: 1, dueToday: 1),
        _tile('z', position: 2, overdue: 2, dueToday: 1),
        _tile('w', position: 3, dueToday: 1),
      ], sort: DeckLevelSort.due);
      expect(_ids(level), ['z', 'y', 'w', 'x']);
    });

    test('equal names keep the manual order', () {
      final level = DeckLevel.of([
        _tile('second', name: 'Same', position: 1),
        _tile('first', name: 'same', position: 0),
      ], sort: DeckLevelSort.name);
      expect(_ids(level), ['first', 'second']);
    });
  });

  group('DeckLevelFilter and the level summary', () {
    final mixed = _tile(
      'mixed',
      position: 0,
      cards: 4,
      newCards: 1,
      overdue: 1,
      dueToday: 1,
      oldestDueAt: DateTime(2026, 9, 22),
    );
    final future = _tile('future', position: 1, cards: 1);

    test('due keeps the decks with a Due card (IT-DISC-003)', () {
      expect(_ids(DeckLevel.of([mixed, future], filter: DeckLevelFilter.due)), [
        'mixed',
      ]);
      expect(
        DeckLevel.of([future], filter: DeckLevelFilter.due).tiles,
        isEmpty,
      );
    });

    test('the summary counts every deck of the level, whatever the filter (BR-STUDY-068)', () {
      final level = DeckLevel.of([mixed, future], filter: DeckLevelFilter.due);
      expect(
        (
          level.overdueCount,
          level.dueTodayCount,
          level.newCount,
          level.scheduledCount,
        ),
        (1, 1, 1, 2),
      );
      expect(level.maxOverdueDays, 1);
    });
  });
}
```

Create `test/features/deck/data/deck_level_read_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// S-DUE (agent-execution-guide §6.2) at T0 = 2026-09-23 10:00, with every
// due_at on a local midnight (BR-STUDY-074).
final _now = DateTime(2026, 9, 23, 10);
final _today = DateTime(2026, 9, 23);

void main() {
  late SelectCounter counter;
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  late DeckEntity library;
  late DeckEntity mixed;
  late DeckEntity noDueGroup;

  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    library = await repo.root('Due library');
    mixed = await repo.sub(library.id, 'Mixed due');
    noDueGroup = await repo.sub(library.id, 'No due group');
    final futureOnly = await repo.sub(noDueGroup.id, 'Future only');
    await insertCard(db, id: 'new', deckId: mixed.id);
    await insertCard(
      db,
      id: 'begin',
      deckId: mixed.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: _today,
      box: 2,
    );
    await insertCard(
      db,
      id: 'review',
      deckId: mixed.id,
      learnedAt: DateTime(2026, 9, 10),
      dueAt: DateTime(2026, 9, 22),
      box: 5,
    );
    await insertCard(
      db,
      id: 'master',
      deckId: mixed.id,
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 23),
      box: 8,
    );
    await insertCard(
      db,
      id: 'future',
      deckId: futureOnly.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 25),
      box: 4,
    );
  });
  tearDown(() => db.close());

  Stream<List<DeckTile>> level(String? parentId) =>
      repo.watchLevel(parentId: parentId, now: _now, startOfToday: _today);

  test('the root level counts each whole tree (IT-DISC-001)', () async {
    await repo.root('Empty', SchedulerType.sm2);

    final tiles = await level(null).first;

    final [dueLibrary, empty] = tiles;
    expect(dueLibrary.name, 'Due library');
    expect(dueLibrary.schedulerType, SchedulerType.eightBox);
    expect(
      (
        dueLibrary.cardCount,
        dueLibrary.newCount,
        dueLibrary.overdueCount,
        dueLibrary.dueTodayCount,
      ),
      (5, 1, 1, 1),
    );
    expect(
      (dueLibrary.subDeckCount, dueLibrary.oldestDueAt),
      (2, DateTime(2026, 9, 22)),
    );
    expect(
      (empty.cardCount, empty.schedulerType, empty.oldestDueAt),
      (0, SchedulerType.sm2, null),
    );
  });

  test(
    'a deeper level counts the subtree of each child, with the root scheduler',
    () async {
      final [mixedTile, noDueTile] = await level(library.id).first;

      expect(
        (
          mixedTile.cardCount,
          mixedTile.newCount,
          mixedTile.overdueCount,
          mixedTile.dueTodayCount,
        ),
        (4, 1, 1, 1),
      );
      expect(
        (
          noDueTile.cardCount,
          noDueTile.newCount,
          noDueTile.dueCount,
          noDueTile.subDeckCount,
        ),
        (1, 0, 0, 1),
      );
      expect(noDueTile.schedulerType, SchedulerType.eightBox);
      expect(noDueTile.startOfToday, _today);
    },
  );

  test('decks and cards in the Trash are left out (spec §8)', () async {
    await insertCard(
      db,
      id: 'trashed card',
      deckId: mixed.id,
      deleteBatchId: 'b',
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [noDueGroup.id],
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'future'",
    );

    final tiles = await level(library.id).first;

    expect(
      [for (final tile in tiles) (tile.name, tile.cardCount)],
      [('Mixed due', 4)],
    );
    final [root] = await level(null).first;
    expect((root.cardCount, root.subDeckCount), (4, 1));
  });

  test('each emission is one statement, and a new card emits again (UC-DECK-003 A2)', () async {
    counter.selects = 0;
    final emitted = <List<DeckTile>>[];
    final subscription = level(null).listen(emitted.add);
    await pumpEventQueue();
    expect((emitted.length, counter.selects), (1, 1));

    await insertCard(db, id: 'another', deckId: mixed.id);
    await pumpEventQueue();

    expect((emitted.length, counter.selects), (2, 2));
    expect(
      (emitted.last.single.cardCount, emitted.last.single.newCount),
      (6, 2),
    );
    await subscription.cancel();
  });
}
```

Create `test/features/deck/domain/watch_deck_level_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_level_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
  });
  tearDown(() => db.close());

  test(
    'a new local day turns Due today into Overdue with no write (BR-STUDY-067)',
    () async {
      final root = await decks.root('Korean');
      final leaf = await decks.sub(root.id, 'Nouns');
      await insertCard(
        db,
        id: 'c',
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 20),
        dueAt: DateTime(2026, 9, 23),
        box: 2,
      );
      await insertCard(
        db,
        id: 'd',
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 20),
        dueAt: DateTime(2026, 9, 24),
        box: 2,
      );
      final clock = FakeDayClock(DateTime(2026, 9, 23, 22));
      final levels = <DeckLevel>[];
      final subscription = WatchDeckLevelUseCase(decks, clock)(
        parentId: root.id,
      ).listen(levels.add);
      await pumpEventQueue();

      clock.startDay(DateTime(2026, 9, 24));
      await pumpEventQueue();

      final [before, after] = [for (final level in levels) level.tiles.single];
      expect(
        (before.scheduleStatus, before.overdueCount, before.dueTodayCount),
        (DeckScheduleStatus.dueToday, 0, 1),
      );
      expect(
        (after.scheduleStatus, after.overdueDays),
        (DeckScheduleStatus.overdue, 1),
      );
      expect((after.overdueCount, after.dueTodayCount), (1, 1));
      await subscription.cancel();
    },
  );

  test('the sort and the filter reach the level', () async {
    final root = await decks.root('Korean');
    final quiet = await decks.sub(root.id, 'Quiet');
    final busy = await decks.sub(root.id, 'Busy');
    await insertCard(db, id: 'q', deckId: quiet.id);
    await insertCard(
      db,
      id: 'b',
      deckId: busy.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 22),
      box: 2,
    );

    final level =
        await WatchDeckLevelUseCase(
              decks,
              FakeDayClock(DateTime(2026, 9, 23, 9)),
            )(
              parentId: root.id,
              sort: DeckLevelSort.name,
              filter: DeckLevelFilter.due,
            )
            .first;

    expect([for (final tile in level.tiles) tile.name], ['Busy']);
    expect((level.newCount, level.overdueCount), (1, 1));
  });
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/core/error/failure_test.dart \
  test/core/text/folded_text_test.dart \
  test/features/deck/domain/deck_level_model_test.dart \
  test/features/deck/data/deck_level_read_test.dart \
  test/features/deck/domain/watch_deck_level_use_case_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/core/error/failure_test.dart` — `Error: The method 'mapDatabaseErrors' isn't defined for the type 'Stream<int>'.`
- `test/core/text/folded_text_test.dart` — `Error when reading 'lib/core/text/folded_text.dart': No such file or directory`
- `test/features/deck/domain/deck_level_model_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_level_model.dart': No such file or directory`
- `test/features/deck/data/deck_level_read_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_level_model.dart': No such file or directory`
- `test/features/deck/domain/watch_deck_level_use_case_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_level_model.dart': No such file or directory`

- [ ] **Step 3: Create `foldText`**

Create `lib/core/text/folded_text.dart`:

```dart
/// The folded form of a text: trimmed, then lowercased. schema.md defines
/// `front_folded`, `back_folded` and `tags.name_folded` this way, and every
/// search term and name sort folds the same way so they compare alike.
/// Written in Dart because SQLite's `lower()` and `NOCASE` fold ASCII only.
String foldText(String text) => text.trim().toLowerCase();
```

- [ ] **Step 4: Map a watch's database errors**

In `lib/core/error/failure.dart`:

Replace

```dart
import 'package:drift/isolate.dart' show DriftRemoteException;
```

with

```dart
import 'dart:async';

import 'package:drift/isolate.dart' show DriftRemoteException;
```

Replace

```dart
  };
}
```

with

```dart
  };
}

/// A watch reports its database errors the way a one-shot read does.
extension DatabaseErrorStream<T> on Stream<T> {
  Stream<T> mapDatabaseErrors() => transform(
    StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) =>
          sink.addError(mapDatabaseError(error), stackTrace),
    ),
  );
}
```

- [ ] **Step 5: Add the two deck level queries**

The variables are typed (`:now AS DATETIME`) so drift generates non-null parameters; their positional order is their first appearance in the SQL, which the DAO follows.

Replace the whole of `lib/core/database/queries/deck_queries.drift` with:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/srs.drift';

-- BR-DECK-023: the active decks below :deck_id and the active cards of its
-- subtree. No row when :deck_id is not an active deck.
deckDeletionSummary:
WITH RECURSIVE subtree(id) AS (
  SELECT id FROM deck WHERE id = :deck_id AND delete_batch_id IS NULL
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
  WHERE d.delete_batch_id IS NULL
)
SELECT
  (SELECT COUNT(*) - 1 FROM subtree) AS sub_deck_count,
  (SELECT COUNT(*) FROM card c
   WHERE c.deck_id IN (SELECT id FROM subtree) AND c.delete_batch_id IS NULL)
    AS card_count
FROM deck
WHERE id = :deck_id AND delete_batch_id IS NULL;

-- UC-DECK-003: every root deck with the counts of its whole tree, grouped by
-- root_id in one statement. The sets are those of BR-STUDY-047 and
-- BR-STUDY-051: New is an unlearned card; Due is a learned card whose due_at
-- is at or before :now, Overdue before :start_of_today and Due today from it
-- on (BR-STUDY-068). Both come from Dart (BR-STUDY-068).
deckLevelOfRoots(:start_of_today AS DATETIME, :now AS DATETIME)
  AS DeckTileRow:
SELECT
  d.id, d.name, d.sibling_position, d.created_at, d.scheduler_type,
  (SELECT COUNT(*) FROM deck s
   WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL) AS sub_deck_count,
  COALESCE(t.card_count, 0) AS card_count,
  COALESCE(t.new_count, 0) AS new_count,
  COALESCE(t.overdue_count, 0) AS overdue_count,
  COALESCE(t.due_today_count, 0) AS due_today_count,
  t.oldest_due_at AS oldest_due_at
FROM deck d
LEFT JOIN (
  SELECT k.root_id AS tile_id,
    COUNT(*) AS card_count,
    COUNT(*) FILTER (WHERE cs.learned_at IS NULL) AS new_count,
    COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
      AND cs.due_at < :start_of_today) AS overdue_count,
    COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
      AND cs.due_at >= :start_of_today AND cs.due_at <= :now) AS due_today_count,
    MIN(cs.due_at) FILTER (WHERE cs.learned_at IS NOT NULL
      AND cs.due_at <= :now) AS oldest_due_at
  FROM card c
  JOIN deck k ON k.id = c.deck_id
  JOIN card_schedule cs ON cs.card_id = c.id
  WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL
  GROUP BY k.root_id
) t ON t.tile_id = d.id
WHERE d.parent_id IS NULL AND d.delete_batch_id IS NULL
ORDER BY d.sibling_position, d.id;

-- UC-DECK-003: every deck directly under :parent_id with the counts of its
-- subtree, in one statement: a recursive walk anchored at each child, cycle
-- safe (UNION) and never capped. The sets are those of deckLevelOfRoots.
deckLevelOfChildren(:parent_id AS TEXT, :start_of_today AS DATETIME,
  :now AS DATETIME) AS DeckTileRow:
WITH RECURSIVE tree(tile_id, deck_id) AS (
  SELECT id, id FROM deck
  WHERE parent_id = :parent_id AND delete_batch_id IS NULL
  UNION
  SELECT tree.tile_id, d.id FROM deck d JOIN tree ON d.parent_id = tree.deck_id
  WHERE d.delete_batch_id IS NULL
),
counts AS (
  SELECT tree.tile_id AS tile_id,
    COUNT(*) AS card_count,
    COUNT(*) FILTER (WHERE cs.learned_at IS NULL) AS new_count,
    COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
      AND cs.due_at < :start_of_today) AS overdue_count,
    COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
      AND cs.due_at >= :start_of_today AND cs.due_at <= :now) AS due_today_count,
    MIN(cs.due_at) FILTER (WHERE cs.learned_at IS NOT NULL
      AND cs.due_at <= :now) AS oldest_due_at
  FROM tree
  JOIN card c ON c.deck_id = tree.deck_id AND c.delete_batch_id IS NULL
  JOIN card_schedule cs ON cs.card_id = c.id
  GROUP BY tree.tile_id
)
SELECT
  d.id, d.name, d.sibling_position, d.created_at, r.scheduler_type,
  (SELECT COUNT(*) FROM deck s
   WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL) AS sub_deck_count,
  COALESCE(counts.card_count, 0) AS card_count,
  COALESCE(counts.new_count, 0) AS new_count,
  COALESCE(counts.overdue_count, 0) AS overdue_count,
  COALESCE(counts.due_today_count, 0) AS due_today_count,
  counts.oldest_due_at AS oldest_due_at
FROM deck d
JOIN deck r ON r.id = d.root_id
LEFT JOIN counts ON counts.tile_id = d.id
WHERE d.parent_id = :parent_id AND d.delete_batch_id IS NULL
ORDER BY d.sibling_position, d.id;
```

- [ ] **Step 6: Fold tag names with `foldText`**

In `lib/features/tags/domain/entities/tag_entity.dart`:

Replace

```dart
import 'package:memox/core/error/outcome.dart';
```

with

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
```

Replace

```dart
  /// The form uniqueness is judged on (BR-TAG-001): trim, then lowercase, the
  /// same fold schema.md defines for `front_folded`. Written in Dart because
  /// SQLite's `lower()` is ASCII-only.
  static String fold(String name) => name.trim().toLowerCase();
```

with

```dart
  /// The form uniqueness is judged on (BR-TAG-001): `name_folded` in
  /// schema.md, the fold every name and search term shares.
  static String fold(String name) => foldText(name);
```

- [ ] **Step 7: Create `DeckTile` and `DeckLevel`**

Create `lib/features/deck/domain/models/deck_level_model.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// One deck of a level with the counts of its whole subtree (UC-DECK-003).
/// New and Due are never merged (BR-STUDY-046); the counts are as of the
/// local day that starts at [startOfToday] (BR-STUDY-068).
final class DeckTile {
  const DeckTile({
    required this.id,
    required this.name,
    required this.siblingPosition,
    required this.createdAt,
    required this.schedulerType,
    required this.subDeckCount,
    required this.cardCount,
    required this.newCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.oldestDueAt,
    required this.startOfToday,
  });

  final String id;
  final String name;
  final int siblingPosition;
  final DateTime createdAt;

  /// The scheduler of the deck's root (BR-DECK-024).
  final SchedulerType schedulerType;

  /// The decks directly under this one.
  final int subDeckCount;
  final int cardCount;
  final int newCount;
  final int overdueCount;
  final int dueTodayCount;

  /// The `due_at` of the subtree's oldest Due card; null when none is Due.
  final DateTime? oldestDueAt;
  final DateTime startOfToday;

  int get dueCount => overdueCount + dueTodayCount;

  /// Learned cards not Due yet: the neutral set (BR-STUDY-068).
  int get scheduledCount => cardCount - newCount - dueCount;

  DeckScheduleStatus get scheduleStatus =>
      DeckScheduleStatus.of(oldestDueAt, startOfToday);

  int get overdueDays =>
      DeckScheduleStatus.overdueDays(oldestDueAt, startOfToday);
}

/// A level of the tree as the person asked for it, and the summary of every
/// deck on it whatever the filter: the four disjoint sets of BR-STUDY-068 and
/// the longest overdue run (BR-STUDY-067).
final class DeckLevel {
  const DeckLevel._({
    required this.tiles,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.newCount,
    required this.scheduledCount,
    required this.maxOverdueDays,
  });

  factory DeckLevel.of(
    List<DeckTile> tiles, {
    DeckLevelSort sort = DeckLevelSort.manual,
    DeckLevelFilter filter = DeckLevelFilter.all,
  }) {
    int sum(int Function(DeckTile tile) count) =>
        tiles.fold(0, (total, tile) => total + count(tile));
    return DeckLevel._(
      tiles: sort.apply([
        for (final tile in tiles)
          if (filter.keeps(tile)) tile,
      ]),
      overdueCount: sum((tile) => tile.overdueCount),
      dueTodayCount: sum((tile) => tile.dueTodayCount),
      newCount: sum((tile) => tile.newCount),
      scheduledCount: sum((tile) => tile.scheduledCount),
      maxOverdueDays: tiles.fold(
        0,
        (longest, tile) =>
            tile.overdueDays > longest ? tile.overdueDays : longest,
      ),
    );
  }

  final List<DeckTile> tiles;
  final int overdueCount;
  final int dueTodayCount;
  final int newCount;
  final int scheduledCount;
  final int maxOverdueDays;
}
```

- [ ] **Step 8: Create the level sort and filter**

Create `lib/features/deck/domain/models/deck_level_query_model.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';

/// How a level is ordered (UC-DECK-003, UC-DECK-006). Every order ends in the
/// manual one, `(sibling_position, id)`, so equal keys stay stable. The
/// "progress" order UC-DECK-006 names has no definition yet and is not here.
enum DeckLevelSort {
  manual,

  /// Folded name, so case does not matter (IT-DISC-005).
  name,

  /// Newest `created_at` first.
  recent,

  /// Most Due cards first.
  due;

  List<DeckTile> apply(List<DeckTile> tiles) => [...tiles]..sort(_compare);

  int _compare(DeckTile a, DeckTile b) {
    final byKey = switch (this) {
      manual => 0,
      name => foldText(a.name).compareTo(foldText(b.name)),
      recent => b.createdAt.compareTo(a.createdAt),
      due => b.dueCount.compareTo(a.dueCount),
    };
    if (byKey != 0) return byKey;
    final byPosition = a.siblingPosition.compareTo(b.siblingPosition);
    if (byPosition != 0) return byPosition;
    return a.id.compareTo(b.id);
  }
}

/// Which decks of a level are shown (IT-DISC-003).
enum DeckLevelFilter {
  all,

  /// Decks with at least one Due card.
  due;

  bool keeps(DeckTile tile) => switch (this) {
    all => true,
    due => tile.dueCount > 0,
  };
}
```

- [ ] **Step 9: Add `watchLevel` to the contract**

In `lib/features/deck/domain/repositories/deck_repository.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
```

Replace

```dart
  Future<DeckEntity?> findById(String id);
```

with

```dart
  Future<DeckEntity?> findById(String id);

  /// UC-DECK-003: the decks under [parentId], the roots when it is null, in
  /// manual order, with the counts of their subtrees as of [now] and the
  /// local day starting at [startOfToday]. Emits again on every change.
  Stream<List<DeckTile>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  });
```

- [ ] **Step 10: Watch a level**

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart
        DeckCompanion(siblingPosition: Value(position), updatedAt: Value(now)),
      );
```

with

```dart
        DeckCompanion(siblingPosition: Value(position), updatedAt: Value(now)),
      );

  /// The decks under [parentId], the roots when it is null, with the counts
  /// of their subtrees: one statement per emission (`deck_queries.drift`).
  Stream<List<DeckTileRow>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  }) {
    if (parentId == null) {
      return _db.deckLevelOfRoots(startOfToday, now).watch();
    }
    return _db.deckLevelOfChildren(parentId, startOfToday, now).watch();
  }
```

- [ ] **Step 11: Map the level rows to tiles**

In `lib/features/deck/data/repositories/deck_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
```

Replace

```dart
  });

  /// A sub-deck's content type follows what it holds (BR-DECK-006..008,
```

with

```dart
  });

  @override
  Stream<List<DeckTile>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  }) => _dao
      .watchLevel(parentId: parentId, now: now, startOfToday: startOfToday)
      .map((rows) => [for (final row in rows) _toTile(row, startOfToday)])
      .mapDatabaseErrors();

  /// A sub-deck's content type follows what it holds (BR-DECK-006..008,
```

Replace

```dart
  updatedAt: row.updatedAt,
);
```

with

```dart
  updatedAt: row.updatedAt,
);

DeckTile _toTile(DeckTileRow row, DateTime startOfToday) => DeckTile(
  id: row.id,
  name: row.name,
  siblingPosition: row.siblingPosition,
  createdAt: row.createdAt,
  schedulerType: SchedulerType.fromCode(row.schedulerType!),
  subDeckCount: row.subDeckCount,
  cardCount: row.cardCount,
  newCount: row.newCount,
  overdueCount: row.overdueCount,
  dueTodayCount: row.dueTodayCount,
  oldestDueAt: row.oldestDueAt,
  startOfToday: startOfToday,
);
```

- [ ] **Step 12: Fold card sides with `foldText`**

In `lib/features/card/data/datasources/card_dao.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';
```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/text/folded_text.dart';
```

Replace

```dart
          frontFolded: Value(_folded(front)),
          backFolded: Value(_folded(back)),
```

with

```dart
          frontFolded: Value(foldText(front)),
          backFolded: Value(foldText(back)),
```

Delete

```dart
/// `front_folded` / `back_folded` (schema.md): trim, then Unicode lowercase.
String _folded(String side) => side.trim().toLowerCase();
```

- [ ] **Step 13: Create `watch_deck_level_use_case.dart`**

Create `lib/features/deck/domain/usecases/watch_deck_level_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

/// UC-DECK-003: a level of the tree with its counts, again on every change
/// and at every local midnight, when Due today becomes Overdue with no write
/// (BR-STUDY-067, BR-STUDY-068).
final class WatchDeckLevelUseCase {
  const WatchDeckLevelUseCase(this._decks, this._clock);

  final DeckRepository _decks;
  final DayClock _clock;

  /// The roots when [parentId] is null.
  Stream<DeckLevel> call({
    String? parentId,
    DeckLevelSort sort = DeckLevelSort.manual,
    DeckLevelFilter filter = DeckLevelFilter.all,
  }) => watchEachLocalDay(
    _clock,
    (now) => _decks
        .watchLevel(
          parentId: parentId,
          now: now,
          startOfToday: startOfLocalDay(now),
        )
        .map((tiles) => DeckLevel.of(tiles, sort: sort, filter: filter)),
  );
}
```

- [ ] **Step 14: Regenerate the docs index and check the docs**

`docs/_generated/traceability.md` lists, for each use case, the tests
that name its id, and `docs/README.md` wants docs and code in the same commit;
this task's tests name use case ids.

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `OK docs/_generated: generated 3 files`, then `PASS — 0 error(s), 83 warning(s)`.

- [ ] **Step 15: Generate the Drift and Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `Built with build_runner`, and no `drift_dev` warning.

- [ ] **Step 16: Run the task's tests**

```bash
flutter test test/core/error/failure_test.dart \
  test/core/text/folded_text_test.dart \
  test/features/deck/domain/deck_level_model_test.dart \
  test/features/deck/data/deck_level_read_test.dart \
  test/features/deck/domain/watch_deck_level_use_case_test.dart
```

Expected: `+21: All tests passed!`

- [ ] **Step 17: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+278: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 18: Commit**

```bash
git add docs/_generated \
  lib/core/database/queries/deck_queries.drift \
  lib/core/error/failure.dart \
  lib/core/text/folded_text.dart \
  lib/features/card/data/datasources/card_dao.dart \
  lib/features/deck/data/datasources/deck_dao.dart \
  lib/features/deck/data/repositories/deck_repository_impl.dart \
  lib/features/deck/domain/models/deck_level_model.dart \
  lib/features/deck/domain/models/deck_level_query_model.dart \
  lib/features/deck/domain/repositories/deck_repository.dart \
  lib/features/deck/domain/usecases/watch_deck_level_use_case.dart \
  lib/features/tags/domain/entities/tag_entity.dart \
  test/core/error/failure_test.dart \
  test/core/text/folded_text_test.dart \
  test/features/deck/data/deck_level_read_test.dart \
  test/features/deck/domain/deck_level_model_test.dart \
  test/features/deck/domain/watch_deck_level_use_case_test.dart \
  test/support/card_fixtures.dart \
  test/support/test_database.dart
git commit -m "feat(deck): add the deck level read model with its midnight refresh"
```


### Task 6: The open deck, deck move targets and deck search

**Files:**
- Create: `lib/features/deck/domain/models/deck_create_option_model.dart`, `lib/features/deck/domain/models/deck_move_target_model.dart`, `lib/features/deck/domain/models/deck_path_model.dart`, `lib/features/deck/domain/models/deck_search_hit_model.dart`, `lib/features/deck/domain/models/deck_tree_model.dart`, `lib/features/deck/domain/models/deck_view_model.dart`, `lib/features/deck/domain/usecases/search_decks_use_case.dart`, `lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart`, `lib/features/deck/domain/usecases/watch_deck_use_case.dart`
- Modify: `lib/core/database/queries/deck_queries.drift`, `lib/features/deck/domain/entities/deck_entity.dart`, `lib/features/deck/domain/repositories/deck_repository.dart`, `lib/features/deck/data/datasources/deck_dao.dart`, `lib/features/deck/data/repositories/deck_repository_impl.dart`
- Test (create): `test/features/deck/data/deck_navigation_read_test.dart`, `test/features/deck/domain/deck_navigation_use_cases_test.dart`
- Test (modify): `test/features/deck/domain/deck_entity_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `foldText`, `mapDatabaseErrors` (Task 5); `deck_queries.drift`,
  `DeckDao`, `DeckFixtures` (Task 4); `insertCard` (Task 5).
- Produces:
  - `enum DeckCreateOption { deck, card }` and the getter
    `Set<DeckCreateOption> DeckEntity.createOptions`.
  - `final class DeckPathEntry({required String id, required String name})`;
    `final class DeckTreeNode({id, name, parentId, siblingPosition, isCandidate})`
    and `List<T> candidatesInTreeOrder<T>(List<DeckTreeNode> nodes,
    T Function(DeckTreeNode node, List<DeckPathEntry> path) build)` in
    `deck/domain/models/deck_tree_model.dart`.
  - `DeckView({deck, schedulerType, isSchedulerLocked, breadcrumb})` with
    `createOptions`; `DeckMoveTarget({id, name, path})`;
    `DeckSearchHit({id, name, path})`.
  - `DeckRepository.watchDeck(String deckId)` → `Stream<DeckView?>`;
    `watchMoveTargets(String deckId)` → `Stream<List<DeckMoveTarget>>`;
    `watchSearch({required String? scopeDeckId, required String foldedTerm})` →
    `Stream<List<DeckSearchHit>>`; from the named queries `deckAndAncestors`,
    `deckMoveTargets` and `deckSearchScope` (row class `DeckForestRow`).
  - `WatchDeckUseCase({deckId})` → `Stream<Outcome<DeckView, DeckRejection>>`,
    `WatchDeckMoveTargetsUseCase({deckId})`, `SearchDecksUseCase({scopeDeckId,
    term})`.

Spec §8 "An open deck", "Deck move targets" and "Deck search". The move targets
read the same rules `DeckEntity.checkMove` applies, so every deck offered is one
`moveDeck` accepts. Paths are built in Dart from one query's rows: the query
returns the candidates and every deck on their paths, flagged; the tree walk
turns them into paths in tree order.

- [ ] **Step 1: Write the failing tests**

In `test/features/deck/domain/deck_entity_test.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
```

Replace

```dart
    });
  });
}
```

with

```dart
    });
  });

  group('createOptions (BR-DECK-005, BR-DECK-007, BR-DECK-012)', () {
    DeckEntity deck(DeckContentType type, {int depth = 2}) => DeckEntity(
      id: 'd',
      name: 'd',
      parentId: depth == 1 ? null : 'p',
      rootId: 'r',
      depth: depth,
      contentType: type,
      schedulerType: null,
      generation: null,
      firstAnsweredAt: null,
      siblingPosition: 0,
      createdAt: DateTime(2026, 9, 23),
      updatedAt: DateTime(2026, 9, 23),
    );

    test('a root and a deck of decks offer a deck, a deck of cards a card', () {
      expect(deck(DeckContentType.deck, depth: 1).createOptions, {
        DeckCreateOption.deck,
      });
      expect(deck(DeckContentType.deck).createOptions, {DeckCreateOption.deck});
      expect(deck(DeckContentType.card).createOptions, {DeckCreateOption.card});
    });

    test('an empty sub-deck offers both', () {
      expect(deck(DeckContentType.unset).createOptions, {
        DeckCreateOption.deck,
        DeckCreateOption.card,
      });
    });

    test('the deepest level offers no deck (BR-DECK-001)', () {
      expect(
        deck(DeckContentType.unset, depth: DeckEntity.maxDepth).createOptions,
        {DeckCreateOption.card},
      );
    });
  });
}
```

Create `test/features/deck/data/deck_navigation_read_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

/// A path as a person reads it, so two paths compare by their names.
String _shown(List<DeckPathEntry> path) =>
    [for (final step in path) step.name].join(' / ');

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl repo;
  setUp(() {
    db = openTestDatabase();
    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  Future<void> trash(String deckId) => db.customStatement(
    "UPDATE deck SET delete_batch_id = 'batch' WHERE id = ?",
    [deckId],
  );

  group('watchDeck', () {
    test('gives the deck, the root scheduler, the lock, the options and the breadcrumb', () async {
      final root = await repo.root('Korean', SchedulerType.sm2);
      final branch = await repo.sub(root.id, 'Vocabulary');
      final leaf = await repo.sub(branch.id, 'Academic words');

      final view = (await repo.watchDeck(leaf.id).first)!;

      expect(view.deck.name, 'Academic words');
      expect(
        (view.schedulerType, view.isSchedulerLocked),
        (SchedulerType.sm2, false),
      );
      expect(view.createOptions, {
        DeckCreateOption.deck,
        DeckCreateOption.card,
      });
      expect(_shown(view.breadcrumb), 'Korean / Vocabulary');
      expect((await repo.watchDeck(root.id).first)!.breadcrumb, isEmpty);
    });

    test(
      'the scheduler is locked once the root has an answer (BR-SRS-003)',
      () async {
        final root = await repo.root('Korean');
        final leaf = await repo.sub(root.id, 'Nouns');
        final views = <DeckView?>[];
        final subscription = repo.watchDeck(leaf.id).listen(views.add);
        await pumpEventQueue();

        await db.customUpdate(
          'UPDATE deck SET first_answered_at = 1 WHERE id = ?',
          variables: [Variable<String>(root.id)],
          updates: {db.deck},
        );
        await pumpEventQueue();

        expect(
          [for (final view in views) view!.isSchedulerLocked],
          [false, true],
        );
        await subscription.cancel();
      },
    );

    test('emits null once the deck is gone or in the Trash', () async {
      final root = await repo.root('Korean');
      final leaf = await repo.sub(root.id, 'Nouns');
      final other = await repo.sub(root.id, 'Verbs');
      final views = <DeckView?>[];
      final subscription = repo.watchDeck(leaf.id).listen(views.add);
      await pumpEventQueue();

      await repo.deleteDeck(deckId: leaf.id);
      await pumpEventQueue();
      await trash(other.id);

      expect(views.last, isNull);
      expect(await repo.watchDeck(other.id).first, isNull);
      await subscription.cancel();
    });
  });

  group('watchMoveTargets (UC-DECK-005)', () {
    test(
      'offers every deck the move rules allow, with its path, in tree order',
      () async {
        final korean = await repo.root('Korean');
        final grammar = await repo.sub(korean.id, 'Grammar');
        final moving = await repo.sub(grammar.id, 'Particles');
        await repo.sub(moving.id, 'Inside the moving deck');
        await repo.sub(korean.id, 'Vocabulary');
        final cards = await repo.sub(korean.id, 'Holds cards');
        await insertCard(db, id: 'c', deckId: cards.id);
        final japanese = await repo.root('Japanese');
        await repo.sub(japanese.id, 'Kana');
        final sm2 = await repo.root('Spanish', SchedulerType.sm2);
        await repo.sub(sm2.id, 'Verbs');

        final targets = await repo.watchMoveTargets(moving.id).first;

        expect(
          [for (final target in targets) (target.name, _shown(target.path))],
          [
            ('Korean', ''),
            ('Vocabulary', 'Korean'),
            ('Japanese', ''),
            ('Kana', 'Japanese'),
          ],
        );
      },
    );

    test('leaves out a root of another generation and a target too deep for the subtree', () async {
      final korean = await repo.root('Korean');
      final moving = await repo.sub(korean.id, 'Moving');
      await repo.sub(moving.id, 'Child');
      var deep = await repo.root('Deep');
      for (var level = 2; level <= 9; level++) {
        deep = await repo.sub(deep.id, 'Level $level');
      }
      final reset = await repo.root('Reset');
      await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
        reset.id,
      ]);

      final targets = await repo.watchMoveTargets(moving.id).first;

      final names = [for (final target in targets) target.name];
      expect(names, contains('Level 8'), reason: 'depth 8 + height 2 = 10');
      expect(
        names,
        isNot(contains('Level 9')),
        reason: 'depth 9 + height 2 = 11',
      );
      expect(names, isNot(contains('Reset')));
    });

    test(
      'a root deck, a missing deck and a deck in the Trash have no target',
      () async {
        final korean = await repo.root('Korean');
        final leaf = await repo.sub(korean.id, 'Nouns');
        await repo.root('Japanese');
        await trash(leaf.id);

        expect(await repo.watchMoveTargets(korean.id).first, isEmpty);
        expect(await repo.watchMoveTargets('missing').first, isEmpty);
        expect(await repo.watchMoveTargets(leaf.id).first, isEmpty);
      },
    );
  });

  group('watchSearch (IT-DISC-006)', () {
    late DeckEntity eightBox;
    setUp(() async {
      eightBox = await repo.root('D-EB');
      final vocabulary = await repo.sub(eightBox.id, 'Vocabulary');
      await repo.sub(vocabulary.id, 'Academic words');
      await repo.sub(eightBox.id, 'Ăn uống');
      final sm2 = await repo.root('D-SM2', SchedulerType.sm2);
      await repo.sub(sm2.id, 'Academic phrases');
    });

    List<(String, String)> shown(List<DeckSearchHit> hits) => [
      for (final hit in hits) (hit.name, _shown(hit.path)),
    ];

    test('finds the decks below the scope, each with its path', () async {
      final hits = await repo
          .watchSearch(scopeDeckId: eightBox.id, foldedTerm: 'academic')
          .first;

      expect(shown(hits), [('Academic words', 'D-EB / Vocabulary')]);
    });

    test('with no scope it searches every deck', () async {
      final hits = await repo
          .watchSearch(scopeDeckId: null, foldedTerm: 'academic')
          .first;

      expect(shown(hits), [
        ('Academic words', 'D-EB / Vocabulary'),
        ('Academic phrases', 'D-SM2'),
      ]);
    });

    test('matches letters beyond ASCII whatever their case', () async {
      final hits = await repo
          .watchSearch(scopeDeckId: null, foldedTerm: 'ăn')
          .first;

      expect(shown(hits), [('Ăn uống', 'D-EB')]);
    });

    test('the scope itself is not a hit', () async {
      final hits = await repo
          .watchSearch(scopeDeckId: eightBox.id, foldedTerm: 'd-eb')
          .first;

      expect(hits, isEmpty);
    });
  });

  test('a target and a hit carry the deck id', () async {
    final korean = await repo.root('Korean');
    final moving = await repo.sub(korean.id, 'Moving');
    final other = await repo.sub(korean.id, 'Other');

    final List<DeckMoveTarget> targets = await repo
        .watchMoveTargets(moving.id)
        .first;
    final hits = await repo
        .watchSearch(scopeDeckId: null, foldedTerm: 'other')
        .first;

    expect([for (final target in targets) target.id], [other.id]);
    expect(hits.single.id, other.id);
  });
}
```

Create `test/features/deck/domain/deck_navigation_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/domain/usecases/search_decks_use_case.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_use_case.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  test(
    'WatchDeckUseCase answers notFound once the open deck is deleted',
    () async {
      final root = await decks.root('Korean');
      final leaf = await decks.sub(root.id, 'Nouns');
      final results = <Outcome<DeckView, DeckRejection>>[];
      final subscription = WatchDeckUseCase(decks)(deckId: leaf.id)
          .listen(results.add);
      await pumpEventQueue();

      await decks.deleteDeck(deckId: leaf.id);
      await pumpEventQueue();

      expect(results.first, isA<Ok<DeckView, DeckRejection>>());
      expect(
        (results.last as Rejected<DeckView, DeckRejection>).reason,
        DeckRejection.notFound,
      );
      await subscription.cancel();
    },
  );

  test(
    'SearchDecksUseCase folds the term, and a blank term finds nothing',
    () async {
      final root = await decks.root('Korean');
      await decks.sub(root.id, 'Academic words');
      final search = SearchDecksUseCase(decks);

      final hits = await search(scopeDeckId: null, term: '  ACADEMIC ').first;
      final none = await search(scopeDeckId: null, term: '   ').first;

      expect([for (final hit in hits) hit.name], ['Academic words']);
      expect(none, isEmpty);
    },
  );

  test('WatchDeckMoveTargetsUseCase lists where a deck may go', () async {
    final root = await decks.root('Korean');
    final moving = await decks.sub(root.id, 'Moving');
    await decks.sub(root.id, 'Other');

    final targets = await WatchDeckMoveTargetsUseCase(decks)(deckId: moving.id)
        .first;

    expect([for (final target in targets) target.name], ['Other']);
  });
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/features/deck/domain/deck_entity_test.dart \
  test/features/deck/data/deck_navigation_read_test.dart \
  test/features/deck/domain/deck_navigation_use_cases_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/features/deck/domain/deck_entity_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_create_option_model.dart': No such file or directory`
- `test/features/deck/data/deck_navigation_read_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_create_option_model.dart': No such file or directory`
- `test/features/deck/domain/deck_navigation_use_cases_test.dart` — `Error when reading 'lib/features/deck/domain/models/deck_view_model.dart': No such file or directory`

- [ ] **Step 3: Add the open-deck, move-target and search queries**

In `lib/core/database/queries/deck_queries.drift`:

Replace

```sql
WHERE d.parent_id = :parent_id AND d.delete_batch_id IS NULL
ORDER BY d.sibling_position, d.id;
```

with

```sql
WHERE d.parent_id = :parent_id AND d.delete_batch_id IS NULL
ORDER BY d.sibling_position, d.id;

-- An open deck: the deck and every deck above it, root first. No row when
-- :deck_id is not an active deck.
deckAndAncestors(:deck_id AS TEXT):
WITH RECURSIVE up(id, parent_id) AS (
  SELECT id, parent_id FROM deck
  WHERE id = :deck_id AND delete_batch_id IS NULL
  UNION
  SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id
)
SELECT * FROM deck WHERE id IN (SELECT id FROM up) ORDER BY depth;

-- UC-DECK-005: the decks a move of :deck_id may pick, and the decks on their
-- paths. The rules are DeckEntity.checkMove's, read the same way: active
-- decks of every tree whose root runs the same scheduler at the same
-- generation as the deck's root (BR-DECK-024), outside the deck's subtree
-- (BR-DECK-017), holding decks or nothing (BR-DECK-009) and shallow enough
-- for the subtree's height (BR-DECK-001). The current parent comes back with
-- is_candidate false: it is only a step of the other paths. No row for a
-- root, a missing deck or a deck in the Trash.
deckMoveTargets(:deck_id AS TEXT, :max_depth AS INTEGER) AS DeckForestRow:
WITH RECURSIVE
  moving AS (
    SELECT d.id, d.parent_id, r.scheduler_type, r.generation
    FROM deck d JOIN deck r ON r.id = d.root_id
    WHERE d.id = :deck_id AND d.parent_id IS NOT NULL
      AND d.delete_batch_id IS NULL
  ),
  subtree(id, height) AS (
    SELECT id, 1 FROM moving
    UNION ALL
    SELECT d.id, subtree.height + 1 FROM deck d
    JOIN subtree ON d.parent_id = subtree.id
    WHERE subtree.height < :max_depth
  )
SELECT d.id, d.name, d.parent_id, d.sibling_position,
  d.id <> m.parent_id AS is_candidate
FROM deck d
JOIN deck r ON r.id = d.root_id
JOIN moving m
  ON r.scheduler_type = m.scheduler_type AND r.generation = m.generation
WHERE d.delete_batch_id IS NULL
  AND d.content_type IN ('deck', 'unset')
  AND d.id NOT IN (SELECT id FROM subtree)
  AND d.depth + (SELECT MAX(height) FROM subtree) <= :max_depth;

-- IT-DISC-006: the decks a search inside :scope_id looks through, and the
-- decks on their paths. is_candidate marks the decks strictly below
-- :scope_id, or every active deck when :scope_id is null. Matching the name
-- is Dart's: deck has no folded name, and SQLite's lower() folds ASCII only.
deckSearchScope(:scope_id AS TEXT OR NULL) AS DeckForestRow:
WITH RECURSIVE
  up(id, parent_id) AS (
    SELECT id, parent_id FROM deck
    WHERE id = :scope_id AND delete_batch_id IS NULL
    UNION
    SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id
  ),
  down(id) AS (
    SELECT id FROM up WHERE id = :scope_id
    UNION
    SELECT d.id FROM deck d JOIN down ON d.parent_id = down.id
    WHERE d.delete_batch_id IS NULL
  )
SELECT d.id, d.name, d.parent_id, d.sibling_position,
  (:scope_id IS NULL OR (d.id IN (SELECT id FROM down) AND d.id <> :scope_id))
    AS is_candidate
FROM deck d
WHERE d.delete_batch_id IS NULL
  AND (:scope_id IS NULL
    OR d.id IN (SELECT id FROM up) OR d.id IN (SELECT id FROM down));
```

- [ ] **Step 4: Create `DeckCreateOption`**

Create `lib/features/deck/domain/models/deck_create_option_model.dart`:

```dart
/// What "Create" can add inside a deck (BR-DECK-012).
enum DeckCreateOption { deck, card }
```

- [ ] **Step 5: Create `DeckMoveTarget`**

Create `lib/features/deck/domain/models/deck_move_target_model.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck a move may pick (UC-DECK-005).
final class DeckMoveTarget {
  const DeckMoveTarget({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;

  /// The decks from the root down to this deck's parent; empty for a root.
  final List<DeckPathEntry> path;
}
```

- [ ] **Step 6: Create `DeckPathEntry`**

Create `lib/features/deck/domain/models/deck_path_model.dart`:

```dart
/// One deck on the way down from a root: enough to show a path and to open
/// that deck.
final class DeckPathEntry {
  const DeckPathEntry({required this.id, required this.name});

  final String id;
  final String name;
}
```

- [ ] **Step 7: Create `DeckSearchHit`**

Create `lib/features/deck/domain/models/deck_search_hit_model.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck whose name holds the search term (IT-DISC-006).
final class DeckSearchHit {
  const DeckSearchHit({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;

  /// The decks from the root down to this deck's parent, so two decks of the
  /// same name tell apart; empty for a root.
  final List<DeckPathEntry> path;
}
```

- [ ] **Step 8: Create the tree walk**

Create `lib/features/deck/domain/models/deck_tree_model.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck as a walk of its tree needs it: where it hangs, and whether the
/// walk hands it back ([isCandidate]) or only passes through it.
final class DeckTreeNode {
  const DeckTreeNode({
    required this.id,
    required this.name,
    required this.parentId,
    required this.siblingPosition,
    required this.isCandidate,
  });

  final String id;
  final String name;
  final String? parentId;
  final int siblingPosition;
  final bool isCandidate;
}

/// The candidates among [nodes] in tree order — roots first, each deck
/// followed by the decks below it, siblings in manual order
/// `(sibling_position, id)` — each built by [build] with its path from the
/// root. [nodes] hold every deck on the candidates' paths, so one query
/// serves every path instead of a query per deck.
List<T> candidatesInTreeOrder<T>(
  List<DeckTreeNode> nodes,
  T Function(DeckTreeNode node, List<DeckPathEntry> path) build,
) {
  final children = <String?, List<DeckTreeNode>>{};
  for (final node in nodes) {
    (children[node.parentId] ??= []).add(node);
  }
  for (final siblings in children.values) {
    siblings.sort((a, b) {
      final byPosition = a.siblingPosition.compareTo(b.siblingPosition);
      if (byPosition != 0) return byPosition;
      return a.id.compareTo(b.id);
    });
  }
  final found = <T>[];
  void visit(String? parentId, List<DeckPathEntry> path) {
    for (final node in children[parentId] ?? const <DeckTreeNode>[]) {
      if (node.isCandidate) found.add(build(node, path));
      visit(node.id, [...path, DeckPathEntry(id: node.id, name: node.name)]);
    }
  }

  visit(null, const []);
  return found;
}
```

- [ ] **Step 9: Create `DeckView`**

Create `lib/features/deck/domain/models/deck_view_model.dart`:

```dart
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// An open deck: what its screen and its Create menu need.
final class DeckView {
  const DeckView({
    required this.deck,
    required this.schedulerType,
    required this.isSchedulerLocked,
    required this.breadcrumb,
  });

  final DeckEntity deck;

  /// The scheduler of the deck's root (BR-DECK-024).
  final SchedulerType schedulerType;

  /// The root has an answer, so its scheduler cannot change (BR-SRS-003).
  final bool isSchedulerLocked;

  /// The decks from the root down to the parent; empty for a root.
  final List<DeckPathEntry> breadcrumb;

  Set<DeckCreateOption> get createOptions => deck.createOptions;
}
```

- [ ] **Step 10: Add `createOptions` to `DeckEntity`**

In `lib/features/deck/domain/entities/deck_entity.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
```

Replace

```dart
  bool get isRoot => parentId == null;
```

with

```dart
  bool get isRoot => parentId == null;

  /// What "Create" offers here (BR-DECK-005, BR-DECK-007, BR-DECK-012):
  /// decks in a root or a deck of decks, cards in a deck of cards, both in an
  /// empty sub-deck, and no deck at the deepest level (BR-DECK-001).
  Set<DeckCreateOption> get createOptions {
    final byContent = switch (contentType) {
      DeckContentType.deck => {DeckCreateOption.deck},
      DeckContentType.card => {DeckCreateOption.card},
      DeckContentType.unset => {DeckCreateOption.deck, DeckCreateOption.card},
    };
    if (depth < maxDepth) return byContent;
    return byContent.difference({DeckCreateOption.deck});
  }
```

- [ ] **Step 11: Add the three watches to the contract**

In `lib/features/deck/domain/repositories/deck_repository.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
```

Replace

```dart
    required DateTime startOfToday,
  });
}
```

with

```dart
    required DateTime startOfToday,
  });

  /// An open deck, again on every change; null once it is gone or in the
  /// Trash.
  Stream<DeckView?> watchDeck(String deckId);

  /// UC-DECK-005: where [deckId] may move, in tree order; empty for a root.
  Stream<List<DeckMoveTarget>> watchMoveTargets(String deckId);

  /// IT-DISC-006: the decks below [scopeDeckId], or all when it is null,
  /// whose folded name holds [foldedTerm], in tree order.
  Stream<List<DeckSearchHit>> watchSearch({
    required String? scopeDeckId,
    required String foldedTerm,
  });
}
```

- [ ] **Step 12: Watch the three queries**

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart
    return _db.deckLevelOfChildren(parentId, startOfToday, now).watch();
  }
```

with

```dart
    return _db.deckLevelOfChildren(parentId, startOfToday, now).watch();
  }

  /// [id] and every deck above it, root first; empty when [id] is not an
  /// active deck.
  Stream<List<Deck>> watchDeckAndAncestors(String id) =>
      _db.deckAndAncestors(id).watch();

  /// The decks a move of [id] may pick, and the decks on their paths.
  Stream<List<DeckForestRow>> watchMoveTargetRows(
    String id, {
    required int maxDepth,
  }) => _db.deckMoveTargets(id, maxDepth).watch();

  /// The decks a search inside [scopeId] looks through, every active deck
  /// when it is null, and the decks on their paths.
  Stream<List<DeckForestRow>> watchSearchRows(String? scopeId) =>
      _db.deckSearchScope(scopeId).watch();
```

- [ ] **Step 13: Build the view, the targets and the hits**

In `lib/features/deck/data/repositories/deck_repository_impl.dart`:

Replace

```dart
import 'package:memox/core/id/new_id.dart';
```

with

```dart
import 'package:memox/core/id/new_id.dart';
import 'package:memox/core/text/folded_text.dart';
```

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
```

Replace

```dart
      .mapDatabaseErrors();

  /// A sub-deck's content type follows what it holds (BR-DECK-006..008,
```

with

```dart
      .mapDatabaseErrors();

  @override
  Stream<DeckView?> watchDeck(String deckId) =>
      _dao.watchDeckAndAncestors(deckId).map(_toView).mapDatabaseErrors();

  @override
  Stream<List<DeckMoveTarget>> watchMoveTargets(String deckId) => _dao
      .watchMoveTargetRows(deckId, maxDepth: DeckEntity.maxDepth)
      .map(
        (rows) => candidatesInTreeOrder(
          [for (final row in rows) _nodeOf(row)],
          (node, path) =>
              DeckMoveTarget(id: node.id, name: node.name, path: path),
        ),
      )
      .mapDatabaseErrors();

  @override
  Stream<List<DeckSearchHit>> watchSearch({
    required String? scopeDeckId,
    required String foldedTerm,
  }) => _dao
      .watchSearchRows(scopeDeckId)
      .map(
        (rows) => [
          for (final hit in candidatesInTreeOrder(
            [for (final row in rows) _nodeOf(row)],
            (node, path) =>
                DeckSearchHit(id: node.id, name: node.name, path: path),
          ))
            if (foldText(hit.name).contains(foldedTerm)) hit,
        ],
      )
      .mapDatabaseErrors();

  /// A sub-deck's content type follows what it holds (BR-DECK-006..008,
```

Replace

```dart
  startOfToday: startOfToday,
);
```

with

```dart
  startOfToday: startOfToday,
);

/// [rows] run from the root down to the open deck.
DeckView? _toView(List<Deck> rows) {
  if (rows.isEmpty) return null;
  final root = rows.first;
  return DeckView(
    deck: _toEntity(rows.last),
    schedulerType: _schedulerOf(root)!,
    isSchedulerLocked: root.firstAnsweredAt != null,
    breadcrumb: [
      for (final row in rows.take(rows.length - 1))
        DeckPathEntry(id: row.id, name: row.name),
    ],
  );
}

DeckTreeNode _nodeOf(DeckForestRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: row.isCandidate,
);
```

- [ ] **Step 14: Create `search_decks_use_case.dart`**

Create `lib/features/deck/domain/usecases/search_decks_use_case.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// IT-DISC-006, IT-DISC-007: the decks below [scopeDeckId] (all decks when it
/// is null) whose name holds [term], case and surrounding spaces aside. A
/// blank term searches nothing.
final class SearchDecksUseCase {
  const SearchDecksUseCase(this._decks);

  final DeckRepository _decks;

  Stream<List<DeckSearchHit>> call({
    required String? scopeDeckId,
    required String term,
  }) {
    final foldedTerm = foldText(term);
    if (foldedTerm.isEmpty) return Stream.value(const <DeckSearchHit>[]);
    return _decks.watchSearch(scopeDeckId: scopeDeckId, foldedTerm: foldedTerm);
  }
}
```

- [ ] **Step 15: Create `watch_deck_move_targets_use_case.dart`**

Create `lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-005: the decks the move picker offers, each with its path.
final class WatchDeckMoveTargetsUseCase {
  const WatchDeckMoveTargetsUseCase(this._decks);

  final DeckRepository _decks;

  Stream<List<DeckMoveTarget>> call({required String deckId}) =>
      _decks.watchMoveTargets(deckId);
}
```

- [ ] **Step 16: Create `watch_deck_use_case.dart`**

Create `lib/features/deck/domain/usecases/watch_deck_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// An open deck: its content, Create options, scheduler lock and breadcrumb,
/// again on every change, and notFound once it is deleted.
final class WatchDeckUseCase {
  const WatchDeckUseCase(this._decks);

  final DeckRepository _decks;

  Stream<Outcome<DeckView, DeckRejection>> call({required String deckId}) =>
      _decks
          .watchDeck(deckId)
          .map<Outcome<DeckView, DeckRejection>>(
            (view) => switch (view) {
              final DeckView view => Ok(view),
              null => const Rejected(DeckRejection.notFound),
            },
          );
}
```

- [ ] **Step 17: Regenerate the docs index and check the docs**

`docs/_generated/traceability.md` lists, for each use case, the tests
that name its id, and `docs/README.md` wants docs and code in the same commit;
this task's tests name use case ids.

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `OK docs/_generated: generated 3 files`, then `PASS — 0 error(s), 83 warning(s)`.

- [ ] **Step 18: Generate the Drift and Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `Built with build_runner`, and no `drift_dev` warning.

- [ ] **Step 19: Run the task's tests**

```bash
flutter test test/features/deck/domain/deck_entity_test.dart \
  test/features/deck/data/deck_navigation_read_test.dart \
  test/features/deck/domain/deck_navigation_use_cases_test.dart
```

Expected: `+36: All tests passed!`

- [ ] **Step 20: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+295: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 21: Commit**

```bash
git add docs/_generated \
  lib/core/database/queries/deck_queries.drift \
  lib/features/deck/data/datasources/deck_dao.dart \
  lib/features/deck/data/repositories/deck_repository_impl.dart \
  lib/features/deck/domain/entities/deck_entity.dart \
  lib/features/deck/domain/models/deck_create_option_model.dart \
  lib/features/deck/domain/models/deck_move_target_model.dart \
  lib/features/deck/domain/models/deck_path_model.dart \
  lib/features/deck/domain/models/deck_search_hit_model.dart \
  lib/features/deck/domain/models/deck_tree_model.dart \
  lib/features/deck/domain/models/deck_view_model.dart \
  lib/features/deck/domain/repositories/deck_repository.dart \
  lib/features/deck/domain/usecases/search_decks_use_case.dart \
  lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart \
  lib/features/deck/domain/usecases/watch_deck_use_case.dart \
  test/features/deck/data/deck_navigation_read_test.dart \
  test/features/deck/domain/deck_entity_test.dart \
  test/features/deck/domain/deck_navigation_use_cases_test.dart
git commit -m "feat(deck): add the open deck view, deck move targets and deck search"
```


### Task 7: Card writes and the seven card write use cases

**Files:**
- Create: `lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart`, `lib/features/card/domain/usecases/create_card_use_case.dart`, `lib/features/card/domain/usecases/delete_cards_use_case.dart`, `lib/features/card/domain/usecases/edit_card_use_case.dart`, `lib/features/card/domain/usecases/move_cards_use_case.dart`, `lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart`, `lib/features/card/domain/usecases/set_cards_flagged_use_case.dart`
- Modify: `lib/features/card/domain/entities/card_entity.dart`, `lib/features/card/domain/repositories/card_repository.dart`, `lib/features/card/data/datasources/card_dao.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`, `lib/features/card/di/card_repository_provider.dart`
- Test (create): `test/features/card/domain/card_entity_test.dart`, `test/features/card/data/card_batch_writes_test.dart`, `test/features/card/domain/card_write_use_cases_test.dart`
- Test (modify): `test/support/card_fixtures.dart`, `test/features/card/data/card_repository_impl_test.dart`, `test/integration/foundation_smoke_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `CardDraft`, the new `CardRejection` reasons (Task 1);
  `TagRepository`, `TagRepositoryImpl`, `tagRepositoryProvider`, `totalChanges`
  (Task 3); `DeckFixtures` (Task 4); `foldText`, `insertCard` (Task 5); foundation
  `CardRepositoryImpl`, `CardDao`, `ScheduleRepository.initializeCard`.
- Produces:
  - `CardRepository`: `createCard({required String deckId, required CardDraft draft, DateTime? now})`
    → `Outcome<CardEntity, CardRejection>`;
    `editCard({required String cardId, required CardDraft draft, DateTime? now})`;
    `deleteCards({required Set<String> cardIds})`;
    `moveCards({required Set<String> cardIds, required String targetDeckId, DateTime? now})`;
    `setFlagged({required Set<String> cardIds, required bool isFlagged, DateTime? now})`
    — the last four `Future<Outcome<void, CardRejection>>`. `deleteCard` and
    `CardEntity.checkContent` are gone.
  - `CardRepositoryImpl(AppDatabase db, ScheduleRepository schedules,
    TagRepository tags, {DateTime Function()? now})`; `cardRepositoryProvider`
    watches `tagRepositoryProvider`.
  - `static Outcome<void, CardRejection> CardEntity.checkMove({required String
    targetDeckId, required String targetRootId, required bool targetIsRoot,
    required DeckContentType targetContentType, required Set<String>
    sourceDeckIds, required Set<String> sourceRootIds})`.
  - Use cases over `CardRepository`: `CreateCardUseCase({deckId, draft})`,
    `EditCardUseCase({cardId, draft})`, `DeleteCardsUseCase({cardIds})`,
    `MoveCardsUseCase({cardIds, targetDeckId})`,
    `SetCardsFlaggedUseCase({cardIds, isFlagged})`; over `TagRepository`:
    `AddTagToCardsUseCase({cardIds, tagName})` and
    `RemoveTagFromCardsUseCase({cardIds, tagId})`, both →
    `Outcome<void, TagRejection>`.
  - Test support: `extension CardFixtures on CardRepository` with
    `card(deckId, [draft])`.

Spec §9 "Create a card" … "Set flagged", BR-CARD-010 and BR-CARD-011. Creating
a card runs, in one transaction: `CardDraft.check`, the deck rule, the insert,
`ScheduleRepository.initializeCard`, `TagRepository.replaceForCard`, and the
deck's `content_type`. A batch refuses as a whole when one card is missing or a
rule fails, and an empty batch writes nothing. A deck left with no card returns
to `unset`, and an `unset` target becomes `card` (BR-DECK-015). The foundation's
card test and smoke test move to `CardDraft`.

- [ ] **Step 1: Write the failing tests**

In `test/support/card_fixtures.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';
```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
```

Replace

```dart
});
```

with

```dart
});

/// A card made through the real repository. A refusal here is a broken
/// fixture, so it throws.
extension CardFixtures on CardRepository {
  Future<CardEntity> card(
    String deckId, [
    CardDraft draft = const CardDraft(front: 'front', back: 'back'),
  ]) async => switch (await createCard(deckId: deckId, draft: draft)) {
    Ok(:final value) => value,
    Rejected(:final reason) => throw StateError(
      'fixture card refused: $reason',
    ),
  };
}
```

Create `test/features/card/domain/card_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

void main() {
  group('checkMove (BR-CARD-010)', () {
    Outcome<void, CardRejection> check({
      bool targetIsRoot = false,
      DeckContentType targetContentType = DeckContentType.unset,
      Set<String> sourceDeckIds = const {'source'},
      Set<String> sourceRootIds = const {'root'},
    }) => CardEntity.checkMove(
      targetDeckId: 'target',
      targetRootId: 'root',
      targetIsRoot: targetIsRoot,
      targetContentType: targetContentType,
      sourceDeckIds: sourceDeckIds,
      sourceRootIds: sourceRootIds,
    );

    CardRejection reasonOf(Outcome<void, CardRejection> result) =>
        (result as Rejected<void, CardRejection>).reason;

    test(
      'a sub-deck of the same root holding cards or nothing takes the cards',
      () {
        expect(check(), isA<Ok<void, CardRejection>>());
        expect(
          check(targetContentType: DeckContentType.card),
          isA<Ok<void, CardRejection>>(),
        );
      },
    );

    test('a root or a deck of decks is refused', () {
      expect(
        reasonOf(
          check(targetIsRoot: true, targetContentType: DeckContentType.deck),
        ),
        CardRejection.targetIsRoot,
      );
      expect(
        reasonOf(check(targetContentType: DeckContentType.deck)),
        CardRejection.targetHoldsDecks,
      );
    });

    test('a card already in the target is refused', () {
      expect(
        reasonOf(check(sourceDeckIds: {'source', 'target'})),
        CardRejection.sameDeck,
      );
    });

    test('a card of another root is refused, whatever the schedulers', () {
      expect(
        reasonOf(check(sourceRootIds: {'root', 'twin'})),
        CardRejection.crossRootMove,
      );
    });
  });
}
```

Replace the whole of `test/features/card/data/card_repository_impl_test.dart` with:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

DateTime _now() => DateTime(2026, 9, 23);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

/// Fails the one call `createCard` makes, to prove that the card and its
/// schedule row are written in one transaction (BR-CARD-004).
final class _FailingScheduleRepository implements ScheduleRepository {
  @override
  Future<void> initializeCard({required String cardId}) async =>
      throw StateError('schedule row not written');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  });
  tearDown(() => db.close());

  test(
    'creating a card sets content_type card on the (unset) parent deck',
    () async {
      final result = await cards.createCard(
        deckId: leaf.id,
        draft: const CardDraft(front: 'front', back: 'back'),
      );

      expect(result, isA<Ok<CardEntity, CardRejection>>());
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.card,
      );
    },
  );

  test('creating a card creates its schedule row from the root scheduler and generation (BR-CARD-004)', () async {
    final sm2 = await decks.root('s', SchedulerType.sm2);
    final sm2Leaf = await decks.sub(sm2.id, 'l');

    final card = await cards.card(sm2Leaf.id);

    final row = await db
        .customSelect(
          'SELECT scheduler_type, generation, ease_factor, current_box, learned_at, due_at '
          'FROM card_schedule WHERE card_id = ?',
          variables: [Variable(card.id)],
        )
        .getSingle();
    expect(row.read<String>('scheduler_type'), 'sm2');
    expect(row.read<int>('generation'), 1);
    expect(row.read<double>('ease_factor'), 2.5);
    expect(row.data['current_box'], isNull);
    expect(row.data['learned_at'], isNull);
    expect(row.data['due_at'], isNull);
  });

  test(
    'when the schedule row cannot be written, the card is not created either',
    () async {
      final failing = CardRepositoryImpl(
        db,
        _FailingScheduleRepository(),
        TagRepositoryImpl(db, now: _now),
        now: _now,
      );

      await expectLater(
        failing.createCard(
          deckId: leaf.id,
          draft: const CardDraft(front: 'f', back: 'b', tagNames: ['t']),
        ),
        throwsA(anything),
      );

      expect(await _count(db, 'card'), 0);
      expect(await _count(db, 'tags'), 0);
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.unset,
      );
    },
  );

  test('a card cannot be created directly on a root deck', () async {
    final result = await cards.createCard(
      deckId: root.id,
      draft: const CardDraft(front: 'f', back: 'b'),
    );

    expect(_reason(result), CardRejection.notACardContainer);
    expect(await _count(db, 'card'), 0);
    expect(await _count(db, 'card_schedule'), 0);
  });

  test(
    'a card cannot be created in a deck that already holds sub-decks',
    () async {
      final branch = await decks.sub(root.id, 'b');
      await decks.sub(branch.id, 'child');

      final result = await cards.createCard(
        deckId: branch.id,
        draft: const CardDraft(front: 'f', back: 'b'),
      );

      expect(_reason(result), CardRejection.notACardContainer);
    },
  );

  test('a draft the card rules refuse writes nothing (BR-CARD-001..003, BR-TAG-002)', () async {
    final before = await totalChanges(db);

    Future<CardRejection> refusal(CardDraft draft) async =>
        _reason(await cards.createCard(deckId: leaf.id, draft: draft));

    expect(
      await refusal(const CardDraft(front: '   ', back: 'b')),
      CardRejection.blankContent,
    );
    expect(
      await refusal(const CardDraft(front: 'f', back: '')),
      CardRejection.blankContent,
    );
    expect(
      await refusal(CardDraft(front: 'x' * 61, back: 'b')),
      CardRejection.frontTooLong,
    );
    expect(
      await refusal(
        CardDraft(
          front: 'f',
          back: 'b',
          tagNames: [for (var i = 0; i < 11; i++) 'tag $i'],
        ),
      ),
      CardRejection.tooManyTags,
    );
    expect(await totalChanges(db), before);
  });

  test('the flag and the tags of the draft are stored with the card', () async {
    final card = await cards.card(
      leaf.id,
      const CardDraft(
        front: 'f',
        back: 'b',
        isFlagged: true,
        tagNames: ['Verb', ' verb ', 'Food'],
      ),
    );

    final tags = await db
        .customSelect(
          'SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id '
          'WHERE ct.card_id = ? ORDER BY t.name_folded',
          variables: [Variable(card.id)],
        )
        .get();
    expect(card.isFlagged, isTrue);
    expect(
      [for (final row in tags) row.read<String>('name')],
      ['Food', 'Verb'],
    );
  });

  test(
    'optional example/hint/pronunciation trim to NULL, not empty string',
    () async {
      final card = await cards.card(
        leaf.id,
        const CardDraft(front: 'f', back: 'b', hint: '   '),
      );

      expect(card.hint, isNull);
    },
  );

  test(
    'front_folded/back_folded are Unicode-lowercase, not SQL lower()',
    () async {
      final card = await cards.card(
        leaf.id,
        const CardDraft(front: 'CÔNG NGHỆ', back: 'technology'),
      );

      final row = await db
          .customSelect(
            'SELECT front_folded FROM card WHERE id = ?',
            variables: [Variable(card.id)],
          )
          .getSingle();
      expect(row.read<String>('front_folded'), 'công nghệ');
    },
  );
}
```

Create `test/features/card/data/card_batch_writes_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The card writes stage 2 adds: edit, and the batches of BR-CARD-011, each
// all or nothing in one transaction.

DateTime _t0() => DateTime(2026, 9, 23);
final _later = DateTime(2026, 9, 24);

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity nouns;
  late DeckEntity verbs;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _t0);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _t0),
      TagRepositoryImpl(db, now: _t0),
      now: _t0,
    );
    root = await decks.root('Korean');
    nouns = await decks.sub(root.id, 'Nouns');
    verbs = await decks.sub(root.id, 'Verbs');
  });
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  Future<DeckContentType> contentTypeOf(String deckId) async =>
      (await decks.findById(deckId))!.contentType;

  Future<Map<String, Object?>> cardRow(String cardId) async =>
      (await db
              .customSelect(
                'SELECT * FROM card WHERE id = ?',
                variables: [Variable(cardId)],
              )
              .getSingle())
          .data;

  Future<List<String>> tagNamesOf(String cardId) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id '
              'WHERE ct.card_id = ? ORDER BY t.name_folded',
              variables: [Variable(cardId)],
            )
            .get())
      row.read<String>('name'),
  ];

  Future<void> learn(String cardId) => db.customStatement(
    'UPDATE card_schedule SET learned_at = 1, due_at = 2, current_box = 3 '
    'WHERE card_id = ?',
    [cardId],
  );

  /// A card's stored seconds, as Drift writes a DateTime.
  int seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

  group('editCard (BR-CARD-005)', () {
    test('replaces the content, the flag and the tags; keeps the schedule and the log', () async {
      final card = await cards.card(
        nouns.id,
        const CardDraft(front: 'f', back: 'b', tagNames: ['old']),
      );
      await learn(card.id);
      await db.customStatement(
        'INSERT INTO review_log (id, card_id, session_id, scheduler_type, '
        'generation, kind, mode, "action", answered_at) VALUES '
        "('log', ?, 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
        [card.id],
      );

      final result = await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(
          front: ' CÔNG ',
          back: 'work',
          hint: 'h',
          isFlagged: true,
          tagNames: ['Verb'],
        ),
        now: _later,
      );

      expect(result, isA<Ok<void, CardRejection>>());
      final row = await cardRow(card.id);
      expect(
        (
          row['front'],
          row['front_folded'],
          row['back'],
          row['hint'],
          row['is_flagged'],
        ),
        ('CÔNG', 'công', 'work', 'h', 1),
      );
      expect(
        (row['created_at'], row['updated_at']),
        (seconds(_t0()), seconds(_later)),
      );
      expect(await tagNamesOf(card.id), ['Verb']);
      final schedule = await db
          .customSelect(
            'SELECT learned_at, current_box FROM card_schedule WHERE card_id = ?',
            variables: [Variable(card.id)],
          )
          .getSingle();
      expect(schedule.data, {'learned_at': 1, 'current_box': 3});
      expect(await count('review_log'), 1);
    });

    test(
      'refuses a draft the rules refuse and a missing card, writing nothing',
      () async {
        final card = await cards.card(nouns.id);
        final before = await totalChanges(db);

        expect(
          _reason(
            await cards.editCard(
              cardId: card.id,
              draft: CardDraft(front: 'x' * 61, back: 'b'),
            ),
          ),
          CardRejection.frontTooLong,
        );
        expect(
          _reason(
            await cards.editCard(
              cardId: 'missing',
              draft: const CardDraft(front: 'f', back: 'b'),
            ),
          ),
          CardRejection.notFound,
        );
        expect(await totalChanges(db), before);
      },
    );
  });

  group('deleteCards (BR-CARD-011)', () {
    test('deletes the batch with its schedule rows and tag links; an emptied deck is unset', () async {
      final a = await cards.card(
        nouns.id,
        const CardDraft(front: 'a', back: 'a', tagNames: ['t']),
      );
      final b = await cards.card(verbs.id);
      await cards.card(verbs.id);

      final result = await cards.deleteCards(cardIds: {a.id, b.id});

      expect(result, isA<Ok<void, CardRejection>>());
      expect(
        (
          await count('card'),
          await count('card_schedule'),
          await count('card_tags'),
        ),
        (1, 1, 0),
      );
      expect(await contentTypeOf(nouns.id), DeckContentType.unset);
      expect(await contentTypeOf(verbs.id), DeckContentType.card);
    });

    test('one missing card refuses the whole batch', () async {
      final a = await cards.card(nouns.id);
      final before = await totalChanges(db);

      expect(
        _reason(await cards.deleteCards(cardIds: {a.id, 'missing'})),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
  });

  group('moveCards (BR-CARD-010)', () {
    test(
      'writes only deck_id and updated_at, and both content types follow',
      () async {
        final card = await cards.card(
          nouns.id,
          const CardDraft(
            front: 'f',
            back: 'b',
            isFlagged: true,
            tagNames: ['t'],
          ),
        );
        await learn(card.id);
        final empty = await decks.sub(root.id, 'Empty');

        final result = await cards.moveCards(
          cardIds: {card.id},
          targetDeckId: empty.id,
          now: _later,
        );

        expect(result, isA<Ok<void, CardRejection>>());
        final row = await cardRow(card.id);
        expect((row['deck_id'], row['is_flagged']), (empty.id, 1));
        expect(
          (row['created_at'], row['updated_at']),
          (seconds(_t0()), seconds(_later)),
        );
        expect(await tagNamesOf(card.id), ['t']);
        final schedule = await db
            .customSelect(
              'SELECT learned_at, current_box FROM card_schedule WHERE card_id = ?',
              variables: [Variable(card.id)],
            )
            .getSingle();
        expect(schedule.data, {'learned_at': 1, 'current_box': 3});
        expect(await contentTypeOf(nouns.id), DeckContentType.unset);
        expect(await contentTypeOf(empty.id), DeckContentType.card);
      },
    );

    test('refuses a batch the rules refuse, writing nothing', () async {
      final a = await cards.card(nouns.id);
      final b = await cards.card(verbs.id);
      final branch = await decks.sub(root.id, 'Branch');
      await decks.sub(branch.id, 'Child');
      final twin = await decks.root('Twin');
      final twinLeaf = await decks.sub(twin.id, 'Twin leaf');
      final before = await totalChanges(db);

      Future<CardRejection> refusal(Set<String> ids, String targetId) async =>
          _reason(await cards.moveCards(cardIds: ids, targetDeckId: targetId));

      expect(await refusal({a.id}, 'missing'), CardRejection.targetNotFound);
      expect(await refusal({a.id}, root.id), CardRejection.targetIsRoot);
      expect(await refusal({a.id}, branch.id), CardRejection.targetHoldsDecks);
      expect(await refusal({a.id, b.id}, verbs.id), CardRejection.sameDeck);
      expect(
        await refusal({a.id}, twinLeaf.id),
        CardRejection.crossRootMove,
        reason: 'refused even though both roots run eight_box at generation 1',
      );
      expect(
        await refusal({a.id, 'missing'}, verbs.id),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
  });

  group('setFlagged (BR-CARD-011)', () {
    test(
      'sets the value given on every card; a card already at it is not written',
      () async {
        final flagged = await cards.card(
          nouns.id,
          const CardDraft(front: 'f', back: 'b', isFlagged: true),
        );
        final plain = await cards.card(nouns.id);

        await cards.setFlagged(
          cardIds: {flagged.id, plain.id},
          isFlagged: true,
          now: _later,
        );

        expect(
          (
            (await cardRow(flagged.id))['is_flagged'],
            (await cardRow(flagged.id))['updated_at'],
          ),
          (1, seconds(_t0())),
        );
        expect(
          (
            (await cardRow(plain.id))['is_flagged'],
            (await cardRow(plain.id))['updated_at'],
          ),
          (1, seconds(_later)),
        );

        await cards.setFlagged(
          cardIds: {flagged.id, plain.id},
          isFlagged: false,
        );

        expect(
          [
            (await cardRow(flagged.id))['is_flagged'],
            (await cardRow(plain.id))['is_flagged'],
          ],
          [0, 0],
        );
      },
    );

    test('one missing card refuses the whole batch', () async {
      final a = await cards.card(nouns.id);
      final before = await totalChanges(db);

      expect(
        _reason(
          await cards.setFlagged(cardIds: {a.id, 'missing'}, isFlagged: true),
        ),
        CardRejection.notFound,
      );
      expect(await totalChanges(db), before);
    });
  });

  test(
    'an empty batch writes nothing, and an unset target stays unset',
    () async {
      final empty = await decks.sub(root.id, 'Empty');
      final before = await totalChanges(db);

      expect(
        await cards.deleteCards(cardIds: {}),
        isA<Ok<void, CardRejection>>(),
      );
      expect(
        await cards.moveCards(cardIds: {}, targetDeckId: empty.id),
        isA<Ok<void, CardRejection>>(),
      );
      expect(
        await cards.setFlagged(cardIds: {}, isFlagged: true),
        isA<Ok<void, CardRejection>>(),
      );
      expect(await totalChanges(db), before);
      expect(await contentTypeOf(empty.id), DeckContentType.unset);
    },
  );

  test('a card or a deck in the Trash is out of reach of every card write (spec §8)', () async {
    final card = await cards.card(nouns.id);
    final trashedCard = await cards.card(nouns.id);
    final trashedDeck = await decks.sub(root.id, 'Trashed');
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
      [trashedCard.id],
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [trashedDeck.id],
    );
    final before = await totalChanges(db);
    const draft = CardDraft(front: 'f', back: 'b');

    expect(
      _reason(await cards.editCard(cardId: trashedCard.id, draft: draft)),
      CardRejection.notFound,
    );
    expect(
      _reason(await cards.deleteCards(cardIds: {trashedCard.id})),
      CardRejection.notFound,
    );
    expect(
      _reason(
        await cards.moveCards(
          cardIds: {trashedCard.id},
          targetDeckId: verbs.id,
        ),
      ),
      CardRejection.notFound,
    );
    expect(
      _reason(
        await cards.setFlagged(cardIds: {trashedCard.id}, isFlagged: true),
      ),
      CardRejection.notFound,
    );
    expect(
      _reason(
        await cards.moveCards(cardIds: {card.id}, targetDeckId: trashedDeck.id),
      ),
      CardRejection.targetNotFound,
    );
    expect(
      _reason(await cards.createCard(deckId: trashedDeck.id, draft: draft)),
      CardRejection.notFound,
    );
    expect(await totalChanges(db), before);
  });
}
```

Create `test/features/card/domain/card_write_use_cases_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/usecases/add_tag_to_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/create_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/delete_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/move_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/remove_tag_from_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The card write use cases forward to one repository call each (AD-12). They
// run here over the real repositories, so the test asserts what a person
// sees, not that a fake was called.

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test(
    'the card write use cases drive a deck of cards end to end (UC-CARD-001)',
    () async {
      DateTime now() => DateTime(2026, 9, 23);
      final decks = DeckRepositoryImpl(db, now: now);
      final tags = TagRepositoryImpl(db, now: now);
      final cards = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: now),
        tags,
        now: now,
      );
      final root = await decks.root('Korean');
      final nouns = await decks.sub(root.id, 'Nouns');
      final verbs = await decks.sub(root.id, 'Verbs');
      final create = CreateCardUseCase(cards);
      CardEntity created(Outcome<CardEntity, CardRejection> result) =>
          (result as Ok<CardEntity, CardRejection>).value;

      final apple = created(
        await create(
          deckId: nouns.id,
          draft: const CardDraft(front: '사과', back: 'apple'),
        ),
      );
      final pear = created(
        await create(
          deckId: nouns.id,
          draft: const CardDraft(front: '배', back: 'pear'),
        ),
      );
      await EditCardUseCase(cards)(
        cardId: apple.id,
        draft: const CardDraft(front: '사과', back: 'an apple'),
      );
      await SetCardsFlaggedUseCase(cards)(
        cardIds: {apple.id, pear.id},
        isFlagged: true,
      );
      await AddTagToCardsUseCase(tags)(
        cardIds: {apple.id, pear.id},
        tagName: 'Fruit',
      );
      final fruitId =
          (await db
                  .customSelect(
                    "SELECT id FROM tags WHERE name_folded = 'fruit'",
                  )
                  .getSingle())
              .read<String>('id');
      await RemoveTagFromCardsUseCase(tags)(cardIds: {pear.id}, tagId: fruitId);
      await MoveCardsUseCase(cards)(cardIds: {pear.id}, targetDeckId: verbs.id);
      await DeleteCardsUseCase(cards)(cardIds: {apple.id});

      final rows = await db
          .customSelect('SELECT id, deck_id, back, is_flagged FROM card')
          .get();
      expect(
        [
          for (final row in rows)
            (
              row.read<String>('id'),
              row.read<String>('deck_id'),
              row.read<int>('is_flagged'),
            ),
        ],
        [(pear.id, verbs.id, 1)],
      );
      final links = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM card_tags WHERE card_id = ?',
            variables: [Variable(pear.id)],
          )
          .getSingle();
      expect(links.read<int>('n'), 0);
      expect(
        (await decks.findById(nouns.id))!.contentType,
        DeckContentType.unset,
      );
      expect(
        (await decks.findById(verbs.id))!.contentType,
        DeckContentType.card,
      );
    },
  );
}
```

In `test/integration/foundation_smoke_test.dart`:

Replace

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
```

with

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
```

Replace

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
```

Replace

```dart
    'deck -> card -> two reviews -> reset leaves a consistent database',
```

with

```dart
    'deck -> tagged card -> two reviews -> reset leaves a consistent database',
```

Replace

```dart
      final cards = CardRepositoryImpl(db, schedules, now: () => now);
```

with

```dart
      final cards = CardRepositoryImpl(
        db,
        schedules,
        TagRepositoryImpl(db, now: () => now),
        now: () => now,
      );
```

Replace

```dart
        front: '사과',
        back: 'apple',
```

with

```dart
        draft: const CardDraft(front: '사과', back: 'apple', tagNames: ['fruit']),
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/features/card/domain/card_entity_test.dart \
  test/features/card/data/card_repository_impl_test.dart \
  test/features/card/data/card_batch_writes_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  test/integration/foundation_smoke_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/features/card/domain/card_entity_test.dart` — `Error: Member not found: 'CardEntity.checkMove'.`
- `test/features/card/data/card_repository_impl_test.dart` — `Error: Too many positional arguments: 2 allowed, but 3 found.`
- `test/features/card/data/card_batch_writes_test.dart` — `Error: Too many positional arguments: 2 allowed, but 3 found.`
- `test/features/card/domain/card_write_use_cases_test.dart` — `Error when reading 'lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart': No such file or directory`
- `test/integration/foundation_smoke_test.dart` — `Error: Too many positional arguments: 2 allowed, but 3 found.`

- [ ] **Step 3: Replace `checkContent` with the move rule in `CardEntity`**

In `lib/features/card/domain/entities/card_entity.dart`:

Replace

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
```

with

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
```

Replace

```dart
  /// BR-CARD-001: both faces carry text.
  static Outcome<void, CardRejection> checkContent({
    required String front,
    required String back,
  }) => front.trim().isEmpty || back.trim().isEmpty
      ? const Rejected(CardRejection.blankContent)
      : const Ok(null);
```

with

```dart
  /// BR-CARD-010: where a batch of cards may go. [sourceDeckIds] are the
  /// decks the cards sit in, [sourceRootIds] the roots of those decks. A
  /// move never crosses roots, even between two roots that happen to run the
  /// same scheduler at the same generation.
  static Outcome<void, CardRejection> checkMove({
    required String targetDeckId,
    required String targetRootId,
    required bool targetIsRoot,
    required DeckContentType targetContentType,
    required Set<String> sourceDeckIds,
    required Set<String> sourceRootIds,
  }) {
    if (targetIsRoot) return const Rejected(CardRejection.targetIsRoot);
    if (targetContentType == DeckContentType.deck) {
      return const Rejected(CardRejection.targetHoldsDecks);
    }
    if (sourceDeckIds.contains(targetDeckId)) {
      return const Rejected(CardRejection.sameDeck);
    }
    if (sourceRootIds.any((rootId) => rootId != targetRootId)) {
      return const Rejected(CardRejection.crossRootMove);
    }
    return const Ok(null);
  }
```

- [ ] **Step 4: Rewrite the card repository contract**

Replace the whole of `lib/features/card/domain/repositories/card_repository.dart` with:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

/// The one implementation is `CardRepositoryImpl` (data layer). The contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
///
/// A batch takes a set of card ids and is all or nothing in one transaction:
/// one card the rules refuse refuses the batch, and nothing is written
/// (BR-CARD-011). An empty set writes nothing and answers `Ok`.
abstract interface class CardRepository {
  /// UC-CARD-001: the card, its schedule row (BR-CARD-004) and its tags, and
  /// the deck becomes a deck of cards when it held nothing (BR-DECK-008).
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  });

  /// UC-CARD-001 A1: new content, flag and tags; the schedule row and the
  /// review log stay as they are (BR-CARD-005).
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  });

  /// Their schedule rows, logs and tag links go with them; a deck left with
  /// no card is unset again (BR-DECK-015).
  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
  });

  /// BR-CARD-010: only `deck_id` and `updated_at` change.
  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  });

  /// An explicit value for every card, never a toggle (BR-CARD-011).
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  });
}
```

- [ ] **Step 5: Read active rows only, and write drafts and batches**

Replace the whole of `lib/features/card/data/datasources/card_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';

/// Row access for `card`, plus the reads and writes of the owning `deck` row
/// that card writes need. It returns Drift rows, never domain entities, and
/// runs inside the caller's transaction. A card or deck in the Trash is out
/// of reach of every write (spec §8).
final class CardDao {
  CardDao(this._db);

  final AppDatabase _db;

  Future<CardRow?> findRow(String id) =>
      (_db.select(_db.card)
            ..where((card) => card.id.equals(id) & card.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The active cards among [ids].
  Future<List<CardRow>> liveRows(Set<String> ids) => (_db.select(
    _db.card,
  )..where((card) => card.id.isIn(ids) & card.deleteBatchId.isNull())).get();

  Future<Deck?> deckRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  Future<List<Deck>> deckRows(Set<String> ids) =>
      (_db.select(_db.deck)..where((deck) => deck.id.isIn(ids))).get();

  Future<void> insertCard({
    required String id,
    required String deckId,
    required CardDraft draft,
    required DateTime now,
  }) => _db
      .into(_db.card)
      .insert(
        _contentOf(draft).copyWith(
          id: Value(id),
          deckId: Value(deckId),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  Future<void> updateContent(String id, CardDraft draft, DateTime now) =>
      (_db.update(_db.card)..where((card) => card.id.equals(id))).write(
        _contentOf(draft).copyWith(updatedAt: Value(now)),
      );

  /// Their schedule rows, review logs and tag links go with them by cascade.
  Future<void> deleteCards(Set<String> ids) =>
      (_db.delete(_db.card)..where((card) => card.id.isIn(ids))).go();

  Future<void> moveCards(Set<String> ids, String deckId, DateTime now) =>
      (_db.update(_db.card)..where((card) => card.id.isIn(ids))).write(
        CardCompanion(deckId: Value(deckId), updatedAt: Value(now)),
      );

  /// Writes only the cards whose flag differs from [isFlagged].
  Future<void> setFlagged(Set<String> ids, bool isFlagged, DateTime now) {
    final flag = isFlagged ? 1 : 0;
    return (_db.update(_db.card)..where(
          (card) => card.id.isIn(ids) & card.isFlagged.equals(flag).not(),
        ))
        .write(CardCompanion(isFlagged: Value(flag), updatedAt: Value(now)));
  }

  /// Whether [deckId] still holds a live card; tombstones do not count, as in
  /// invariant 29.
  Future<bool> holdsCards(String deckId) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM card WHERE deck_id = ?'
          ' AND delete_batch_id IS NULL) AS holds',
          variables: [Variable<String>(deckId)],
          readsFrom: {_db.card},
        )
        .getSingle();
    return row.read<bool>('holds');
  }

  Future<void> setDeckContentType(
    String deckId,
    String contentType,
    DateTime now,
  ) => (_db.update(_db.deck)..where((deck) => deck.id.equals(deckId))).write(
    DeckCompanion(contentType: Value(contentType), updatedAt: Value(now)),
  );
}

/// The columns a draft sets: sides trimmed with their folded forms computed
/// in Dart (schema.md), blank optional fields stored as null.
CardCompanion _contentOf(CardDraft draft) => CardCompanion(
  front: Value(draft.front.trim()),
  back: Value(draft.back.trim()),
  frontFolded: Value(foldText(draft.front)),
  backFolded: Value(foldText(draft.back)),
  example: Value(_trimmedOrNull(draft.example)),
  hint: Value(_trimmedOrNull(draft.hint)),
  pronunciation: Value(_trimmedOrNull(draft.pronunciation)),
  isFlagged: Value(draft.isFlagged ? 1 : 0),
);

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
```

- [ ] **Step 6: Implement the draft and batch writes**

Replace the whole of `lib/features/card/data/repositories/card_repository_impl.dart` with:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// Every write reads the rows its rules need and writes inside one
/// transaction, which the schedule row (BR-CARD-004) and the tag links join.
/// A refusal writes nothing.
final class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(
    this._db,
    this._schedules,
    this._tags, {
    DateTime Function()? now,
  }) : _dao = CardDao(_db),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final ScheduleRepository _schedules;
  final TagRepository _tags;
  final CardDao _dao;
  final DateTime Function() _now;

  @override
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return const Rejected(CardRejection.notFound);
      final contentType = DeckContentType.values.byName(deck.contentType);
      final container = DeckEntity.checkCreateCard(
        parentContentType: contentType,
      );
      if (container case Rejected()) {
        return const Rejected(CardRejection.notACardContainer);
      }

      final id = newId();
      await _dao.insertCard(id: id, deckId: deckId, draft: draft, now: at);
      await _schedules.initializeCard(cardId: id);
      await _replaceTags(id, draft, at);
      if (contentType == DeckContentType.unset) {
        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
      }
      return Ok(_toEntity((await _dao.findRow(id))!));
    });
  }

  @override
  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      if (await _dao.findRow(cardId) == null) {
        return const Rejected(CardRejection.notFound);
      }
      await _dao.updateContent(cardId, draft, at);
      await _replaceTags(cardId, draft, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
  }) {
    final at = _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok(null);
      final rows = await _dao.liveRows(cardIds);
      if (rows.length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      await _dao.deleteCards(cardIds);
      await _unsetEmptied({for (final row in rows) row.deckId}, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok(null);
      final rows = await _dao.liveRows(cardIds);
      if (rows.length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      final target = await _dao.deckRow(targetDeckId);
      if (target == null) return const Rejected(CardRejection.targetNotFound);
      final sourceDeckIds = {for (final row in rows) row.deckId};
      final sources = await _dao.deckRows(sourceDeckIds);
      final targetContentType = DeckContentType.values.byName(
        target.contentType,
      );
      final rule = CardEntity.checkMove(
        targetDeckId: target.id,
        targetRootId: target.rootId,
        targetIsRoot: target.parentId == null,
        targetContentType: targetContentType,
        sourceDeckIds: sourceDeckIds,
        sourceRootIds: {for (final source in sources) source.rootId},
      );
      if (rule case Rejected(:final reason)) return Rejected(reason);

      await _dao.moveCards(cardIds, targetDeckId, at);
      await _unsetEmptied(sourceDeckIds, at);
      if (targetContentType == DeckContentType.unset) {
        await _dao.setDeckContentType(
          targetDeckId,
          DeckContentType.card.name,
          at,
        );
      }
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok(null);
      if ((await _dao.liveRows(cardIds)).length != cardIds.length) {
        return const Rejected(CardRejection.notFound);
      }
      await _dao.setFlagged(cardIds, isFlagged, at);
      return const Ok(null);
    });
  }

  /// The draft passed [CardDraft.check], which holds the tag rules, so a
  /// refusal here is a bug: throwing rolls the whole write back.
  Future<void> _replaceTags(String cardId, CardDraft draft, DateTime at) async {
    final result = await _tags.replaceForCard(
      cardId: cardId,
      names: draft.tagNames,
      now: at,
    );
    if (result case Rejected(:final reason)) {
      throw StateError('tags refused a checked draft: $reason');
    }
  }

  /// A card deck left with no card is unset again (BR-DECK-015, invariant 29).
  Future<void> _unsetEmptied(Set<String> deckIds, DateTime at) async {
    for (final deckId in deckIds) {
      if (await _dao.holdsCards(deckId)) continue;
      await _dao.setDeckContentType(deckId, DeckContentType.unset.name, at);
    }
  }

  /// One transaction. Nothing inside catches: a throw leaves it, Drift rolls
  /// every row of the write back together, and the error leaves as
  /// `mapDatabaseError`'s [Failure].
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

CardEntity _toEntity(CardRow row) => CardEntity(
  id: row.id,
  deckId: row.deckId,
  front: row.front,
  back: row.back,
  isFlagged: row.isFlagged == 1,
  example: row.example,
  hint: row.hint,
  pronunciation: row.pronunciation,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);
```

- [ ] **Step 7: Give the card repository the tag repository**

In `lib/features/card/di/card_repository_provider.dart`:

Replace

```dart
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
```

with

```dart
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/tags/di/tag_repository_provider.dart';
```

Replace

```dart
  ref.watch(scheduleRepositoryProvider),
```

with

```dart
  ref.watch(scheduleRepositoryProvider),
  ref.watch(tagRepositoryProvider),
```

- [ ] **Step 8: Create `add_tag_to_cards_use_case.dart`**

Create `lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-CARD-001 A6, A8: the tag named [tagName] on every card given, reused
/// by its folded name or created (BR-TAG-001, BR-CARD-011).
final class AddTagToCardsUseCase {
  const AddTagToCardsUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({
    required Set<String> cardIds,
    required String tagName,
  }) => _tags.attachByName(cardIds: cardIds, name: tagName);
}
```

- [ ] **Step 9: Create `create_card_use_case.dart`**

Create `lib/features/card/domain/usecases/create_card_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001, UC-DECK-004 card branch: a new card, ready to learn
/// (BR-CARD-004).
final class CreateCardUseCase {
  const CreateCardUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<CardEntity, CardRejection>> call({
    required String deckId,
    required CardDraft draft,
  }) => _cards.createCard(deckId: deckId, draft: draft);
}
```

- [ ] **Step 10: Create `delete_cards_use_case.dart`**

Create `lib/features/card/domain/usecases/delete_cards_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A2, A6: the cards and their learning history are gone, all
/// or none (BR-CARD-011).
final class DeleteCardsUseCase {
  const DeleteCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({required Set<String> cardIds}) =>
      _cards.deleteCards(cardIds: cardIds);
}
```

- [ ] **Step 11: Create `edit_card_use_case.dart`**

Create `lib/features/card/domain/usecases/edit_card_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A1: new content for a card; its learning stays (BR-CARD-005).
final class EditCardUseCase {
  const EditCardUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required String cardId,
    required CardDraft draft,
  }) => _cards.editCard(cardId: cardId, draft: draft);
}
```

- [ ] **Step 12: Create `move_cards_use_case.dart`**

Create `lib/features/card/domain/usecases/move_cards_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A5, A6: the cards go to another deck of the same root, with
/// their learning (BR-CARD-010).
final class MoveCardsUseCase {
  const MoveCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required Set<String> cardIds,
    required String targetDeckId,
  }) => _cards.moveCards(cardIds: cardIds, targetDeckId: targetDeckId);
}
```

- [ ] **Step 13: Create `remove_tag_from_cards_use_case.dart`**

Create `lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-CARD-001 A8: the tag off every card given; the tag itself stays.
final class RemoveTagFromCardsUseCase {
  const RemoveTagFromCardsUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({
    required Set<String> cardIds,
    required String tagId,
  }) => _tags.detach(cardIds: cardIds, tagId: tagId);
}
```

- [ ] **Step 14: Create `set_cards_flagged_use_case.dart`**

Create `lib/features/card/domain/usecases/set_cards_flagged_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A6, A7: Set flagged or Remove flag on every card given
/// (BR-CARD-011).
final class SetCardsFlaggedUseCase {
  const SetCardsFlaggedUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required Set<String> cardIds,
    required bool isFlagged,
  }) => _cards.setFlagged(cardIds: cardIds, isFlagged: isFlagged);
}
```

- [ ] **Step 15: Regenerate the docs index and check the docs**

`docs/_generated/traceability.md` lists, for each use case, the tests
that name its id, and `docs/README.md` wants docs and code in the same commit;
this task's tests name use case ids.

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `OK docs/_generated: generated 3 files`, then `PASS — 0 error(s), 82 warning(s)`.

- [ ] **Step 16: Generate the Drift and Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `Built with build_runner`, and no `drift_dev` warning.

- [ ] **Step 17: Run the task's tests**

```bash
flutter test test/features/card/domain/card_entity_test.dart \
  test/features/card/data/card_repository_impl_test.dart \
  test/features/card/data/card_batch_writes_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  test/integration/foundation_smoke_test.dart
```

Expected: `+25: All tests passed!`

- [ ] **Step 18: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+309: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 19: Commit**

```bash
git add docs/_generated \
  lib/features/card/data/datasources/card_dao.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/di/card_repository_provider.dart \
  lib/features/card/domain/entities/card_entity.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart \
  lib/features/card/domain/usecases/create_card_use_case.dart \
  lib/features/card/domain/usecases/delete_cards_use_case.dart \
  lib/features/card/domain/usecases/edit_card_use_case.dart \
  lib/features/card/domain/usecases/move_cards_use_case.dart \
  lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart \
  lib/features/card/domain/usecases/set_cards_flagged_use_case.dart \
  test/features/card/data/card_batch_writes_test.dart \
  test/features/card/data/card_repository_impl_test.dart \
  test/features/card/domain/card_entity_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  test/integration/foundation_smoke_test.dart \
  test/support/card_fixtures.dart
git commit -m "feat(card): add card drafts with tags, edit and batch writes, and the card write use cases"
```


### Task 8: The card list: filters, search, window, counts, Select all

**Files:**
- Create: `lib/features/card/domain/models/card_list_query_model.dart`, `lib/features/card/domain/models/card_list_view_model.dart`, `lib/features/card/data/datasources/card_list_dao.dart`, `lib/features/card/data/mappers/card_mapper.dart`, `lib/features/card/domain/usecases/select_all_card_ids_use_case.dart`, `lib/features/card/domain/usecases/watch_card_list_use_case.dart`
- Modify: `lib/features/srs/domain/models/card_schedule_state_model.dart`, `lib/features/card/domain/repositories/card_repository.dart`, `lib/features/srs/data/repositories/schedule_repository_impl.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`
- Test (create): `test/features/card/data/card_list_read_test.dart`, `test/features/card/domain/card_list_use_cases_test.dart`
- Test (modify): `test/features/srs/domain/card_schedule_state_model_test.dart`

**Interfaces:**
- Consumes: `DayClock`, `watchEachLocalDay`, `CardDisplayStatus`, `FakeDayClock`
  (Task 2); `foldText`, `mapDatabaseErrors`, `SelectCounter`, `insertCard`
  (Task 5); the Task 7 `CardRepository` and `CardRepositoryImpl`.
- Produces:
  - `factory CardScheduleState.fromColumns({required SchedulerType type,
    required int generation, required DateTime? learnedAt, required DateTime?
    dueAt, required DateTime? lastAnsweredAt, required int answerCount,
    required int lapseCount, required int? currentBox, required double?
    easeFactor, required int? intervalDays, required int? repetitions})`; the
    srs repository maps its rows through it.
  - `enum CardListFilter { all, due, newCards, flagged }`,
    `enum CardListSort { newest, dueFirst }`,
    `CardListQuery({CardListFilter filter, CardListSort sort, String searchTerm})`.
  - `CardListItem({id, front, back, isFlagged, dueAt, displayStatus})`,
    `CardListCounts({all, due, newCards, flagged})`,
    `CardListView({items, hasMore, counts})`.
  - `CardRepository.watchCardList({required String deckId, required
    CardListQuery query, required int windowSize, required DateTime now})` →
    `Stream<CardListView>`; `cardIdsMatching({required String deckId, required
    CardListQuery query, required DateTime now})` → `Future<Set<String>>`.
  - `CardListDao` (the one predicate) and `card/data/mappers/card_mapper.dart`
    (`cardEntityOf`, `scheduleStateOf`, `listItemOf`).
  - `WatchCardListUseCase(CardRepository, DayClock)` with
    `call({deckId, query, windowSize})`; `SelectAllCardIdsUseCase(CardRepository,
    DayClock)` with `call({deckId, query})`.

Spec §8 "The card list". One Dart function builds the predicate from the deck,
the filter and the search term, and the list, the counts and Select all all
read through it (BR-CARD-012). The search matches the folded term inside a
folded side with `instr`, so `%` and `_` need no escaping. The window asks for
`windowSize + 1` rows; the extra one only sets `hasMore`. The counts apply the
search but not the filter, in one statement (IT-ORG-005).

- [ ] **Step 1: Write the failing tests**

In `test/features/srs/domain/card_schedule_state_model_test.dart`:

Replace

```dart
    },
  );
}
```

with

```dart
    },
  );

  test('fromColumns reads the columns of the scheduler the row runs', () {
    final learned = DateTime(2026, 9, 20);
    final eightBox = CardScheduleState.fromColumns(
      type: SchedulerType.eightBox,
      generation: 2,
      learnedAt: learned,
      dueAt: DateTime(2026, 9, 23),
      lastAnsweredAt: learned,
      answerCount: 3,
      lapseCount: 1,
      currentBox: 4,
      easeFactor: null,
      intervalDays: null,
      repetitions: null,
    );
    final sm2 = CardScheduleState.fromColumns(
      type: SchedulerType.sm2,
      generation: 1,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      currentBox: null,
      easeFactor: 2.36,
      intervalDays: 6,
      repetitions: 2,
    );

    expect(
      (eightBox.generation, eightBox.currentBox, eightBox.answerCount),
      (2, 4, 3),
    );
    expect(eightBox.easeFactor, isNull);
    expect((sm2.easeFactor, sm2.intervalDays, sm2.repetitions), (2.36, 6, 2));
    expect(sm2.currentBox, isNull);
  });
}
```

Create `test/features/card/data/card_list_read_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// `Mixed due` of S-DUE (agent-execution-guide §6.2) at T0 = 2026-09-23 10:00,
// every due_at on a local midnight (BR-STUDY-074).
final _now = DateTime(2026, 9, 23, 10);

void main() {
  late SelectCounter counter;
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late DeckEntity mixed;

  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
    DateTime clock() => DateTime(2026, 9, 1);
    final decks = DeckRepositoryImpl(db, now: clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: clock),
      TagRepositoryImpl(db, now: clock),
      now: clock,
    );
    final root = await decks.root('Due library');
    mixed = await decks.sub(root.id, 'Mixed due');
    await insertCard(
      db,
      id: 'new',
      deckId: mixed.id,
      front: 'abandon',
      back: 'từ bỏ',
      createdAt: DateTime(2026, 9, 1),
    );
    await insertCard(
      db,
      id: 'begin',
      deckId: mixed.id,
      front: 'benevolent',
      back: 'nhân từ',
      isFlagged: true,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 23),
      box: 2,
      createdAt: DateTime(2026, 9, 2),
    );
    await insertCard(
      db,
      id: 'review',
      deckId: mixed.id,
      front: 'candid',
      back: 'thẳng thắn',
      learnedAt: DateTime(2026, 9, 10),
      dueAt: DateTime(2026, 9, 22),
      box: 5,
      createdAt: DateTime(2026, 9, 3),
    );
    await insertCard(
      db,
      id: 'master',
      deckId: mixed.id,
      front: 'diligent',
      back: 'chăm chỉ',
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 23),
      box: 8,
      createdAt: DateTime(2026, 9, 4),
    );
  });
  tearDown(() => db.close());

  Future<CardListView> list({
    CardListQuery query = const CardListQuery(),
    int windowSize = 50,
  }) => cards
      .watchCardList(
        deckId: mixed.id,
        query: query,
        windowSize: windowSize,
        now: _now,
      )
      .first;

  List<String> ids(CardListView view) => [
    for (final item in view.items) item.id,
  ];

  test(
    'the counts of every filter, under the search only (IT-ORG-005)',
    () async {
      final all = await list();
      final searched = await list(
        query: const CardListQuery(
          filter: CardListFilter.newCards,
          searchTerm: 'từ',
        ),
      );

      expect(
        (
          all.counts.all,
          all.counts.due,
          all.counts.newCards,
          all.counts.flagged,
        ),
        (4, 2, 1, 1),
      );
      expect(
        (
          searched.counts.all,
          searched.counts.due,
          searched.counts.newCards,
          searched.counts.flagged,
        ),
        (2, 1, 1, 1),
      );
    },
  );

  test('each filter keeps its cards (IT-ORG-005)', () async {
    Future<List<String>> through(CardListFilter filter) async =>
        ids(await list(query: CardListQuery(filter: filter)));

    expect(await through(CardListFilter.due), ['review', 'begin']);
    expect(await through(CardListFilter.newCards), ['new']);
    expect(await through(CardListFilter.flagged), ['begin']);
  });

  test(
    'the search matches a folded front or back as a substring (IT-ORG-001)',
    () async {
      Future<List<String>> found(String term) async =>
          ids(await list(query: CardListQuery(searchTerm: term)));

      expect(await found('abandon'), ['new']);
      expect(await found('  NHÂN TỪ '), ['begin']);
      expect(await found('không-tồn-tại'), isEmpty);
      expect(await found('%'), isEmpty, reason: 'no LIKE wildcard');
    },
  );

  test('newest follows created_at; dueFirst puts the soonest due first and New last (IT-ORG-003)', () async {
    expect(ids(await list()), ['master', 'review', 'begin', 'new']);
    expect(
      ids(await list(query: const CardListQuery(sort: CardListSort.dueFirst))),
      ['review', 'begin', 'master', 'new'],
    );
  });

  test('each item carries its flag, due date and display status', () async {
    final items = {for (final item in (await list()).items) item.id: item};

    expect(
      [
        for (final id in ['new', 'begin', 'review', 'master'])
          items[id]!.displayStatus,
      ],
      [
        CardDisplayStatus.newCard,
        CardDisplayStatus.beginning,
        CardDisplayStatus.reviewing,
        CardDisplayStatus.mastered,
      ],
    );
    expect(
      (items['begin']!.isFlagged, items['begin']!.dueAt),
      (true, DateTime(2026, 9, 23)),
    );
    expect(
      (items['new']!.front, items['new']!.back, items['new']!.dueAt),
      ('abandon', 'từ bỏ', null),
    );
  });

  test(
    'the window holds windowSize cards and says whether more follow',
    () async {
      final first = await list(windowSize: 3);
      final whole = await list(windowSize: 4);

      expect((first.items.length, first.hasMore), (3, true));
      expect((whole.items.length, whole.hasMore), (4, false));
    },
  );

  test('a card in the Trash is left out', () async {
    await insertCard(
      db,
      id: 'trashed',
      deckId: mixed.id,
      deleteBatchId: 'batch',
    );

    final view = await list();

    expect(view.counts.all, 4);
    expect(ids(view), isNot(contains('trashed')));
  });

  test('an emission is two statements, the window and the counts, and a change emits once', () async {
    counter.selects = 0;
    final views = <CardListView>[];
    final subscription = cards
        .watchCardList(
          deckId: mixed.id,
          query: const CardListQuery(),
          windowSize: 50,
          now: _now,
        )
        .listen(views.add);
    await pumpEventQueue();
    expect((views.length, counter.selects), (1, 2));

    await insertCard(db, id: 'another', deckId: mixed.id);
    await pumpEventQueue();

    expect((views.length, counter.selects), (2, 4));
    expect(views.last.counts.all, 5);
    await subscription.cancel();
  });

  test('Select all takes every card the query lets through, past the window (BR-CARD-012)', () async {
    final due = await cards.cardIdsMatching(
      deckId: mixed.id,
      query: const CardListQuery(filter: CardListFilter.due),
      now: _now,
    );
    final searched = await cards.cardIdsMatching(
      deckId: mixed.id,
      query: const CardListQuery(searchTerm: 'từ'),
      now: _now,
    );

    expect(due, {'begin', 'review'});
    expect(searched, {'new', 'begin'});
  });
}
```

Create `test/features/card/domain/card_list_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/usecases/select_all_card_ids_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_list_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    DateTime now() => DateTime(2026, 9, 1);
    final decks = DeckRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      TagRepositoryImpl(db, now: now),
      now: now,
    );
    final root = await decks.root('Korean');
    leaf = await decks.sub(root.id, 'Nouns');
    await insertCard(
      db,
      id: 'today',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 23),
      box: 2,
    );
    await insertCard(
      db,
      id: 'tomorrow',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 24),
      box: 2,
    );
  });
  tearDown(() => db.close());

  test(
    'a new local day brings the cards due that day into Due (BR-STUDY-068)',
    () async {
      final clock = FakeDayClock(DateTime(2026, 9, 23, 23));
      final views = <CardListView>[];
      final subscription = WatchCardListUseCase(cards, clock)(
        deckId: leaf.id,
        query: const CardListQuery(filter: CardListFilter.due),
        windowSize: 50,
      ).listen(views.add);
      await pumpEventQueue();

      clock.startDay(DateTime(2026, 9, 24));
      await pumpEventQueue();

      final [before, after] = views;
      expect({for (final item in before.items) item.id}, {'today'});
      expect({for (final item in after.items) item.id}, {'today', 'tomorrow'});
      expect((before.counts.due, after.counts.due), (1, 2));
      await subscription.cancel();
    },
  );

  test('Select all reads Due at the clock\'s now', () async {
    final select = SelectAllCardIdsUseCase(
      cards,
      FakeDayClock(DateTime(2026, 9, 24, 8)),
    );

    final ids = await select(
      deckId: leaf.id,
      query: const CardListQuery(filter: CardListFilter.due),
    );

    expect(ids, {'today', 'tomorrow'});
  });
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/features/srs/domain/card_schedule_state_model_test.dart \
  test/features/card/data/card_list_read_test.dart \
  test/features/card/domain/card_list_use_cases_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/features/srs/domain/card_schedule_state_model_test.dart` — `Error: Member not found: 'CardScheduleState.fromColumns'.`
- `test/features/card/data/card_list_read_test.dart` — `Error when reading 'lib/features/card/domain/models/card_list_query_model.dart': No such file or directory`
- `test/features/card/domain/card_list_use_cases_test.dart` — `Error when reading 'lib/features/card/domain/models/card_list_query_model.dart': No such file or directory`

- [ ] **Step 3: Add `CardScheduleState.fromColumns`**

In `lib/features/srs/domain/models/card_schedule_state_model.dart`:

Replace

```dart
      repetitions: 0,
```

with

```dart
      repetitions: 0,
    ),
  };

  /// The state a `card_schedule` row holds, column by column (schema.md):
  /// the columns of the scheduler [type] names are set, the other
  /// scheduler's are null, as the row's CHECK constraints keep them.
  factory CardScheduleState.fromColumns({
    required SchedulerType type,
    required int generation,
    required DateTime? learnedAt,
    required DateTime? dueAt,
    required DateTime? lastAnsweredAt,
    required int answerCount,
    required int lapseCount,
    required int? currentBox,
    required double? easeFactor,
    required int? intervalDays,
    required int? repetitions,
  }) => switch (type) {
    SchedulerType.eightBox => CardScheduleState.eightBox(
      generation: generation,
      learnedAt: learnedAt,
      dueAt: dueAt,
      lastAnsweredAt: lastAnsweredAt,
      answerCount: answerCount,
      lapseCount: lapseCount,
      currentBox: currentBox!,
    ),
    SchedulerType.sm2 => CardScheduleState.sm2(
      generation: generation,
      learnedAt: learnedAt,
      dueAt: dueAt,
      lastAnsweredAt: lastAnsweredAt,
      answerCount: answerCount,
      lapseCount: lapseCount,
      easeFactor: easeFactor!,
      intervalDays: intervalDays!,
      repetitions: repetitions!,
```

- [ ] **Step 4: Create the list query**

Create `lib/features/card/domain/models/card_list_query_model.dart`:

```dart
/// Which cards of a deck the list shows (UC-CARD-001, IT-ORG-005).
enum CardListFilter {
  all,

  /// Learned and due at the list's now (BR-STUDY-047).
  due,

  /// Not learned yet (BR-CARD-007).
  newCards,
  flagged,
}

/// How the list is ordered (IT-ORG-003).
enum CardListSort {
  /// `(created_at DESC, id DESC)`.
  newest,

  /// Soonest `due_at` first, New cards last, then as [newest].
  dueFirst,
}

/// What the person asked the card list for. The list, its counts and Select
/// all read the same query (BR-CARD-012).
final class CardListQuery {
  const CardListQuery({
    this.filter = CardListFilter.all,
    this.sort = CardListSort.newest,
    this.searchTerm = '',
  });

  final CardListFilter filter;
  final CardListSort sort;

  /// As typed: folded before it is matched, and a blank term searches
  /// nothing out.
  final String searchTerm;
}
```

- [ ] **Step 5: Create the list view**

Create `lib/features/card/domain/models/card_list_view_model.dart`:

```dart
import 'package:memox/features/card/domain/models/card_display_status_model.dart';

/// One row of the card list.
final class CardListItem {
  const CardListItem({
    required this.id,
    required this.front,
    required this.back,
    required this.isFlagged,
    required this.dueAt,
    required this.displayStatus,
  });

  final String id;
  final String front;
  final String back;
  final bool isFlagged;

  /// Null for a card not learned yet.
  final DateTime? dueAt;
  final CardDisplayStatus displayStatus;
}

/// How many cards each filter would show under the current search, whatever
/// filter is picked (IT-ORG-005).
final class CardListCounts {
  const CardListCounts({
    required this.all,
    required this.due,
    required this.newCards,
    required this.flagged,
  });

  final int all;
  final int due;
  final int newCards;
  final int flagged;
}

/// The card list as it stands: a window of items and the filter counts.
final class CardListView {
  const CardListView({
    required this.items,
    required this.hasMore,
    required this.counts,
  });

  final List<CardListItem> items;

  /// More cards follow the window; the list asks for a larger one to see
  /// them.
  final bool hasMore;
  final CardListCounts counts;
}
```

- [ ] **Step 6: Add the list reads to the contract**

In `lib/features/card/domain/repositories/card_repository.dart`:

Replace

```dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';
```

with

```dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
```

Replace

```dart
    DateTime? now,
  });
}
```

with

```dart
    DateTime? now,
  });

  /// UC-CARD-001: the first [windowSize] cards of [deckId] that [query] lets
  /// through, whether more follow, and the count of every filter under the
  /// same search (IT-ORG-005). Due is due at [now]. Emits again on every
  /// change of a card or a schedule row.
  Stream<CardListView> watchCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  });

  /// BR-CARD-012: the ids of every card [query] lets through.
  Future<Set<String>> cardIdsMatching({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  });
}
```

- [ ] **Step 7: Map schedule rows through `fromColumns`**

In `lib/features/srs/data/repositories/schedule_repository_impl.dart`:

Replace

```dart
CardScheduleState _stateOf(CardSchedule row) =>
    switch (SchedulerType.fromCode(row.schedulerType)) {
      SchedulerType.eightBox => CardScheduleState.eightBox(
        generation: row.generation,
        learnedAt: row.learnedAt,
        dueAt: row.dueAt,
        lastAnsweredAt: row.lastAnsweredAt,
        answerCount: row.answerCount,
        lapseCount: row.lapseCount,
        currentBox: row.currentBox!,
      ),
      SchedulerType.sm2 => CardScheduleState.sm2(
        generation: row.generation,
        learnedAt: row.learnedAt,
        dueAt: row.dueAt,
        lastAnsweredAt: row.lastAnsweredAt,
        answerCount: row.answerCount,
        lapseCount: row.lapseCount,
        easeFactor: row.easeFactor!,
        intervalDays: row.intervalDays!,
        repetitions: row.repetitions!,
      ),
    };
```

with

```dart
CardScheduleState _stateOf(CardSchedule row) => CardScheduleState.fromColumns(
  type: SchedulerType.fromCode(row.schedulerType),
  generation: row.generation,
  learnedAt: row.learnedAt,
  dueAt: row.dueAt,
  lastAnsweredAt: row.lastAnsweredAt,
  answerCount: row.answerCount,
  lapseCount: row.lapseCount,
  currentBox: row.currentBox,
  easeFactor: row.easeFactor,
  intervalDays: row.intervalDays,
  repetitions: row.repetitions,
);
```

- [ ] **Step 8: Create the card list DAO and its one predicate**

Drift names the table classes after the `.drift` table names: `Card` for `card` (row class `CardRow`) and `CardScheduleTable` for `card_schedule`.

Create `lib/features/card/data/datasources/card_list_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';

/// The card list read model (UC-CARD-001). Every read goes through
/// [_predicate], so the list, its counts and Select all never disagree about
/// which cards a query lets through (BR-CARD-012).
final class CardListDao {
  CardListDao(this._db);

  final AppDatabase _db;

  Card get _card => _db.card;
  CardScheduleTable get _schedule => _db.cardSchedule;

  /// Up to [limit] cards with their schedule rows, in [query]'s order.
  /// Emits again whenever a card or a schedule row changes.
  Stream<List<(CardRow, CardSchedule)>> watchWindow({
    required String deckId,
    required CardListQuery query,
    required int limit,
    required DateTime now,
  }) {
    final select =
        _db.select(_card).join([
            innerJoin(_schedule, _schedule.cardId.equalsExp(_card.id)),
          ])
          ..where(_predicate(deckId: deckId, query: query, now: now))
          ..orderBy(_order(query.sort))
          ..limit(limit);
    return select.watch().map(
      (rows) => [
        for (final row in rows)
          (row.readTable(_card), row.readTable(_schedule)),
      ],
    );
  }

  /// All, Due, New and Flagged under [searchTerm], whatever the filter, in
  /// one statement (IT-ORG-005).
  Future<({int all, int due, int newCards, int flagged})> counts({
    required String deckId,
    required String searchTerm,
    required DateTime now,
  }) async {
    final all = countAll();
    final due = countAll(filter: _passes(CardListFilter.due, now));
    final newCards = countAll(filter: _passes(CardListFilter.newCards, now));
    final flagged = countAll(filter: _passes(CardListFilter.flagged, now));
    final select =
        _db.selectOnly(_card).join([
            innerJoin(_schedule, _schedule.cardId.equalsExp(_card.id)),
          ])
          ..addColumns([all, due, newCards, flagged])
          ..where(_inDeck(deckId, searchTerm));
    final row = await select.getSingle();
    return (
      all: row.read(all)!,
      due: row.read(due)!,
      newCards: row.read(newCards)!,
      flagged: row.read(flagged)!,
    );
  }

  /// BR-CARD-012: every card [query] lets through, not only a window.
  Future<Set<String>> ids({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) async {
    final select =
        _db.selectOnly(_card).join([
            innerJoin(_schedule, _schedule.cardId.equalsExp(_card.id)),
          ])
          ..addColumns([_card.id])
          ..where(_predicate(deckId: deckId, query: query, now: now));
    return {for (final row in await select.get()) row.read(_card.id)!};
  }

  /// The one place that says which cards a query lets through: the active
  /// cards of [deckId], under the search, through the filter. A tag filter
  /// (BR-TAG-004) is one more term here.
  Expression<bool> _predicate({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) => _inDeck(deckId, query.searchTerm) & _passes(query.filter, now);

  /// The search matches the folded term inside a folded side with `instr`,
  /// so `%` and `_` are plain characters and nothing needs escaping.
  Expression<bool> _inDeck(String deckId, String searchTerm) {
    final inDeck = _card.deckId.equals(deckId) & _card.deleteBatchId.isNull();
    final term = foldText(searchTerm);
    if (term.isEmpty) return inDeck;
    return inDeck &
        (_holds(_card.frontFolded, term) | _holds(_card.backFolded, term));
  }

  Expression<bool> _passes(CardListFilter filter, DateTime now) =>
      switch (filter) {
        CardListFilter.all => const Constant(true),
        CardListFilter.due =>
          _schedule.learnedAt.isNotNull() &
              _schedule.dueAt.isSmallerOrEqualValue(now),
        CardListFilter.newCards => _schedule.learnedAt.isNull(),
        CardListFilter.flagged => _card.isFlagged.equals(1),
      };

  List<OrderingTerm> _order(CardListSort sort) => switch (sort) {
    CardListSort.newest => [
      OrderingTerm.desc(_card.createdAt),
      OrderingTerm.desc(_card.id),
    ],
    CardListSort.dueFirst => [
      OrderingTerm.asc(_schedule.learnedAt.isNull()),
      OrderingTerm.asc(_schedule.dueAt),
      OrderingTerm.desc(_card.createdAt),
      OrderingTerm.desc(_card.id),
    ],
  };
}

Expression<bool> _holds(Expression<String> folded, String term) =>
    FunctionCallExpression<int>('instr', [
      folded,
      Variable<String>(term),
    ]).isBiggerThanValue(0);
```

- [ ] **Step 9: Create the card mapper**

Create `lib/features/card/data/mappers/card_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

CardEntity cardEntityOf(CardRow row) => CardEntity(
  id: row.id,
  deckId: row.deckId,
  front: row.front,
  back: row.back,
  isFlagged: row.isFlagged == 1,
  example: row.example,
  hint: row.hint,
  pronunciation: row.pronunciation,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

CardScheduleState scheduleStateOf(CardSchedule row) =>
    CardScheduleState.fromColumns(
      type: SchedulerType.fromCode(row.schedulerType),
      generation: row.generation,
      learnedAt: row.learnedAt,
      dueAt: row.dueAt,
      lastAnsweredAt: row.lastAnsweredAt,
      answerCount: row.answerCount,
      lapseCount: row.lapseCount,
      currentBox: row.currentBox,
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
    );

CardListItem listItemOf(CardRow card, CardSchedule schedule) => CardListItem(
  id: card.id,
  front: card.front,
  back: card.back,
  isFlagged: card.isFlagged == 1,
  dueAt: schedule.dueAt,
  displayStatus: CardDisplayStatus.of(scheduleStateOf(schedule)),
);
```

- [ ] **Step 10: Implement the list reads**

In `lib/features/card/data/repositories/card_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/card/data/datasources/card_dao.dart';
```

with

```dart
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/data/mappers/card_mapper.dart';
```

Replace

```dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';
```

with

```dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
```

Replace

```dart
  }) : _dao = CardDao(_db),
```

with

```dart
  }) : _dao = CardDao(_db),
       _listDao = CardListDao(_db),
```

Replace

```dart
  final CardDao _dao;
```

with

```dart
  final CardDao _dao;
  final CardListDao _listDao;
```

Replace

```dart
      return Ok(_toEntity((await _dao.findRow(id))!));
```

with

```dart
      return Ok(cardEntityOf((await _dao.findRow(id))!));
```

Replace

```dart
  }

  /// The draft passed [CardDraft.check], which holds the tag rules, so a
```

with

```dart
  }

  @override
  Stream<CardListView> watchCardList({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
    required DateTime now,
  }) => _listDao
      .watchWindow(
        deckId: deckId,
        query: query,
        limit: windowSize + 1,
        now: now,
      )
      .asyncMap((rows) async {
        // The window's watch re-runs on every change the counts could see,
        // so reading the counts here keeps one emission per change.
        final counts = await _listDao.counts(
          deckId: deckId,
          searchTerm: query.searchTerm,
          now: now,
        );
        return CardListView(
          items: [
            for (final (card, schedule) in rows.take(windowSize))
              listItemOf(card, schedule),
          ],
          hasMore: rows.length > windowSize,
          counts: CardListCounts(
            all: counts.all,
            due: counts.due,
            newCards: counts.newCards,
            flagged: counts.flagged,
          ),
        );
      })
      .mapDatabaseErrors();

  @override
  Future<Set<String>> cardIdsMatching({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) => _mapped(() => _listDao.ids(deckId: deckId, query: query, now: now));

  /// The draft passed [CardDraft.check], which holds the tag rules, so a
```

Replace

```dart
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
```

with

```dart
  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
```

Delete

```dart

CardEntity _toEntity(CardRow row) => CardEntity(
  id: row.id,
  deckId: row.deckId,
  front: row.front,
  back: row.back,
  isFlagged: row.isFlagged == 1,
  example: row.example,
  hint: row.hint,
  pronunciation: row.pronunciation,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);
```

- [ ] **Step 11: Create `select_all_card_ids_use_case.dart`**

Create `lib/features/card/domain/usecases/select_all_card_ids_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// BR-CARD-012: Select all takes every card the list's query lets through,
/// not only the rows loaded on screen.
final class SelectAllCardIdsUseCase {
  const SelectAllCardIdsUseCase(this._cards, this._clock);

  final CardRepository _cards;
  final DayClock _clock;

  Future<Set<String>> call({
    required String deckId,
    required CardListQuery query,
  }) => _cards.cardIdsMatching(deckId: deckId, query: query, now: _clock.now());
}
```

- [ ] **Step 12: Create `watch_card_list_use_case.dart`**

Create `lib/features/card/domain/usecases/watch_card_list_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001: a window of a deck's cards and the filter counts, again on
/// every change and at every local midnight, when cards fall due with no
/// write (BR-STUDY-068).
final class WatchCardListUseCase {
  const WatchCardListUseCase(this._cards, this._clock);

  final CardRepository _cards;
  final DayClock _clock;

  Stream<CardListView> call({
    required String deckId,
    required CardListQuery query,
    required int windowSize,
  }) => watchEachLocalDay(
    _clock,
    (now) => _cards.watchCardList(
      deckId: deckId,
      query: query,
      windowSize: windowSize,
      now: now,
    ),
  );
}
```

- [ ] **Step 13: Run the task's tests**

```bash
flutter test test/features/srs/domain/card_schedule_state_model_test.dart \
  test/features/card/data/card_list_read_test.dart \
  test/features/card/domain/card_list_use_cases_test.dart
```

Expected: `+14: All tests passed!`

- [ ] **Step 14: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+321: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 15: Commit**

```bash
git add lib/features/card/data/datasources/card_list_dao.dart \
  lib/features/card/data/mappers/card_mapper.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/models/card_list_query_model.dart \
  lib/features/card/domain/models/card_list_view_model.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/card/domain/usecases/select_all_card_ids_use_case.dart \
  lib/features/card/domain/usecases/watch_card_list_use_case.dart \
  lib/features/srs/data/repositories/schedule_repository_impl.dart \
  lib/features/srs/domain/models/card_schedule_state_model.dart \
  test/features/card/data/card_list_read_test.dart \
  test/features/card/domain/card_list_use_cases_test.dart \
  test/features/srs/domain/card_schedule_state_model_test.dart
git commit -m "feat(card): add the card list with filters, search, counts and Select all"
```


### Task 9: Card detail, review history and card move targets

**Files:**
- Create: `lib/core/database/queries/card_queries.drift`, `lib/features/card/domain/models/card_detail_model.dart`, `lib/features/card/domain/models/card_move_target_model.dart`, `lib/features/card/domain/models/review_history_model.dart`, `lib/features/card/data/datasources/card_detail_dao.dart`, `lib/features/card/domain/usecases/load_card_history_page_use_case.dart`, `lib/features/card/domain/usecases/watch_card_detail_use_case.dart`, `lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart`
- Modify: `lib/core/database/app_database.dart`, `lib/features/card/domain/repositories/card_repository.dart`, `lib/features/card/data/mappers/card_mapper.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`, `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`
- Test (create): `test/features/card/data/card_detail_read_test.dart`, `test/features/card/domain/card_read_use_cases_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `DeckPathEntry`, `DeckTreeNode`, `candidatesInTreeOrder` and the row
  class `DeckForestRow` (Task 6); `card_mapper.dart`, `scheduleStateOf`,
  `CardDisplayStatus` (Tasks 2 and 8); srs `ReviewKind`, `EightBoxAction`,
  `Sm2Action`, `SchedulerType` (foundation).
- Produces:
  - `CardDetail({card, tags, schedulerType, schedule})` with `displayStatus`;
    `ReviewHistoryEntry` (the stored values of one `review_log` row),
    `ReviewHistoryCursor({answeredAt, id})`,
    `ReviewHistoryPage({entries, next})` with `static const size = 50`;
    `CardMoveTarget({id, name, path})`.
  - `CardRepository.watchDetail(String cardId)` → `Stream<CardDetail?>`;
    `historyPage({required String cardId, ReviewHistoryCursor? after})` →
    `Future<ReviewHistoryPage?>`; `watchMoveTargets(String sourceDeckId)` →
    `Stream<List<CardMoveTarget>>`.
  - `lib/core/database/queries/card_queries.drift` with `cardDetail`,
    `cardHistoryPage` (row class `CardHistoryRow`) and `cardMoveTargets`
    (`DeckForestRow`).
  - `WatchCardDetailUseCase({cardId})` →
    `Stream<Outcome<CardDetail, CardRejection>>`,
    `LoadCardHistoryPageUseCase({cardId, cursor})` →
    `Future<Outcome<ReviewHistoryPage, CardRejection>>`,
    `WatchCardMoveTargetsUseCase({sourceDeckId})`.

Spec §8 "Card detail", "Review history" and "Card move targets"; BR-CARD-013…019.
The detail query lists the tags with drift's `LIST(...)`, so the watch follows
the card, its schedule row and its tags. A history page is one keyset
statement on `(answered_at DESC, id DESC)`, never `OFFSET`: an answer written
while the person pages neither repeats a row nor hides one. Nothing here
writes (BR-CARD-013).

- [ ] **Step 1: Write the failing tests**

Create `test/features/card/data/card_detail_read_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late SelectCounter counter;
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late TagRepositoryImpl tags;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
    DateTime now() => DateTime(2026, 9, 23);
    decks = DeckRepositoryImpl(db, now: now);
    tags = TagRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      tags,
      now: now,
    );
    root = await decks.root('Korean');
    leaf = await decks.sub(root.id, 'Nouns');
  });
  tearDown(() => db.close());

  /// A review_log row as the study flow writes it; [at] orders the history.
  Future<void> logAnswer(
    String cardId,
    String id,
    DateTime at, {
    int generation = 1,
  }) => db.customStatement(
    'INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, '
    'kind, mode, "action", answered_at, next_due_at, previous_box, next_box) '
    "VALUES (?, ?, 's', 'eight_box', ?, 'scheduled', 'recall', 'remembered', ?, ?, 2, 3)",
    [
      id,
      cardId,
      generation,
      at.millisecondsSinceEpoch ~/ 1000,
      at.millisecondsSinceEpoch ~/ 1000 + 86400,
    ],
  );

  group('watchDetail (BR-CARD-014)', () {
    test(
      'gives the content, the flag, the tags by folded name and the schedule',
      () async {
        final card = await cards.card(
          leaf.id,
          const CardDraft(
            front: '사과',
            back: 'apple',
            example: 'An apple a day',
            isFlagged: true,
            tagNames: ['fruit', 'Apple'],
          ),
        );

        final detail = (await cards.watchDetail(card.id).first)!;

        expect(
          (detail.card.front, detail.card.example, detail.card.isFlagged),
          ('사과', 'An apple a day', true),
        );
        expect([for (final tag in detail.tags) tag.name], ['Apple', 'fruit']);
        expect(
          (
            detail.schedulerType,
            detail.schedule.currentBox,
            detail.displayStatus,
          ),
          (SchedulerType.eightBox, 1, CardDisplayStatus.newCard),
        );
      },
    );

    test(
      'emits again when a tag, the schedule row or the content changes',
      () async {
        final card = await cards.card(leaf.id);
        final details = <CardDetail?>[];
        final subscription = cards.watchDetail(card.id).listen(details.add);
        await pumpEventQueue();

        await tags.attachByName(cardIds: {card.id}, name: 'verb');
        await pumpEventQueue();
        await db.customUpdate(
          'UPDATE card_schedule SET learned_at = 1, due_at = 2, current_box = 5 WHERE card_id = ?',
          variables: [Variable(card.id)],
          updates: {db.cardSchedule},
        );
        await pumpEventQueue();
        await cards.editCard(
          cardId: card.id,
          draft: const CardDraft(
            front: 'new',
            back: 'back',
            tagNames: ['verb'],
          ),
        );
        await pumpEventQueue();

        expect(
          [for (final detail in details) detail!.tags.length],
          [0, 1, 1, 1],
        );
        expect(details[2]!.displayStatus, CardDisplayStatus.reviewing);
        expect(details.last!.card.front, 'new');
        await subscription.cancel();
      },
    );

    test('emits null once the card is deleted, and a card in the Trash is not shown (BR-CARD-019)', () async {
      final card = await cards.card(leaf.id);
      final trashed = await cards.card(leaf.id);
      await db.customStatement(
        "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
        [trashed.id],
      );
      final details = <CardDetail?>[];
      final subscription = cards.watchDetail(card.id).listen(details.add);
      await pumpEventQueue();

      await cards.deleteCards(cardIds: {card.id});
      await pumpEventQueue();

      expect((details.first != null, details.last), (true, null));
      expect(await cards.watchDetail(trashed.id).first, isNull);
      await subscription.cancel();
    });
  });

  group('historyPage (BR-CARD-015..018)', () {
    test('pages of 50, newest first, each in one statement', () async {
      final card = await cards.card(leaf.id);
      final start = DateTime(2026, 1, 1);
      for (var i = 0; i < 120; i++) {
        await logAnswer(
          card.id,
          'log-${i.toString().padLeft(3, '0')}',
          start.add(Duration(hours: i)),
        );
      }

      counter.selects = 0;
      final first = (await cards.historyPage(cardId: card.id))!;
      expect(counter.selects, 1);
      final second = (await cards.historyPage(
        cardId: card.id,
        after: first.next,
      ))!;
      final third = (await cards.historyPage(
        cardId: card.id,
        after: second.next,
      ))!;

      expect(
        (first.entries.length, second.entries.length, third.entries.length),
        (50, 50, 20),
      );
      expect(
        (first.entries.first.id, third.entries.last.id),
        ('log-119', 'log-000'),
      );
      expect(third.next, isNull);
    });

    test(
      'an answer logged while paging neither repeats a row nor skips one',
      () async {
        final card = await cards.card(leaf.id);
        final start = DateTime(2026, 1, 1);
        for (var i = 0; i < 60; i++) {
          await logAnswer(
            card.id,
            'log-${i.toString().padLeft(3, '0')}',
            start.add(Duration(hours: i)),
          );
        }

        final first = (await cards.historyPage(cardId: card.id))!;
        await logAnswer(card.id, 'log-new', DateTime(2026, 6, 1));
        final second = (await cards.historyPage(
          cardId: card.id,
          after: first.next,
        ))!;

        final seen = [
          for (final entry in [...first.entries, ...second.entries]) entry.id,
        ];
        expect(seen.toSet().length, 60);
        expect(seen, isNot(contains('log-new')));
      },
    );

    test('answers in the same second cross a page boundary without a repeat or a gap', () async {
      final card = await cards.card(leaf.id);
      for (var i = 0; i < 55; i++) {
        final id = 'log-${i.toString().padLeft(3, '0')}';
        await logAnswer(card.id, id, DateTime(2026, 1, 1, 12));
      }

      final first = (await cards.historyPage(cardId: card.id))!;
      final second = (await cards.historyPage(
        cardId: card.id,
        after: first.next,
      ))!;

      final ids = [
        for (final entry in [...first.entries, ...second.entries]) entry.id,
      ];
      expect(
        (ids.length, ids.toSet().length, ids.first, second.next),
        (55, 55, 'log-054', null),
      );
    });

    test('an entry carries the stored values of its row (BR-CARD-016, BR-CARD-017)', () async {
      final card = await cards.card(leaf.id);
      await logAnswer(card.id, 'old', DateTime(2026, 1, 1), generation: 1);
      await logAnswer(card.id, 'recent', DateTime(2026, 2, 1), generation: 2);

      final page = (await cards.historyPage(cardId: card.id))!;

      final [recent, old] = page.entries;
      expect((recent.generation, old.generation), (2, 1));
      expect(
        (recent.kind, recent.mode, recent.action),
        (ReviewKind.scheduled, 'recall', EightBoxAction.remembered),
      );
      expect(
        (recent.previousBox, recent.nextBox, recent.previousEaseFactor),
        (2, 3, null),
      );
      expect(
        (recent.answeredAt, recent.nextDueAt),
        (DateTime(2026, 2, 1), DateTime(2026, 2, 2)),
      );
      expect((recent.isTimedOut, recent.usedHint), (false, null));
    });

    test(
      'a card with no answer has an empty page; a missing card has none',
      () async {
        final card = await cards.card(leaf.id);

        final page = (await cards.historyPage(cardId: card.id))!;

        expect(page.entries, isEmpty);
        expect(page.next, isNull);
        expect(await cards.historyPage(cardId: 'missing'), isNull);
      },
    );

    test(
      'reading the detail and the history writes nothing (BR-CARD-013)',
      () async {
        final card = await cards.card(leaf.id);
        await logAnswer(card.id, 'log', DateTime(2026, 1, 1));
        final before = await totalChanges(db);

        await cards.watchDetail(card.id).first;
        await cards.historyPage(cardId: card.id);

        expect(await totalChanges(db), before);
      },
    );
  });

  test('card move targets are the other card decks of the root, with their paths (BR-CARD-010)', () async {
    final verbs = await decks.sub(root.id, 'Verbs');
    final branch = await decks.sub(root.id, 'Grammar');
    final particles = await decks.sub(branch.id, 'Particles');
    await cards.card(particles.id);
    await cards.card(leaf.id);
    final trashed = await decks.sub(root.id, 'Trashed');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [trashed.id],
    );
    final other = await decks.root('Twin');
    await decks.sub(other.id, 'Twin leaf');

    final targets = await cards.watchMoveTargets(leaf.id).first;

    expect(
      [
        for (final target in targets)
          (
            target.name,
            [for (final step in target.path) step.name].join(' / '),
          ),
      ],
      [('Verbs', 'Korean'), ('Particles', 'Korean / Grammar')],
    );
    expect(targets.first.id, verbs.id);
  });
}
```

Create `test/features/card/domain/card_read_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_move_targets_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    DateTime now() => DateTime(2026, 9, 23);
    decks = DeckRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      TagRepositoryImpl(db, now: now),
      now: now,
    );
    final root = await decks.root('Korean');
    leaf = await decks.sub(root.id, 'Nouns');
  });
  tearDown(() => db.close());

  test('WatchCardDetailUseCase answers notFound once the card is deleted (UC-CARD-002, BR-CARD-019)', () async {
    final card = await cards.card(leaf.id);
    final results = <Outcome<CardDetail, CardRejection>>[];
    final subscription = WatchCardDetailUseCase(cards)(cardId: card.id)
        .listen(results.add);
    await pumpEventQueue();

    await cards.deleteCards(cardIds: {card.id});
    await pumpEventQueue();

    expect(results.first, isA<Ok<CardDetail, CardRejection>>());
    expect(
      (results.last as Rejected<CardDetail, CardRejection>).reason,
      CardRejection.notFound,
    );
    await subscription.cancel();
  });

  test(
    'LoadCardHistoryPageUseCase gives an empty first page, or notFound',
    () async {
      final card = await cards.card(leaf.id);
      final load = LoadCardHistoryPageUseCase(cards);

      final page = await load(cardId: card.id);
      final missing = await load(cardId: 'missing');

      expect(
        (page as Ok<ReviewHistoryPage, CardRejection>).value.entries,
        isEmpty,
      );
      expect(
        (missing as Rejected<ReviewHistoryPage, CardRejection>).reason,
        CardRejection.notFound,
      );
    },
  );

  test(
    'WatchCardMoveTargetsUseCase lists where the cards of a deck may go',
    () async {
      final other = await decks.sub(leaf.parentId!, 'Verbs');

      final targets = await WatchCardMoveTargetsUseCase(cards)(
        sourceDeckId: leaf.id,
      ).first;

      expect([for (final target in targets) target.id], [other.id]);
    },
  );
}
```

- [ ] **Step 2: Run them and watch them fail**

```bash
flutter test test/features/card/data/card_detail_read_test.dart \
  test/features/card/domain/card_read_use_cases_test.dart
```

Expected: FAIL, each file for the reason given:

- `test/features/card/data/card_detail_read_test.dart` — `Error when reading 'lib/features/card/domain/models/card_detail_model.dart': No such file or directory`
- `test/features/card/domain/card_read_use_cases_test.dart` — `Error when reading 'lib/features/card/domain/models/card_detail_model.dart': No such file or directory`

- [ ] **Step 3: Create the card query file**

Create `lib/core/database/queries/card_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/tags.drift';
import '../tables/srs.drift';

-- BR-CARD-014: an active card, its schedule row and its tags in folded-name
-- order. Drift reads the tags with a second statement and watches all four
-- tables, so a tag change emits again. No row when :card_id is not an active
-- card (BR-CARD-019).
cardDetail(:card_id AS TEXT):
SELECT c.**, s.**,
  LIST(SELECT t.* FROM tags t JOIN card_tags ct ON ct.tag_id = t.id
       WHERE ct.card_id = c.id ORDER BY t.name_folded, t.id) AS tags
FROM card c
JOIN card_schedule s ON s.card_id = c.id
WHERE c.id = :card_id AND c.delete_batch_id IS NULL;

-- BR-CARD-015: one page of a card's review log in one statement, newest
-- first by keyset on (answered_at DESC, id DESC), after the row
-- (:after_answered_at, :after_id), or from the newest when they are null.
-- The card is the left side of the join: no row at all means it is not an
-- active card; one row with a null log means it has no answer on this page
-- (BR-CARD-018). :row_limit is the page size plus one, which tells the
-- caller whether another page follows.
cardHistoryPage(:card_id AS TEXT, :after_answered_at AS DATETIME OR NULL,
  :after_id AS TEXT OR NULL, :row_limit AS INTEGER) AS CardHistoryRow:
SELECT c.id AS card_id, r.**
FROM card c
LEFT JOIN review_log r ON r.card_id = c.id
  AND (:after_answered_at IS NULL
    OR r.answered_at < :after_answered_at
    OR (r.answered_at = :after_answered_at AND r.id < :after_id))
WHERE c.id = :card_id AND c.delete_batch_id IS NULL
ORDER BY r.answered_at DESC, r.id DESC
LIMIT :row_limit;

-- BR-CARD-010: the decks the cards of :source_deck_id may move to, and the
-- decks on their paths: every active deck of the source's tree.
-- is_candidate marks a sub-deck that holds cards or nothing, other than the
-- source. No row when the source is not an active deck.
cardMoveTargets(:source_deck_id AS TEXT) AS DeckForestRow:
SELECT d.id, d.name, d.parent_id, d.sibling_position,
  (d.parent_id IS NOT NULL AND d.content_type IN ('unset', 'card')
    AND d.id <> :source_deck_id) AS is_candidate
FROM deck d
JOIN deck source ON source.root_id = d.root_id
WHERE source.id = :source_deck_id AND source.delete_batch_id IS NULL
  AND d.delete_batch_id IS NULL;
```

- [ ] **Step 4: Include the card queries in `AppDatabase`**

In `lib/core/database/app_database.dart`:

Replace

```dart
    'package:memox/core/database/tables/settings.drift',
```

with

```dart
    'package:memox/core/database/tables/settings.drift',
    'package:memox/core/database/queries/card_queries.drift',
```

- [ ] **Step 5: Create `CardDetail`**

Create `lib/features/card/domain/models/card_detail_model.dart`:

```dart
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';

/// A card as its detail screen shows it (BR-CARD-014).
final class CardDetail {
  const CardDetail({
    required this.card,
    required this.tags,
    required this.schedulerType,
    required this.schedule,
  });

  final CardEntity card;

  /// In folded-name order.
  final List<TagEntity> tags;

  /// The scheduler whose fields [schedule] holds; the other scheduler's
  /// fields are not shown (BR-CARD-014).
  final SchedulerType schedulerType;
  final CardScheduleState schedule;

  CardDisplayStatus get displayStatus => CardDisplayStatus.of(schedule);
}
```

- [ ] **Step 6: Create `CardMoveTarget`**

Create `lib/features/card/domain/models/card_move_target_model.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck the cards of a selection may move to (UC-CARD-001 A5, BR-CARD-010).
final class CardMoveTarget {
  const CardMoveTarget({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;

  /// The decks from the root down to this deck's parent, so two decks of the
  /// same name tell apart (BR-DECK-021).
  final List<DeckPathEntry> path;
}
```

- [ ] **Step 7: Create the review history models**

Create `lib/features/card/domain/models/review_history_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// One answer in a card's history with the values its `review_log` row
/// stored (BR-CARD-016): nothing is inferred from before and after.
final class ReviewHistoryEntry {
  const ReviewHistoryEntry({
    required this.id,
    required this.generation,
    required this.schedulerType,
    required this.kind,
    required this.mode,
    required this.action,
    required this.answeredAt,
    required this.isTimedOut,
    required this.usedHint,
    required this.nextDueAt,
    required this.previousBox,
    required this.nextBox,
    required this.previousEaseFactor,
    required this.nextEaseFactor,
    required this.previousIntervalDays,
    required this.nextIntervalDays,
  });

  final String id;

  /// The history groups by it (BR-CARD-017).
  final int generation;

  /// Which before and after values the entry holds.
  final SchedulerType schedulerType;
  final ReviewKind kind;

  /// The study mode code as stored (BR-MODE-008), such as `recall`. The
  /// study feature owns the modes and their labels.
  final String mode;

  /// An `EightBoxAction` or a `Sm2Action`, after [schedulerType].
  final Enum action;
  final DateTime answeredAt;

  /// The answer timed out (BR-STUDY-034).
  final bool isTimedOut;

  /// Set on a `fill` answer only (BR-STUDY-028).
  final bool? usedHint;

  /// Null on a turn that does not move the schedule (BR-STUDY-053).
  final DateTime? nextDueAt;
  final int? previousBox;
  final int? nextBox;
  final double? previousEaseFactor;
  final double? nextEaseFactor;
  final int? previousIntervalDays;
  final int? nextIntervalDays;
}

/// Where the next page starts: the last entry shown (BR-CARD-015).
final class ReviewHistoryCursor {
  const ReviewHistoryCursor({required this.answeredAt, required this.id});

  final DateTime answeredAt;
  final String id;
}

/// One page of a card's history, newest first. An empty page is a valid
/// answer (BR-CARD-018).
final class ReviewHistoryPage {
  const ReviewHistoryPage({required this.entries, required this.next});

  /// At most [size] entries.
  static const size = 50;

  final List<ReviewHistoryEntry> entries;

  /// Null on the last page.
  final ReviewHistoryCursor? next;
}
```

- [ ] **Step 8: Add the detail, history and target reads to the contract**

In `lib/features/card/domain/repositories/card_repository.dart`:

Replace

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
```

with

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
```

Replace

```dart
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
```

with

```dart
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
```

Replace

```dart
    required DateTime now,
  });
}
```

with

```dart
    required DateTime now,
  });

  /// BR-CARD-014: the card with its tags and schedule, again whenever one of
  /// them changes; null once it is gone or in the Trash (BR-CARD-019).
  /// Reading writes nothing (BR-CARD-013).
  Stream<CardDetail?> watchDetail(String cardId);

  /// BR-CARD-015: the page of the card's history after [after], the newest
  /// page when it is null; null when the card is not active.
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  });

  /// BR-CARD-010: where the cards of [sourceDeckId] may move, in tree order.
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId);
}
```

- [ ] **Step 9: Create the card detail DAO**

Create `lib/features/card/data/datasources/card_detail_dao.dart`:

```dart
import 'package:memox/core/database/app_database.dart';

/// The reads of one card (`card_queries.drift`). They write nothing
/// (BR-CARD-013).
final class CardDetailDao {
  CardDetailDao(this._db);

  final AppDatabase _db;

  /// The card, its schedule row and its tags; empty once the card is gone or
  /// in the Trash. Emits again when any of them changes.
  Stream<List<CardDetailResult>> watchDetail(String cardId) =>
      _db.cardDetail(cardId).watch();

  /// Up to [limit] log rows after [afterAnsweredAt], [afterId], newest first,
  /// in one statement. Empty when the card is not active; one row with a
  /// null log when it has no answer there.
  Future<List<CardHistoryRow>> historyRows(
    String cardId, {
    required DateTime? afterAnsweredAt,
    required String? afterId,
    required int limit,
  }) => _db.cardHistoryPage(afterAnsweredAt, afterId, cardId, limit).get();

  /// The decks of the source's tree, candidates marked (BR-CARD-010).
  Stream<List<DeckForestRow>> watchMoveTargetRows(String sourceDeckId) =>
      _db.cardMoveTargets(sourceDeckId).watch();
}
```

- [ ] **Step 10: Map details, history entries and tree nodes**

In `lib/features/card/data/mappers/card_mapper.dart`:

Replace

```dart
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
```

Replace

```dart
  displayStatus: CardDisplayStatus.of(scheduleStateOf(schedule)),
);
```

with

```dart
  displayStatus: CardDisplayStatus.of(scheduleStateOf(schedule)),
);

CardDetail cardDetailOf(CardDetailResult row) => CardDetail(
  card: cardEntityOf(row.c),
  tags: [for (final tag in row.tags) TagEntity(id: tag.id, name: tag.name)],
  schedulerType: SchedulerType.fromCode(row.s.schedulerType),
  schedule: scheduleStateOf(row.s),
);

ReviewHistoryEntry historyEntryOf(ReviewLog row) {
  final type = SchedulerType.fromCode(row.schedulerType);
  return ReviewHistoryEntry(
    id: row.id,
    generation: row.generation,
    schedulerType: type,
    kind: ReviewKind.values.byName(row.kind),
    mode: row.mode,
    action: switch (type) {
      SchedulerType.eightBox => EightBoxAction.values.byName(row.action),
      SchedulerType.sm2 => Sm2Action.values.byName(row.action),
    },
    answeredAt: row.answeredAt,
    isTimedOut: row.outcomeReason != null,
    usedHint: switch (row.usedHint) {
      final int flag => flag == 1,
      null => null,
    },
    nextDueAt: row.nextDueAt,
    previousBox: row.previousBox,
    nextBox: row.nextBox,
    previousEaseFactor: row.previousEaseFactor,
    nextEaseFactor: row.nextEaseFactor,
    previousIntervalDays: row.previousIntervalDays,
    nextIntervalDays: row.nextIntervalDays,
  );
}

DeckTreeNode deckTreeNodeOf(DeckForestRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: row.isCandidate,
);
```

- [ ] **Step 11: Implement the detail, the history page and the targets**

In `lib/features/card/data/repositories/card_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/card/data/datasources/card_dao.dart';
```

with

```dart
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/data/datasources/card_detail_dao.dart';
```

Replace

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
```

with

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
```

Replace

```dart
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
```

with

```dart
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
```

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
```

Replace

```dart
       _listDao = CardListDao(_db),
```

with

```dart
       _listDao = CardListDao(_db),
       _detailDao = CardDetailDao(_db),
```

Replace

```dart
  final CardListDao _listDao;
```

with

```dart
  final CardListDao _listDao;
  final CardDetailDao _detailDao;
```

Replace

```dart
  }) => _mapped(() => _listDao.ids(deckId: deckId, query: query, now: now));

  /// The draft passed [CardDraft.check], which holds the tag rules, so a
```

with

```dart
  }) => _mapped(() => _listDao.ids(deckId: deckId, query: query, now: now));

  @override
  Stream<CardDetail?> watchDetail(String cardId) => _detailDao
      .watchDetail(cardId)
      .map((rows) => rows.isEmpty ? null : cardDetailOf(rows.single))
      .mapDatabaseErrors();

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) => _mapped(() async {
    final rows = await _detailDao.historyRows(
      cardId,
      afterAnsweredAt: after?.answeredAt,
      afterId: after?.id,
      limit: ReviewHistoryPage.size + 1,
    );
    if (rows.isEmpty) return null;
    final logs = [
      for (final row in rows)
        if (row.r case final ReviewLog log) log,
    ];
    final entries = [
      for (final log in logs.take(ReviewHistoryPage.size)) historyEntryOf(log),
    ];
    return ReviewHistoryPage(
      entries: entries,
      next: logs.length > ReviewHistoryPage.size
          ? ReviewHistoryCursor(
              answeredAt: entries.last.answeredAt,
              id: entries.last.id,
            )
          : null,
    );
  });

  @override
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId) =>
      _detailDao
          .watchMoveTargetRows(sourceDeckId)
          .map(
            (rows) => candidatesInTreeOrder(
              [for (final row in rows) deckTreeNodeOf(row)],
              (node, path) =>
                  CardMoveTarget(id: node.id, name: node.name, path: path),
            ),
          )
          .mapDatabaseErrors();

  /// The draft passed [CardDraft.check], which holds the tag rules, so a
```

- [ ] **Step 12: Create `load_card_history_page_use_case.dart`**

Create `lib/features/card/domain/usecases/load_card_history_page_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// BR-CARD-015…018: one page of a card's history after [cursor], the newest
/// page without one; notFound when the card is gone.
final class LoadCardHistoryPageUseCase {
  const LoadCardHistoryPageUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<ReviewHistoryPage, CardRejection>> call({
    required String cardId,
    ReviewHistoryCursor? cursor,
  }) async {
    final page = await _cards.historyPage(cardId: cardId, after: cursor);
    if (page == null) return const Rejected(CardRejection.notFound);
    return Ok(page);
  }
}
```

- [ ] **Step 13: Create `watch_card_detail_use_case.dart`**

Create `lib/features/card/domain/usecases/watch_card_detail_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-002: a card's detail, again on every change, and notFound once
/// the card is gone (BR-CARD-019). It writes nothing (BR-CARD-013).
final class WatchCardDetailUseCase {
  const WatchCardDetailUseCase(this._cards);

  final CardRepository _cards;

  Stream<Outcome<CardDetail, CardRejection>> call({required String cardId}) =>
      _cards
          .watchDetail(cardId)
          .map<Outcome<CardDetail, CardRejection>>(
            (detail) => switch (detail) {
              final CardDetail detail => Ok(detail),
              null => const Rejected(CardRejection.notFound),
            },
          );
}
```

- [ ] **Step 14: Create `watch_card_move_targets_use_case.dart`**

Create `lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart`:

```dart
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A5: the decks the Move picker offers, each with its path.
final class WatchCardMoveTargetsUseCase {
  const WatchCardMoveTargetsUseCase(this._cards);

  final CardRepository _cards;

  Stream<List<CardMoveTarget>> call({required String sourceDeckId}) =>
      _cards.watchMoveTargets(sourceDeckId);
}
```

- [ ] **Step 15: Name the owner of the card queries**

In `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`:

Replace

```json
  "database_query_features": {
```

with

```json
  "database_query_features": {
    "card_queries": ["card"],
```

- [ ] **Step 16: Regenerate the docs index and check the docs**

`docs/_generated/traceability.md` lists, for each use case, the tests
that name its id, and `docs/README.md` wants docs and code in the same commit;
this task's tests name use case ids.

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `OK docs/_generated: generated 3 files`, then `PASS — 0 error(s), 81 warning(s)`.

- [ ] **Step 17: Generate the Drift and Riverpod code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: ends with `Built with build_runner`, and no `drift_dev` warning.

- [ ] **Step 18: Run the task's tests**

```bash
flutter test test/features/card/data/card_detail_read_test.dart \
  test/features/card/domain/card_read_use_cases_test.dart
```

Expected: `+13: All tests passed!`

- [ ] **Step 19: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+334: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 20: Commit**

```bash
git add .claude/skills/flutter-workflow/scripts/verification_impact_map.json \
  docs/_generated \
  lib/core/database/app_database.dart \
  lib/core/database/queries/card_queries.drift \
  lib/features/card/data/datasources/card_detail_dao.dart \
  lib/features/card/data/mappers/card_mapper.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/models/card_detail_model.dart \
  lib/features/card/domain/models/card_move_target_model.dart \
  lib/features/card/domain/models/review_history_model.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/card/domain/usecases/load_card_history_page_use_case.dart \
  lib/features/card/domain/usecases/watch_card_detail_use_case.dart \
  lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart \
  test/features/card/data/card_detail_read_test.dart \
  test/features/card/domain/card_read_use_cases_test.dart
git commit -m "feat(card): add the card detail, the keyset review history and card move targets"
```


### Task 10: Point the feature docs at the code

**Files:**
- Modify: `docs/features/card/README.md`, `docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md`, `docs/features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md`, `docs/features/deck/README.md`, `docs/features/deck/usecases/UC-DECK-001-tao-root-deck.md`, `docs/features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md`, `docs/features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md`, `docs/features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md`, `docs/features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md`, `docs/features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md`, `docs/features/tags/README.md`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: every use case file of Tasks 4–9, and the `deck`, `card` and `tags`
  backend folders.
- Produces: the `code:` field of UC-DECK-001…006, UC-CARD-001…002 and of the
  deck, card and tags READMEs; the READMEs lose the note that the repository has
  no `lib/`; `docs/_generated/` regenerated.

Spec §11 "Docs". A `code:` list is one line (`tools/docs/generate.py` reads only
inline lists) of paths that exist. The UI session adds its presentation paths
later.

- [ ] **Step 1: Fill `code:` in `docs/features/card/README.md`**

In `docs/features/card/README.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/card/domain, lib/features/card/data, lib/features/card/di, lib/core/database/queries/card_queries.drift]
```

Delete

```markdown

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.
```

- [ ] **Step 2: Fill `code:` in `docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md`**

In `docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart, lib/features/card/domain/usecases/edit_card_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/move_cards_use_case.dart, lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart, lib/features/card/domain/usecases/set_cards_flagged_use_case.dart, lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart, lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart]
```

- [ ] **Step 3: Fill `code:` in `docs/features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md`**

In `docs/features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/card/domain/usecases/watch_card_detail_use_case.dart, lib/features/card/domain/usecases/load_card_history_page_use_case.dart]
```

- [ ] **Step 4: Fill `code:` in `docs/features/deck/README.md`**

In `docs/features/deck/README.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/deck/domain, lib/features/deck/data, lib/features/deck/di, lib/core/database/queries/deck_queries.drift]
```

Delete

```markdown

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.
```

- [ ] **Step 5: Fill `code:` in `docs/features/deck/usecases/UC-DECK-001-tao-root-deck.md`**

In `docs/features/deck/usecases/UC-DECK-001-tao-root-deck.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/deck/domain/usecases/create_root_deck_use_case.dart]
```

- [ ] **Step 6: Fill `code:` in `docs/features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md`**

In `docs/features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/deck/domain/usecases/rename_deck_use_case.dart, lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart, lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart]
```

- [ ] **Step 7: Fill `code:` in `docs/features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md`**

In `docs/features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/usecases/search_decks_use_case.dart]
```

- [ ] **Step 8: Fill `code:` in `docs/features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md`**

In `docs/features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/usecases/create_sub_deck_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart]
```

- [ ] **Step 9: Fill `code:` in `docs/features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md`**

In `docs/features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart, lib/features/deck/domain/usecases/move_deck_use_case.dart]
```

- [ ] **Step 10: Fill `code:` in `docs/features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md`**

In `docs/features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart]
```

- [ ] **Step 11: Fill `code:` in `docs/features/tags/README.md`**

In `docs/features/tags/README.md`:

Replace

```markdown
code: []
```

with

```markdown
code: [lib/features/tags/domain, lib/features/tags/data, lib/features/tags/di]
```

Delete

```markdown

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.
```

- [ ] **Step 12: Regenerate the docs index and check the docs**

Filling `code:` removes the eight "ready UC has `code: []`" warnings of
UC-DECK-001…006 and UC-CARD-001…002; the remaining warnings belong to other
features.

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `OK docs/_generated: generated 3 files`, then `PASS — 0 error(s), 73 warning(s)`.

- [ ] **Step 13: Run the phased gate**

Run each of the five commands from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: `No issues found!`; `+334: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 28 | Errors: 0 | Warnings: 0 | Info: 28` (the 28 are the UI's
`targets_pending`, not this plan's).

- [ ] **Step 14: Commit**

```bash
git add docs/_generated \
  docs/features/card/README.md \
  docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md \
  docs/features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md \
  docs/features/deck/README.md \
  docs/features/deck/usecases/UC-DECK-001-tao-root-deck.md \
  docs/features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md \
  docs/features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md \
  docs/features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md \
  docs/features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md \
  docs/features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md \
  docs/features/tags/README.md
git commit -m "docs(deck,card,tags): point the feature docs at the backend code"
```


## Plan self-review

- **Spec coverage.** §5 structure: Tasks 1–9 create every listed file;
  `core/text` is Clarification 7. §6 use cases: deck — Task 4 (eight writes),
  Task 5 (`WatchDeckLevel`), Task 6 (`WatchDeck`, `WatchDeckMoveTargets`,
  `SearchDecks`); card — Task 7 (seven writes), Task 8 (`WatchCardList`,
  `SelectAllCardIds`), Task 9 (`WatchCardDetail`, `LoadCardHistoryPage`,
  `WatchCardMoveTargets`). §7 rules and models: Tasks 1, 2, 4 and 6. §8 read
  models: Tasks 4 (deletion summary), 5, 6, 8 and 9. §9 writes: Tasks 3, 4 and
  7. §10 day clock: Tasks 2, 5 and 8. §11 verification: every task's gate, the
  statement counts in Tasks 5, 8 and 9, docs in Task 10.
- **Placeholders.** None: every step carries its code or its command and
  expected output, and every code block ran in the prototype.
- **Type consistency.** The Interfaces blocks name each signature once; later
  tasks consume them as produced (checked by compiling each task on top of the
  previous one in the prototype).
- **Review Focus.** Each of the five lines has its test in the owning task.
