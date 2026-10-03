<!-- Hand-written screen record. -->

# 08 · Card create

Adding a card to an open `card` deck: `CardEditorScreen.create` →
`CardEditorFormWidget` in create mode (library phase 4a). UC-CARD-001 steps
2–4, A4 (continuous add); BR-CARD-001, BR-CARD-002, BR-CARD-003.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) | Close (✕); title "New card". No Save here: the single Save is the footer's "Save card" (critique 2026-09-30 part 3a records it). |
| Deck path | `DeckContextHeaderWidget` (`MxBreadcrumb`), injected by `app/` (ruling P4a-L7) | Library › ancestors › deck › "New card": the deck is named once (critique 2026-09-30). Not a picker: the card belongs to the deck it was opened from. |
| Deck-rejects banner | `MxInlineBanner` (warning) | "This deck no longer accepts cards." / "It now holds sub-decks. Your text is kept on this phone."; shown only once the target deck can no longer hold a card. The text goes to the draft at once, and leaving asks nothing (SP2a 2.15). |
| Draft banner | `CardDraftBannerWidget` (`MxInlineBanner` neutral) | "Unsaved text from earlier" / "Kept on this phone only, not synced. Restore it or discard it."; Discard (outline) and Restore (secondary), above the fields. Shown only when a draft kept on this device differs from the empty form; a draft equal to it is dropped (SP2a R9, 2.14). The slot eases open and shut (Remove animations: at once); Restore and Discard move focus to the front field and announce "Draft restored" / "Draft discarded" (SP2a audit m1, m2). |
| Front | `CardFieldWidget` (`MxTextField`, `MxTextFieldVariant.term`) | Overline "Front · Term", "Required", live "{count} / 60"; inline error once the field is touched (ruling P4a-L2). |
| Back | `CardFieldWidget` (`MxTextFieldVariant.meaning`) | Overline "Back · Meaning", "Required", "{count} / 240"; inline error once touched. |
| Optional details | `CardAddDetailsWidget` disclosure → `CardOptionalFieldsWidget` (3 × `CardFieldWidget`, `MxTextFieldVariant.detail`) | "Add details · example · hint · pronunciation"; opens example, hint, pronunciation, each "· optional", "{count} / 240". |
| Tags | `CardTagEditorWidget` (`CardRemovableTagChipWidget` × n, `MxButton` "Add tag", `MxFieldMessage`) | "Tags · optional · {n} / 10"; removable chips, an inline add input with an "Add" button beside it (enabled while the field holds text; Done adds too). At 10 tags, Add tag is withdrawn and a warning message shows (BR-TAG-002). |
| Footer | `CardEditorFooterWidget` (`MxFooterBar`) | Caption line; Cancel (`MxButton` outline) + a block primary "Save card" / "Retry save"; a danger `MxInlineBanner` after a failed save. Cancel, the close button and Back are held while a save is in flight (SP2a 2.16). |
| Discard dialog | `CardDiscardDialogWidget` (`MxDialog`, `MxSheetActions`) | "Discard this card?" / "What you typed is not saved."; Keep editing / Discard. Guards leaving a dirty new-card form (ruling P4a-L5). |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | "This deck is no longer here" / "It was moved to Trash or deleted while you were adding cards. This card was not saved; your text is kept on this phone."; Back to deck + Open Trash (FE-B1 D11). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| emptyForm | `card_editor_create_light.png` | `card_editor_create_dark.png` | Blank fields, Save disabled, caption "Front and back are required to save." |
| valid | no golden | no golden | — |
| details | no golden | no golden | The opened example, hint and pronunciation are live `MxTextField`s. |
| draftOffered | `card_editor_draft_light.png` | `card_editor_draft_dark.png` | The neutral banner above Front; Restore fills the form, Discard drops the draft. |
| validationErr | `card_editor_errors_light.png` | `card_editor_errors_dark.png` | The message shows only once the back field has been touched (ruling P4a-L2). |
| frontTooLong | no golden | no golden | Shown once the front field is touched. |
| tagLimit | no golden | no golden | — |
| deckRejects | no golden | no golden | Caption "This deck can't take cards now." and banner "It now holds sub-decks. Your text is kept on this phone."; the draft stays and the next opening on that deck offers it back; no path exists here to choose another deck (see Rulings). |
| saving | no golden | no golden | The button shows only its spinner in place of the label — no "Saving…" text inside the button (see Rulings). |
| saveFailed | no golden | no golden | — |
Other goldens: `card_editor_create_keyboard_light.png` / `card_editor_create_keyboard_dark.png` (the form with the keyboard open).

Two further states, both built as
extensions of ruling P4a-L1…L5 (§9 row 79, "gone state" + discard confirm) from
the edit form to create: a deck-gone state (`CardGoneWidget`, above) when the
target deck disappears mid-add, and a discard-changes confirm ("Discard this
card?") when leaving a dirty new-card form without saving.

## Rulings

- **§9 row 81 (P4a-L7):** the deck chip is not a picker, so a deck that rejects cards says "This deck can't take cards now." / "It now holds sub-decks." with no "choose another deck".
- **§9 row 101:** "Add details" has a solid `outlineVariant` edge, 48 tall (touch floor).
- **§9 row 81 (P4a-L8):** "Add tag" is an outline `MxButton` chip; there is no dashed-border token.
- **§9 row 81:** `DeckContextHeaderWidget` sits outside the scroll as a persistent header.
- **§9 row 46 (plan O2):** while saving, `MxButton` swaps its label for the spinner; the words live only in the caption line.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** field headers are field labels in sentence case (14/600); Required is a caption in primary ink beside them; Optional details stays a section label.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the tag field has an "Add" button (`cardTagConfirm`) beside it, enabled while the field holds text; Done or Add adds the tag through the same checks (BR-TAG-001, BR-TAG-002); Save first adds the tag still typed, and an invalid one shows its error and saves nothing; "Save and add another" clears the tag field with the rest of the form.

- **SP2a R9 (2026-10-03, spec `2026-10-03-ui-hardening-sp2a-design.md` §3.2):** what is typed is kept in `card_draft`, 500 ms after the last change, per `create:<deckId>`. It is device-local: never synced, its text never logged (the DB tracer logs a `card_draft` statement without its arguments), dropped after 30 days. A save, Discard on the discard dialog and an unchanged form clear it; a refused deck keeps it. No autosave runs while a kept draft is on offer.

## Copy

- App bar and caption: "New card" · "Front and back are required to save." · "Fix the marked field to enable save." · "You can keep adding cards after saving." · "Saving to this device…" · "This deck can't take cards now."
- Fields: "Front · Term" · "Back · Meaning" · "Required" · "{count} / {limit}" · "The term you want to remember" · "The meaning; separate several with commas" · "Add details" · "example · hint · pronunciation" · "Optional details" · "· optional" · "Example sentence" · "Hint" · "Pronunciation" · "A sentence using this term" · "A clue that jogs memory without giving the answer" · "Romanisation or a note on how to say it".
- Errors: "Add the term to remember." · "The term can be at most 60 characters. Move the rest into the meaning or an example." · "Add a meaning so this card can be answered." · "The meaning can be at most 240 characters." · "Keep this to 240 characters."
- Deck rejects: "This deck no longer accepts cards." · "It now holds sub-decks. Your text is kept on this phone."
- Draft: "Unsaved text from earlier" · "Kept on this phone only, not synced. Restore it or discard it." · "Restore" · "Discard".
- Tags: "Tags" · "optional · {count} / {limit}" · "Add tag" · "Add" · "Remove {tag}" · "A card can carry 10 tags. Remove one to add another."
- Footer: "Cancel" · "Save card" · "Retry save" · "Couldn't save card." · "Nothing was lost. Tap Save to try again."
- Discard: "Discard this card?" · "What you typed is not saved." · "Keep editing" · "Discard".
- Gone: "This deck is no longer here" · "It was moved to Trash or deleted while you were adding cards. This card was not saved; your text is kept on this phone." · "Back to deck" · "Open Trash".
- Toast: "Card added".
