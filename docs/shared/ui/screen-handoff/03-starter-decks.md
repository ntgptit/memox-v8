<!-- Hand-written screen record. -->

# 03 · Starter decks

The templates bundled with the build, each copied into the library as a deck of the
person's own under the scheduler they choose. UC-STARTER-001; BR-STARTER-001…010; spec
[2026-09-27-tags-starter-ui-design.md](../../../superpowers/specs/2026-09-27-tags-starter-ui-design.md)
(FE-B4).

## Entry points

- **The Library's app bar:** the sparkles action pushes `/decks/starter`, full screen on
  the root navigator, with no bottom bar (D2, D5).
- **The empty Library:** "Browse starter decks" under "Create deck" (screen 01
  `rootEmpty`).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back and "Starter decks". |
| Note | `MxNote` (flask), dismissible | "These decks are practice fixtures for development and testing, not published course material. Anything you add is yours to edit." (BR-STARTER-010). Shown while the templates load too. |
| A card per template | `MxCard` + `MxIconTile` (sparkles) + `MxBadge` | The title, "In library" once a copy is in the library, the facts "{front} · {back} · {n} cards · {m} sub-decks · {source}", then the add ("Add to library" in primary, or "Add another copy" in secondary, critique 2026-09-30) and "Suggests {algorithm}". The title wraps and the badge follows it; the suggestion drops below the button, whole, when both do not fit (critique P2a). The facts and the actions line up with the title, past the tile. |
| Algorithm sheet | `MxBottomSheet` + `MxOptionRow` ×2 + `MxSheetActions` | "Add “{title}”", "The scheduler locks after the first review. Changing it later resets learning progress.", "REVIEW ALGORITHM · REQUIRED", SM-2 ("grade yourself, intervals adapt") and Eight boxes ("Boxes 1–8 · match, guess, recall, fill"); the suggested one is prefixed "Suggested for this deck ·" and chosen first. Cancel / "Add deck". |

Language names come from a small table of the tags the build ships: English,
Vietnamese, Korean, and "Latin" for a `-Latn` tag; any other tag shows as written (D7). The fixtures' source, "Development fixture", is named in the
person's language too; any other source shows as written.

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| list | `starter_list_light.png` | `starter_list_dark.png` | The badge and the suggestion wrap instead of truncating (UI-base row 135). |
| choose | `starter_choose_light.png` | `starter_choose_dark.png` | — |
| adding | `starter_adding_light.png` | `starter_adding_dark.png` | The options and Cancel lock, the sheet cannot be dismissed (Back, the scrim or a drag; `MxBottomSheet.isHeld`), and "Add deck" spins with no "Adding…" text (D13). A second add is ignored. |
| added | `starter_added_light.png` | `starter_added_dark.png` | The sheet closes; "Added “{title}” · {algorithm} · {n} new cards" with Open, which goes to the new root deck in the Library. |
| alreadyPresent | `starter_already_present_light.png` | `starter_already_present_dark.png` | A copy made meanwhile copies nothing more. |
| secondCopy | `starter_second_copy_light.png` | `starter_second_copy_dark.png` | "Add second copy" opens the algorithm sheet (BR-STARTER-008). |
| addFailed | `starter_add_failed_light.png` | `starter_add_failed_dark.png` | The sheet stays with the choice; the danger banner's lead "Couldn't add the deck." sits above "Nothing was copied — try again."; the button reads "Try again". `templateNotFound` reads the same (spec §6). A throw that is not a `Failure` is reported once (library "starter add") and reads the same, so the sheet never stays held on a spinner (SP2b 2.29). |
| loading | `starter_loading_light.png` | `starter_loading_dark.png` | The note, then skeleton rows (UI-base row 125). |
| none | `starter_none_light.png` | `starter_none_dark.png` | "Create a deck" returns to the Library and opens its create dialog. |
| loadFailed | `starter_load_failed_light.png` | `starter_load_failed_dark.png` | Titled "Couldn't load starter decks", with Retry. |

Goldens: `test/features/starter_decks/presentation/goldens/starter_{list,choose,adding,added,already_present,second_copy,add_failed,loading,none,load_failed}_{light,dark}.png`.

## Rulings

- **Critique P3:** "In library" follows the title and moves to the next line when the title wraps, so nothing overflows at text scale 2.
- **Critique P2a:** "Suggests {algorithm}" drops below the add button, whole, rather than being cut.
- **D13 (FE-A3 C8):** the add button shows the spinner alone, no "Adding…" text.
- **UI-base row 125:** loading shows the note, then generic skeleton rows.
- **Critique 2026-09-30:** "Add to library" is primary; "Add another copy", for a template already in the library, is secondary.
- **Critique 2026-09-30:** the fixture note has a close button ("Hide this note"); once hidden it stays hidden on this device (`dismissed_note`).
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the algorithm sheet labels its choice "Review algorithm" as a field label with a Required caption, not one all-caps line.
- **SP2b 2.29 (spec `2026-10-03-ui-hardening-sp2b-design.md`):** `add()` catches any throw, not only a `Failure`: both clear the busy state and set the failed state ("Try again"), and Back is released.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the algorithm sheet's body is the lock line (`deckSchedulerNote`: "The scheduler locks after the first review. Changing it later resets learning progress."), replacing the counts sentence; the card's facts line keeps the counts.

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
