# UI hardening SP3 — library and cards UX (screens 01–12) — design

Status: draft for owner approval ·
Path: architectural, sub-project SP3 of [the UI hardening spec](2026-10-03-ui-hardening-design.md) ·
Owner rulings: R1, R5; calls V1, V5, V6 (that spec §3, §7). WBS row: FE-D30.

## 1. Intent

SP3 fixes rows 3.01–3.54 of §6.2 of the parent spec: the Library, algorithm, starter, search,
tags, Trash, card list, card editor, card detail, import and export screens (01–12).
Every row was re-checked against the code on `claude/ui-hardening-sp2b` (after SP1 and SP2a).
No row was already fixed; two were half done (3.46 by the SP1 chip hairline, 3.48 by F9, where
the file card picks) and keep only their remainder.

Success:

- every behaviour row has a test that fails before its fix; copy and layout rows get a widget
  test or a golden;
- `dod_check.sh` is green, then the Linux goldens (`run_goldens.sh`);
- the owner approves the golden-compare page before the merge;
- the detail files of screens 01–12, the screen index and WBS row FE-D30 tell the truth.

Outcome count: 52 fixed, 2 merged (3.19 into 3.20, 3.32 into 3.30), 0 already fixed, 0 ruled out
(one part of 3.26, "Empty Trash", is ruled out inside its row: DECISION D6).

## 2. Owner rulings used

- **R1.** Every finding is in scope, Minor included.
- **V1.** Keep the terms; add a one-line definition where each first appears on a screen. Applied
  where the term is the subject of the screen (3.06, 3.10, 3.44/45 below). The algorithm label in
  a summary card (01 open deck, 07) echoes a choice already defined and is not defined again: a
  note says something new. "Front · Term" and "Back · Meaning" are defined by the field hints
  ("The term you want to remember", "The meaning; separate several with commas"), so 08/09 need
  no change.
- **V5.** Search falls back to accent-insensitive matches listed after the exact ones; amends
  BR-SEARCH-002 (§6). The Fill judge is SP4.
- **V6.** Manual create shows a non-blocking "Already in this deck" note under the front field;
  saving stays allowed.
- DESIGN.md voice: failure says first nothing was lost; neutral for notes; a note says something
  new; a destructive confirm names the loss.

## 3. Design

Where = `lib/features/…` unless stated. VI is the Vietnamese ARB string. New strings go to
`app_en.arb` and `app_vi.arb`; "key*" is a changed existing key.

### 3.1 Library and deck dialogs (01) — `deck/presentation/widgets/`

| # | Fix | Where |
|---|---|---|
| 3.01 | The due strip names its verb. A trailing "Study" label (labelLarge, `primaryInk`) sits left of the chevron; title stays "{n} cards due". Display-only strip (no `onOpen`) shows neither. EN "Study" · VI "Học" (`libraryDueAction`). | `sections/deck_due_strip_widget.dart:38-70` |
| 3.02 | Starter decks no longer share the sparkles glyph that means "new cards" (`AppIcons.newCards`). `AppIcons.starterDecks` becomes `Icons.library_add_outlined` (DECISION D4). The three app-bar buttons keep their tooltips (`MxIconButton` already shows `semanticLabel` as one); no visible text, per the M3 app-bar rule. | `core/theme/foundations/app_icons.dart:88`, `sections/deck_library_root_widget.dart:87-101` |
| 3.03 | A term never breaks inside itself. `deckSubDeckCount*`, `deckCardCount`, `deckDepthHeader`: word joiner (U+2060) after the hyphen of "sub-deck(s)" and a no-break space between number and noun; `deckRowMeta` becomes `{subDecks} · {cards}`, so a wrap falls only between the two terms and "·" stays with the first. The due strip's breakdown already glues terms (`MxWorkloadBreakdownLine._gluedSeparator`); a layout test pins it at 320 dp. VI: same joiners, "bộ thẻ con" keeps a no-break space. | `l10n/app_en.arb:1879-1901,2036`, `items/deck_row_widget.dart:35-40` |
| 3.04 | The sort sheet has one left edge: the title, "Sort by", every option row and the toggle row share the option rows' text inset (the header's `AppSpacing.card` and the section header's `AppSpacing.control` are replaced by it). "Most due" gets a hint like its siblings: EN "Most cards due first" · VI "Nhiều thẻ đến hạn nhất trước" (`deckSortDueHint`). | `overlays/deck_level_query_sheets_widget.dart:48-60,100-111` |
| 3.05 | The gone state no longer claims a time it cannot know (`DeckRejection.notFound` does not tell a trashed deck from a purged one). `deckGoneBody*`: EN "It's no longer in your library. A deck you moved to Trash can still be restored from there for 30 days." · VI "Bộ thẻ không còn trong thư viện. Bộ thẻ đã chuyển vào Thùng rác vẫn khôi phục được ở đó trong 30 ngày." Same body in the card, editor and detail gone states stays as is (they say "while you were away" truthfully only there). | `l10n/app_en.arb:2049`, `sections/deck_gone_state_widget.dart` |
| 3.06 | First-deck dialog: the bare tray becomes a labelled field. Label "Review algorithm" (`deckReviewAlgorithm`) with a "Required" caption (`starterSheetRequired`), then two `MxOptionRow`s (Eight boxes, SM-2) with the existing one-line definitions `algorithmEightBoxDescription` / `algorithmSm2Description` (V1), inside an `MxCard` as the reset dialog's `_AlgorithmChoice` does. Nothing is preselected. The lock note says the real rule: `deckSchedulerNote*` EN "Locks when the first card finishes learning. Changing it after that means resetting learning progress." · VI "Khoá khi thẻ đầu tiên học xong. Muốn đổi sau đó phải đặt lại tiến độ học." (also used by the starter sheet). | `overlays/create_root_deck_dialog_widget.dart:124-140`, `l10n/app_en.arb:167` |
| 3.07 | Create gives feedback and cannot hide its result. Both create dialogs pop the new `DeckEntity` (the sub-deck dialog now does too). The caller (a) sets the level's filter to `all` when it was Due only (a new deck has nothing due), (b) shows a toast EN "“{name}” created" · VI "Đã tạo “{name}”" with action "Open" · "Mở", which calls `onOpenDeck(id)`. A sort that places it elsewhere is covered by the Open action. | `overlays/create_root_deck_dialog_widget.dart:86-88`, `overlays/deck_name_dialog_widget.dart:50-60,182-193`, `sections/deck_library_root_widget.dart:79`, `screens/deck_level_screen.dart:303` |
| 3.08 | The name error clears on the first edit (`onChanged`). Create checks both fields in one tap: a blank name sets `DeckRejection.blankName` locally and a missing algorithm shows its message at the same time; the use case still owns every other rule. | `overlays/create_root_deck_dialog_widget.dart:71-76,113-122` |
| 3.09 | Reorder stays in the sheet when it is only blocked. `deckLevelCanReorder` becomes a three-state `DeckReorderAvailability` (`available`, `blocked`, `hidden`): hidden below two decks (nothing to order), blocked when the sort is not Manual or Due only is on. A blocked row is `isEnabled: false` with subtitle EN "Sort by Manual and show every deck to reorder" · VI "Chọn sắp xếp Thủ công và hiện mọi bộ thẻ để đổi thứ tự" (`deckReorderBlockedHint`). | `states/deck_reorder_mode_state.dart:21-40`, `overlays/deck_action_sheet_widget.dart:31-57,150-157` |

### 3.2 Algorithm and starter decks (02, 03)

| # | Fix | Where |
|---|---|---|
| 3.10 | "Locked" once, and the way out beside it. When locked, the `MxNote` above the options goes (its words move into the strip) and the strip body becomes EN "A cycle runs from one reset to the next. The first card finished learning on {date}. To change the algorithm, reset learning progress below." · VI "Một chu kỳ chạy từ lần đặt lại này đến lần sau. Thẻ đầu tiên học xong ngày {date}. Muốn đổi thuật toán, hãy đặt lại tiến độ học ở dưới." (`algorithmLockedBody*`; defines "cycle", V1). Title stays "Locked · cycle {n}". `algorithmLockedNote` is deleted. When locked, "Start over" follows the strip directly and the disabled options come after it. | `widgets/sections/deck_lock_strip_widget.dart`, `screens/deck_algorithm_screen.dart:191-220` |
| 3.11 | The reset dialog's Kept and Lost tiles stack at full width instead of two half-width columns, and their copy is shortened: Kept EN "Decks, cards, tags, notes and every past answer (kept as cycle {n})" · VI "Bộ thẻ, thẻ, tag, ghi chú và mọi câu trả lời cũ (giữ lại ở chu kỳ {n})"; Lost EN "Every card's schedule and progress; {all N cards become new}" · VI "Lịch và tiến độ của mọi thẻ; {cả N thẻ trở thành thẻ mới}". The open-session variant adds "; the open session". | `overlays/deck_reset_dialog_widget.dart:154-190`, `l10n/app_en.arb:2344-2366` |
| 3.12 | No "Required" beside a choice that is always made. The starter sheet drops the caption: the suggested algorithm is preselected, so the label reads "Review algorithm" alone. (3.06's dialog keeps the caption: nothing is preselected there.) | `overlays/starter_algorithm_sheet_widget.dart:99-104` |
| 3.13 | "Suggests {algorithm}" moves up under the facts line (inside the card's `MergeSemantics` group) and the add button stands alone below. | `items/starter_template_card_widget.dart:86-100` |
| 3.14 | The identical sparkles tile goes: it carries no information, and the title now leads at the card's left edge (`_indent` is removed). The facts line, "Suggests" and the add button align with it. | `items/starter_template_card_widget.dart:28,57-75` |

### 3.3 Search (04) — `search/` (V5)

V5 adds one tier after `contains`: **plain**, a card or deck found only once accents are ignored.

- `foldText` is unchanged (case-only). A second pure function `plainText(folded)` goes in
  `lib/core/text/plain_text.dart` (DECISION D1): NFD, drop combining marks U+0300–U+036F,
  `đ`→`d`, then NFC. Hangul decomposes to jamo, not marks, so Korean is untouched.
- `SearchTier` gains `plain` (index 3). `_noTier` becomes 4. `searchTierOf` returns `plain` when
  `plainText(folded).contains(plainText(term))` and no earlier tier matched.
- `search_queries.drift`: the three tier `CASE`s gain `WHEN instr(plain_text(x), :plain_term) > 0
  THEN 3 ELSE 4`; `tier < 4`; `:plain_term` is passed beside `:term`. The cursor, sort key and
  paging are unchanged (tier is already part of the key). Decks are matched in Dart and use the
  same function.
- A plain hit has no highlighted range (lengths differ; the existing rule "unmarked rather than
  marked wrong"). The first plain row of each group is preceded by a caption: EN "Without accents"
  · VI "Khi bỏ dấu" (`searchPlainTier`), so the person sees why "học" answered "hoc".

| # | Fix | Where |
|---|---|---|
| 3.15 | The idle hints stop looking tappable and stop hard-coding KO/VI. The `MxCard` of three `MxListRow`s becomes one plain caption line per field kind (glyph + words, no surface, no examples): "a deck name · a card term or meaning · a tag name". `searchHint*Example` keys are deleted. | `widgets/sections/search_hints_widget.dart:28-47` |
| 3.16 | The accent rule is said once, in the idle note, and changes with V5: EN "Case and accents don't have to match: “hoc” also finds “học”, after the exact matches. Examples, hints and pronunciation are not searched." · VI "Không cần khớp hoa/thường hay dấu: “hoc” cũng tìm ra “học”, xếp sau kết quả khớp đúng. Ví dụ, gợi ý và phát âm không được tìm." (`searchAccentNote*`). The no-results body loses its accent sentence ("Search covers deck names, card terms and meanings, and tag names."). The permanent results footer `searchFooter` is deleted. | `l10n/app_en.arb:2069,2170,2183`, `widgets/sections/search_results_widget.dart:100-106` |
| 3.17 | The kind leads, the path follows, so "empty" is not a path segment: `searchHolds*` become "Holds cards · {path}", "Holds sub-decks · {path}", "Empty · {path}" (VI "Chứa thẻ · {path}", "Chứa bộ thẻ con · {path}", "Trống · {path}"). | `widgets/items/search_deck_hit_row_widget.dart:35-40`, `l10n/app_en.arb:2090-2108` |
| 3.18 | The rows stay while the next term loads. `_watchThrough(null)` sets `SearchScreenLoading` only from idle or failed; from results or no-results it keeps the state until the new first page arrives. | `controllers/search_screen_controller.dart:75-82` |

### 3.4 Tags (05) — `tags/presentation/`, plus a tag-only search

**Tag-only search (3.20, merges 3.19).** "Cards with this tag" must not be a text search (it finds
"adverb" for "verb", and decks). `LibrarySearchScreen` gains `tagId`/`tagName` (tag mode): no
search field, title "Tagged “{name}”" · VI "Gắn tag “{name}”", no deck group, no highlights, no
plain-tier caption. A new statement `searchTaggedCardHits(:tag_id, cursor…, :limit)` in
`search_queries.drift` lists live cards joined on `card_tags.tag_id = :tag_id`, tier constant 0,
same key `(tier, front_folded, created_at, id)`, so `SearchCursor` and paging are reused.
`SearchRepository.watchSearch` and `SearchLibraryUseCase` take an optional `tagId`; the controller
gets `searchTag(tagId)`. Empty result: EN "No cards carry this tag" / "Cards in the Trash don't count."
· VI "Chưa thẻ nào gắn tag này" / "Thẻ trong Thùng rác không được tính." Route: `AppRoutes.searchForTag(id, name)`
beside `searchFor`; the Library-branch placement (plan C4) is kept.

| # | Fix | Where |
|---|---|---|
| 3.19 | (merged into 3.20) A row tap opens the tag's cards in tag mode; ⋮ opens the sheet. The sheet drops "Find cards with this tag" (now the row tap) and keeps Rename and Delete, so the destructive command is never one tap from browsing. | `items/tag_row_widget.dart:33`, `overlays/tag_actions_sheet_widget.dart:61`, `screens/tags_screen.dart:61`, `app/router/app_router.dart:155-170` |
| 3.20 | Tag-only search as above. | as above |
| 3.21 | The delete note stops contradicting the action. `tagsDeleteSafe*`: EN "No card is deleted. {All N cards stay} in their decks and lose only this tag." · VI "Không thẻ nào bị xoá. {Cả N thẻ} vẫn ở trong bộ thẻ của chúng và chỉ mất tag này." (0 cards: "No card is deleted."). | `overlays/tag_delete_dialog_widget.dart:36`, `l10n/app_en.arb:5877` |
| 3.22 | The merge state drops two of its five layers: the caption under the field (`tagsLengthUnique`) and `tagsMergeSafe`. What stays: label, field, one panel (notice, chips). Notice EN "A tag called “{target}” already exists. This merges “{source}” into it; its spelling stays “{target}”." · VI "Đã có tag “{target}”. Thao tác này gộp “{source}” vào đó; giữ cách viết “{target}”." The counter shows only past the limit (already so). | `overlays/tag_rename_dialog_widget.dart:168-176,246-249` |
| 3.23 | The empty state loses its button: "Go to library" cannot lead to where tags are made (a card editor in some deck). Body EN "Tags appear here once you add one to a card, in the card editor." · VI "Tag xuất hiện ở đây khi bạn gắn tag cho một thẻ trong trình sửa thẻ." | `screens/tags_screen.dart:194-201`, `l10n/app_en.arb:5724` |
| 3.24 | Success is no longer silent: after rename EN "Renamed to “{name}”" · VI "Đã đổi tên thành “{name}”"; after merge EN "Merged into “{target}” · {n} cards" · VI "Đã gộp vào “{target}” · {n} thẻ"; after delete EN "Removed “{tag}” from {n} cards" · VI "Đã gỡ “{tag}” khỏi {n} thẻ". Keyboard Done no longer drops the first 250 ms: it cancels the settle timer, reads the plan now, and then writes only when the plan is a plain rename; a merge plan shows its panel and waits for the visible "Merge tags" button (the merge stays disclosed before it is confirmed). | `screens/tags_screen.dart:105-125`, `overlays/tag_rename_dialog_widget.dart:99-103,166` |

### 3.5 Trash (06) — `trash/presentation/`

| # | Fix | Where |
|---|---|---|
| 3.25 | A fourth chip "Expiring · {n}" (shown only when some entry has under 3 days left, the same `trashExpiringSoon` that tints the badge) filters to those entries, soonest first; header "{n} entries · expiring first". VI "Sắp hết hạn · {n}" / "{n} mục · sắp hết hạn trước". | `states/trash_state.dart:5-14`, `screens/trash_screen.dart:229-240,262-281` |
| 3.26 | Selecting gains "Select all" in the app bar: every shown entry of the locked kind, or of the active filter's kind, disabled while the filter is All and nothing is picked. EN "Select all" · VI "Chọn tất cả". "Empty Trash" is not added (DECISION D6): select all, then Delete, empties a kind and names the count. | `screens/trash_screen.dart:176-190`, `trash_controller.dart` |
| 3.27 | The number is stated once: while selecting, the title says "{n} cards selected" and the header drops its total, reading "Cards" or "Decks" (`trashFilterCards/Decks`). | `screens/trash_screen.dart:262-281` |
| 3.28 | The two notes stop pushing the list down. The retention note is one line, EN "Kept 30 days, then removed automatically." · VI "Giữ 30 ngày, rồi tự động xoá." (the restore question is asked by the restore sheet). Blocked purges collapse to one banner: with one batch the existing sentence; with several EN "{n} entries were kept because each holds something deleted earlier." · VI "{n} mục được giữ lại vì mỗi mục còn chứa thứ đã xoá trước đó." (`trashPurgeBlockedMany`). | `l10n/app_en.arb:1443,1841`, `screens/trash_screen.dart:205-228,285-310` |
| 3.29 | A clock that went backward cannot print the impossible. `trashDeletedAgo` clamps `elapsed` at zero ("just now"); `trashTimeLeft` clamps `left` at `trashRetention` (never "31 days left"). The purge side is R10 (SP2b 2.30). | `widgets/support/trash_labels_widget.dart:36-55` |

### 3.6 Card list (07) — `card/presentation/widgets/`

| # | Fix | Where |
|---|---|---|
| 3.30 | One row less above the first card. The sort trigger moves into the filter row as its pinned trailing control (the chips keep scrolling beside it). The "Cards" header row exists only while something narrows the list, and then it says only what the chips cannot (3.32). Hidden while selecting, as now. | `sections/card_list_toolbar_widget.dart:74`, `sections/card_list_section_widget.dart:440-462` |
| 3.31 | The status is said once per row: a card whose due kind is `newCard` shows no "New" badge (the label reads NEW); the other kinds keep their badge. | `items/card_row_widget.dart:160-182` |
| 3.32 | (merged into 3.30) While narrowed, the chips already count the matches, so the header reads EN "Narrowed from {total}" · VI "Thu hẹp từ {total} thẻ" (`cardNarrowedFrom`), not "Showing 3 of 4". | `l10n/app_en.arb:2443` |
| 3.33 | The failed bulk flag names its action. `cardBulkFailedTitle*` takes the action and count: EN "Couldn't flag {n} cards" / "Couldn't remove the flag from {n} cards" with body "Nothing changed. The cards stay selected." · VI "Chưa gắn cờ được {n} thẻ" / "Chưa gỡ cờ được khỏi {n} thẻ". | `sections/card_list_section_widget.dart:386-410` |
| 3.34 | Selection is taught once. A dismissible `MxNote.hint` above the summary (not while searching or selecting; only when the deck holds 2+ cards): EN "Touch and hold a card to select several, then move, flag, tag, export or trash them together." · VI "Chạm và giữ một thẻ để chọn nhiều thẻ, rồi chuyển, gắn cờ, gắn tag, xuất hoặc bỏ vào Thùng rác cùng lúc." Its dismissal persists in `dismissed_note` under `NoteKeys.cardListSelection` (DECISION D3). | `sections/card_list_section_widget.dart:425-440`, `core/notes/note_keys.dart` |
| 3.35 | A search with no match offers its way out. The empty state gets "Clear search" and, when tags are applied, "Clear tag filter"; the body names what else narrows: EN "Try a different term, or clear the search. A tag filter is also on." (only then). VI "Thử từ khác, hoặc xoá tìm kiếm. Bộ lọc tag cũng đang bật." | `sections/card_list_empty_widget.dart:36-48`, `sections/card_list_section_widget.dart:464` |
| 3.36 | A failed refresh no longer replaces the list or hides the selection. With rows already loaded, `async.hasError` keeps them and shows a warning `MxInlineBanner` above them, EN "Couldn't refresh this list. Your cards are safe." with Retry · VI "Chưa làm mới được danh sách. Thẻ của bạn vẫn an toàn." The full error page stays for a first load with no rows. | `sections/card_list_section_widget.dart:318-330` |

### 3.7 Card create, edit and detail (08–10) (V6)

| # | Fix | Where |
|---|---|---|
| 3.37 | A field shows its count only near the limit: from 80% of it, and always past it. The label and "Required" stay (the legend is the accessible cue). | `sections/card_field_widget.dart:112-130` |
| 3.38 | One way out per intent: the footer Cancel goes (create and edit); the close/back button and system Back keep the same discard guard. Save is the footer's only action. DECISION D7. | `sections/card_editor_footer_widget.dart:49-64`, `sections/card_editor_form_widget.dart:456` |
| 3.39 | V6. On create, 300 ms after the front stops changing, ask whether a live card of this deck has the same `front_folded` (new `CardRepository.hasFront(deckId, front)`, `.drift` query `liveCardFrontExists`, `CheckFrontInDeckUseCase`; ADR-020). If so a neutral field note "Already in this deck" · VI "Đã có trong bộ thẻ này" shows under the front field (live region); Save stays enabled. Edit mode does not check. The tone is a new `MxFieldMessageTone.note` (D2). | `sections/card_field_widget.dart`, `sections/card_editor_form_widget.dart`, `core/database/queries/card_row_queries.drift:19`, `shared/widgets/mx_field_message.dart:1-30` |
| 3.40 | "Save, keep adding" keeps the tags (a batch usually shares them) and clears everything else, flag included. `_clearForNext` stops resetting `_tags`; the saved baseline is taken after, so the form is not dirty. | `sections/card_editor_form_widget.dart:363-375` |
| 3.41 | The flag is no longer an app-bar glyph that looks instant but is a draft change. It becomes a row in the form, "Flagged" with an `MxToggle` and the hint EN "Flag it to find it again under the Flagged filter." · VI "Gắn cờ để tìm lại trong bộ lọc Cờ." (`cardFlagRow*`); the app bar keeps only the close/back button. Create gets the same row. Amends ruling P4a-L6 (D7). | `sections/card_editor_app_bar_widget.dart:35-56`, `sections/card_editor_body_widget.dart` |
| 3.42 | A never-studied card reads "New · Not studied yet" (VI "Mới · Chưa học"), not "New · 0 answers · 0 lapses": answers and lapses appear once `answerCount > 0`; the due date still follows. | `sections/card_edit_summary_widget.dart:32-38` |
| 3.43 | Every edit save says so: toast EN "Card saved" · VI "Đã lưu thẻ" (`cardSavedToast`), so a flag-only or tag-only save is acknowledged. The editor's Trash confirm names unsaved edits when the form is dirty: its body adds EN "Edits you haven't saved are dropped with it." · VI "Các chỉnh sửa chưa lưu cũng bị bỏ theo." (`showDeleteCardsDialog(hasUnsavedEdits:)`). | `sections/card_editor_form_widget.dart:340-343,515`, `sections/card_trash_section_widget.dart:29-37`, `overlays/card_delete_dialog_widget.dart:30-60` |
| 3.44 | The outcome leads. The kind ("Learning", "Review", "Repeat") drops to `rowDescription` beside the badge, and the first meta line is one joined string, "{mode} · Box {from} → {to}" ("Recall · Box 4 → 5"), so the move is no longer a bare token. | `items/card_history_event_widget.dart:60-90,96-110` |
| 3.45 | One overline, not two. Cycle headers show only when the entry's generation is above 1 or changes between neighbours; a card never reset shows "History · newest first" alone. The first header on screen carries the definition (V1): EN "A cycle starts at each reset of learning progress." · VI "Mỗi lần đặt lại tiến độ học bắt đầu một chu kỳ mới." The schedule card gets the algorithm's existing one-line description under its title (`algorithmEightBoxDescription` / `algorithmSm2Description`, V1). | `sections/card_history_scroll_widget.dart:93-103`, `sections/card_schedule_widget.dart` |

### 3.8 Import and export (11, 12) — `transfer/presentation/`

| # | Fix | Where |
|---|---|---|
| 3.46 | The field trigger leads its row. SP1's hairline already marks it a control; the rest: a mapped column's `MxChipTrigger` is `isActive` (primary container, primary-ink edge), "Not imported" stays the ghost chip, so mapped columns read as chosen and unmapped as open. | `items/import_mapping_row_widget.dart:76-87` |
| 3.47 | Three orientation layers, not four: the numbered section labels go. `importSectionSource/Columns/Preview*`: "Choose a source", "Map columns", "Preview" (VI "Chọn nguồn", "Ghép cột", "Xem trước"); the tracker already says "Step n of 4". | `l10n/app_en.arb:3482-3490`, `sections/import_source_section_widget.dart:101`, `sections/import_mapping_section_widget.dart:67`, `sections/import_preview_section_widget.dart:39` |
| 3.48 | The look-alike empty state under "Choose a file" goes: it cannot be tapped while the card above does the picking. Its one useful line, "Nothing is added until you confirm.", becomes a caption under the two source cards. | `sections/import_source_section_widget.dart:183-192` |
| 3.49 | The file chip is not repeated on the preview. It stays on Source and Columns (it carries the sheet picker and the remove action); step 3 and the importing step show only the tracker. | `sections/import_source_section_widget.dart:196-200` |
| 3.50 | The partial result states its numbers and shrinks: hero title EN "{written} added, {skipped} skipped" · VI "Đã thêm {written}, bỏ {skipped}" (`importPartialTitle*`), `isCompact: true` for the success, partial and none heroes. | `sections/import_result_widget.dart:40-62` |
| 3.51 | The count is said once, on the action. Title EN "Export all cards" / "Export selected cards" (VI "Xuất toàn bộ thẻ" / "Xuất các thẻ đã chọn"); "Export {n} cards" on the button keeps it (owner 2026-09-26). | `overlays/card_export_sheet_widget.dart:190-198`, `l10n/app_en.arb` `exportTitle*` |
| 3.52 | A final problem (stale, empty, no share target) hides the format rows and the content note instead of dimming them: the sheet is the banner and Close. | `overlays/card_export_sheet_widget.dart:120-155` |
| 3.53 | The share sheet is announced. A caption under the content note: EN "Next, your phone's share sheet opens so you choose where the file goes." · VI "Tiếp theo, bảng chia sẻ của điện thoại sẽ mở để bạn chọn nơi lưu tệp." (`exportShareNote`), hidden on final problems. | `overlays/card_export_sheet_widget.dart:148-156` |
| 3.54 | Memory stays bounded. `BuildExportUseCase` reads the cards in keyset pages of 1,000 and CSV/TSV are encoded page by page into one `BytesBuilder` (no `List<List<String>>` of the whole deck); XLSX, which the `excel` encoder builds whole, is limited to 20,000 cards, the same cap as import: above it the XLSX row is disabled with EN "XLSX holds up to 20,000 cards. Use CSV for more." · VI "XLSX chứa tối đa 20.000 thẻ. Dùng CSV nếu nhiều hơn." DECISION D5. | `domain/usecases/build_export_use_case.dart:27-50,66-78`, `card/data/repositories/card_transfer_repository_impl.dart:88`, `data/repositories/transfer_file_repository_impl.dart` |

## 4. Shared code

All need owner approval in one popup; each lists the recommended option.

- **DECISION D1 (V5 mechanism): register a SQLite function `plain_text` (recommended)** in
  `lib/core/database/connection.dart` (`driftDatabase(native: DriftNativeOptions(setup: …))`), with the pure
  function `plainText` in `lib/core/text/plain_text.dart` and the drift `sqlite_functions` build option
  so `search_queries.drift` can call it. No schema change, no sync change, one function shared by SQL and
  Dart; the cost is a scan the tier `CASE` already makes. Per BR-SEARCH-009, no stored column or FTS until
  measured (`ponytail:` ceiling: ~20k cards per search). First plan task is a spike confirming drift_dev 2.35
  accepts the option; if it does not, fall back to stored `front_plain`/`back_plain`/`name_plain`
  columns (schema 13→14, backfill in the migration, sync trigger untouched).
- **DECISION D2: add `MxFieldMessageTone.note`** (info glyph, `onSurfaceVariant` ink) to `MxFieldMessage` for V6.
  Recommended over reusing `warning`: DESIGN.md reserves warning for a refusal or limit, and a duplicate is
  neither.
- **DECISION D3: add `NoteKeys.cardListSelection`** (`lib/core/notes/note_keys.dart`). One constant on the
  existing `dismissed_note` store; no new table.
- **DECISION D4: `AppIcons.starterDecks` → `Icons.library_add_outlined`**, distinct from `newCards`.
- **DECISION D5 (export memory, 3.54): page-by-page CSV/TSV and a 20,000-card XLSX cap (recommended)** over
  a hard refusal above 20,000 (which would block portability) or doing nothing (OOM on low-end phones).
- **DECISION D6 (Trash, 3.26): "Select all" without an "Empty Trash" button (recommended).** A second
  irreversible entry point adds no capability: select all, then Delete, names the count and confirms.
- **DECISION D7 (editor chrome): the flag moves from the app bar into the form, and the footer Cancel goes.**
  Amends ruling P4a-L6 and the footer of screens 08/09. Recommended: the flag is a draft field and reads as
  one; the ✕/Back already exits through the same guard.

Nothing else touches `lib/core/` or `lib/shared/` apart from copy keys.

## 5. Business-rule changes

Docs are Vietnamese; paths under `docs/features/`.

- `search/rules/BR-SEARCH-002-mot-ham-chuan-hoa-dung-chung.md` (V5). New rule text: "Cả câu truy vấn lẫn dữ
  liệu MUST đi qua hàm chuẩn hoá chính `foldText`: trim, hạ chữ theo Unicode của Dart, case-only, giữ dấu. MUST có
  đúng một hàm thứ hai, `plainText`: NFD, bỏ dấu kết hợp U+0300–U+036F, đ→d, rồi NFC, áp trên dạng đã fold; nó chỉ
  quyết định bậc dự phòng 'khớp bỏ dấu' (BR-SEARCH-004), không bao giờ bậc 1–3. SQL MUST NOT dùng `lower()` hay
  `COLLATE NOCASE`; `plainText` vào SQL qua hàm do app đăng ký, không qua bảng dịch ký tự trong SQL."
- `search/rules/BR-SEARCH-004-ba-bac-khop.md` → "Bốn bậc khớp": đúng toàn bộ, tiền tố, chứa, rồi bỏ dấu; bậc bỏ
  dấu chỉ cho kết quả không có bậc 1–3 ở trường nào; bậc của card vẫn là bậc tốt nhất.
- `search/data.md`: the "Chuẩn hoá" and "Thứ tự" paragraphs ("giữ dấu" gains "kết quả bỏ dấu xếp sau").
- `search/usecases/UC-SEARCH-001-…md`: idle and no-result copy; new alternate flow **A5 — Tìm theo tag** (tag mode of
  §3.4: cards only, exact tag, no highlights); acceptance line for the plain tier.
- `tags/usecases/UC-TAG-001-…md`: "Find cards" is the row tap and opens A5 of UC-SEARCH-001 instead of a text search.
- `card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md`: A4 ("giữ tag, xoá trống các ô còn lại"); A6 loses "hoặc dùng
  action **Select** trên app bar" (never built; the one-time note teaches long-press); new **A10 — Gợi ý trùng mặt
  trước** (V6: ghi chú không chặn, chỉ ở form tạo).
- `trash/usecases/UC-TRASH-001-…md`: A6 filter gains "Sắp hết hạn"; new alternate "Chọn tất cả".
- Not changed: BR-TRASH-009 (retention), BR-TAG-008 (the delete keeps the links-only rule; only its wording on screen).

## 6. Testing

TDD per row: write the failing test, then the fix. Windows runs go through `run_tests.sh`; goldens only in Linux.

| Cluster | Test files (existing, extended unless "new") | Review Focus |
|---|---|---|
| 3.1 | `deck_level_screen_test`, `create_root_deck_dialog_widget_test`, `deck_name_dialog_widget_test`, `deck_sort_filter_sheet_test`, `deck_action_sheet_test`, `deck_row_widget_test`; new `deck_reorder_availability_test` | Name of 200 chars with the Due filter on; create while a sort hides the new deck; create from the sub-deck dialog at level 10; Reorder with exactly 2 decks and a Due filter; "{n} sub-decks" at 320 dp |
| 3.2 | `deck_algorithm_screen_test`, `deck_reset_dialog_test`, `starter_library_screen_test` | Locked deck with no `firstAnsweredAt` date (null); reset dialog with an open session; starter with a suggested algorithm the person then changes |
| 3.3 | `search/data/search_cards_test`, `search_decks_test`, `search_pages_test`, `search_cursor_test`, `search_screen_controller_test`, `library_search_screen_test`; new `plain_text_test` | "hoc" with exact, prefix and plain hits across a page boundary (cursor stable); Hangul and `đ`/`Đ`; a term that is accent-free in the data ("hoc") and accented in the query ("học"); fast typing (no skeleton flash); Trash rows never in the plain tier |
| 3.4 | `tags_screen_test`, `tag_actions_controller_test`, `search_*` (tag mode); new `search_tagged_cards_test` | Tag "verb" with a card tagged "adverb" (must not appear); tag whose only cards are in the Trash; Done pressed 100 ms after typing a name that would merge; rename onto a case variant; delete a tag with 0 cards |
| 3.5 | `trash_screen_test`, `trash_selection_test`, `trash_controller_test`, new `trash_labels_test` | Clock 5 minutes behind `deletedAt`; entry with 2 h left; Select all with the filter on All and nothing picked; two blocked purges; Expiring chip when the last expiring entry is restored |
| 3.6 | `card_list_section_test`, `card_row_test`, `card_list_state_test`, `card_list_flag_retry_test`, `card_selection_test` | Search no-match with a tag filter and a status filter on; list error while 3 cards are selected (selection and bulk bar survive); deck of exactly 1 card (no selection note); narrowed list with 0 hits |
| 3.7 | `card_editor_screen_test`, `card_editor_save_test`, `card_editor_draft_test`, `card_detail_screen_test`, `card_history_scroll_test`; new `card_front_duplicate_test` | Front differing only in case or NFC form; duplicate in the Trash (must not warn); save-and-continue with tags then Back (not dirty, no discard dialog); edit save that only changes the flag; Trash from a dirty editor; card with history in cycle 1 only vs cycles 1–2 |
| 3.8 | `card_import_screen_test`, `import_step_tracker_test`, `import_result_skipped_test`, `card_export_sheet_test`, `card_export_controller_test`, new `build_export_paging_test` | Export of exactly 1,000 / 1,001 / 20,001 cards; selection export with gone ids; import result with 0 skipped; XLSX row at 20,001 cards; mapping with all columns "Not imported" |

## 7. Goldens

Default text scale only (owner rule). Moved (regenerate in Linux, review page before merge):

- 01: `library_decks`, `library_sort`, `library_deck_open`, `library_empty` (strip, meta wrap, sheet edge);
  02: `library_algorithm_locked`, `library_algorithm_unlocked`, `library_algorithm_reset`;
  03: `starter_list`, `starter_choose`, `starter_adding`, `starter_add_failed`.
- 04: `search_empty_query`, `search_results`, `search_no_results`; 05: `tags_loaded`, `tags_empty`, `tags_sheet`,
  `tags_rename_merge`, `tags_del`; 06: `trash_all`, `trash_selection`, `trash_purge_blocked`.
- 07: `card_list`, `card_selection`, `card_list_bulk_failed`; 08/09: `card_editor_create`, `card_editor_errors`,
  `card_editor_draft`, `card_editor_create_keyboard`, the edit goldens; 10: `card_detail_top`, `card_detail_history`.
- 11: `import_source`, `import_mapping`, `import_mapping_no_header`, `import_preview`, `import_partial`,
  `import_too_large`, `import_preview_failed`; 12: `export_deck`, `export_failed`, `export_stale`.

New goldens: `library_create_deck` (labelled algorithm field), `search_results_plain`, `tags_tagged_cards`,
`trash_expiring`, `card_list_select_note`, `card_list_narrowed`, `card_editor_duplicate_note`,
`card_detail_cycles`, `import_mapped_chips`.

## 8. Detail files, WBS, out of scope

- Detail files and index rows: `docs/shared/ui/screen-handoff/01…12-*.md` and `00-index.md`. The Copy and Layout
  sections of 01, 02, 04, 05 and 06 also correct existing drift (e.g. 01's create-dialog copy describes
  descriptions the code never had). `DESIGN.md`: the field-note tone (D2).
- WBS: `docs/wbs_FE.md` row FE-D30 "UI hardening SP3: thư viện và thẻ — tìm bỏ dấu, tag-only, Thùng rác, soạn thẻ"; set done only after the
  gate and the Linux goldens are green.
- Out of scope: SP2b (2.26–2.48), SP4's Fill judge (V5's other half), large text scales, two-pane layouts,
  the launcher icon, the toast replacement rule (R7), an "Empty Trash" button (D6), a stored accent column or
  FTS (BR-SEARCH-009), syncing anything new.

## Owner decisions (2026-10-03, `AskUserQuestion`)

- **D1 (V5):** SQLite function `plain_text` (`lib/core/text/plain_text.dart`, drift
  `sqlite_functions`); first task is the spike; fall back to `*_plain` columns only if
  drift rejects the option.
- **D2, D3, D4:** approved — `MxFieldMessageTone.note`, `NoteKeys.cardListSelection`,
  `AppIcons.starterDecks` → `Icons.library_add_outlined`.
- **D5:** stream CSV/TSV page by page; cap XLSX at 20,000 cards.
- **D6:** "Select all" only; no "Empty Trash" button.
- **D7:** the flag moves into the form (amends P4a-L6) and the footer Cancel goes.
