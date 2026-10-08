# Library empty state: chrome follows the content (The Content Gate) — design

Status: owner rulings 2026-10-08 (chat), spec awaiting review ·
Path: architectural (one derived screen state, one named rule in `DESIGN.md`, one screen,
copy) ·
Linear: a new epic once this spec is approved; its plan's tasks become the sub-issues.

## 1. Intent

**The problem.** On a first run, or after the last deck goes to the Trash, the Library root
(screen 01) shows its empty state in the body but keeps its whole chrome: the search
trigger "Search decks, cards, tags", and the app bar's Starter decks, Tags and Trash. Two of
those act on content that does not exist (search, Tags), so the person can open a search
over nothing and a tag catalog that says "No tags yet". The FAB, by contrast, already waits
for a first deck. The body and the chrome read the same stream but decide on their own, one
element at a time.

**What this is not.** The deck list itself is already data-driven: skeleton, failure, empty
and list all come from `deckLevelProvider` (`lib/features/deck/presentation/widgets/sections/deck_level_body_widget.dart`).
The empty state component (`MxEmptyState`, 24 call sites) is the shared standard. What is
missing is one screen state the chrome also reads, and a named rule that says which controls
depend on content, so the next screen does not re-derive it by hand.

**Success means:** on the Library root every element (app bar actions, search trigger, FAB,
body) changes in the same frame when the deck count crosses zero in either direction; the
rule is written in `DESIGN.md` and the screens that already follow it are cited; the new
empty-state copy reads as an action; the gate passes and the changed goldens pass the golden
review.

## 2. Owner rulings (2026-10-08)

- **R1 · Approach.** A derived `LibraryRootState` provider read by the chrome and the body,
  plus a named rule in `DESIGN.md` (option A). Not a `hasDecks` flag kept in the widget
  (option B), and not a content gate inside `MxAppShell` (option C: no second caller, and
  each screen names different globals).
- **R2 · Trash stays.** The Trash is the recovery store (BR-TRASH-009, FE-B1 D1): deleting
  the last deck empties the Library and fills the Trash, so its entry never depends on the
  Library's content. It is not gated on the Trash's own content either (no second stream in
  the app bar; the Trash screen says when it is empty).
- **R3 · Absent, not dimmed.** A content-dependent control is absent while there is no
  content, as Trash › Select, Tags › search and the Library's FAB already are. The 0.38 dim
  stays for a control that exists but cannot act right now (a disabled Save).
- **R4 · Copy.** `libraryEmptyBody` becomes action-first: en "Organize your cards into
  decks. Create your own or start with a ready-made collection." · vi "Sắp xếp thẻ thành bộ
  thẻ. Tạo bộ của riêng bạn hoặc bắt đầu với một bộ mẫu có sẵn." The title, the two actions
  and the footnote keep their strings.

## 3. Root cause analysis

1. **One stream, several deciders.** The root level is the stream
   `deckLevelProvider(parentId: null, sort, filter)` → `DeckLevel` (domain,
   `lib/features/deck/domain/models/deck_level_model.dart`). `DeckLevelBodyWidget` turns it
   into skeleton / `MxErrorState` / list / `emptyState`. `DeckLibraryRootWidget`
   (`lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart`) watches
   the same stream but reads it only for the FAB, as a local
   `hasDecks = (value?.deckCount ?? 0) > 0`; the search trigger and the three app bar actions
   are built unconditionally, and only reorder mode swaps them for Done. There is no screen
   state the chrome reads; each element is a separate decision, and three of four were never
   made.
2. **"Empty" has one correct definition, used in one place.** `DeckLevel.tiles` is the
   level after the sort & filter; with "Due only" it can be empty while `deckCount > 0`
   (state rootDueEmpty, "Nothing due right now"). Ruling L4 defines the empty Library as
   `deckCount == 0`, and `DeckLevelListWidget` applies it. The chrome must use that same
   definition, not `tiles.isEmpty`, or the filter would hide the search field.
3. **Lifecycle scope of each control.** Starter decks is a content-creation entry (FE-B4
   D2): global. Tags exist only on cards (tags appear "as you add them when creating or
   editing flashcards"; cards in the Trash do not count, BR-TAG-010), so no deck ⇒ no card ⇒
   no tag: content-dependent. Search covers deck names, card faces and tag names (ADR-009):
   content-dependent. The Trash holds what the Library lost: global (R2). The task statement
   grouped Trash with Tags; the data model says otherwise.
4. **The convention exists, unnamed.** Trash hides "Select" while it has no entry
   (`trash_screen.dart`); Tags hides its search field while the catalog is empty (critique
   2026-09-30 part 3d-2); the Library hides its FAB until a first deck (kit 01); Card list
   hides its FAB while selecting. Four screens apply one rule by hand, and none of them
   wrote it down, so the Library applied it to one of its four content-dependent controls.
5. **No missing "page state standard".** Screens are `AsyncValue` of a domain stream plus
   `MxSkeletonList`, `MxErrorState` and `MxEmptyState`; the Riverpod skill states that empty
   is `data` with an empty list and the decision to render the empty state is presentation's.
   Sealed screen states exist where a screen carries task status (search, settings,
   monitoring, starter add). What is missing is a screen state that the chrome reads, which
   is what §4.2 adds, derived from the stream, not a second source.

## 4. Design

### 4.1 Domain: one definition of empty

`DeckLevel` gains `bool get hasDecks => deckCount > 0;` with the doc "The level holds at
least one deck, whatever the filter shows (ruling L4)". `DeckLevelListWidget` and the new
state read it; the inline `deckCount > 0` in the root widget goes.

### 4.2 Presentation: `LibraryRootState`

`lib/features/deck/presentation/states/library_root_state.dart`:

```dart
/// The Library root as one state for its chrome and its body (screen 01):
/// the search trigger, Tags and the FAB exist only with decks (The Content
/// Gate, DESIGN.md); Starter decks and the Trash always do.
sealed class LibraryRootState {
  const LibraryRootState();
  bool get hasDecks => this is LibraryRootDecks;
}

final class LibraryRootLoading extends LibraryRootState { const LibraryRootLoading(); }
final class LibraryRootFailed extends LibraryRootState { const LibraryRootFailed(); }
final class LibraryRootEmpty extends LibraryRootState { const LibraryRootEmpty(); }
final class LibraryRootDecks extends LibraryRootState {
  const LibraryRootDecks(this.level);
  final DeckLevel level;
}

@riverpod
LibraryRootState libraryRootState(Ref ref) {
  final query = ref.watch(deckLevelQueryProvider(null));
  final level = ref.watch(
    deckLevelProvider(parentId: null, sort: query.sort, filter: query.filter),
  );
  return switch (level) {
    AsyncData(:final value) when value.hasDecks => LibraryRootDecks(value),
    AsyncData() => const LibraryRootEmpty(),
    AsyncError() => const LibraryRootFailed(),
    _ => const LibraryRootLoading(),
  };
}
```

Rules of the mapping:

- A refresh that still has data (`AsyncData` with `isLoading`) stays `Decks` or `Empty`:
  the chrome does not flicker while the stream re-emits (every change, each local midnight).
- A failure maps to `Failed` even when a stale value exists, as the body does
  (`level.when(error:)` shows `MxErrorState`): nothing on the screen pretends to be live.
- The provider is derived: it watches the same family instance the body watches, so one
  stream emission rebuilds both in the same frame. It holds no copy of the data and no
  side effect.

### 4.3 The chrome, per state

| Element | Loading | Failed | Empty | Decks | Reordering |
|---|---|---|---|---|---|
| App bar title "Library" | yes | yes | yes | yes | yes |
| Starter decks (sparkles) | yes | yes | yes | yes | Done replaces the actions |
| Tags | no | no | no | yes | — |
| Trash | yes | yes | yes | yes | — |
| Search trigger | no | no | no | yes | no (as today, 3d-2) |
| FAB "New deck" | no | no | no | yes | no (as today) |
| Body | skeleton | `MxErrorState` + Retry | `MxEmptyState` | strip, header, rows | reorder list |

`DeckLibraryRootWidget` watches `libraryRootStateProvider` and `deckReorderModeProvider(null)`
and builds the app bar, the search trigger and the FAB from that table. It no longer
watches `deckLevelProvider` directly. The body stays `DeckLevelBodyWidget`: it serves the
open deck too, and its own `AsyncValue` switch agrees with the state by construction (same
provider instance, same frame). Loading and failure count as "no content": the search
trigger and Tags appear with the first `Decks`, so a first run never shows a field that a
frame later disappears.

### 4.4 The named rule

`DESIGN.md` › Layout › Named Rules gains:

> **The Content Gate Rule.** A control that acts on a screen's content (search, filter,
> select, tag, the FAB that adds a sibling to a list) exists only once that content exists,
> and is absent, not dimmed, until then; loading and failure count as no content. A control
> that creates the first content or recovers it (Create, Starter decks, Import, the Trash,
> Back) stays in every state. Trash › Select, Tags › search, the Library's FAB, search field
> and Tags follow it; the 0.38 dim is for a control that exists but cannot act right now.

Screens already following the rule are cited, not changed. The UI-base register (§9) gets
one row closing the Library's two gaps with this spec.

### 4.5 Copy and the call to action

- `libraryEmptyBody` (en/vi) per R4; its `@` description names this spec. Title "Start your
  library", "Create deck" (primary, filled) and "Browse starter decks" (secondary) and the
  footnote keep their strings and their order: `MxEmptyState` already ranks them.
- No third action here. Epic DEV-288 ("Import từ Library") adds "Import cards from a file"
  as the empty state's third action and an Import icon on the app bar "when the Library has
  decks"; both agree with the rule (Import creates content; its app bar icon is DEV-288's own
  ruling to wait for decks) and nothing in this spec pre-empts them.

### 4.6 Edge cases

- **Delete the last deck.** The stream emits `deckCount == 0` → `Empty`: the search
  trigger, Tags and the FAB go in the same frame as the body's empty state; the Undo toast
  (FE-B1) and the Trash entry remain the two ways back.
- **Create the first deck** from the empty state's action: the stream emits one deck →
  `Decks`: search, Tags and the FAB appear with the first row.
- **"Due only" with decks but nothing due:** `Decks` (deckCount > 0): the chrome stays;
  the body shows "Nothing due right now" as today (rootDueEmpty).
- **Reorder with one deck, then delete it elsewhere:** reorder mode ends with the level's
  own handling today; this spec adds no new case.
- **Tablet (rail from 600dp):** the same chrome; `app_tablet_landscape_library` has decks and
  does not move.
- **The search screen (04) while the Library empties under it:** out of scope; screen 04
  keeps its idle and no-results states.

### 4.7 Files

- Modify: `lib/features/deck/domain/models/deck_level_model.dart` (`hasDecks`),
  `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart`,
  `lib/features/deck/presentation/widgets/sections/deck_level_list_widget.dart` (use
  `hasDecks`), `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `DESIGN.md`,
  `docs/shared/ui/screen-handoff/01-deck-list.md` (rows App bar, Search, rootEmpty, copy),
  `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9 register row).
- Create: `lib/features/deck/presentation/states/library_root_state.dart` (+ `.g.dart`,
  generated), `test/features/deck/presentation/library_root_state_test.dart`.
- Tests: `test/features/deck/presentation/deck_level_screen_test.dart` (scenarios below),
  goldens `library_empty_*`, `app_library_*` (the empty root loses its search field and
  Tags), through `run_goldens.sh --update` and a golden-compare page.

## 5. Tests

- **Unit, `library_root_state_test.dart`** (a `ProviderContainer` with the level stream
  overridden): loading → `Loading`; a level with one deck → `Decks` carrying it; a level
  with none → `Empty`; a failure → `Failed`; "Due only" with decks and no due tile → `Decks`;
  a stream that goes 1 → 0 → 1 yields `Decks`, `Empty`, `Decks` in order.
- **Widget, `deck_level_screen_test.dart`:**
  - Scenario A, first run: the app bar holds Starter decks and the Trash and not Tags; no
    search trigger; no FAB; the body offers Create deck and Browse starter decks with the
    new copy.
  - Scenario B, the last deck goes to the Trash from its ⋮: the same frame shows the empty
    body, no search trigger, no Tags, no FAB; the Trash action and the Undo toast are
    present.
  - Scenario C, the first deck is created from the empty state's action: the search
    trigger, Tags and the FAB appear with the row.
  - The existing "the root app bar holds Starter decks, Tags and Trash" test is scoped to
    a Library with decks.
- **Goldens:** `library_empty_light/dark`, `app_library_light/dark` regenerated; the
  golden-compare page explains the two absent controls and the copy.
- **Gate:** `dod_check.sh` PASS; `check_architecture.sh` unchanged (the state lives in the
  deck feature's presentation layer and imports nothing new).

## 6. Out of scope

- A dimmed variant of the gated controls (R3).
- Gating any other screen's chrome: the rule cites them; they already comply.
- The Search screen's own states, the Import entry (DEV-288), and the Trash's content.
