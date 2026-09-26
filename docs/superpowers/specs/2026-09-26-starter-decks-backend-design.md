# MemoX V8 — Starter decks backend design (package 10)

Status: draft for the owner's review 2026-09-26 · Path: architectural

## 1. Intent

Build BE-B4 of [`docs/wbs_BE.md`](../../wbs_BE.md): the store side of the Starter library,
UC-STARTER-001, with BR-STARTER-001…BR-STARTER-010 and the deck, card and scheduler rules
a copy leans on (BR-DECK-002, BR-DECK-020, BR-CARD-004).

The package writes `domain/`, `data/` and `di/` of a new feature `lib/features/starter_decks/`,
one optional parameter on the deck contract, the template assets and two fixture templates.
Screen 03 of the kit ("Starter decks") belongs to FE-B4 in
[`docs/wbs_FE.md`](../../wbs_FE.md); §9 is its contract.

Success means:

- the library lists every bundled template with what screen 03 shows for it: title,
  languages, card and sub-deck counts, content source, suggested scheduler, and whether it
  is already in the library;
- adding a template copies it, in one transaction, into an ordinary deck tree of the
  person's own, with one fresh schedule row per card under the scheduler they chose;
- adding a template that is already in the library copies nothing unless a second copy is
  confirmed;
- a broken manifest, a broken template, an app update with a new template version, and a
  copy that fails half-way each behave as UC-STARTER-001 says;
- every rule the package owns has a test that fails when it breaks, and the phased gate of
  the root `README.md` passes after every task.

## 2. Context (2026-09-26)

- `master` is at `047fa2c`. Every backend item before BE-B4 is done; Card Transfer (BE-B3,
  FE-B3) merged in #72 and #74.
- **The use case.** UC-STARTER-001 is `ready` with `code: []` and no Given/When/Then
  (an open question in the file). The README and `data.md` of the feature describe
  templates as JSON assets under `assets/templates/`; none exist, and `pubspec.yaml`
  declares only `assets/fonts/OFL.txt`.
- **The rules, in short.** A template is not a deck (BR-STARTER-001) and has a stable
  `template_id` with `version`, `locale`, `title` and `content_source` (BR-STARTER-002).
  Using one creates a copy: a new root, the sub-deck tree, every card and a study state
  per card under the chosen scheduler (BR-STARTER-003), in one transaction
  (BR-STARTER-009). The copy records `source_template_id` and `source_template_version`;
  the template may only suggest a scheduler (BR-STARTER-004). The copy is an ordinary
  deck with no link back (BR-STARTER-005); a new template version never touches it
  (BR-STARTER-006). Copying is idempotent by `(source_template_id,
  source_template_version)` (BR-STARTER-007); a deliberate second copy is allowed after a
  confirmation that says one exists (BR-STARTER-008). The content is a fixture for
  development and test and says so (BR-STARTER-010).
- **What exists.**
  - `deck` already has `source_template_id TEXT NULL` and `source_template_version INTEGER
    NULL` (schema.md); nothing writes them. No schema change is needed.
  - `DeckRepository.createRootDeck(name, schedulerType)` writes a root with `content_type
    = 'deck'`, `root_id = id`, `depth = 1`, `generation = 1`, the scheduler's version, and
    the next top-level `sibling_position`. `createSubDeck(parentId, name)` checks the depth
    (`DeckEntity.maxDepth = 10`) and turns an `unset` parent into a deck of decks.
  - `CardRepository.createCard(deckId, draft)` checks `CardDraft`, writes the card, its
    schedule row (`ScheduleRepository.initializeCard`, BR-CARD-004) and its tags, and turns
    an `unset` deck into a deck of cards — inside its own transaction, which joins an
    outer one.
  - `DeckEntity.checkName` (BR-DECK-020: not blank, at most 200 characters, no
    uniqueness) and `CardDraft.check()` hold the per-field rules.
  - `tableChanges(db, tables)` (`lib/core/database/`) is the shared trigger of a read
    model.
  - The import map (`test/architecture/boundary_rules.dart`) has no `starter_decks`
    entry; a new feature adds its own entry in the commit that creates its folder
    (ADR-011).
  - Roots cannot move (`DeckRejection.rootCannotMove`), so a copy's root stays a root.
  - Cards are created with a second-precision `created_at` and a UUID v4 id, and a
    session serves new cards by `created_at, id`: cards written in the same second keep no
    order. Card Transfer's import has the same property.
- **The kit.** Screen 03 "Starter decks" (`StarterLibraryScreenV3`) has ten states: `list`,
  `choose`, `adding`, `added`, `alreadyPresent`, `secondCopy`, `addFailed`, `loading`,
  `none`, `loadFailed`. A template card shows the title, the two languages, the card and
  sub-deck counts, the source ("Development fixture"), the suggested algorithm, and an
  "In library" badge that turns its action into "Add another copy". Adding asks for the
  algorithm with the suggestion selected; `added` says "Added “{title}” · SM-2 · 60 new
  cards" with an Open action; `alreadyPresent` says "Already in your library — nothing was
  copied"; `secondCopy` asks "Add a second copy?"; `addFailed` says "Nothing was copied —
  try again"; `none` is "No starter decks in this build"; `loadFailed` is "Couldn't load
  starter decks".

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Scope: BE-B4 only, no schema change, no migration. | The two source columns exist (§2). |
| D2 | A new feature `starter_decks` owns the templates and orchestrates the copy: its repository opens one transaction and calls `DeckRepository` and `CardRepository` inside it. Every table is still written by the feature that owns it. The import map gains `'starter_decks': {'deck', 'card', 'srs'}`. | The owner's choice of approach A (2026-09-26). The deck feature cannot own the copy (`card → deck` would become a cycle); a card-feature copy would repeat the deck's creation logic (depth, `root_id`, positions, scheduler version). |
| D3 | `DeckRepository.createRootDeck` gains an optional `sourceTemplate` (`DeckSourceTemplate(templateId, version)`), written on the root only. | BR-STARTER-004. The root is the copy; its sub-decks are part of it. |
| D4 | Templates are JSON assets: `assets/templates/manifest.json` lists the template files; each file is one template (§5). The library reads them once, through an injectable `AssetBundle`. | UC-STARTER-001 step 5; `data.md`. A test bundle replaces the assets. |
| D5 | Ship two small fixtures shaped like the kit's samples: *English → Vietnamese · Everyday* (4 sub-decks × 10 cards, suggests Eight boxes) and *Korean → Romanisation · Hangul basics* (Consonants 14, Vowels 10, suggests SM-2), both with the content source "Development fixture". | The owner's choice (2026-09-26); BR-STARTER-010. |
| D6 | A missing or unreadable manifest is an empty library; an unreadable or invalid template is left out and the others stay. A template is invalid when a field BR-STARTER-002 needs is missing, its `templateId` repeats an earlier template's, the suggested scheduler is unknown, a deck holds both sub-decks and cards or neither, the top level holds cards, the tree is deeper than `DeckEntity.maxDepth`, or a name or card breaks `DeckEntity.checkName` or `CardDraft.check()`. | UC-STARTER-001 E2, E3. A template the library shows can always be copied. |
| D7 | "In library" is a root outside the Trash with the same `(source_template_id, source_template_version)`. A copy in the Trash does not count. | BR-STARTER-007, UC-STARTER-001 A4: a person who deleted the copy gets it back without being told it exists. |
| D8 | `addStarterDeck(templateId, schedulerType, allowSecondCopy)` checks "in library" inside its transaction. When a copy exists and `allowSecondCopy` is false it writes nothing and refuses with `alreadyInLibrary`; when true it writes a second, independent copy. | BR-STARTER-007, BR-STARTER-008; the kit's `alreadyPresent` and `secondCopy`. The check in the transaction makes two quick taps one copy. |
| D9 | The copy's root takes the template's title; a second copy takes it too. Sub-decks are written in template order, depth first; cards in template order. | BR-DECK-020 has no uniqueness rule. `sibling_position` keeps the sub-deck order; card order is not kept (§2, known limit). |
| D10 | A rejection from `DeckRepository` or `CardRepository` inside the copy is a broken invariant, not a reason: it throws, the transaction rolls back, and the caller gets the `Failure` of a failed write. | D6 already refused every template that could be rejected. BR-STARTER-009, UC-STARTER-001 E4. |
| D11 | `StarterRejection` has two reasons: `templateNotFound` (no template in the library with that id) and `alreadyInLibrary`. | The only refusals a person can reach. |
| D12 | The library is a watch: the templates, read once, joined with the copies in the library, read again on every write to `deck`. | "In library" changes when a copy is added, deleted, restored or purged. |
| D13 | `locale` is the language of the template's own text (title and deck names). The library lists every template, in manifest order, whatever the app's language. | BR-STARTER-002 requires the field; with fixtures in one language there is nothing to filter yet. |
| D14 | Restore the BE-C5 row (Unicode NFC of card text and tag names) to `wbs_BE.md`. | The owner's D17 decision of package 9a added it; it was lost when 9a did not merge. |

## 4. Structure

```
lib/features/starter_decks/
├── domain/
│   ├── models/        starter_template_model (template, deck and card nodes),
│   │                  starter_library_entry_model, starter_copy_model
│   ├── repositories/  starter_library_repository
│   ├── failures/      starter_failure (enum StarterRejection)
│   └── usecases/      watch_starter_library_use_case, add_starter_deck_use_case
├── data/
│   ├── datasources/   template_asset_data_source (AssetBundle), starter_dao (copies)
│   ├── mappers/       starter_template_mapper (JSON → model, the D6 checks)
│   └── repositories/  starter_library_repository_impl
└── di/                starter_library_repository_provider
```

Outside the feature: `lib/features/deck/` gains `DeckSourceTemplate`
(`domain/models/deck_source_template_model.dart`) and the optional parameter on
`createRootDeck`; `pubspec.yaml` declares `assets/templates/`; the import map gains the
entry of D2. No presentation layer: FE-B4 adds it, with the use-case providers.

## 5. Templates

### 5.1 Files

```
assets/templates/
├── manifest.json
└── en/
    ├── everyday_en_vi.json
    └── hangul_basics.json
```

`manifest.json`:

```json
{ "templates": ["en/everyday_en_vi.json", "en/hangul_basics.json"] }
```

A template file:

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
    { "name": "Greetings", "cards": [ { "front": "hello", "back": "xin chào" } ] }
  ]
}
```

- `templateId`, `version` (an integer ≥ 1), `locale`, `title`, `contentSource`,
  `frontLanguage`, `backLanguage` and `defaultScheduler` (`eight_box` or `sm2`) are
  required.
- `decks` is the root's sub-decks. A deck has a `name` and either `decks` or `cards`, not
  both, and not an empty list.
- A card has `front` and `back`, and may have `example`, `hint` and `pronunciation`. No
  tags.
- Language fields are BCP 47 tags (`en`, `vi`, `ko`, `ko-Latn`); FE-B4 turns them into
  names.

### 5.2 The fixtures (D5)

| Template | Id | Sub-decks | Cards | Suggests |
|---|---|---|---|---|
| English → Vietnamese · Everyday | `fixture.everyday-en-vi` | Greetings, Food & drink, Travel, Home (10 each) | 40 | Eight boxes |
| Korean → Romanisation · Hangul basics | `fixture.hangul-basics` | Consonants (ㄱ…ㅎ, 14), Vowels (ㅏ…ㅣ, 10) | 24 | SM-2 |

Everyday cards are an English word and its Vietnamese meaning. Hangul cards are a letter
and its Revised Romanization; the consonants carry the letter's name as `hint`
(`기역 (giyeok)`). Both have `frontLanguage`/`backLanguage` `en`/`vi` and `ko`/`ko-Latn`,
`version` 1 and `contentSource` "Development fixture".

### 5.3 Reading

- `TemplateAssetDataSource.load()` reads the manifest, then each listed file, through the
  `AssetBundle` it is given (`rootBundle` in the app). It returns the templates that pass
  D6, in manifest order, and never throws for content: a missing or malformed manifest is
  an empty list, a missing, malformed or invalid file is skipped.
- The repository keeps the loaded templates for its lifetime; an app update ships new
  assets and a new process.

## 6. The library (read)

- `watchLibrary()` → `Stream<List<StarterLibraryEntry>>`: the templates of §5.3, each with
  `cardCount`, `subDeckCount` (every deck of the tree under the root) and `isInLibrary`
  (D7).
- The copies come from one statement per firing of `tableChanges(db, [deck])`: the
  `(source_template_id, source_template_version)` pairs of the rows with
  `source_template_id IS NOT NULL AND delete_batch_id IS NULL`.
- A database error reaches the stream as its `Failure` (the kit's `loadFailed`); an empty
  list is the kit's `none`.

## 7. The copy (write)

`addStarterDeck(templateId, schedulerType, {allowSecondCopy = false})` →
`Outcome<StarterCopy, StarterRejection>`, one transaction:

1. The template with `templateId` from §5.3; none → `templateNotFound`, nothing written.
2. "In library" (D7) for its `(templateId, version)`; a copy and no `allowSecondCopy` →
   `alreadyInLibrary`, nothing written.
3. `DeckRepository.createRootDeck(title, schedulerType, sourceTemplate:
   DeckSourceTemplate(templateId, version))`.
4. Depth first, in template order: `createSubDeck(parentId, name)` for each deck; for a
   deck of cards, `CardRepository.createCard(deckId, CardDraft(...))` for each card, in
   order.
5. Any `Rejected` in 3–4 throws (D10); any database error propagates. Either way the
   transaction rolls back, and the caller gets a `Failure`: the kit's `addFailed`.

`StarterCopy` carries `rootDeckId`, `title`, `schedulerType` and `cardCount`: what the
`added` snackbar and its Open action need.

The result, for every copy: a root with `content_type = 'deck'`, `root_id = id`,
`depth = 1`, `generation = 1`, `first_answered_at = NULL`, the chosen scheduler and the two
source columns; each sub-deck with the root's id as `root_id`, its depth, and
`content_type` `deck` or `card` from its content; each card unlearned, with exactly one
schedule row under the chosen scheduler (UC-STARTER-001 postconditions). Nothing else in
the database changes.

## 8. The rules, where each is held

| Rule | Held by |
|---|---|
| BR-STARTER-001 | Templates are assets; only §7 turns one into rows. |
| BR-STARTER-002 | D6: a template without the fields is not listed. |
| BR-STARTER-003, BR-STARTER-009 | §7: one transaction, rolled back on any failure. |
| BR-STARTER-004 | D3; the scheduler is the caller's argument, the template's is only `suggestedScheduler`. |
| BR-STARTER-005 | The copy is written by `createRootDeck`, `createSubDeck` and `createCard`, like any deck; only the two source columns remember the template. |
| BR-STARTER-006 | Nothing reads or writes a copy because of a template after the copy is written; a new version is a template not yet in the library (D7). |
| BR-STARTER-007, BR-STARTER-008 | D7, D8. The confirmation's words are FE-B4's. |
| BR-STARTER-010 | D5: the content source says "Development fixture"; FE-B4 shows it and the kit's note. |

## 9. Use cases and the contract for the UI (FE-B4)

| Use case | Signature | Kit states |
|---|---|---|
| `WatchStarterLibraryUseCase` | `Stream<List<StarterLibraryEntry>> call()` | `loading` (no value yet), `list`, `none` (empty), `loadFailed` (error) |
| `AddStarterDeckUseCase` | `Future<Outcome<StarterCopy, StarterRejection>> call({required String templateId, required SchedulerType schedulerType, bool allowSecondCopy = false})` | `adding`, `added` (`Ok`), `alreadyPresent` (`alreadyInLibrary`), `addFailed` (a `Failure`) |

- `StarterLibraryEntry`: `templateId`, `version`, `title`, `locale`, `frontLanguage`,
  `backLanguage`, `contentSource`, `suggestedScheduler`, `cardCount`, `subDeckCount`,
  `isInLibrary`.
- `choose` preselects `suggestedScheduler`. "Add another copy" on an entry with
  `isInLibrary` opens `secondCopy`; its confirmation calls with `allowSecondCopy: true`.
  "Add to library" calls without it, so a copy that appeared meanwhile ends in
  `alreadyPresent`.
- Open uses `StarterCopy.rootDeckId`; the snackbar's count is `StarterCopy.cardCount`.
- `templateNotFound` is reachable only through a stale entry; FE-B4 treats it like
  `addFailed`.

## 10. Tests

| Layer | What |
|---|---|
| Mapper | a valid template; each D6 refusal (missing field, unknown scheduler, deck with both or neither, cards at the top level, depth over 10, blank or long deck name, blank or long card side) |
| Data source (fake `AssetBundle`) | manifest order; missing and malformed manifest → empty; a missing, malformed or invalid file skipped while the others load |
| Fixtures | the bundled assets load both templates with 40 and 24 cards, 4 and 2 sub-decks, "Development fixture", and pass D6 |
| Repository (Drift in memory) | the copy's shape (§7) against the schema invariants of `test/support/invariant_queries.dart`; one schedule row per card under each scheduler; the source columns on the root only; sub-deck order; `alreadyInLibrary` writes nothing; `allowSecondCopy` writes a second tree; a copy in the Trash is not in the library, and after a restore it is; a new version of a template in the library is not in the library and copies without confirmation, leaving the old copy unchanged (BR-STARTER-006); a failure half-way (a card rejected, forced by a test template that skips D6) leaves the database as it was; `templateNotFound`; the watch re-emits on add, delete and restore, and a database error reaches it |
| Use cases | pass-through of arguments and results |

## 11. Documents

- UC-STARTER-001: `code`, the scope line (backend BE-B4 done, screen 03 is FE-B4), and
  Given/When/Then for the main flow, A2, A3, A4, E2, E3 and E4 in place of the open
  question.
- Feature README (`code`, scope, the open question on missing code removed) and `data.md`
  (the file layout and JSON of §5, the fixture list).
- `docs/wbs_BE.md`: BE-B4 done with its evidence; the BE-C5 row (D14).
  `docs/wbs_FE.md`: FE-B4's next step points at §9. `docs/_generated` regenerated.

## 12. Out of scope

- Screen 03, the first-launch route and the Study Home CTA (FE-B4; BR-STUDY-077's backend
  side exists since BE-A6).
- Production content, content in other languages, and filtering by `locale`.
- Keeping card order inside a sub-deck (§2).
- Tags in templates.

## 13. Risks and rollback

- **Nested transactions.** The copy relies on the owners' transactions joining the outer
  one, as `createCard` already does with the schedule row. The rollback test of §10 is the
  proof; without it the package does not merge.
- **Fixture content.** Wrong content would be a fixture bug, not data loss; the content is
  small enough to review line by line in the PR.
- **Rollback.** The package adds a feature, assets and an optional parameter. Reverting
  the merge removes them; copies already made stay ordinary decks (BR-STARTER-005).
