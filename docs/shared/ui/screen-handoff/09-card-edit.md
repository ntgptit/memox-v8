<!-- Hand-written screen record. -->

# 09 · Card edit

Editing a card's content: `CardEditorScreen.edit` → `_EditLoader` →
`CardEditorFormWidget` in edit mode (library phase 4a/4b). UC-CARD-001 A1;
BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-005 (content changes never
touch the study state or history).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back; title "Edit card"; a flag `MxIconButton` that toggles here, edit only (ruling P4a-L6, §9 row 80); Save writes the content first, then the flag only when it was toggled here (`setFlagged`, BR-CARD-009, DEV-220), so a flag set elsewhere while the editor was open is kept. No Save here: the single Save is the footer's "Save changes" (`DESIGN.md` › `MxAppBar`, as 08 records it; DEV-233). |
| Deck path | `DeckContextHeaderWidget` | Library › ancestors › deck › "Edit". |
| History summary | `CardEditSummaryWidget` (full-bleed `MxCard`, `MxListRow`, `MxIconTile`) | "{status} · {n} answers · {n} lapses · due {date}"; its chevron opens the card detail, which closes the editor underneath it (ruling P4a-L10, §9 row 82). |
| Front / Back | `CardFieldWidget` | Same fields as create, prefilled from the card: the app's form field box and body type (DEV-169). |
| Optional details | `CardOptionalFieldsWidget` (always open, "Optional details" overline, no disclosure) | Example, hint, pronunciation prefilled. |
| Tags | `CardTagEditorWidget` | Prefilled tags; same add/remove/limit behaviour as create, including the "Add" button and Save adding the tag still typed (invalid: error, nothing saved). |
| More | `CardTrashSectionWidget` (`MxCard`, `MxButton` outline "Move to Trash") | "Move this card to Trash" / "Leaves this deck and can be restored from Trash for 30 days, schedule and history included."; opens the shared delete dialog (FE-B1 D13). |
| Footer | `CardEditorFooterWidget` (`MxActionPair` 1 : 1) | Cancel + "Save changes" / "Retry save", sharing the row equally; danger banner after a failed save. |
| Move to Trash dialog | `CardDeleteDialogWidget` (`MxDialog`, `MxNote`, `MxSheetActions`) | "Move this card to Trash?", a front/back preview card, "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected."; Cancel · "Move" (the title names the Trash, DEV-179), spinning while it moves (FE-B1 D15). |
| Discard dialog | `showCardDiscardDialog` (`showMxConfirm`) | "Discard changes?" / "You edited {parts}. Leaving now keeps the card as it was saved.", naming what changed; Keep editing / Discard (ruling P4a-L5). |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | "This card is no longer here" / "It was moved to Trash while you were editing. Your unsaved changes were not applied; the card can still be restored from Trash."; Back to deck + Open Trash (FE-B1 D11). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `card_editor_edit_light.png` | `card_editor_edit_dark.png` | Save is off until the draft differs from the saved card; the caption reads "Edits never change the schedule or history." `card_editor_save_test.dart::edit: Save waits for a change and goes quiet when it is undone (critique 2026-09-30 part 3d-1)`. |
| dirty | no golden | no golden | A field, a tag or the flag differs from the saved card: Save is on and the caption no longer reads "Edits never change the schedule or history." `card_editor_save_test.dart::edit: Save waits for a change and goes quiet when it is undone (critique 2026-09-30 part 3d-1)`. |
| more | `card_editor_more_light.png` | `card_editor_more_dark.png` | The form scrolled to its last block, the More card with Move to Trash (kit 09); the golden test then taps it for delConfirm. `card_editor_golden_test.dart::card editor, Move to Trash, $theme`. |
| loading | no golden | no golden | A single generic `MxSkeletonList` (4 rows) stands in for the whole form; no field-shaped skeletons — see Rulings. The flag/Save actions and the deck path also hold off until loaded. |
| loadError | no golden | no golden | Full-screen `MxErrorState`, "Couldn't load this card" — the body is the shared "Nothing was lost. Try again in a moment." |
| notFound | no golden | no golden | `CardGoneWidget`; both actions are live now that Trash exists (§9 row 87, closed by FE-B1 D11). |
| validationErr | no golden | no golden | Error shown only once the back field is touched (ruling P4a-L2). The create form's `card_editor_errors_*` (screen 08) draws the same field errors; the edit form has no golden of its own. `card_editor_screen_test.dart::an edited card missing its back asks for the missing field (kit 09 validation)`. |
| dirtySaving | no golden | no golden | The button shows only its spinner in place of the label (see Rulings). Cancel, the back arrow and the flag are off (dimmed, read as disabled), system Back is held, and the fields are read-only until the write answers (as on 08; closing audit 2026-10-17). |
| saveFailed | no golden | no golden | The form keeps the edits; the footer shows the danger banner and the button reads "Retry save". The banner names the changes, not the card: "Couldn't save changes." (`cardSaveChangesFailedTitle`; create keeps "Couldn't save card."), over the shared body "Nothing was lost. Tap Retry save to try again." (`cardSaveFailedBody`, which names the button as it reads). VERIFIED `card_editor_save_failure_test.dart::edit: a failed save names the changes, not the card, and the body names the button as it reads (audit 2026-10-17)`; the banner as a block: `card_editor_blocks_test.dart::the footer turns a failure into an inline banner and a retry`. |
| flagToggled | no golden | no golden | The app bar flag swaps `flag` / `flagged` and reads under one stable name, "Flag this card", with its on / off state (never a name that flips to "Remove flag, on"); the flag alone is a change that enables Save; Save writes the flag only when it was toggled here (DEV-220). `card_editor_save_test.dart::edit: the flag alone is a change (Review Focus 3)`, `::edit: a flag toggled in the editor is saved (DEV-220)`, `::edit: a flag set while the editor was open survives a content-only save (BR-CARD-009, DEV-220)`. |
| missingField | no golden | no golden | An edit that blanked a required side: the caption asks "Add the missing field to enable save."; Save off. `card_editor_screen_test.dart::an edited card missing its back asks for the missing field (kit 09 validation)`. |
| pendingTag | no golden | no golden | As on 08: a typed tag counts as a change, Save adds it, an invalid one stops the save. `card_tag_input_test.dart::edit: Save keeps the tag still in the field`, `::an invalid tag in the field stops Save and says why`. |
| savedEdit | no golden | no golden | A successful save closes the editor with no toast. Code read: `card_editor_form_widget.dart` (`_afterSave`, `_leave`). |
| goneOnSave | no golden | no golden | Save (or the live read) finds the card gone: `CardGoneWidget` "This card is no longer here"; Back to deck (closes the card's detail underneath too, the editor popping `true` as after Move to Trash) and Open Trash. `card_editor_screen_test.dart::a card deleted while editing shows it is gone (RF3)`. |
| discard | no golden | no golden | The body names what was edited ("You edited the meaning and the hint…"). |
| delConfirm | `card_editor_trash_dialog_light.png` | `card_editor_trash_dialog_dark.png` | Minus the glyph beside the title (§9 row 108) and the answer count in the note (§9 row 110); spins while the move commits (FE-B1 D15). |

Every state above is built.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the card lands | loaded | VERIFIED `card_editor_screen_test.dart::edit starts from the card, flags in the app bar, saves` |
| loading | the read fails | loadError | `UNVERIFIED (code read)`: `card_editor_screen.dart` (`_EditLoader`) |
| loadError | Retry | loading, then loaded | `UNVERIFIED (code read)`: invalidates `cardDetailProvider` |
| loading / loaded | the card is deleted or moved to Trash | notFound / goneOnSave; unsaved edits are not applied | VERIFIED `::a card deleted while editing shows it is gone (RF3)` |
| loaded | change a field or a tag | dirty; Save on | VERIFIED `card_editor_save_test.dart::edit: Save waits for a change and goes quiet when it is undone (critique 2026-09-30 part 3d-1)` |
| dirty | undo the change | loaded, Save off | VERIFIED same test |
| loaded | tap the flag | flagToggled: the same name "Flag this card" with the toggled state on | VERIFIED `card_editor_screen_test.dart::the flag toggle reports its state under one stable name, never a label that contradicts it (ruling P4a-L6; audit 2026-10-17)` |
| dirty | blank a required side | missingField / validationErr; Save off | VERIFIED `::an edited card missing its back asks for the missing field (kit 09 validation)` |
| dirty | Save | dirtySaving, then savedEdit: the editor closes | VERIFIED `::edit starts from the card, flags in the app bar, saves` |
| dirtySaving | a second tap on Save | one write | VERIFIED `::a double tap on Save changes writes once` |
| dirtySaving | the write fails | saveFailed: "Couldn't save changes." · "Nothing was lost. Tap Retry save to try again."; the button reads "Retry save" | VERIFIED `card_editor_save_failure_test.dart::edit: a failed save names the changes, not the card, and the body names the button as it reads (audit 2026-10-17)` |
| held write (dirtySaving) | a bug (not a `Failure`) | saveFailed, the same banner and "Retry save" as a `Failure`: Save, Cancel, Back and the flag are live again; the bug is reported | VERIFIED `card_held_bug_test.dart::a save that dies on a bug leaves the editor saying so, with its controls back (Ruling P4a-L3)` |
| dirtySaving | Cancel, the back arrow, the flag or system Back | the controls are off and Back is ignored; the write lands (no discard dialog) | VERIFIED `card_editor_save_failure_test.dart::edit: while the save runs, Back, Cancel and the flag are off, not dead taps (closing audit 2026-10-17)`; system Back: `UNVERIFIED (code read)`, the `PopScope` returns while `_isSaving`; the create twin is VERIFIED `card_editor_save_test.dart::create: Cancel, close and Back are held while the card saves; the save lands and says so, with no discard dialog` |
| dirtySaving | the fields | read-only until the write answers | `UNVERIFIED (code read)`: `isReadOnly: _isSaving` in `card_editor_form_widget.dart` |
| saveFailed | Retry save | dirtySaving | `UNVERIFIED (code read)` |
| dirtySaving | the content saves and the flag write fails | saveFailed with the content already written | `UNVERIFIED (code read)`: `_edit` runs `editCard` then `setFlagged`; no test fails the second write |
| dirty | Back, Cancel | discard, naming what changed; Keep editing returns, Discard closes | VERIFIED `::leaving an edited card names what was edited (kit 09 discard)` |
| loaded | Back, Cancel with no change | the editor closes at once | `UNVERIFIED (code read)`: `PopScope.canPop` |
| loaded | tap the history summary | the card detail (screen 10), the editor closed underneath | `UNVERIFIED (code read)`: `card_edit_summary_widget.dart`, `onOpenDetails: _close` |
| loaded | Move to Trash | delConfirm; Cancel returns; Move closes the editor with the edits left behind | VERIFIED for the dialog `card_bulk_actions_test.dart::Trash asks with the count; Cancel keeps the selection; several cards get no Undo (FE-B1 D4)`; the editor entry `UNVERIFIED (code read)`: `card_trash_section_widget.dart` |
| delConfirm | Move is tapped twice, or the move fails | one move, the dialog held; a failure keeps the dialog | VERIFIED `card_bulk_actions_test.dart::Move to Trash spins while the cards move (FE-B1 D15)`; the failure `UNVERIFIED (code read)` |
| goneOnSave / notFound | Back to deck | the deck: the editor pops `true`, so the card's detail beneath it closes too, which would only say the same | VERIFIED `test/app/library_routes_test.dart::a card trashed elsewhere while it is edited: Back to deck returns to the deck, past its detail (audit 2026-10-17)` |
| goneOnSave / notFound | Open Trash | screen 06 | `UNVERIFIED (code read)` |

## Rulings

- **§9 row 108:** the Move to Trash dialog has no glyph (`MxDialog` has no glyph slot).
- **§9 row 110:** the dialog reads "Recoverable from Trash for 30 days, with its schedule and history" and "Leaves this deck and can be restored…"; it reads no history count, and the path above the "More" card already names the deck.
- **§9 rows 80, 28, E-L2:** the flag glyph swaps (`flag` → `flagged`) but never recolours; there is no streak token.
- **§9 rows 101, 81 (P4a-L8):** "Add details" has a solid edge, 48 tall; "Add tag" is an outline `MxButton` chip.
- **§9 row 81:** `DeckContextHeaderWidget` sits outside the scroll as a persistent header, above the scrolling history strip.
- **§9 row 46 (plan O2):** while saving, `MxButton` swaps its label for the spinner; the words live only in the caption line.
- **§9 row 125:** loading is a single generic `MxSkeletonList`, the app-wide convention (screens 15, 22, 23, 25, 26 do the same).
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** field headers are field labels in sentence case (14/600); Required is a caption in `context.accentColor` beside them; Optional details stays a section label.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** in edit, Save is enabled only once the draft differs from the saved card; create is unchanged.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the tag field has the same "Add" button and add rule as create; Save adds the tag still typed (so pending tag text enables Save, and is saved), and an invalid one shows its error and saves nothing.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is plain text colour everywhere, the card list included (F6).
- **DEV-169 (owner 2026-10-05):** every card field (term, meaning, example, hint, pronunciation) is the app's form field: muted fill that lightens on focus, r12, 12 padding, 52 floor, the body role; the term no longer sets 24/700 nor the meaning 16/500. The footer pair shares the row 1 : 1 like every footer pair. **DEV-372 (Material 3):** the field is the outlined M3 field: no fill (the page ground shows through), 16 text inset, 56 floor, the input in `bodyLarge`; the field paints its label above the box (4 clear, `labelMedium`, `onSurfaceVariant`, `error` in error) with the optional field's glyph before it and "Required" or "· optional" after it, and the count "{count} / {limit}" moves from the header to the trailing end of the supporting row under the box (`error` with the field's error); the caret turns `error` in error.
- **Q-C-1 (owner, 2026-10-16):** as on 08, the Tags meta and Add details' field list wrap only between whole terms (`metaLine`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- App bar: "Edit card" · "Flag this card" (the one name; the on / off state is the toggle's).
- History summary: "{status} · {answers}" · "{lapses}" · "due {date}".
- Fields: same labels, hints and errors as 08-card-create, plus "Optional details".
- Footer: "Cancel" · "Save changes" · "Retry save" · "Couldn't save changes." · "Nothing was lost. Tap Retry save to try again." · "Edits never change the schedule or history." · "Add the missing field to enable save." · "Fix the marked field to enable save." · "Saving to this device…".
- More: "More" · "Move this card to Trash" · "Leaves this deck and can be restored from Trash for 30 days, schedule and history included." · "Move to Trash".
- Move to Trash dialog: "Move this card to Trash?" · "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move".
- Discard: "Discard changes?" · "You edited {parts}. Leaving now keeps the card as it was saved." (parts: "the term", "the meaning", "the example", "the hint", "the pronunciation", "the flag", "the tags", joined "a, b and c") · "Keep editing" · "Discard".
- Gone: "This card is no longer here" · "It was moved to Trash while you were editing. Your unsaved changes were not applied; the card can still be restored from Trash." · "Back to deck" · "Open Trash".
- Load error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." · "Retry".
