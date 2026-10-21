# Deck names: at most 32 characters

**Status:** draft for owner review · **Tier 2** (a BR, a Drift migration, a
Supabase migration and RPC check) · **Owner decisions:** 2026-10-21 (below).

## 1. Goal

A deck name is short enough to read at a glance: **at most 32 visible
characters**, 15–25 recommended, to lower the information density of every
list, title and sheet that shows it. One rule, enforced the same way by Create,
Rename, Import, the starter copy and the server. Nothing else in the product
changes: no colour, no other business rule, no other screen's layout.

## 2. Owner decisions (2026-10-21)

| # | Decision |
|---|---|
| N1 | The limit is 32 **visible characters** (grapheme clusters, as `DeckEntity.checkName` already counts), not code units. 15–25 is a recommendation shown in the dialog, never a rule. |
| N2 | The app counts graphemes; the server, which cannot count them, holds a **ceiling of 128 code points** (NFC). The app checks the same ceiling, so the server never refuses a name the app took and sync never jams. |
| N3 | **Migrate now** (the app is in development): names longer than 32 are cut to 32 by a data migration, so no grandfather rule exists anywhere. This replaces the request's "never truncate existing names". |
| N4 | The dialog counter shows from the 26th character ("26/32"); over 32 the field shows an inline error and Save locks. Typing is never blocked and a paste is never cut. |
| N5 | The six surfaces with no sighted path to a full name (reorder row, import result row, import deck row without a clash, in-session context line, Move/Restore picker rows, reminder notification) are separate sub-issues, not this spec. |

## 3. Impact review (measured 2026-10-21)

- **Rule:** BR-DECK-020 says 200 characters. One validator,
  `DeckEntity.checkName` (`lib/features/deck/domain/entities/deck_entity.dart`),
  serves `createRootDeck`, `createSubDeck`, `renameDeck`
  (`deck_repository_impl.dart`), the import plan (`import_plan_model.dart`) and
  the starter mapper (`starter_template_mapper.dart`). Sync pull applies remote
  rows without it.
- **Drift:** `deck.name TEXT NOT NULL`, no length CHECK; schema version 17.
- **Supabase:** `public.deck.name text not null` with no length check;
  `private.deck_upsert` (latest in `20261011000000_trash_purge_rules.sql`)
  checks shape, not the name.
- **Data:** the server holds 3 live decks, the longest 13 characters; none in
  the Trash. Local data on the owner's phone was not measurable from here,
  hence the migration (N3).
- **Starter fixture:** the title "Korean → Romanisation · Hangul basics" is 37
  characters; at 32 the mapper would drop the template from the Starter Library
  without a word. "English → Vietnamese · Everyday" is 31 and passes.
- **Tests:** with the limit set to 32 in a throwaway tree, 21 tests failed in 9
  files: 3 rule tests (`deck_entity_test.dart`), 12 starter tests (the Hangul
  title), 6 long-name UI tests (`study_home_wrap_test.dart`,
  `study_entry_other_deck_test.dart`, `deck_level_screen_test.dart`,
  `deck_algorithm_screen_test.dart`).
- **UI:** 38 surfaces draw a deck name; none clips without an ellipsis or a
  scroll, none clamps the text scale. The gaps of N5 remain.

## 4. The rule (BR-DECK-020, rewritten)

A deck name MUST be non-blank after trim, at most **32 visible characters**
(grapheme clusters) and at most **128 code points** in its stored form
(trimmed, NFC; `storedText`). 15–25 characters is recommended. The same rule
holds for every name the app writes: create, create a sub-deck, rename, an
import section that makes a deck, a starter copy's root and sub-decks. A name
the app reads from the server is not checked (sync never refuses a pull).

`DeckEntity`:

```dart
/// BR-DECK-020, in characters as a person sees them (grapheme clusters).
static const maxNameLength = 32;

/// BR-DECK-020: the server's ceiling, in code points of the stored form; it
/// counts what Postgres can (owner 2026-10-21, N2).
static const maxNameCodePoints = 128;
```

`checkName` adds `storedText(name).runes.length > maxNameCodePoints` to the
`nameTooLong` refusal. No new rejection: a name over either bound is "too
long".

## 5. Data migration (Drift v17 → v18)

A step in `lib/core/database/migrations/`, raw SQL only, released once, read
page by page in `id` order as `nfc_text_migration.dart` does:

- for each deck whose stored name breaks §4 (more than 32 grapheme clusters,
  or more than 128 code points), write the longest run of whole grapheme
  clusters from its start that keeps both bounds, then trim the end; the
  stored name starts with a non-space, so the result is never blank;
- `updated_at` is stamped with the migration's time, so the server's
  last-write rule takes the new name;
- the existing `deck_sync_update` trigger queues each change for sync;
- the step returns the changes `(id, old, new)`; once the upgrade has run,
  `AppDatabase` logs one line per deck through the app log (ADR-018), so a cut
  name can be recovered by hand.

Trashed decks are cut too (a restore must not bring back an invalid name).

## 6. Server (Supabase migration)

- `private.deck_upsert` raises `VALIDATION_FAILED` when
  `char_length(r->>'name') > 128` (the app sends the stored form), before any
  write; the op comes back `rejected` as every other invalid row.
- `public.deck` gains `constraint deck_name_length check (char_length(name)
  <= 128)`, validated at once (every row is 13 or shorter).
- pgTAP: a 128-code-point name is applied, a 129 one is rejected with the row
  the server holds unchanged; a 32-grapheme emoji name of more than 32 code
  points is applied (N2: the server never refuses what the app took).
- Gate: `npx supabase db start`, `npx supabase test db`, and
  `bash tools/supabase/run_auth_it.sh` (the PR changes `supabase/migrations/`).

## 7. Create and Rename dialogs

`create_root_deck_dialog_widget.dart` and `deck_name_dialog_widget.dart`
(create a sub-deck, rename):

| Name length (visible characters) | Field |
|---|---|
| 0–25 | no counter |
| 26–32 | counter "{n}/32" in the field's `counter` slot (`MxTextField`), muted |
| 33 and more, or over 128 code points | the counter in the error tone, the inline message "Keep the name to 32 characters." under the field, Save disabled |
| blank | as today: the blank reason on submit |

- The rejection is computed as the text changes (as `tag_rename_dialog_widget`
  does), so Save locks before a tap; the repository still checks on write.
- No `maxLength`: typing is never blocked and a paste is kept whole, so the
  user sees what to shorten (UC-DECK-001 E2).
- The counter reuses the shape of the tag dialog's (`tagsLength`, "{length} /
  {max}"): a deck key `deckNameLength` with the same placeholders.
- TalkBack: the counter is read with the field ("26 of 32 characters"); the
  error is announced when it appears.
- Copy:
  - `deckRejectionNameTooLong`: "Keep the name to 32 characters." · "Tên dài tối đa 32 ký tự."
  - `importRowDeckNameTooLong`: "Deck name over 32 characters" · "Tên deck dài quá 32 ký tự"
  - `deckNameLength`: "{length} / {max}" · "{length} / {max}"; spoken "{length} of {max} characters" · "{length} trên {max} ký tự"

## 8. Import

Unchanged mechanism: a section name that fails `checkName` makes its rows
invalid with the deck-name reason (BR-TRANSFER-015); only the number in the
reason changes. After the migration no deck holds a longer name, so importing
into an existing deck of the same name needs no special case.

## 9. Starter fixture

`assets/templates/en/hangul_basics.json`: the title becomes "Korean · Hangul
basics" (22). The template id and version stay; a copy made before keeps its
name, cut by the migration when it is longer than 32.

## 10. Screens and states

Only the two dialogs change. Their states, with screen 01's detail file
(`rootCreate`, the sub-deck create and rename dialogs) updated:

| State | Trigger | Evidence planned |
|---|---|---|
| short | 0–25 characters | widget test: no counter |
| near | 26–32 | widget test, golden at 32 ("32/32") light and dark |
| over | 33+ or 129+ code points | widget test: error text, Save null; golden light and dark |
| blank | empty or spaces, on submit | existing test |
| pasted long | a 40-character paste | widget test: the field holds all 40, Save locked |
| submitting | as today | existing tests |

Impeccable: critique and audit the dialog states above against `DESIGN.md`.

## 11. Tests

- `deck_entity_test.dart`: 32 passes, 33 fails; graphemes, not code units
  (Vietnamese with stacked marks, Korean, a ZWJ emoji); a 32-grapheme name over
  128 code points fails; spaces around do not count.
- Migration test (v17 → v18, `test/drift/`): a 40-character Vietnamese name is
  cut to 32 graphemes and trimmed; a 32 one is untouched; a trashed deck is
  cut; each cut is queued in `sync_outbox` and returned for the log; a large
  library is paged.
- The six long-name UI tests keep their purpose with a 32-character name (it
  still wraps to two lines on 320 and 360 dp, and ellipsizes in one-line
  rows); where a test needs more than two lines it inserts the row raw, as
  data from an older server would arrive.
- Starter tests pass again with the new title.
- Import: a 33-character section name makes its rows invalid with the new copy.
- pgTAP as in §6.

## 12. Out of scope

- The six surfaces of N5 (sub-issues of this epic, each Tier 1).
- Tag names (50, BR-TAG-001), card text, any other limit.
- Colours, the type scale, any other screen's layout.

## 13. Risks

- **A cut name reads badly** ("Korean → Romanisation · Hangul b"). Accepted
  (N3); the log keeps the old name.
- **A device still on an older build** can push a name over 128 code points;
  the server refuses it and the sync notice says so. Over 32 graphemes but
  within 128 it is accepted and shown as data, never refused on pull.
- **Grapheme segmentation differs between Dart versions** for rare scripts;
  the server ceiling is in code points, so a mismatch can only make the app
  stricter, never jam sync.
