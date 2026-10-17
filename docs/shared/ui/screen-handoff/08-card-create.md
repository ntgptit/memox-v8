<!-- Hand-written screen record. -->

# 08 · Card create

Adding a card to an open `card` deck: `CardEditorScreen.create` →
`CardEditorFormWidget` in create mode (library phase 4a). UC-CARD-001 steps
2–4, A4 (continuous add); BR-CARD-001, BR-CARD-002, BR-CARD-003.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Close (✕); title "New card". No Save here: the single Save is the footer's "Save card" (critique 2026-09-30 part 3a records it). |
| Deck path | `DeckContextHeaderWidget` (`MxBreadcrumb`), injected by `app/` (ruling P4a-L7) | Library › ancestors › deck › "New card": the deck is named once (critique 2026-09-30). Not a picker: the card belongs to the deck it was opened from. |
| Deck-rejects banner | `MxInlineBanner` (warning) | "This deck no longer accepts cards." / "It now holds sub-decks."; shown only once the target deck can no longer hold a card. |
| Front | `CardFieldWidget` (`MxTextField`, `MxTextFieldVariant.term`) | Label "Front · Term" above the box with "Required" beside it, live "{count} / 60" at the trailing end of the row under the box; inline error once the field is touched (ruling P4a-L2). |
| Back | `CardFieldWidget` (`MxTextFieldVariant.detail`) | Label "Back · Meaning" with "Required", "{count} / 240" under the box; inline error once touched. |
| Optional details | `CardAddDetailsWidget` disclosure → `CardOptionalFieldsWidget` (3 × `CardFieldWidget`, `MxTextFieldVariant.detail`) | "Add details · example · hint · pronunciation"; opens example, hint, pronunciation, each "· optional", "{count} / 240". |
| Tags | `CardTagEditorWidget` (`CardRemovableTagChipWidget` × n, `MxButton` "Add tag", `MxFieldMessage`) | "Tags · optional · {n} / 10"; removable chips, an inline add input with an "Add" button beside it (enabled while the field holds text; Done adds too). At 10 tags, Add tag is withdrawn and a warning message shows (BR-TAG-002). |
| Footer | `CardEditorFooterWidget` (`MxFooterBar`, `MxActionPair` 1 : 1) | Caption line; Cancel (`MxButton` outline) + a primary "Save card" / "Retry save", sharing the row equally (DEV-169); a danger `MxInlineBanner` after a failed save. |
| Discard dialog | `showCardDiscardDialog` (`showMxConfirm`) | "Discard this card?" / "What you typed is not saved."; Keep editing / Discard. Guards leaving a dirty new-card form (ruling P4a-L5). |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | "This deck is no longer here" / "It was moved to Trash or deleted while you were adding cards. This card was not saved."; Back to deck + Open Trash (FE-B1 D11). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| emptyForm | `card_editor_create_light.png` | `card_editor_create_dark.png` | Blank fields, Save disabled, caption "Front and back are required to save." |
| valid | no golden | no golden | Front and back filled: Save is enabled, caption "You can keep adding cards after saving." `card_editor_screen_test.dart::Save waits for a front and a back`. |
| details | no golden | no golden | The opened example, hint and pronunciation are live `MxTextField`s. |
| validationErr | `card_editor_errors_light.png` | `card_editor_errors_dark.png` | The message shows only once the back field has been touched (ruling P4a-L2). |
| frontTooLong | no golden | no golden | Shown once the front field is touched. |
| tagLimit | no golden | no golden | At 10 tags Add tag is withdrawn and "A card can carry 10 tags. Remove one to add another." shows (BR-TAG-002). Code read: `card_tag_editor_widget.dart`. |
| deckRejects | no golden | no golden | Caption "This deck can't take cards now." and banner "It now holds sub-decks."; no path exists here to choose another deck (see Rulings). |
| saving | no golden | no golden | The button shows only its spinner in place of the label — no "Saving…" text inside the button (see Rulings). Cancel, ✕ and system Back are held, and every field is read-only, until the write answers: it lands either way, so a discard question would say something untrue and nothing typed meanwhile can be lost to the form clearing for the next card. |
| saveFailed | no golden | no golden | A write failure keeps the form and everything typed; the footer shows the danger banner "Couldn't save card." · "Nothing was lost. Tap Retry save to try again." (the body names the button as it reads) and the button reads "Retry save". `card_editor_screen_test.dart::a failed save keeps the form and offers Retry save (RF4)`. |
| saved | no golden | no golden | A valid save writes the card, clears every field and the tags, returns the focus to Front and shows the toast "Card added"; the screen stays open for the next card (UC-CARD-001 A4). `card_editor_screen_test.dart::Save adds the card, clears the form and refocuses (RF1)`. |
| pendingTag | no golden | no golden | A tag typed but not added is part of the card: Save adds it first (a refused tag stops the save, takes the focus and shows its error), and leaving asks first. `card_tag_input_test.dart::create: Save adds the pending tag, and the next card starts with none and an empty field (Review Focus 2)`, `::create: a refused tag stops Save and takes the focus, so its error is in view (final review)`. |
| discardNew | no golden | no golden | Back, Close or Cancel on a changed form: "Discard this card?" · "What you typed is not saved." · Keep editing / Discard; an unchanged form closes at once. `card_editor_screen_test.dart::Back on a changed form asks; Keep editing keeps it (RF2)`, `card_editor_blocks_test.dart::the discard dialog answers Discard or Keep editing`. |
| deckGone | no golden | no golden | Save finds the deck gone: `CardGoneWidget` "This deck is no longer here" (nothing was saved), Back to deck + Open Trash; no footer. Reached on a save, not while typing. Code read: `card_editor_form_widget.dart` (`_afterSave`). |
Other goldens: `card_editor_create_keyboard_light.png` / `card_editor_create_keyboard_dark.png` (the form with the keyboard open).

Two further states, both built as
extensions of ruling P4a-L1…L5 (§9 row 79, "gone state" + discard confirm) from
the edit form to create: a deck-gone state (`CardGoneWidget`, above) when the
target deck disappears mid-add, and a discard-changes confirm ("Discard this
card?") when leaving a dirty new-card form without saving.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| emptyForm | type a front and a back | valid | VERIFIED `card_editor_screen_test.dart::Save waits for a front and a back` |
| emptyForm / valid | type past a limit, or blank a touched side | validationErr / frontTooLong; Save off | VERIFIED `::errors show as the person types (ruling P4a-L2)` |
| valid | Add details | details | VERIFIED `::Add details opens the optional fields` |
| valid | Add tag, up to 10 | tagLimit at 10 | `UNVERIFIED (code read)` for the limit; adding is VERIFIED `card_tag_input_test.dart::Add adds the typed tag and keeps the field open` |
| valid | Save | saving, then saved (the form stays open and empty) | VERIFIED `card_editor_screen_test.dart::Save adds the card, clears the form and refocuses (RF1)` |
| saving | Cancel, ✕ or system Back in the same instant | ignored (`_close` returns while `_isSaving`; `PopScope` does not ask); the save lands and the toast "Card added" shows; no discard dialog | VERIFIED `card_editor_save_test.dart::create: Cancel, close and Back are held while the card saves; the save lands and says so, with no discard dialog` (Cancel is driven; ✕ and Back share `_close` and the `PopScope`: `UNVERIFIED (code read)`) |
| saving | the fields while the write runs | read-only (`isReadOnly: _isSaving`) | `UNVERIFIED (code read)`: `card_editor_form_widget.dart`, `card_field_widget.dart`, `card_optional_fields_widget.dart` |
| saving | a second tap on Save | one card | VERIFIED `::a double tap on Save adds one card` |
| saving | the write fails | saveFailed, the typed content kept | VERIFIED `::a failed save keeps the form and offers Retry save (RF4)` |
| saveFailed | Retry save | saving, then saved | `UNVERIFIED (code read)`: `card_editor_form_widget.dart` (`_save` clears `_hasFailed`) |
| saving | the deck now holds sub-decks | deckRejects: warning banner, Save off, nothing written | VERIFIED `::a deck that now holds decks refuses with a warning banner` |
| saving | the deck is gone | deckGone | `UNVERIFIED (code read)`: `card_editor_form_widget.dart` (`_afterSave`); the edit-side twin is VERIFIED `::a card deleted while editing shows it is gone (RF3)` |
| saving | another refusal | the form stays, a toast gives the reason | `UNVERIFIED (code read)`: `_afterSave` |
| saving | the screen is left before the write ends | no state is set | `UNVERIFIED (code read)`: `_save` returns on `!mounted` |
| any dirty state | Back, Close, Cancel | discardNew; Keep editing returns, Discard closes | VERIFIED `::Back on a changed form asks; Keep editing keeps it (RF2)`, `::a tag typed but not added still asks before leaving` |
| any unchanged state | Back, Close, Cancel | the screen closes at once | `UNVERIFIED (code read)`: `PopScope.canPop` is true while the form is clean |
| any | the keyboard opens | the deck path steps aside and returns after | VERIFIED `card_editor_keyboard_test.dart::the deck path steps aside while typing and comes back after (audit P1)` |
| deckGone | Back to deck / Open Trash | the deck / screen 06 | `UNVERIFIED (code read)`: `CardGoneWidget` callbacks |

## Rulings

- **DEV-169 (owner 2026-10-05):** every card field (term, meaning, example, hint, pronunciation) is the app's form field: muted fill that lightens on focus, r12, 12 padding, 52 floor, the body role. The footer pair shares the row 1 : 1 like every footer pair. **DEV-372 (Material 3):** the field is the outlined M3 field: no fill (the page ground shows through), 16 text inset, 56 floor, the input in `bodyLarge`; the field paints its label above the box (4 clear, `labelMedium`, `onSurfaceVariant`, `error` in error) with the optional field's glyph before it and "Required" or "· optional" after it, and the count "{count} / {limit}" moves from the header to the trailing end of the supporting row under the box (`error` with the field's error); the caret turns `error` in error.
- **§9 row 81 (P4a-L7):** the deck chip is not a picker, so a deck that rejects cards says "This deck can't take cards now." / "It now holds sub-decks." with no "choose another deck".
- **§9 row 101:** "Add details" has a solid edge, 48 tall (touch floor); the edge is the outline, as the fields beside it (DEV-166, was `outlineVariant` at about 1.5:1).
- **§9 row 81 (P4a-L8):** "Add tag" is an outline `MxButton` chip; there is no dashed-border token.
- **§9 row 81:** `DeckContextHeaderWidget` sits outside the scroll as a persistent header.
- **§9 row 46 (plan O2):** while saving, `MxButton` swaps its label for the spinner; the words live only in the caption line.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** field headers are field labels in sentence case (14/600); Required is a caption in `context.accentColor` beside them; Optional details stays a section label.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the tag field has an "Add" button (`cardTagConfirm`) beside it, enabled while the field holds text; Done or Add adds the tag through the same checks (BR-TAG-001, BR-TAG-002); Save first adds the tag still typed, and an invalid one shows its error and saves nothing; "Save and add another" clears the tag field with the rest of the form.
- **Q-C-1 (owner, 2026-10-16):** the Tags meta ("optional · 1 / 10") and Add details' field list wrap only between whole terms (`metaLine`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- App bar and caption: "New card" · "Front and back are required to save." · "Fix the marked field to enable save." · "You can keep adding cards after saving." · "Saving to this device…" · "This deck can't take cards now."
- Fields: "Front · Term" · "Back · Meaning" · "Required" · "{count} / {limit}" · "The term you want to remember" · "The meaning; separate several with commas" · "Add details" · "example · hint · pronunciation" · "Optional details" · "· optional" · "Example sentence" · "Hint" · "Pronunciation" · "A sentence using this term" · "A clue that jogs memory without giving the answer" · "Romanisation or a note on how to say it".
- Errors: "Add the term to remember." · "The term can be at most 60 characters. Move the rest into the meaning or an example." · "Add a meaning so this card can be answered." · "The meaning can be at most 240 characters." · "Keep this to 240 characters."
- Deck rejects: "This deck no longer accepts cards." · "It now holds sub-decks."
- Tags: "Tags" · "optional · {count} / {limit}" · "Add tag" · "Add" · "Remove {tag}" · "A card can carry 10 tags. Remove one to add another."
- Footer: "Cancel" · "Save card" · "Retry save" · "Couldn't save card." · "Nothing was lost. Tap Retry save to try again."
- Discard: "Discard this card?" · "What you typed is not saved." · "Keep editing" · "Discard".
- Gone: "This deck is no longer here" · "It was moved to Trash or deleted while you were adding cards. This card was not saved." · "Back to deck" · "Open Trash".
- Toast: "Card added".
