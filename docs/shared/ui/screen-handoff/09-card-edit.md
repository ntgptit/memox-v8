<!-- Hand-written screen record. -->

# 09 · Card edit

Editing a card's content: `CardEditorScreen.edit` → `_EditLoader` →
`CardEditorFormWidget` in edit mode (library phase 4a/4b). UC-CARD-001 A1;
BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-005 (content changes never
touch the study state or history).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) | Back; title "Edit card"; a flag `MxIconButton` that toggles here, edit only (ruling P4a-L6, §9 row 80); trailing compact `MxButton` "Save". |
| Deck path | `DeckContextHeaderWidget` | Library › ancestors › deck › "Edit". |
| History summary | `CardEditSummaryWidget` (full-bleed `MxCard`, `MxListRow`, `MxIconTile`) | "{status} · {n} answers · {n} lapses · due {date}"; its chevron opens the card detail, which closes the editor underneath it (ruling P4a-L10, §9 row 82). |
| Front / Back | `CardFieldWidget` | Same fields as create, prefilled from the card. |
| Optional details | `CardOptionalFieldsWidget` (always open, "Optional details" overline, no disclosure) | Example, hint, pronunciation prefilled. |
| Tags | `CardTagEditorWidget` | Prefilled tags; same add/remove/limit behaviour as create. |
| More | `CardTrashSectionWidget` (`MxCard`, `MxButton` outline "Move to Trash") | "Move this card to Trash" / "Leaves this deck and can be restored from Trash for 30 days, schedule and history included."; opens the shared delete dialog (FE-B1 D13). |
| Footer | `CardEditorFooterWidget` | Cancel + "Save changes" / "Retry save"; danger banner after a failed save. |
| Move to Trash dialog | `CardDeleteDialogWidget` (`MxDialog`, `MxNote`, `MxSheetActions`) | "Move this card to Trash?", a front/back preview card, "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected."; the confirm spins while it moves (FE-B1 D15). |
| Discard dialog | `CardDiscardDialogWidget` | "Discard changes?" / "You edited {parts}. Leaving now keeps the card as it was saved.", naming what changed; Keep editing / Discard (ruling P4a-L5). |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | "This card is no longer here" / "It was moved to Trash while you were editing. Your unsaved changes were not applied; the card can still be restored from Trash."; Back to deck + Open Trash (FE-B1 D11). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `card_editor_edit_light.png` | `card_editor_edit_dark.png` | — |
| loading | no golden | no golden | A single generic `MxSkeletonList` (4 rows) stands in for the whole form; no field-shaped skeletons — see Rulings. The flag/Save actions and the deck path also hold off until loaded. |
| loadError | no golden | no golden | Full-screen `MxErrorState`, "Couldn't load this card" — the body is the shared "Nothing was lost. Try again in a moment." |
| notFound | no golden | no golden | `CardGoneWidget`; both actions are live now that Trash exists (§9 row 87, closed by FE-B1 D11). |
| validationErr | `card_editor_errors_light.png` | `card_editor_errors_dark.png` | Error shown only once the back field is touched (ruling P4a-L2). |
| dirtySaving | no golden | no golden | The button shows only its spinner in place of the label (see Rulings). |
| saveFailed | no golden | no golden | — |
| discard | no golden | no golden | The body names what was edited ("You edited the meaning and the hint…"). |
| delConfirm | `card_editor_trash_dialog_light.png` | `card_editor_trash_dialog_dark.png` | Minus the glyph beside the title (§9 row 108) and the answer count in the note (§9 row 110); spins while the move commits (FE-B1 D15). |
Other goldens: `card_editor_more_light.png` / `card_editor_more_dark.png` (the More card with Move to Trash).


Every state above is built.

## Rulings

- **§9 row 108:** the Move to Trash dialog has no glyph (`MxDialog` has no glyph slot).
- **§9 row 110:** the dialog reads "Recoverable from Trash for 30 days, with its schedule and history" and "Leaves this deck and can be restored…"; it reads no history count, and the path above the "More" card already names the deck.
- **§9 rows 80, 28, E-L2:** the flag glyph swaps (`flag` → `flagged`) but never recolours; there is no streak token.
- **§9 rows 101, 81 (P4a-L8):** "Add details" has a solid edge, 48 tall; "Add tag" is an outline `MxButton` chip.
- **§9 row 81:** `DeckContextHeaderWidget` sits outside the scroll as a persistent header, above the scrolling history strip.
- **§9 row 46 (plan O2):** while saving, `MxButton` swaps its label for the spinner; the words live only in the caption line.
- **§9 row 125:** loading is a single generic `MxSkeletonList`, the app-wide convention (screens 15, 22, 23, 25, 26 do the same).
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** field headers are field labels in sentence case (14/600); Required is a caption in primary ink beside them; Optional details stays a section label.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** in edit, Save is enabled only once the draft differs from the saved card; create is unchanged.

## Copy

- App bar: "Edit card" · "Flag this card" · "Remove flag" · "Save".
- History summary: "{status} · {answers}" · "{lapses}" · "due {date}".
- Fields: same labels, hints and errors as 08-card-create, plus "Optional details".
- Footer: "Cancel" · "Save changes" · "Retry save" · "Couldn't save changes." · "Nothing was lost. Tap Save to try again." · "Editing content never changes the schedule or history." · "Add the missing field to enable save." · "Fix the marked field to enable save." · "Saving to this device…".
- More: "More" · "Move this card to Trash" · "Leaves this deck and can be restored from Trash for 30 days, schedule and history included." · "Move to Trash".
- Move to Trash dialog: "Move this card to Trash?" · "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move to Trash".
- Discard: "Discard changes?" · "You edited {parts}. Leaving now keeps the card as it was saved." (parts: "the term", "the meaning", "the example", "the hint", "the pronunciation", "the flag", "the tags", joined "a, b and c") · "Keep editing" · "Discard".
- Gone: "This card is no longer here" · "It was moved to Trash while you were editing. Your unsaved changes were not applied; the card can still be restored from Trash." · "Back to deck" · "Open Trash".
- Load error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." · "Retry".
