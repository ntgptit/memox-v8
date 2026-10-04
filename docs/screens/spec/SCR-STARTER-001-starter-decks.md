---
id: SCR-STARTER-001
name: Starter decks
domain: starter-decks
status: ready
route: [/decks/starter]
---

# Starter decks

## Purpose

The templates bundled with the build, each copied into the library as a deck of the person's
own under the review algorithm they choose. Full screen on the root navigator, with no bottom
bar; opened from the sparkles action on the Library's app bar and from "Browse starter decks"
on the empty Library (SCR-DECK-001 `root_empty`).

## Related Use Cases

- UC-STARTER-001

## Layout

- **App bar** — back and "Starter decks" (content density).
- **Fixture note** — a note with a flask icon and a close button ("Hide this note"): "These
  decks are practice fixtures for development and testing, not published course material.
  Anything you add is yours to edit." Shown while the templates load too; once hidden it stays
  hidden on this device.
- **A card per template** — an icon tile (sparkles), the title, an "In library" badge once a
  copy is in the library, the facts "{front} · {back} · {n} cards · {m} sub-decks · {source}",
  then the add button ("Add to library" in primary, or "Add another copy" in secondary) and
  "Suggests {algorithm}". The title wraps and the badge follows it; the suggestion drops below
  the button, whole, when both do not fit. The facts and the actions line up with the title.
- **Language and source names** — from a small table of the tags the build ships: English,
  Vietnamese, Korean, and "Latin" for a `-Latn` tag; any other tag shows as written. The
  fixtures' source, "Development fixture", is named in the person's language; any other source
  shows as written.
- **Second-copy dialog** — "Add a second copy?" before the algorithm sheet, for a template
  already in the library.
- **Algorithm sheet** — a bottom sheet: "Add “{title}”", the lock line "The scheduler locks
  after the first review. Changing it later resets learning progress.", a field label "Review
  algorithm" with a Required caption, two option rows — SM-2 ("grade yourself, intervals
  adapt") and Eight boxes ("Boxes 1–8 · match, guess, recall, fill") — the template's suggested
  one prefixed "Suggested for this deck ·" and chosen first; Cancel / "Add deck".

## States

### `list` · List

The badge and the suggestion wrap instead of truncating.

Golden: light, dark

### `choose` · Algorithm sheet

Golden: light, dark

### `adding` · Adding

The options and Cancel lock, the sheet cannot be dismissed (Back, the scrim or a drag), and
"Add deck" spins with no "Adding…" text. A second add is ignored.

Golden: light, dark

### `added` · Added

The sheet closes; the toast "Added “{title}” · {algorithm} · {n} new cards" with Open.

Golden: light, dark

### `already_present` · Already present

A copy made meanwhile copies nothing more: the snackbar "Already in your library — nothing was
copied".

Golden: light, dark

### `second_copy` · Second copy

The dialog "Add a second copy?"; "Add second copy" opens the algorithm sheet.

Golden: light, dark

### `add_failed` · Add failed

The sheet stays with the choice; a danger banner leads "Couldn't add the deck." above "Nothing
was copied — try again."; the button reads "Try again". `templateNotFound` reads the same.

Golden: light, dark

### `loading` · Loading

The note, then skeleton rows.

Golden: light, dark

### `none` · No starter decks

The build ships no template: "No starter decks in this build" with "Create a deck".

Golden: light, dark

### `load_failed` · Load failed

"Couldn't load starter decks" with Retry.

Golden: light, dark

## Controls

### Template list

- Type: read
- Invokes: FN-STARTER-001

### Hide this note

- Type: icon button
- Purpose: hides the fixture note on this device for good.

### Add to library

- Type: primary button
- Purpose: opens the algorithm sheet (`choose`).

### Add another copy

- Type: secondary button
- Purpose: opens the second-copy dialog (`second_copy`).

### Add second copy (second-copy dialog)

- Type: dialog confirm
- Purpose: opens the algorithm sheet for a second copy. Cancel closes; nothing is copied.

### Algorithm option rows

- Type: option rows
- Enabled when: no add is running.

### Add deck (algorithm sheet)

- Type: primary sheet action
- Enabled when: no add is running; a second press while one runs is ignored.
- Invokes: FN-STARTER-002

#### On success

- `added`.

#### On failure

- `alreadyInLibrary` → `already_present`.
- `templateNotFound` and a database failure → `add_failed`; "Add deck" reads "Try again".

### Cancel (algorithm sheet)

- Type: sheet action
- Enabled when: no add is running.
- Purpose: closes the sheet; nothing is copied.

### Open (added toast)

- Type: toast action

#### On success

- Navigate to: SCR-DECK-001

### Create a deck (`none`)

- Type: button

#### On success

- Navigate to: SCR-DECK-001 (its create dialog opens).

### Retry (`load_failed`)

- Type: button
- Invokes: FN-STARTER-001

## Responsive Behavior

"In library" follows the title and moves to the next line when the title wraps, and "Suggests
{algorithm}" drops below the add button, whole, so nothing overflows or truncates at large
text. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| While an add runs the sheet cannot be dismissed and a second add is ignored. | — |
| The add button shows the spinner alone, never "Adding…". | — |
| A template already in the library asks before a second copy. | — |
| Nothing is inserted into the library until the person adds a template. | — |

## Copy

"Starter decks" · "These decks are practice fixtures for development and testing, not
published course material. Anything you add is yours to edit." · "In library" · "{n}
cards" · "{m} sub-decks" · "Add to library" · "Add another copy" · "Development fixture" · "Suggests {algorithm}"
· "SM-2" · "Eight boxes" · "Add “{title}”" · "The scheduler locks after the first review.
Changing it later resets learning progress." · "Review algorithm · required" · "grade yourself, intervals adapt" · "Boxes
1–8 · match, guess, recall, fill" · "Suggested for this deck · {description}" · "Add
deck" · "Try again" · "Couldn't add the deck." · "Nothing was copied — try again." ·
"Added “{title}” · {algorithm} · {n} new cards" · "Open" · "Already in your library —
nothing was copied" · "Add a second copy?" · "“{title}” is already in your library. A
second copy is a separate deck with its own progress." · "Add second copy" · "No starter
decks in this build" · "This version ships without practice content. Create a deck or
import cards instead." · "Create a deck" · "Couldn't load starter decks" · "Your library
is unaffected. Try again in a moment."

## Rulings

- **Critique P3:** "In library" follows the title and moves to the next line when the title
  wraps, so nothing overflows at text scale 2.
- **Critique P2a:** "Suggests {algorithm}" drops below the add button, whole, rather than being
  cut.
- **D13 (FE-A3 C8):** the add button shows the spinner alone, no "Adding…" text.
- **UI-base row 125:** loading shows the note, then generic skeleton rows.
- **Critique 2026-09-30:** "Add to library" is primary; "Add another copy", for a template
  already in the library, is secondary.
- **Critique 2026-09-30:** the fixture note has a close button ("Hide this note"); once hidden
  it stays hidden on this device (`dismissed_note`).
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):**
  the algorithm sheet labels its choice "Review algorithm" as a field label with a Required
  caption, not one all-caps line.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the
  algorithm sheet's body is the lock line (`deckSchedulerNote`: "The scheduler locks after the
  first review. Changing it later resets learning progress."), replacing the counts sentence;
  the card's facts line keeps the counts.
- **Spec §6:** `templateNotFound` reads as the add failure, never as its own message.
