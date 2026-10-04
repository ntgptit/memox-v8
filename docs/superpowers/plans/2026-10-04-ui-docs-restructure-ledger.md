# UI docs restructure — migration ledger

Seeded by `python3 tools/docs/ledger.py seed`; outcomes are written by hand.
An outcome is one of: moved → `<path relative to docs/>`; superseded → <ID or ruling>;
dropped — <reason>, approved <YYYY-MM-DD>; pending → <SCR id> (…) while the target
spec is not written. `check.py --ledger` verifies them and fails on pending.

## shared/ui/screen-handoff/00-index.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/00-index.md:1` <!-- Hand-written screen index. --> |  |
| `shared/ui/screen-handoff/00-index.md:3` # MemoX screen index |  |
| `shared/ui/screen-handoff/00-index.md:5` Every screen of the app. Each detail file records the screen's layout, its state |  |
| `shared/ui/screen-handoff/00-index.md:10` ## Status values |  |
| `shared/ui/screen-handoff/00-index.md:12` - **built:** the app has the screen and its detail file describes it. |  |
| `shared/ui/screen-handoff/00-index.md:13` - **out of V8:** belongs to a sub-project after V8.0 (`PRODUCT.md`, deferred). |  |
| `shared/ui/screen-handoff/00-index.md:15` ## Screens |  |
| `shared/ui/screen-handoff/00-index.md:17` \| # \| Screen \| States \| FE item \| Status \| Detail \| |  |
| `shared/ui/screen-handoff/00-index.md:19` \| 01 \| Deck list · recursive \| 22 \| FE-A1 \| built \| [01-deck-list.md](01-deck-li |  |
| `shared/ui/screen-handoff/00-index.md:20` \| 02 \| Review algorithm & reset \| 9 \| FE-A4 \| built \| [02-review-algorithm.md](0 |  |
| `shared/ui/screen-handoff/00-index.md:21` \| 03 \| Starter decks \| 10 \| FE-B4 \| built \| [03-starter-decks.md](03-starter-dec |  |
| `shared/ui/screen-handoff/00-index.md:22` \| 04 \| Library search \| 5 \| FE-A1, FE-A10 \| built \| [04-library-search.md](04-li |  |
| `shared/ui/screen-handoff/00-index.md:23` \| 05 \| Tags \| 12 \| FE-B2 \| built \| [05-tags.md](05-tags.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:24` \| 06 \| Trash \| 15 \| FE-B1 \| built \| [06-trash.md](06-trash.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:25` \| 07 \| Card list \| 15 \| FE-A2 \| built \| [07-card-list.md](07-card-list.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:26` \| 08 \| Card create \| 9 \| FE-A2 \| built \| [08-card-create.md](08-card-create.md) |  |
| `shared/ui/screen-handoff/00-index.md:27` \| 09 \| Card edit \| 9 \| FE-A2 \| built \| [09-card-edit.md](09-card-edit.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:28` \| 10 \| Card detail \| 7 \| FE-A2 \| built \| [10-card-detail.md](10-card-detail.md) |  |
| `shared/ui/screen-handoff/00-index.md:29` \| 11 \| Card import \| 16 \| FE-B3 \| built \| [11-card-import.md](11-card-import.md) |  |
| `shared/ui/screen-handoff/00-index.md:30` \| 12 \| Card export \| 9 \| FE-B3 \| built \| [12-card-export.md](12-card-export.md) |  |
| `shared/ui/screen-handoff/00-index.md:31` \| 13 \| Study home \| 9 \| FE-A8, SB-U1 \| built \| [13-study-home.md](13-study-home. |  |
| `shared/ui/screen-handoff/00-index.md:32` \| 14 \| Study entry \| 9 \| FE-A6, FE-A7 \| built \| [14-study-entry.md](14-study-ent |  |
| `shared/ui/screen-handoff/00-index.md:33` \| 15 \| Study options \| 7 \| FE-A3 \| built \| [15-study-options.md](15-study-option |  |
| `shared/ui/screen-handoff/00-index.md:34` \| 16 \| Study · Browse \| 1 \| FE-A6 \| built \| [16-study-browse.md](16-study-browse |  |
| `shared/ui/screen-handoff/00-index.md:35` \| 16a \| Study · Self-assess (`self_assess`) \| — \| FE-A6 \| built \| [16a-study-sel |  |
| `shared/ui/screen-handoff/00-index.md:36` \| 17 \| Study · Match \| 1 \| FE-A6 \| built \| [17-study-match.md](17-study-match.md |  |
| `shared/ui/screen-handoff/00-index.md:37` \| 18 \| Study · Guess \| 1 \| FE-A6 \| built \| [18-study-guess.md](18-study-guess.md |  |
| `shared/ui/screen-handoff/00-index.md:38` \| 19 \| Study · Recall \| 3 \| FE-A6 \| built \| [19-study-recall.md](19-study-recall |  |
| `shared/ui/screen-handoff/00-index.md:39` \| 20 \| Study · Fill \| 3 \| FE-A6 \| built \| [20-study-fill.md](20-study-fill.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:40` \| 21 \| Session summary \| 10 \| FE-A6 \| built \| [21-session-summary.md](21-session |  |
| `shared/ui/screen-handoff/00-index.md:41` \| 22 \| Progress \| 8 \| FE-A9 \| built \| [22-progress.md](22-progress.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:42` \| 23 \| Settings \| 12 \| FE-A3, SB-U1, FE-B8, FE-B9 \| built \| [23-settings.md](23- |  |
| `shared/ui/screen-handoff/00-index.md:43` \| 24 \| Daily reminder \| 9 \| FE-B5, FE-B6 \| built \| [24-daily-reminder.md](24-dai |  |
| `shared/ui/screen-handoff/00-index.md:44` \| 25 \| Theme \| 3 \| FE-A3 \| built \| [25-theme.md](25-theme.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:45` \| 26 \| Language \| 3 \| FE-A3 \| built \| [26-language.md](26-language.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:46` \| 27 \| Sync \| 7 \| SB-U1 \| built \| [27-sync.md](27-sync.md) (shape brief in the s |  |
| `shared/ui/screen-handoff/00-index.md:47` \| 28 \| Monitoring (admin only) \| 15 \| FE-B8 \| built \| [28-monitoring.md](28-moni |  |
| `shared/ui/screen-handoff/00-index.md:48` \| 29 \| Welcome (first launch) \| 2 \| FE-B9 \| built \| [29-welcome.md](29-welcome.m |  |
| `shared/ui/screen-handoff/00-index.md:49` \| 30 \| Sign-in, merge sheet, transition layer \| 13 \| FE-B9, FE-B10 \| built \| [30 |  |
| `shared/ui/screen-handoff/00-index.md:50` \| 31 \| Code \| 2 \| FE-B9 \| built \| [31-code.md](31-code.md) \| |  |
| `shared/ui/screen-handoff/00-index.md:51` \| 32 \| Account \| 9 \| FE-B10 \| built \| [32-account.md](32-account.md) (shape in t |  |
| `shared/ui/screen-handoff/00-index.md:52` \| 33 \| Users (admin) \| 5 \| FE-B11 \| built \| [33-users.md](33-users.md) (shape in |  |
| `shared/ui/screen-handoff/00-index.md:54` ## Rules shared by every screen |  |
| `shared/ui/screen-handoff/00-index.md:56` - **Controls without their feature** are hidden. The Library root's "Coming soon |  |
| `shared/ui/screen-handoff/00-index.md:58` - **Data displays without their data** are hidden, never drawn empty: an empty m |  |
| `shared/ui/screen-handoff/00-index.md:60` - **Delete moves to the Trash** (UC-TRASH-001). "Move to Trash", "Recoverable fo |  |
| `shared/ui/screen-handoff/00-index.md:63` - **Copy** is written in English first; Vietnamese is added to the ARB with the |  |

## shared/ui/screen-handoff/01-deck-list.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/01-deck-list.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:3` # 01 · Deck list | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:5` One recursive screen for the Library root (`/decks`) and any open deck | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:8` ## Layout — root | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:10` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:12` \| App bar \| `MxAppBar` (large) \| "Library", then Starter decks (sparkles, screen | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:13` \| Search \| `MxSearchField`, trigger mode \| Hint "Search decks". A tap pushes `/d | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:14` \| Due strip \| `MxCard` (hero) + `MxIconTile` + `MxWorkloadBreakdownLine` \| Bolt | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:15` \| Section header \| `MxListSectionHeader` + `MxChipTrigger` \| "N DECKS"; pill "Ma | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:16` \| Rows \| `MxCard` per deck, 8 apart \| 44 px `MxIconTile` (layers = holds decks, | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:17` \| FAB \| `MxFab` \| "New deck". \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:19` ## Layout — open deck | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:21` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:23` \| App bar \| `MxAppBar` \| Back, deck name, `⋮` (the deck's action sheet). \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:24` \| Breadcrumb \| `MxBreadcrumb` \| Library › ancestors › deck. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:25` \| Summary card \| `MxCard` (hero) \| For a deck holding sub-decks: `MxMasteryDonut | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:26` \| List \| as root \| Header "Sub-decks" with the sort pill: the summary card state | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:27` \| FAB \| `MxFab` \| "New sub-deck"; none at level 10 (BR-DECK-001), and none on an | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:28` \| By content type \| — \| `unset`: empty state with the two create choices (BR-DEC | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:30` ## Action sheet | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:32` `MxBottomSheet` headed by the deck's name, and `MxActionSheetCommandRow`s withou | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:35` - **Root deck:** Open deck · Study this deck → screen 14 · Rename · Study option | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:39` - **Sub-deck:** Open · Study this deck → screen 14 · Rename · | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:44` ## Sort & filter sheet | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:46` One `MxBottomSheet`, "Sort & filter": | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:48` - Sort by (`MxOptionRow`): Manual order "Drag decks to arrange them" · Date adde | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:51` - Toggle row (`MxSettingsRow` + `MxToggle`): "Only decks with due cards" / "Hide | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:53` - "Sort by" is an `MxListSectionHeader`; Done is the sheet's `MxSheetActions` fo | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:54` - Button "Done". | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:56` ## States | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:58` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:60` \| rootLoaded \| `library_decks_light.png` \| `library_decks_dark.png` \| Every row | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:61` \| rootLoading \| no golden \| no golden \| Skeletons in the row's shape; header kep | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:62` \| rootEmpty \| `library_empty_light.png` \| `library_empty_dark.png` \| "Create dec | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:63` \| rootError \| no golden \| no golden \| "Couldn't load your library" with Retry. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:64` \| rootSearch \| no golden \| no golden \| The field is a trigger: a tap opens scree | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:65` \| rootSortFilter \| `library_sort_light.png` \| `library_sort_dark.png` \| Progress | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:66` \| rootDueEmpty \| no golden \| no golden \| "Nothing due right now" with "Show all | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:67` \| rootOverflow \| `library_deck_actions_light.png` \| `library_deck_actions_dark.p | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:68` \| rootCreate \| no golden \| no golden \| The create dialog; no algorithm chosen up | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:69` \| rootRename \| no golden \| no golden \| The rename dialog. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:70` \| rootDelete \| `library_deck_delete_light.png` \| `library_deck_delete_dark.png` | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:71` \| rootTrashed \| `library_deck_trashed_light.png` \| `library_deck_trashed_dark.pn | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:72` \| deckLoaded \| `library_deck_open_light.png` \| `library_deck_open_dark.png` \| Th | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:73` \| deckEmpty \| `library_deck_unset_light.png` \| `library_deck_unset_dark.png` \| ` | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:74` \| deckMaxDepth \| no golden \| no golden \| No FAB. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:75` \| deckLoading \| no golden \| no golden \| Skeletons under the summary card. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:76` \| deckError \| no golden \| no golden \| Error state with Retry. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:77` \| deckNotFound \| no golden \| no golden \| "This deck is no longer here", Back to | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:78` \| deckOverflow \| no golden \| no golden \| The sub-deck action sheet. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:79` \| deckMove \| no golden \| no golden \| The deck picker; only decks with the same r | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:80` \| deckDelete \| no golden \| no golden \| As rootDelete. \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:81` \| deckTrashed \| no golden \| no golden \| As rootTrashed. Moving the open deck ste | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:82` Other goldens: `library_reorder_light.png` / `library_reorder_dark.png` (reorder | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:84` ## Rulings | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:86` - **Critique 2026-09-30 part 1, R9 (amends P4a-L9):** an `unset` deck has no FAB | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:87` - **FE-B1 D7:** an Undo happens where the item was deleted. A refused Undo says | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:89` - **Owner ruling R4** (deck mastery spec, §9 row 141): the < 34% mastery band us | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:91` - **§9 rows 142, 145 (FE-C1):** the mastery bar's track is `surfaceContainerLow` | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:92` - **Library spec D7:** Reorder is in the root deck's action sheet too. | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:93` - **C-L6:** the action sheet reads only `DeckView`, which carries no counts, so | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:95` - **M3 review 2026-09-28 D2:** reorder mode keeps one `MxCard` per deck, 8 apart | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:97` - **Critique 2026-09-30:** a row's meta and the due strip's breakdown wrap at la | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:98` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:99` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:100` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the due | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:102` ## Pending | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:104` \| Element \| Shown as \| Waits for \| | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:106` \| Level-10 banner "This is level 10, the deepest a deck can go…" over sub-decks | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:108` ## Copy | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:110` - Root: "Library" · "Search decks" · "{n} cards due" · "{n} decks" · "Manual" · | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:111` - Row: "{n} due" · "{n} sub-deck(s)" · "{n} cards" · "Empty · add cards or a sub | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:112` - Summary: "Mastered · {algorithm}". | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:113` - Sort: "Progress" · "Least mastered first". | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:114` - First launch: "Start your library" · "A deck groups the sub-decks that hold yo | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:115` - Error: "Couldn't load your library" · "Your data is safe on this device. Try a | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:116` - Due filter, none: "Nothing due right now" · "No deck has cards waiting. The ne | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:117` - Create: "New deck" · "Holds sub-decks; sub-decks hold cards." · "Name" · "Revi | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:118` - Rename: "Rename deck" · "Only the name changes — sub-decks, cards and schedule | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:119` - Not found: "This deck is no longer here" · "It was moved to Trash or deleted w | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:120` - Move to Trash: "Move to Trash" · "Recoverable for 30 days" · "Move this deck t | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:121` - Move: "Move “{name}” to…" · "Its {n} sub-decks and {n} cards come along, sched | moved → `screens/spec/SCR-DECK-001-deck-list.md` |
| `shared/ui/screen-handoff/01-deck-list.md:122` - Sort & filter: as in "Sort & filter sheet". | moved → `screens/spec/SCR-DECK-001-deck-list.md` |

## shared/ui/screen-handoff/02-review-algorithm.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/02-review-algorithm.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:3` # 02 · Review algorithm & reset | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:5` `/decks/deck/:deckId/algorithm`, root decks only (BR-DECK-025). Replaces the sch | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:8` ## Layout | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:10` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:12` \| App bar, breadcrumb \| `MxAppBar`, `MxBreadcrumb` \| Back, "Review algorithm"; L | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:13` \| Lock strip \| `MxCard` + `MxIconTile` \| Unlocked: plain card, open lock on prim | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:14` \| ALGORITHM \| `MxListSectionHeader`, `MxCard` of two `MxOptionRow`s \| The curren | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:15` \| Note \| `MxNote`, above the options (critique 2026-09-30) \| Unlocked: "Switchin | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:16` \| START OVER \| `MxListSectionHeader`, `MxCard`, `MxButton` (outline) \| "Reset le | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:18` Algorithm descriptions: | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:20` - **Eight boxes:** "Remembered moves a card up a box and forgotten sends it back | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:21` - **SM-2:** "Intervals adapt as you grade each card again, hard, good or easy in | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:23` ## States | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:25` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:27` \| locked \| `library_algorithm_locked_light.png` \| `library_algorithm_locked_dark | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:28` \| unlocked \| `library_algorithm_unlocked_light.png` \| `library_algorithm_unlocke | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:29` \| switching \| no golden \| no golden \| Reached **after** the confirmation dialog | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:30` \| switched \| no golden \| no golden \| Snackbar "Switched to {algorithm} · every c | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:31` \| switchFailed \| no golden \| no golden \| Danger banner with Retry (UC-DECK-002 E | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:32` \| resetConfirm \| `library_algorithm_reset_light.png` \| `library_algorithm_reset_ | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:33` \| resetting \| no golden \| no golden \| The confirm spins and Cancel is off (M3 re | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:34` \| resetDone \| no golden \| no golden \| Then the unlocked state. \| | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:35` \| nothingToLose \| no golden \| no golden \| When `hasProgressToLose` is false (UC- | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:37` Beyond the states above: | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:39` - **Switch confirmation:** `MxDialog`, non-destructive: "Switch to {algorithm}?" | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:40` - **Refused because the tree just locked:** the locked state and the reason (UC- | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:41` - **Loading, load error, not a root or gone:** skeleton, `MxErrorState`, the not | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:43` ## Reset dialog copy | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:45` - Title "Reset learning progress?" | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:46` - With progress: "This starts cycle {n+1} for {deck} and its {count} cards." | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:47` - Kept: "Decks, sub-decks, cards, tags, notes, and every past answer (labelled c | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:48` - Lost: "Every card's schedule, due date and progress; the open session. All {co | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:49` - Nothing to lose: "Nothing has been studied in this cycle yet, so there is noth | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:50` - "Algorithm for the new cycle": "Keep {current}" · "Switch to {other}" | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:51` - Buttons: "Cancel" · "Reset and start cycle {n+1}" (warning tone); while it run | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:52` - Done: "Cycle {n+1} started · {count} cards are new again" | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:53` - Switch failed: "Couldn’t switch." "The deck still uses {algorithm}." · "Retry" | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:55` ## Rulings | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:57` - **UC-DECK-002 steps 3–4:** choosing the other algorithm asks for confirmation | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:58` - **M3 review 2026-09-28 B2:** while a reset runs the confirm button spins (`MxS | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:59` - **Spec A10 (WCAG 2.2 AA):** "Kept" is written in `statusMasteredInk` (4.5:1) o | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:60` - **D-L1:** a switch refused because the tree just locked shows the locked state | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:61` - **Critique 2026-09-30:** each algorithm is described in one sentence. | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:62` - **Critique 2026-09-30 tone pass (final review):** the reset dialog's Kept tile | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `shared/ui/screen-handoff/02-review-algorithm.md:63` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |

## shared/ui/screen-handoff/03-starter-decks.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/03-starter-decks.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:3` # 03 · Starter decks | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:5` The templates bundled with the build, each copied into the library as a deck of | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:10` ## Entry points | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:12` - **The Library's app bar:** the sparkles action pushes `/decks/starter`, full s | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:14` - **The empty Library:** "Browse starter decks" under "Create deck" (screen 01 | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:17` ## Layout | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:19` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:21` \| App bar \| `MxAppBar` (content) \| Back and "Starter decks". \| | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:22` \| Note \| `MxNote` (flask), dismissible \| "These decks are practice fixtures for | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:23` \| A card per template \| `MxCard` + `MxIconTile` (sparkles) + `MxBadge` \| The tit | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:24` \| Algorithm sheet \| `MxBottomSheet` + `MxOptionRow` ×2 + `MxSheetActions` \| "Add | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:26` Language names come from a small table of the tags the build ships: English, | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:30` ## States | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:32` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:34` \| list \| `starter_list_light.png` \| `starter_list_dark.png` \| The badge and the | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:35` \| choose \| `starter_choose_light.png` \| `starter_choose_dark.png` \| — \| | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:36` \| adding \| `starter_adding_light.png` \| `starter_adding_dark.png` \| The options | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:37` \| added \| `starter_added_light.png` \| `starter_added_dark.png` \| The sheet close | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:38` \| alreadyPresent \| `starter_already_present_light.png` \| `starter_already_presen | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:39` \| secondCopy \| `starter_second_copy_light.png` \| `starter_second_copy_dark.png` | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:40` \| addFailed \| `starter_add_failed_light.png` \| `starter_add_failed_dark.png` \| T | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:41` \| loading \| `starter_loading_light.png` \| `starter_loading_dark.png` \| The note, | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:42` \| none \| `starter_none_light.png` \| `starter_none_dark.png` \| "Create a deck" re | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:43` \| loadFailed \| `starter_load_failed_light.png` \| `starter_load_failed_dark.png` | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:45` Goldens: `test/features/starter_decks/presentation/goldens/starter_{list,choose, | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:47` ## Rulings | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:49` - **Critique P3:** "In library" follows the title and moves to the next line whe | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:50` - **Critique P2a:** "Suggests {algorithm}" drops below the add button, whole, ra | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:51` - **D13 (FE-A3 C8):** the add button shows the spinner alone, no "Adding…" text. | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:52` - **UI-base row 125:** loading shows the note, then generic skeleton rows. | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:53` - **Critique 2026-09-30:** "Add to library" is primary; "Add another copy", for | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:54` - **Critique 2026-09-30:** the fixture note has a close button ("Hide this note" | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:55` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:56` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:58` ## Copy | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `shared/ui/screen-handoff/03-starter-decks.md:60` "Starter decks" · "These decks are practice fixtures for development and testing | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |

## shared/ui/screen-handoff/04-library-search.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/04-library-search.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:3` # 04 · Library search | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:5` `/decks/search`. UC-SEARCH-001 on `SearchLibraryUseCase`: deck names, both card | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:8` ## Layout | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:10` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:12` \| App bar \| `MxAppBar` with its title-widget slot \| Back, then `MxSearchField` ( | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:13` \| Empty query \| label, `MxCard` of `MxListRow`s, `MxNote` \| No query runs (BR-SE | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:14` \| Searching \| label, skeleton groups \| "Searching…" (no query: the field shows i | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:15` \| Results \| group headers, `MxCard`s of `MxListRow`s \| No header repeats the que | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:16` \| More \| `MxButton` (secondary, block) \| "Load more results" while another page | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:17` \| Footer \| caption \| "Decks first, then cards · case-insensitive, accents matter | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:18` \| No results \| `MxEmptyState` (neutral, compact) \| Search-off glyph; "No matches | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:19` \| Error \| `MxErrorState` \| "Search didn't run" / "Your library is safe on this d | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:20` \| Load more failed \| `MxInlineBanner` (danger) + Retry \| The rows stay; the end | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:22` ## States | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:24` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:26` \| emptyQuery \| `search_empty_query_light.png` \| `search_empty_query_dark.png` \| | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:27` \| loading \| `search_loading_light.png` \| `search_loading_dark.png` \| — \| | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:28` \| results \| `search_results_light.png` \| `search_results_dark.png` \| Colours per | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:29` \| noResults \| `search_no_results_light.png` \| `search_no_results_dark.png` \| — \| | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:30` \| error \| `search_error_light.png` \| `search_error_dark.png` \| — \| | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:31` \| loadMoreFailed \| `search_load_more_failed_light.png` \| `search_load_more_faile | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:33` ## Pending | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:35` Nothing pending since FE-A10. | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:37` ## Rulings | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:39` - **Spec D9 (owner 2026-09-26):** hint rows are read-only with no fill arrow; a | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:40` - **Spec D19:** every result tile is tinted primary and a matched tag is the neu | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:41` - **Spec D22:** every row is one height (`MxListRow`); a card's title is one lin | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:42` - **Spec D26:** group labels are `MxListSectionHeader` without a glyph, with the | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:43` - The match is emphasised with `rowTitleMatch` (primary, 700) and no background | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:44` - The field in the app bar is `MxSearchField` at its 52 input floor inside the 5 | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `shared/ui/screen-handoff/04-library-search.md:45` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |

## shared/ui/screen-handoff/05-tags.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/05-tags.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:3` # 05 · Tags | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:5` The tag catalog: every tag of the library with its active cards, narrowed by a s | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:10` ## Entry points | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:12` - **The Library's app bar:** the tag action pushes `/decks/tags`, full screen on | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:15` ## Layout | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:17` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:19` \| App bar \| `MxAppBar` (content) \| Back and "Tags". \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:20` \| Search \| `MxSearchField` \| "Search tags". It narrows the catalog with the fold | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:21` \| Header \| `MxListSectionHeader` \| "{n} tags" or "No matches", with "A→Z" as pla | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:22` \| Rows \| `MxSection` + `MxListRow` \| A tag tile, the name (one line, ellipsis), | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:23` \| Action sheet \| `MxBottomSheet` + `MxTagChip` + `MxActionSheetCommandRow` ×3 \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:24` \| Rename dialog \| `MxDialog` + `MxTextField` + `MxSheetActions` \| "Rename tag", | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:25` \| Delete dialog \| `MxDialog` + `MxNote` + `MxSheetActions` \| "Delete this tag?", | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:27` "Find cards with this tag" opens the Library search on the tag's name (D11). The | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:31` ## States | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:33` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:35` \| loaded \| `tags_loaded_light.png` \| `tags_loaded_dark.png` \| Tags in the store' | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:36` \| loading \| `tags_loading_light.png` \| `tags_loading_dark.png` \| The search, the | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:37` \| empty \| `tags_empty_light.png` \| `tags_empty_dark.png` \| Only the empty state: | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:38` \| searchEmpty \| `tags_search_empty_light.png` \| `tags_search_empty_dark.png` \| " | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:39` \| sheet \| `tags_sheet_light.png` \| `tags_sheet_dark.png` \| — \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:40` \| rename \| `tags_rename_light.png` \| `tags_rename_dark.png` \| The tag's name in | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:41` \| renameMerge \| `tags_rename_merge_light.png` \| `tags_rename_merge_dark.png` \| " | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:42` \| nameTooLong \| `tags_name_too_long_light.png` \| `tags_name_too_long_dark.png` \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:43` \| del \| `tags_del_light.png` \| `tags_del_dark.png` \| No glyph over the title; th | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:44` \| busy \| `tags_busy_light.png` \| `tags_busy_dark.png` \| — \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:45` \| opError \| `tags_op_error_light.png` \| `tags_op_error_dark.png` \| One sentence, | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:46` \| tagGone \| `tags_tag_gone_light.png` \| `tags_tag_gone_dark.png` \| The gone stat | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:47` \| read error \| — \| — \| (E1, D10) `MxErrorState` "Couldn't load tags" with Retry. | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:48` Other goldens: `tags_read_error_light.png` / `tags_read_error_dark.png` (the tag | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:51` Goldens: `test/features/tags/presentation/goldens/tags_{loaded,loading,empty,sea | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:53` ## Rulings | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:55` - **D15 (AA):** "Merge tags" uses the warning role with its ink. | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:56` - **BE-B2 D6, D8:** the merge target's count is the union of both tags' cards, n | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:57` - **BR-TAG-003, critique P2b:** there is one order (the store's folded order, di | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:58` - **UC-TAG-001 E1, D10:** a read failure shows `MxErrorState` with Retry. | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:59` - Dialogs quote tag names, carry no glyph and are left-aligned (`MxDialog`); toa | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:60` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:61` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:63` ## Copy | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `shared/ui/screen-handoff/05-tags.md:65` "Tags" · "Search tags" · "{n} tags" · "No matches" · "A→Z" · "{n} cards" · | moved → `screens/spec/SCR-TAG-001-tags.md` |

## shared/ui/screen-handoff/06-trash.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/06-trash.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:3` # 06 · Trash | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:5` Everything deleted in the last 30 days, newest first. Each entry can be restored | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:10` ## Entry points | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:12` - **The Library's app bar:** the Trash icon, beside Coming soon (D1). | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:13` - **Toasts:** the toast after several cards move to the Trash, and every refused | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:15` - **Gone states:** the "no longer here" states of an open deck, the card editor | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:18` The Trash is a full-screen task on the root navigator, `/decks/trash`, with no b | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:21` ## Layout | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:23` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:25` \| App bar \| `MxAppBar` \| Back, "Trash" and "Select" (a compact secondary `MxButt | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:26` \| Note \| `MxNote` (history icon), dismissible \| "Kept for 30 days from deletion, | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:27` \| Filters \| `MxFilterChip` × 3 \| All · Cards · Decks, each with its count (A6). | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:28` \| Header \| `MxListSectionHeader` \| "{n} entries · newest first"; while selecting | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:29` \| Rows \| `MxCard` + `MxRowInk` per entry \| The kind's tile (a checkbox while sel | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:30` \| Kind lock \| `MxNote` \| "Cards and decks can't be selected together." \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:31` \| Blocked purge \| `MxInlineBanner` (warning) \| One per batch the last purge skip | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:32` \| Bar \| `MxFooterBar` + `MxActionPair` \| While selecting: "Restore ({n})" (prima | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:33` \| Actions \| `MxBottomSheet` + `MxActionSheetCommandRow` × 2 \| The name and "{kin | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:34` \| Restore \| `MxDeckPickerSheet` \| "Restore “{name}” to…" or "Restore {n} cards/d | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:35` \| Delete for good \| `MxDialog` + `MxSheetActions.custom` \| "Delete {n} cards per | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:36` \| Toasts \| `MxSnackbar` \| "“{name}” restored to {deck}" / "{n} entries restored | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:38` ## States | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:40` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:42` \| all \| `trash_all_light.png` \| `trash_all_dark.png` \| The tile is tinted, and " | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:43` \| cards \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:44` \| decks \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:45` \| actions \| `trash_actions_light.png` \| `trash_actions_dark.png` \| A row tap ope | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:46` \| restoreTarget \| `trash_restore_target_light.png` \| `trash_restore_target_dark. | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:47` \| noTarget \| `trash_no_target_light.png` \| `trash_no_target_dark.png` \| As the m | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:48` \| restored \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:49` \| undoRefused \| no golden \| no golden \| Shown where the item was deleted, with O | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:50` \| selection \| `trash_selection_light.png` \| `trash_selection_dark.png` \| "Restor | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:51` \| purgeConfirm \| `trash_purge_confirm_light.png` \| `trash_purge_confirm_dark.png | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:52` \| purged \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:53` \| youngerInside \| `trash_purge_blocked_light.png` \| `trash_purge_blocked_dark.pn | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:54` \| empty \| `trash_empty_light.png` \| `trash_empty_dark.png` \| — \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:55` \| loading \| no golden \| no golden \| Skeleton rows. \| | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:56` \| error \| `trash_error_light.png` \| `trash_error_dark.png` \| The app's local-fir | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:58` Goldens: `test/features/trash/presentation/goldens/trash_{all,actions,restore_ta | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:60` ## Rulings | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:62` - **Invariant 36 (spec D6):** a blocked restore says "“X” still contains an entr | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:63` - **P3-L8:** a restore target shows its path, as the move sheets do; targets car | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:64` - **BR-TRASH-006:** a deck has its own restore sheet and rule, with "Top level" | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:65` - **E-L3:** "Select" is a compact secondary `MxButton`. | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:66` - **O11:** the no-target state is `MxDeckPickerSheet`'s empty state (the neutral | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:67` - **Spec §6:** a refused restore closes the sheet and shows a toast; the list fo | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:68` - **Owner 2026-09-26 (UI refinements phase 2):** the selection bar reads "Restor | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:69` - **Owner 2026-09-26:** the time left under 3 days is a warning `MxBadge`; the m | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:70` - **Owner 2026-09-26, BR-TRASH-011:** while selecting, the note hides, the other | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:71` - **Critique 2026-09-30:** the retention note has a close button ("Hide this not | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:72` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:74` ## Copy | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:76` - Header: "Trash" · "Select" · "Kept for 30 days from deletion, then removed aut | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:77` - Row: "Card · deleted {ago}" · "Deck · {n} sub-decks · {m} cards · deleted {ago | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:78` - Actions: "Restore…" · "Choose which deck it goes to" · "Delete permanently" · | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:79` - Restore: "Restore “{name}” to…" · "Its schedule, history, flag and tags come b | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:80` - Selection: "Select entries" · "{n} cards selected" · "{m} cards" · "{m} decks" | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:81` - Delete for good: "Delete {n} cards permanently?" · "They disappear for good, t | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `shared/ui/screen-handoff/06-trash.md:82` - Empty and error: "Trash is empty" · "Decks and cards you delete stay here for | moved → `screens/spec/SCR-TRASH-001-trash.md` |

## shared/ui/screen-handoff/07-card-list.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/07-card-list.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:3` # 07 · Card list | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:5` An open deck whose content type is `card`: the card section of `DeckLevelScreen` | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:8` ## Layout | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:10` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:12` \| App bar \| `MxAppBar`, injected by `app/` (spec A14) \| Back, deck name, search | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:13` \| Breadcrumb \| `MxBreadcrumb` \| Library › ancestors › deck; hidden while selecti | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:14` \| Search \| `MxSearchField` \| Revealed by the search action; closing it clears th | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:15` \| Summary card \| `MxCard` (hero) + `MxMasteryDonut` + `MxWorkloadBreakdownLine` | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:16` \| Filters \| `MxFilterChip` \| All · Due · New · Flagged with counts, then Tags wi | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:17` \| Header \| `MxListSectionHeader` + `MxChipTrigger` \| "Cards" while every card of | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:18` \| Rows \| card surface per row, 8 apart \| The checkbox while selecting (no status | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:19` \| Bulk bar \| `MxFooterBar` with five icon buttons \| Move · Flag · Tag · Export ( | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:20` \| FAB \| `MxFab` \| "New card" (#33); hidden while selecting and while search is o | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:22` ## Deck action sheet (`⋮`) | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:24` Study this deck · Rename · Move to another deck · Import cards (screen 11) · Exp | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:27` ## States | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:29` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:31` \| loaded \| `card_list_light.png` \| `card_list_dark.png` \| The Tags chip reads as | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:32` \| empty \| no golden \| no golden \| The deck is unset again (E-L1): screen 01's un | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:33` \| searchEmpty \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:34` \| loading \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:35` \| error \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:36` \| notFound \| no golden \| no golden \| As screen 01 deckNotFound. \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:37` \| deckActions \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:38` \| selection \| `card_selection_light.png` \| `card_selection_dark.png` \| Long-pres | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:39` \| moveTargets \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:40` \| noMoveTarget \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:41` \| bulkFailed \| `card_list_bulk_failed_light.png` \| `card_list_bulk_failed_dark.p | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:42` \| delCard \| `card_list_trash_dialog_light.png` \| `card_list_trash_dialog_dark.pn | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:43` \| delDeck \| no golden \| no golden \| As screen 01 deckDelete. \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:44` \| trashed \| `card_list_trashed_light.png` \| `card_list_trashed_dark.png` \| One c | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:45` Other goldens: `card_list_search_light.png` / `card_list_search_dark.png` (searc | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:48` Not captured: `cardActions` gives way to the card detail: a tap opens it (#35). | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:53` ## Tag filter | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:55` Shaped by Impeccable before the plan (FE-B2 D3, | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:58` - **The sheet:** `MxBottomSheet`, "Filter by tags" over "Show cards with any of | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:63` - **The footer:** "Clear" (empties the choice, stays open; off when nothing is c | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:67` - **Applying:** a card passes with any chosen tag (BR-TAG-004), and with the sta | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:70` - **No card with these tags (A7):** "No cards with these tags" with "Clear tag f | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:72` \| State \| Golden (light) \| Golden (dark) \| | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:74` \| none chosen \| `card_tag_filter_none_light.png` \| `card_tag_filter_none_dark.pn | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:75` \| one chosen \| `card_tag_filter_one_light.png` \| `card_tag_filter_one_dark.png` | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:76` \| several chosen \| `card_tag_filter_several_light.png` \| `card_tag_filter_severa | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:77` \| applied \| `card_tag_filter_applied_light.png` \| `card_tag_filter_applied_dark. | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:78` \| no card (A7) \| `card_tag_filter_no_card_light.png` \| `card_tag_filter_no_card_ | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:80` The goldens are in `test/features/card/presentation/goldens/`. | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:82` ## Rulings | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:84` - **Critique 2026-09-30 part 1:** search hides the summary card and keeps the fi | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:85` - **Move to Trash dialog:** no glyph (`MxDialog` has no glyph slot); the body re | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:86` - **FE-B2 D14 (critique P1b):** Tags is a filter chip, selected while tags are a | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:87` - **BR-DECK-015, E-L1:** an empty card list makes the deck unset again; screen 0 | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:88` - **E-L2:** the flag uses the warning colour; the theme has no streak token. Sup | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:89` - **E-L3:** "Select all" is a compact secondary `MxButton`. | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:90` - **E-L4:** the due chip is an `MxBadge`: overdue warning, today primary, else n | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:91` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:92` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:93` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:94` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the fla | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:96` ## Copy | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:98` - Summary: "Deck progress · {algorithm}" · "{n} of {total} cards mastered" · "Ne | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:99` - Filters and header: "All" · "Due" · "New" · "Flagged" · "Tags" · "Cards" · "Sh | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:100` - Selection: "{n} selected" · "Select all {total}" · "Move" · "Flag" · "Tag" · " | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:101` - Move to Trash: "Move this card to Trash?" / "Move {n} cards to Trash?" · "Reco | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:102` - Empty: "No cards in this deck yet" · "Write your first card, or bring many at | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:103` - Search empty: "No cards match “{term}”" · "Try a different term, or clear the | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:104` - Tag filter: "Tags" · "Filter by tags" · "Show cards with any of the chosen tag | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:105` - Error: "Couldn't open this deck" · "Your data is safe on this device. Try agai | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `shared/ui/screen-handoff/07-card-list.md:106` - Move: "Move {n} cards to…" · "Schedule, history, flags and tags travel with th | moved → `screens/spec/SCR-CARD-001-card-list.md` |

## shared/ui/screen-handoff/08-card-create.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/08-card-create.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:3` # 08 · Card create | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:5` Adding a card to an open `card` deck: `CardEditorScreen.create` → | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:9` ## Layout | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:11` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:13` \| App bar \| `MxAppBar` (content density) \| Close (✕); title "New card". No Save | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:14` \| Deck path \| `DeckContextHeaderWidget` (`MxBreadcrumb`), injected by `app/` (ru | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:15` \| Deck-rejects banner \| `MxInlineBanner` (warning) \| "This deck no longer accept | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:16` \| Front \| `CardFieldWidget` (`MxTextField`, `MxTextFieldVariant.term`) \| Overlin | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:17` \| Back \| `CardFieldWidget` (`MxTextFieldVariant.meaning`) \| Overline "Back · Mea | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:18` \| Optional details \| `CardAddDetailsWidget` disclosure → `CardOptionalFieldsWidg | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:19` \| Tags \| `CardTagEditorWidget` (`CardRemovableTagChipWidget` × n, `MxButton` "Ad | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:20` \| Footer \| `CardEditorFooterWidget` (`MxFooterBar`) \| Caption line; Cancel (`MxB | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:21` \| Discard dialog \| `CardDiscardDialogWidget` (`MxDialog`, `MxSheetActions`) \| "D | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:22` \| Gone state \| `CardGoneWidget` (`MxEmptyState`) \| "This deck is no longer here" | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:24` ## States | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:26` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:28` \| emptyForm \| `card_editor_create_light.png` \| `card_editor_create_dark.png` \| B | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:29` \| valid \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:30` \| details \| no golden \| no golden \| The opened example, hint and pronunciation a | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:31` \| validationErr \| `card_editor_errors_light.png` \| `card_editor_errors_dark.png` | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:32` \| frontTooLong \| no golden \| no golden \| Shown once the front field is touched. | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:33` \| tagLimit \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:34` \| deckRejects \| no golden \| no golden \| Caption "This deck can't take cards now. | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:35` \| saving \| no golden \| no golden \| The button shows only its spinner in place of | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:36` \| saveFailed \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:37` Other goldens: `card_editor_create_keyboard_light.png` / `card_editor_create_key | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:39` Two further states, both built as | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:45` ## Rulings | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:47` - **§9 row 81 (P4a-L7):** the deck chip is not a picker, so a deck that rejects | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:48` - **§9 row 101:** "Add details" has a solid `outlineVariant` edge, 48 tall (touc | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:49` - **§9 row 81 (P4a-L8):** "Add tag" is an outline `MxButton` chip; there is no d | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:50` - **§9 row 81:** `DeckContextHeaderWidget` sits outside the scroll as a persiste | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:51` - **§9 row 46 (plan O2):** while saving, `MxButton` swaps its label for the spin | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:52` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:53` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:55` ## Copy | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:57` - App bar and caption: "New card" · "Front and back are required to save." · "Fi | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:58` - Fields: "Front · Term" · "Back · Meaning" · "Required" · "{count} / {limit}" · | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:59` - Errors: "Add the term to remember." · "The term can be at most 60 characters. | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:60` - Deck rejects: "This deck no longer accepts cards." · "It now holds sub-decks." | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:61` - Tags: "Tags" · "optional · {count} / {limit}" · "Add tag" · "Add" · "Remove {t | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:62` - Footer: "Cancel" · "Save card" · "Retry save" · "Couldn't save card." · "Nothi | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:63` - Discard: "Discard this card?" · "What you typed is not saved." · "Keep editing | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:64` - Gone: "This deck is no longer here" · "It was moved to Trash or deleted while | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `shared/ui/screen-handoff/08-card-create.md:65` - Toast: "Card added". | moved → `screens/spec/SCR-CARD-002-card-create.md` |

## shared/ui/screen-handoff/09-card-edit.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/09-card-edit.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:3` # 09 · Card edit | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:5` Editing a card's content: `CardEditorScreen.edit` → `_EditLoader` → | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:10` ## Layout | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:12` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:14` \| App bar \| `MxAppBar` (content density) \| Back; title "Edit card"; a flag `MxIc | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:15` \| Deck path \| `DeckContextHeaderWidget` \| Library › ancestors › deck › "Edit". \| | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:16` \| History summary \| `CardEditSummaryWidget` (full-bleed `MxCard`, `MxListRow`, ` | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:17` \| Front / Back \| `CardFieldWidget` \| Same fields as create, prefilled from the c | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:18` \| Optional details \| `CardOptionalFieldsWidget` (always open, "Optional details" | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:19` \| Tags \| `CardTagEditorWidget` \| Prefilled tags; same add/remove/limit behaviour | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:20` \| More \| `CardTrashSectionWidget` (`MxCard`, `MxButton` outline "Move to Trash") | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:21` \| Footer \| `CardEditorFooterWidget` \| Cancel + "Save changes" / "Retry save"; da | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:22` \| Move to Trash dialog \| `CardDeleteDialogWidget` (`MxDialog`, `MxNote`, `MxShee | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:23` \| Discard dialog \| `CardDiscardDialogWidget` \| "Discard changes?" / "You edited | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:24` \| Gone state \| `CardGoneWidget` (`MxEmptyState`) \| "This card is no longer here" | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:26` ## States | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:28` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:30` \| loaded \| `card_editor_edit_light.png` \| `card_editor_edit_dark.png` \| — \| | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:31` \| loading \| no golden \| no golden \| A single generic `MxSkeletonList` (4 rows) s | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:32` \| loadError \| no golden \| no golden \| Full-screen `MxErrorState`, "Couldn't load | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:33` \| notFound \| no golden \| no golden \| `CardGoneWidget`; both actions are live now | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:34` \| validationErr \| `card_editor_errors_light.png` \| `card_editor_errors_dark.png` | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:35` \| dirtySaving \| no golden \| no golden \| The button shows only its spinner in pla | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:36` \| saveFailed \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:37` \| discard \| no golden \| no golden \| The body names what was edited ("You edited | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:38` \| delConfirm \| `card_editor_trash_dialog_light.png` \| `card_editor_trash_dialog_ | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:39` Other goldens: `card_editor_more_light.png` / `card_editor_more_dark.png` (the M | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:42` Every state above is built. | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:44` ## Rulings | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:46` - **§9 row 108:** the Move to Trash dialog has no glyph (`MxDialog` has no glyph | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:47` - **§9 row 110:** the dialog reads "Recoverable from Trash for 30 days, with its | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:48` - **§9 rows 80, 28, E-L2:** the flag glyph swaps (`flag` → `flagged`) but never | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:49` - **§9 rows 101, 81 (P4a-L8):** "Add details" has a solid edge, 48 tall; "Add ta | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:50` - **§9 row 81:** `DeckContextHeaderWidget` sits outside the scroll as a persiste | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:51` - **§9 row 46 (plan O2):** while saving, `MxButton` swaps its label for the spin | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:52` - **§9 row 125:** loading is a single generic `MxSkeletonList`, the app-wide con | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:53` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:54` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:55` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:56` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the fla | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:58` ## Copy | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:60` - App bar: "Edit card" · "Flag this card" · "Remove flag" · "Save". | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:61` - History summary: "{status} · {answers}" · "{lapses}" · "due {date}". | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:62` - Fields: same labels, hints and errors as 08-card-create, plus "Optional detail | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:63` - Footer: "Cancel" · "Save changes" · "Retry save" · "Couldn't save changes." · | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:64` - More: "More" · "Move this card to Trash" · "Leaves this deck and can be restor | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:65` - Move to Trash dialog: "Move this card to Trash?" · "Recoverable from Trash for | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:66` - Discard: "Discard changes?" · "You edited {parts}. Leaving now keeps the card | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:67` - Gone: "This card is no longer here" · "It was moved to Trash while you were ed | moved → `screens/spec/SCR-CARD-003-card-edit.md` |
| `shared/ui/screen-handoff/09-card-edit.md:68` - Load error: "Couldn't load this card" · "Nothing was lost. Try again in a mome | moved → `screens/spec/SCR-CARD-003-card-edit.md` |

## shared/ui/screen-handoff/10-card-detail.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/10-card-detail.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:3` # 10 · Card detail | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:5` A card, read-only, pushed over the card list: `CardDetailScreen` (library | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:9` ## Layout | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:11` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:13` \| App bar \| `MxAppBar` (content density) \| Back; title "Card"; trailing compact | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:14` \| Deck path \| `DeckContextHeaderWidget` \| Library › ancestors › deck › "Card"; s | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:15` \| Content \| `CardDetailContentWidget` (`MxCard`, `MxStatusBadge`, `MxTagChip`) \| | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:16` \| Schedule \| `CardScheduleWidget` (`MxCard`, `MxIconTile` × n) \| "Current schedu | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:17` \| History header \| `MxListSectionHeader` \| "History" / "History · newest first". | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:18` \| History list \| `CardHistoryEventWidget` × n (`MxBadge`, `MxCard`), grouped und | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:19` \| Load more \| `MxButton` (secondary, block) or `MxInlineBanner` (danger) on fail | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:20` \| End of history \| Centred caption line \| "Beginning of history · card added {da | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:21` \| Gone state \| `CardGoneWidget` (`MxEmptyState`) \| "This card is no longer here" | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:23` ## States | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:25` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:27` \| loaded \| `card_detail_top_light.png` \| `card_detail_top_dark.png` \| — \| | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:28` \| loadMore \| no golden \| no golden \| A secondary block `MxButton` "Load older hi | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:29` \| loadMoreFailed \| no golden \| no golden \| Retry sits under the message (see Rul | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:30` \| empty \| no golden \| no golden \| `MxEmptyState` (neutral, compact) "Not studied | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:31` \| loading \| no golden \| no golden \| A single generic `MxSkeletonList` (4 rows) r | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:32` \| error \| no golden \| no golden \| Full-screen `MxErrorState`, "Couldn't load thi | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:33` \| notFound \| no golden \| no golden \| `CardGoneWidget` (shared with the editor's | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:34` Other goldens: `card_detail_history_light.png` / `card_detail_history_dark.png` | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:37` Every state above is built. | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:39` ## Rulings | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:41` - **§9 row 89:** the status badge and flag sit above the front/back, full width. | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:42` - **§9 row 86:** history is a plain `MxCard` per event with absolute date and ti | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:43` - **§9 row 90 (amended, critique 2026-09-30 part 3d-2):** the `MxBadge` carries | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:44` - **§9 row 50:** `MxInlineBanner` actions sit under the message. | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:45` - **UC-CARD-002 E1:** the deck path shows only once the card has loaded; the det | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:46` - **§9 row 125:** loading is a single generic `MxSkeletonList`, the app-wide con | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:47` - **§9 row 115:** in-flow cards are `MxCard` at radius 12. | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:48` - The load error uses the app's shared local-first body "Nothing was lost. Try a | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:49` - **Critique 2026-09-30 tone pass, T5:** a history badge (it names the outcome, | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:50` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:51` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:52` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the fla | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:54` ## Copy | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:56` - App bar: "Card" · "Edit". | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:57` - Content: card front, back, "Example sentence" · "Hint" · "Pronunciation" (each | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:58` - Schedule: "Current schedule · Box {box} of {count}" · "Current schedule · SM-2 | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:59` - History: "History" · "History · newest first" · "Cycle {generation} · {schedul | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:60` - History outcomes (badge) and kinds (plain text): "Learning" · "Review" · "Repe | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:61` - Error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `shared/ui/screen-handoff/10-card-detail.md:62` - Gone: "This card is no longer here" · "It was moved to Trash while you were aw | moved → `screens/spec/SCR-CARD-004-card-detail.md` |

## shared/ui/screen-handoff/11-card-import.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/11-card-import.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:3` # 11 · Card import | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:5` A full-screen task above the shell that adds many cards to one deck from a CSV, | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:10` ## Entry points | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:12` - The open deck's `⋮` sheet, "Import cards": a deck that holds cards or is unset | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:14` - The unset deck's third action, "Import cards from a file". | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:16` Route: `/decks/deck/<id>/cards/import`, on the root navigator, so the bottom nav | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:19` ## Layout | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:21` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:23` \| App bar \| `MxAppBar` (content) \| Close; "Import cards", then "Import results" | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:24` \| Deck context \| `DeckContextHeaderWidget`, injected by `app/` \| Library › ances | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:25` \| Step tracker \| `ImportStepTrackerWidget` \| Source · Columns · Preview · Import | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:26` \| 1 · Choose a source \| `MxCard` options (`isSelected`) \| Choose a file · Paste | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:27` \| Source chip \| `MxCard` + `MxIconTile` \| File name, then "{format} · UTF-8 · re | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:28` \| 2 · Map columns \| `MxSection` of `ImportMappingRowWidget` \| "First row is a he | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:29` \| Mapping error \| `MxInlineBanner` (warning) \| Its own row when Term or Meaning | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:30` \| 3 · Preview \| `MxListSectionHeader` + `MxBadge` + `MxSection` \| The title alon | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:31` \| Importing \| `MxCard` + `MxSpinner` \| "Adding {n} cards…". Close and Back do no | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:32` \| Footer \| `MxFooterBar` \| Cancel + the step action (Read and map columns · Prev | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:33` \| Result \| `MxEmptyState` in the outcome's tone + `MxSection` counts + `MxNote` | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:35` ## States | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:37` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:39` \| empty (Source) \| `import_source_light.png` \| `import_source_dark.png` \| Deck c | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:40` \| pasted \| no golden \| no golden \| The paste field uses the body font, not monos | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:41` \| fileSelected \| no golden \| no golden \| The source options give way to the chip | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:42` \| badEncoding \| no golden \| no golden \| Read is locked (E1) and the caption says | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:43` \| emptySheet \| no golden \| no golden \| One copy for a file, a sheet or text with | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:44` \| parsing \| no golden \| no golden \| "Reading your file…" in the source area. \| | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:45` \| mapping \| `import_mapping_light.png` \| `import_mapping_dark.png` \| Only canoni | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:46` \| mappingNoHeader \| `import_mapping_no_header_light.png` \| `import_mapping_no_he | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:47` \| mappingIncomplete \| no golden \| no golden \| The error is a banner of its own, | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:48` \| previewAll \| no golden \| no golden \| Rows stack front over back instead of thr | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:49` \| previewMix \| `import_preview_light.png` \| `import_preview_dark.png` \| As previ | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:50` \| importing \| no golden \| no golden \| Navigation is inert (IT-NAV-012 step 5). \| | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:51` \| success \| no golden \| no golden \| `MxEmptyState`, success tone; no deck name i | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:52` \| partial \| `import_partial_light.png` \| `import_partial_dark.png` \| As success, | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:53` \| none \| no golden \| no golden \| Neutral tone; Import another file · Back to dec | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:54` \| failed \| no golden \| no golden \| `MxEmptyState`, danger tone; Close · Try agai | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:55` \| rejects \| no golden \| no golden \| `MxEmptyState`, warning tone; Close only. \| | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:57` Goldens: `test/features/transfer/presentation/goldens/import_{source,mapping,pre | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:59` ## Back | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:61` Android Back steps back one step and keeps the draft: Preview → Columns → Source | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:64` ## Rulings | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:66` - **Critique 2026-09-30 part 1:** each mapping row shows its column's first valu | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:67` - **Spec §8.2 K1:** once read, the source step collapses to the source chip. | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:68` - **Spec §8.2 K2, UC-TRANSFER-001 step 5:** the preview shows the first 50 rows | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:69` - **Spec §8.2 K3:** each status icon has a semantic label, a mapping error sits | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:70` - **Spec §8.2 K4:** results use `MxEmptyState` in its success, neutral, warning | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:71` - The deck is shown by the deck context header shared with the card editor and d | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:72` - **UC-TRANSFER-001 step 8, ruling 1:** success offers Import another file · Vie | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:73` - **UC-TRANSFER-001:** there is no deck picker, so rejects offer Close only. | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:74` - **Spec D2:** only the six canonical header names map by themselves. | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:75` - Paste field and header cells use the body font; the theme has no monospace rol | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:76` - **Amends spec §5.1:** the file name shows in the chip while the wizard is open | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:77` - **FE-B3 plan 1:** Import is live from the deck actions. | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:78` - **Critique 2026-09-30:** the file helper ("importHelperBody") has a close butt | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:79` - **Critique 2026-09-30 tone pass, T6:** Ready (chip and row mark) is success; t | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:80` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:81` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the res | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:83` ## Copy | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:85` - Steps: "Source" · "Columns" · "Preview" · "Import" · "Step {n} of 4: {name}". | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:86` - Source: "1 · Choose a source" · "Choose a file" · "CSV, TSV or XLSX · UTF-8" · | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:87` - Problems: "This file is not UTF-8" · "This file can’t be read" · "There are no | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:88` - Mapping: "2 · Map columns" · "First row is a header" · "Column {letter}" · "Te | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:89` - Preview: "3 · Preview" · "Ready · {n}" · "Invalid · {n}" · "Duplicate · {n}" · | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:90` - Footer: "Read and map columns" · "Preview rows" · "Import {n} cards" · "Import | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `shared/ui/screen-handoff/11-card-import.md:91` - Result: "Imported" · "Imported with skips" · "Nothing added" · "Import didn’t | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |

## shared/ui/screen-handoff/12-card-export.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/12-card-export.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:3` # 12 · Card export | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:5` A bottom sheet that hands a deck's cards, or the selected ones, to the system sh | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:10` ## Entry points | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:12` - The open deck's `⋮` sheet, "Export cards": a deck of cards only. An unset deck | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:15` - The card list's bulk bar, "Export": the selected cards. The selection stays af | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:18` ## Layout | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:20` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:22` \| Header \| `MxBottomSheet` header \| "Export all {n} cards" and "Every card in {d | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:23` \| Problem \| `MxInlineBanner` \| One banner per problem, above the formats. Danger | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:24` \| Formats \| `MxListSectionHeader` + `MxOptionRow` × 3 \| CSV (default, "Recommend | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:25` \| Content note \| `MxNote` (file icon) \| The six columns; no schedule, no history | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:26` \| Footer \| `MxSheetActions` (sheet form) \| Cancel · "Export {n} cards" with the | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:27` \| Toast \| `MxSnackbar` \| "Handed {n} cards to the system." once the share sheet | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:29` The overline, the banner and the note line up with the title (20 dp). | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:31` ## States | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:33` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:35` \| wholeDeck \| `export_deck_light.png` \| `export_deck_dark.png` \| CSV carries "Re | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:36` \| selection \| no golden \| no golden \| As wholeDeck. \| | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:37` \| preparing \| no golden \| no golden \| Cancel closes the sheet and nothing is sha | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:38` \| handedOver \| no golden \| no golden \| The toast names no file. \| | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:39` \| shareClosed \| no golden \| no golden \| the export sheet stays open, as it was. | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:40` \| failed \| `export_failed_light.png` \| `export_failed_dark.png` \| For a read or | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:41` \| noShareTarget \| no golden \| no golden \| The banner shows the warning glyph. \| | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:42` \| staleSelection \| `export_stale_light.png` \| `export_stale_dark.png` \| The sele | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:43` \| nothingToExport \| no golden \| no golden \| Reached only by a deck emptied betwe | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:45` Goldens: `test/features/transfer/presentation/goldens/export_{deck,failed,stale} | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:47` ## Rulings | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:49` - **Critique 2026-09-30 part 1, R8:** a final problem (stale, empty, no share ta | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:50` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:51` - **UC-TRANSFER-002 A3 (E1):** closing the share sheet keeps the export sheet op | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:52` - **Spec §7, BR-TRANSFER-014 (E2):** the result reads "Handed {n} cards to the s | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:53` - **UC-TRANSFER-002 step 2 (E3):** CSV carries a "Recommended" badge. | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:54` - **UC-TRANSFER-002 E2–E4 (E4):** read and encode failures share "Couldn't prepa | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:55` - **UC-TRANSFER-002 E5 (E5):** "Export cards" appears on a deck of cards only. | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:56` - **UC-TRANSFER-002 step 3 (owner 2026-09-26):** the action reads "Export {n} ca | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:57` - **BR-TRANSFER-013, backend plan C5:** the file name keeps the deck's own lette | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:58` - Banners use their tone glyph; `MxInlineBanner` has no glyph slot. | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:60` ## Copy | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:62` - Header: "Export all {n} cards" · "Every card in {deck}, whatever filter or sea | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:63` - Formats: "Format" · "CSV" · "Comma-separated · opens anywhere" · "TSV" · "Tab- | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:64` - Note: "Six columns: front, back, example, hint, pronunciation, tags. No schedu | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:65` - Actions: "Cancel" · "Export {n} cards" · "Preparing…" · "Try again" · "Close". | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:66` - Problems: "Couldn’t prepare the file" · "Couldn’t hand the file over" · "No ap | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `shared/ui/screen-handoff/12-card-export.md:67` - Toast: "Handed {n} cards to the system." | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |

## shared/ui/screen-handoff/13-study-home.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/13-study-home.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:3` # 13 · Study home | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:5` The Study tab's landing screen (FE-A8): `StudyHomeScreen`, the session Resume | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:9` ## Layout | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:11` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:13` \| App bar \| `MxAppBar` (screen density) \| "Study"; no date (see Rulings). \| | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:14` \| Resume card \| `MxCard` (hero) + `MxIconTile` + new: `MxLinearProgress` \| "Cont | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:15` \| Workload card \| `MxCard` (no hero: a summary, not a door; sessions start per d | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:16` \| Section header \| `MxListSectionHeader` + trailing `MxButton` (compact secondar | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:17` \| Sync notice \| `MxFloatingNotice` in `MxAppShell.notice` + compact `MxButton` \| | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:18` \| Re-auth notice \| `MxFloatingNotice` in the same slot + compact `MxButton` \| FE | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:19` \| Rows \| full-bleed `MxCard` of `MxListRow`s \| leading `MxIconTile` ("layers"); | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:21` ## States | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:23` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:25` \| loaded \| `study_home_loaded_light.png` \| `study_home_loaded_dark.png` \| The he | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:26` \| noResume \| `study_home_no_resume_light.png` \| `study_home_no_resume_dark.png` | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:27` \| zero \| `study_home_zero_light.png` \| `study_home_zero_dark.png` \| Every root d | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:28` \| noDecks \| `study_home_no_decks_light.png` \| `study_home_no_decks_dark.png` \| " | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:29` \| noCards \| `study_home_no_cards_light.png` \| `study_home_no_cards_dark.png` \| R | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:30` \| loading \| `study_home_loading_light.png` \| `study_home_loading_dark.png` \| A t | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:31` \| error \| `study_home_error_light.png` \| `study_home_error_dark.png` \| `MxErrorS | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:32` \| syncRejected \| ![](../../../../test/features/study/presentation/goldens/study_ | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:33` \| syncStale \| ![](../../../../test/features/study/presentation/goldens/study_hom | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:34` \| reauth \| ![](../../../../test/features/account/presentation/goldens/study_home | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:36` Every state above is built. | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:38` **Built (FE-A8, study roadmap P6):** `StudyHomeScreen` in the Study tab's branch | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:40` - Resume runs `ResumeStudySessionUseCase` and opens the session route. A refusal | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:43` - A deck row opens that deck's Study Entry; "Library" and "Go to Library" open t | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:46` - Goldens: | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:49` ## Rulings | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:51` - **BR-STUDY-068 (owner 2026-09-30):** the hero states "{n} cards due" over its | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:52` - **UI-base row 28:** the resume dot and paused tile use primary; there is no st | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:53` - The app bar carries no date: `MxAppBar.actions` takes buttons only and no BR/U | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:54` - **FE-A8 ruling S3:** the dot beside "Continue studying" is static, as on 14; n | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:55` - **FE-A8 ruling S2, BR-STUDY-074:** the zero-workload body says "…tomorrow." on | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:56` - **FE-A6 spec D14:** the zero card's check tile uses the `success` tone; green | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:57` - **FE-A8 ruling S9:** Resume is a primary block `MxButton` with the play glyph; | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:58` - **E-L3:** "Library" is a compact secondary `MxButton`. | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:59` - **BR-STUDY-076:** the hero and row breakdowns wrap between whole terms, never | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:60` - **UI-base ruling O3:** loading uses a two-bar hero skeleton and the standard ` | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:61` - `MxEmptyState` actions carry no glyph. | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:62` - **Account UI spec R2, B5:** the re-auth notice takes the slot over the sync no | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:63` - **SB-U1 (sync status spec R2, UI-base row 143):** a floating sync notice shows | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:64` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:66` ## Accessibility | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:68` - The dot and the glyphs, the workload terms' included, are decorative (no node | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:69` - A deck with no card is shown dimmed and read as a disabled button (S4); every | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:70` - The hero title and "across {n} decks" are plurals (S5). | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:71` - A row's breakdown wraps between whole terms (glyph, count, word and dot stay t | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:73` ## Copy | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:75` - Header: "Study" · "Tuesday, 16 Sep" (dropped). | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:76` - Resume: "Continue studying" · "{kind} · {mode}" e.g. "Review · Self-assess" · | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:77` - Workload: "Waiting for you" · "{n} cards due" · "across {n} decks". | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:78` - Workload, zero: "Nothing due right now" · "Every card is resting. The next one | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:79` - Resume refused: "This session can't be continued any more". | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:80` - Section: "Your decks" · "Library". | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:81` - No decks: "Nothing to study yet" · "Your library is empty. Copy a starter deck | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:82` - No cards: "Your decks have no cards yet" · "Add cards to a sub-deck, or import | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:83` - Re-auth notice (FE-B10): "Your sign-in expired. Your decks are still on this p | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:84` - Sync notice (SB-U1): "{n} changes weren't accepted." (one: "1 change wasn't ac | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `shared/ui/screen-handoff/13-study-home.md:85` - Error: "Couldn't load your study overview" · "Your cards are safe on this devi | moved → `screens/spec/SCR-STUDY-001-study-home.md` |

## shared/ui/screen-handoff/14-study-entry.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/14-study-entry.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:3` # 14 · Study entry | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:5` The Study Entry of an open deck (FE-A6, FE-A7): `StudyEntryScreen`, the choice | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:8` ## Layout | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:10` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:12` \| App bar \| `MxAppBar` (content density) \| Back, deck name (composed by `app/` f | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:13` \| Breadcrumb \| `MxBreadcrumb` \| Library › ancestors › deck. \| | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:14` \| Hero \| `MxCard` (plain, not a hero card: a summary, not a door) + `MxStatTile` | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:15` \| Resume banner \| `MxCard` \| "Session from today" overline with a pulse dot, "{k | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:16` \| Nothing-due state \| `MxEmptyState` (compact, success tone) \| "Nothing to do ri | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:17` \| Learn row \| full-bleed `MxCard` of one `MxListRow` \| "Learn new cards", subtit | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:18` \| Review options \| `MxListSectionHeader` (overline) + full-bleed `MxCard` of `Mx | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:19` \| Inline banners \| `MxInlineBanner` \| `refused` (warning): counts changed since | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:20` \| Footer \| `MxFooterBar` \| A caption line plus one block `MxButton` (primary; ou | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:22` ## Direction sheet (SM-2 only) | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:24` Tapping the footer's Review action on an SM-2 root deck opens `MxBottomSheet` | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:32` ## States | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:34` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:36` \| sm2 \| `study_entry_sm2_light.png` \| `study_entry_sm2_dark.png` \| The hero and | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:37` \| eightBox \| `study_entry_eight_box_light.png` \| `study_entry_eight_box_dark.png | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:38` \| onlyNew \| `study_entry_only_new_light.png` \| `study_entry_only_new_dark.png` \| | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:39` \| nothing \| `study_entry_nothing_light.png` \| `study_entry_nothing_dark.png` \| P | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:40` \| resume \| `study_entry_resume_light.png` \| `study_entry_resume_dark.png` \| The | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:41` \| starting \| `study_entry_starting_light.png` \| `study_entry_starting_dark.png` | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:42` \| refused \| `study_entry_refused_light.png` \| `study_entry_refused_dark.png` \| I | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:43` \| startFailed \| `study_entry_start_failed_light.png` \| `study_entry_start_failed | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:44` \| loading \| `study_entry_loading_light.png` \| `study_entry_loading_dark.png` \| S | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:45` Other goldens: `study_entry_direction_sheet_light.png` / `study_entry_direction_ | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:48` Every state above is built. | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:50` **Built (FE-A6 P2):** all nine states on `sm2`. Learn (the row's button | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:64` ## Accessibility | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:66` - TalkBack reads the app bar, the breadcrumb, the hero (overline, then "New: {n} | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:67` - Single-line text that ellipsizes keeps line-height 1.5 for stacked marks (UI-b | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:68` - While a session opens, the locked footer and options stay in the reading order | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:70` ## Rulings | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:72` - **UC-STUDY-003:** SM-2's direction is chosen in a separate `MxBottomSheet` ope | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:73` - **UI-base row 28, FE-A8 ruling S3:** the resume dot is primary and static, as | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:74` - **FE-A8 H2:** the resume banner carries a `MxLinearProgress` track under its l | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:75` - **Plan R5:** on `refused` the footer is rebuilt from the up-to-date counts and | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:76` - **Plan R6:** while starting, the button spins (`MxButton.isLoading`) and "Star | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:77` - **Plan R7:** "Start review" answers the choice and closes the sheet; the entry | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:78` - **Plan R8:** the SM-2 caption reads "{shown} of {due} due · oldest first". | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:79` - **Plan R9:** each refusal has its own title: nothing due, no new cards, a mode | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:80` - **Critique 2026-09-30 part 1:** while an open session shows, "Continue" is the | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:81` - **FE-A6 P3 ruling C5:** `eightBox` picks the first available mode at first; th | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:82` - The Learn button is the secondary tone with the sparkles glyph. | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:83` - **BR-CARD-002:** direction descriptions name no language ("See the term, recal | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:84` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:85` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:86` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:88` ## Copy | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:90` - Hero: "{algorithm}" · "Up to {n} cards per session" · "New" · "Due" · "{n} of | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:91` - Resume: "Session from today" · "{kind} · {mode} · {n} of {n} cards" · "Continu | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:92` - Nothing: "Nothing to do right now" · "Every card is learned and resting. Cards | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:93` - Learn row: "Learn new cards" · "Browse, then self-assess" (SM-2) / "Browse → m | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:94` - Review options, Eight boxes: "Review · choose how cards are asked" · "Match" " | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:95` - Direction sheet, SM-2: "Review · question direction" · "Term first" "See the t | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:96` - Banners: "Nothing is due any more." "The due cards were reviewed from another | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `shared/ui/screen-handoff/14-study-entry.md:97` - Footer: "Learn {n} new cards" · "Review {n} due cards" · "Starting…" · "Try ag | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |

## shared/ui/screen-handoff/15-study-options.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/15-study-options.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:3` # 15 · Study options | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:5` A root deck's study options, opened from any deck in its tree: its own cards per | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:12` ## Entry points | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:14` - **The deck action sheet (screen 01):** "Study options" / "Cards per session · | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:16` - **Screen 14's app bar:** the sliders icon, "Study options" (D3). | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:18` Both open `/decks/deck/:deckId/options` on the root navigator, with no bottom ba | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:21` ## Layout | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:23` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:25` \| App bar \| `MxAppBar` (content) \| Back and "Study options". \| | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:26` \| Breadcrumb \| `MxBreadcrumb` \| Library › the deck's path › the deck › "Study op | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:27` \| Note \| `MxNote` (layers) \| The screen's one note (critique 2026-09-30): "These | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:28` \| Unreadable override \| `MxInlineBanner` (warning) \| "This deck's options could | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:29` \| Toggle \| `MxSection` + `MxSettingsRow` + `MxToggle` \| "Use app defaults"; on: | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:30` \| Options \| `MxSection` \| "App defaults (read-only here)" or "This deck"; "Cards | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:31` \| Card limit message \| `MxFieldMessage` (error) \| "Enter a number from 1 to 200" | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:32` \| Footer \| `MxFooterBar` + `MxButton` \| "Save", enabled only for a valid change | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:33` \| Toast \| `MxSnackbar` \| "Saved · applies to the next session". \| | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:35` Save runs Use app defaults when the toggle is on and the root had its own option | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:38` ## States | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:40` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:42` \| override \| `study_options_override_light.png` \| `study_options_override_dark.p | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:43` \| defaults \| `study_options_defaults_light.png` \| `study_options_defaults_dark.p | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:44` \| invalid \| `study_options_invalid_light.png` \| `study_options_invalid_dark.png` | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:45` \| saving \| `study_options_saving_light.png` \| `study_options_saving_dark.png` \| | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:46` \| saved \| `study_options_saved_light.png` \| `study_options_saved_dark.png` \| — \| | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:47` \| saveFailed \| `study_options_save_failed_light.png` \| `study_options_save_faile | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:48` \| loading \| `study_options_loading_light.png` \| `study_options_loading_dark.png` | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:49` \| gone \| — \| — \| (spec §6) a deck gone to the Trash shows "This deck is no longe | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:50` \| read error \| — \| — \| `MxErrorState` with Retry and no invented value. \| | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:52` Goldens: `test/features/settings/presentation/goldens/study_options_{override,de | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:54` ## Rulings | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:56` - `MxNote` carries one plain string, so the root's name is not bold. | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:57` - **UC-SETTINGS-001 E1:** "Enter a number from 1 to 200" sits under the stepper | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:58` - **D9:** Save is enabled only for a valid change; while saving the button spins | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:59` - **Spec §6, UI-base row 129:** a gone root shows the Library's gone state with | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:60` - **M3 review 2026-09-28 E1, E2:** new-card order is one `MxSettingsRow` + `MxSe | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:61` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:62` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:64` ## Copy | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `shared/ui/screen-handoff/15-study-options.md:66` "Study options" · "These options belong to {root} and every sub-deck in it. Chan | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |

## shared/ui/screen-handoff/16-study-browse.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/16-study-browse.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:3` # 16 · Study · Browse | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:5` The first stage of every learning session, for both algorithms (BR-MODE-003, | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:10` ## Layout | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:12` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:14` \| Top bar \| `MxStudyTopBar` \| See [Shared by the session screens](#shared-by-the | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:15` \| Context line \| new: `SessionContextLine` (feature-local, deliberately not a sh | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:16` \| Card \| `MxCard`, full-bleed, feature-local two-pane layout (`StudyFaceCard` is | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:17` \| Navigation \| swipe on the card, and a "Next card" button (`StudyCtaRow`, criti | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:18` \| Footer hint \| new: `SessionFooterHint` (feature-local) \| "Swipe for next or ba | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:20` ## Shared by the session screens | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:22` Common to Browse, Match, Guess, Recall and Fill (17–20). | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:24` - **`MxStudyTopBar`.** Close icon exits the session (see Exit/abandon below). | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:34` - **Exit / abandon.** The close icon, system Back and Guess's blocked-question | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:39` - **Round behaviour (Match, Guess, Recall, Fill only).** These four run in | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:50` - **"Result after commit."** The UI shows a turn's outcome only after its | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:54` - **The unit stays on screen between turns.** The card being answered stays | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:59` - **Keyboard / IME.** Only `fill` (20-study-fill.md) takes typed input; every | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:61` - **`self_assess`.** See | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:63` - **Icon colour guard.** The `Icon(color:)` guard forbids inline glyph colours | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:67` ## Accessibility | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:69` - TalkBack reads the top bar (close, mode, "{done} of {total}"), the context lin | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:70` - Card faces wrap and never ellipsize; Korean and Vietnamese with stacked marks | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:71` - Swipes have accessible actions on the card: "Next card" and, when an earlier c | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:72` - Edges (FE-A6 spec D20): the hint does not change; a right swipe on the round's | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:74` ## States | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:76` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:78` \| default \| `study_browse_light.png` \| `study_browse_dark.png` \| — \| | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:79` Other goldens: `study_browse_looking_back_light.png` / `study_browse_looking_bac | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:82` Not captured: the swipe-back preview of an earlier card in the round | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:85` **Built (FE-A6 P1c):** `StudyBrowseWidget` inside `StudySessionScreen`. Looking | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:91` ## Rulings | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:93` - **Owner ruling 2026-09-27; IT-NAV-010, IT-CONT-004:** the close icon and syste | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:94` - The card follows the finger without a tilt while dragged, and stays still with | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:95` - Pronunciation uses the detail role of the body face; V8's typography has one f | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:96` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:97` - **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-desig | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:99` ## Copy | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:101` - Context line: "{deck} · Learning · stage {n} of {total}". | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `shared/ui/screen-handoff/16-study-browse.md:102` - Footer hint: "Swipe for next or back · nothing is graded" / "Vuốt để sang hoặc | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |

## shared/ui/screen-handoff/16a-study-self-assess.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/16a-study-self-assess.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:3` # 16a · Study · Self-assess | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:5` The `self_assess` session: `sm2`'s review mode, and the second stage of an `sm2` | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:10` ## Job | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:12` A learner on an `sm2` deck, one-handed, in a short gap in the day, grades how we | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:17` ## Layout | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:19` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:21` \| Top bar \| `MxStudyTopBar` \| Close, mode badge "Self-assess", counter "{n} / {t | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:22` \| Context line \| as 16–20 \| "{deck} · Review · Self-assess" (learning session: " | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:23` \| Prompt card \| the study face card (as 19's term card) \| The prompt side for th | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:24` \| Answer card \| the study face card, answer tone \| Hidden until revealed (BR-MOD | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:25` \| Action area, before reveal \| primary block `MxButton` \| "Show answer". \| | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:26` \| Action area, after reveal \| four `MxButton`s in one row, new: `StudyGradeRow` | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:28` ## Behaviour | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:30` - **Reveal:** tapping the card or "Show answer" does the same thing. Revealing w | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:31` - **Grade:** one tap commits the turn and advances to the next card, with no con | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:32` - **Again:** the card comes back after at least three other cards, or at the end | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:33` - **Leaving:** Close and system Back follow the shared exit of 16–20. Everything | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:34` - **Resume:** a resumed session re-opens on the current card unrevealed (BR-STUD | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:35` - **Motion:** the answer card fades and slides in under the prompt (fade-through | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:37` ## Interval preview | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:39` - For a **scheduled** turn (the card's first answer in this session), each grade | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:40` - For a **relearning** turn, the schedule does not move (BR-SRS-016, BR-SRS-017) | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:41` - Format: under 30 days "{n}d"; under a year "{n}mo" (days / 30, rounded); from | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:42` - Needs a backend addition in FE-A6: a read-only preview of the four next interv | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:44` ## States | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:46` \| State \| V8 \| | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:48` \| prompt \| Prompt card and "Show answer"; the answer is hidden. \| | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:49` \| revealed \| Both cards and the grade row; previews on a scheduled turn. \| | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:50` \| relearning \| As revealed, without previews. \| | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:51` \| saving \| The grade row is locked on the tapped grade, with no spinner under 30 | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:52` \| saveFailed \| The session ends as `failed` and the summary (21, Save error) ope | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:53` \| stale \| A reset or algorithm change elsewhere invalidates the session on the n | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:54` Other goldens: `study_self_assess_prompt_light.png` / `study_self_assess_prompt_ | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:56` The goldens `study_self_assess_*` in `test/features/study/presentation/goldens/` | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:59` **Built (FE-A6 P2):** `StudySelfAssessWidget` in the session route's mode switch | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:75` ## Rulings | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:77` - **FE-A6 P2 plan R1:** the mode badge and context line read "Self-assess", as t | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:78` - **Plan R2:** the recessed answer face is always laid out, with a still placeho | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:79` - **Plan R3:** while the grade is written the row takes no tap and draws no chan | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:80` - **Plan R4:** the interval preview is read when the card is served, so the grad | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:81` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:82` - **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-desig | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:83` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the foo | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:85` ## Accessibility | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:87` - TalkBack reads the prompt, then "Show answer". After the reveal, focus moves t | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:88` - Stacked diacritics in either card follow the single-line rule where a line is | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:89` - Touch targets are at least 48 × 48, with 8 between the grades. | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:91` ## Anti-goals | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:93` - No colour-coded rainbow of four grades, and no new rating tokens. | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:94` - No swipe-to-grade, no auto-advance timer, and no per-answer toast or confetti. | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:95` - No editing a card mid-session (as 19 and 20). | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:97` ## Copy | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:99` - "Self-assess" (see Rulings) · "Show answer" · "Again" · "Hard" · "Good" · "Eas | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `shared/ui/screen-handoff/16a-study-self-assess.md:100` - TalkBack: "{grade}, next in {interval}". | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |

## shared/ui/screen-handoff/17-study-match.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/17-study-match.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:3` # 17 · Study · Match | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:5` A round-based graded stage: `eight_box` only — `sm2` never runs `match` | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:12` ## Layout | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:14` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:16` \| Top bar \| `MxStudyTopBar` \| Indigo, as every mode (3c-2 R8); see the shared se | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:17` \| Context line \| `SessionContextLine` \| "{deck} · {Learning/Review} · round {n}" | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:18` \| Board \| grid, up to 10 tiles (5 pairs); new: `MatchBoardTile` (feature-local; | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:19` \| Footer hint \| `SessionFooterHint` \| "Tap a term and its meaning, in either ord | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:21` ## States | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:23` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:25` \| default \| `study_match_board_light.png` \| `study_match_board_dark.png` \| — \| | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:26` Other goldens: `study_match_wrong_light.png` / `study_match_wrong_dark.png` (the | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:28` Not captured: the tile's `idle`/`selected`/`matched` micro-states and the | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:32` **Built (FE-A6 P3):** `StudyMatchWidget` in the session route's mode switch: the | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:38` ## Rulings | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:40` - **FE-A6 spec D14 (P3 ruling C1):** a matched tile uses the `success` semantic; | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:41` - **P3 ruling C7:** during a wrong pair's flash the footer hint reads "Not a mat | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:42` - **BR-STUDY-063, BR-STUDY-070:** a wrong pair flashes the error tone on both ti | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:43` - **BR-STUDY-060, BR-STUDY-062:** a wrong pair keeps its row `pending` for this | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:44` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:45` - **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-desig | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:46` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the foo | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:48` ## Accessibility | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:50` - TalkBack reads the terms first, then the meanings (P3 ruling C8); each tile re | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:51` - Each outcome is announced when its write commits: "Matched", or the wrong-pair | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:52` - The board scrolls once it outgrows the screen at large text, and a soft fade o | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:53` - A word too wide for its tile is drawn just small enough to stay whole; tiles w | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:54` - A tile eases into its tone, surface and ink together (standard duration; at on | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:56` ## Copy | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:58` - Context line: "{deck} · {Learning/Review} · round {n}". | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:59` - Footer hint: "Tap a term and its meaning, in either order" · "Not a match — th | moved → `screens/spec/SCR-STUDY-005-study-match.md` |
| `shared/ui/screen-handoff/17-study-match.md:60` - TalkBack: "Term: {text}" · "Meaning: {text}" · "{tile}, selected" · "{tile}, m | moved → `screens/spec/SCR-STUDY-005-study-match.md` |

## shared/ui/screen-handoff/18-study-guess.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/18-study-guess.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:3` # 18 · Study · Guess | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:5` A round-based graded stage: `eight_box` only (BR-MODE-004). One term, exactly | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:12` ## Layout | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:14` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:16` \| Top bar \| `MxStudyTopBar` \| Indigo, as every mode (3c-2 R8); see the shared se | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:17` \| Context line \| `SessionContextLine` \| "{deck} · Review · round {n}". \| | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:18` \| Prompt \| new: `StudyFaceCard` (feature-local; `MxCard`-based, never promoted t | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:19` \| Options \| 5 rows, new: `GuessOptionRow` (feature-local) \| Lettered A–E badge + | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:20` \| Footer hint \| `SessionFooterHint` \| "Answer shown — the correct option is high | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:22` ## States | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:24` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:26` \| default \| `study_guess_idle_light.png` \| `study_guess_idle_dark.png` \| — \| | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:27` Other goldens: `study_guess_right_light.png` / `study_guess_right_dark.png` (ans | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:29` Not captured: the pre-tap idle appearance of the five options is an | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:32` **Built (FE-A6 P3):** `StudyGuessWidget` in the session route's mode switch: the | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:39` ## Rulings | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:41` - **FE-A6 spec D14 (P3 ruling C1):** the right option uses the `success` semanti | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:42` - **BR-STUDY-040 (P3 ruling C2):** a question that cannot be built shows "This q | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:43` - **P3 ruling C6:** with TalkBack on, the answered state waits on a "Next" butto | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:44` - **BR-STUDY-042:** before the pick the footer hint reads "Only your first pick | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:45` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:46` - **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-desig | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:47` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the foo | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:49` ## Accessibility | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:51` - Each option reads "Option {letter}: {meaning}"; once answered, "…, correct" or | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:52` - The outcome is announced when its write commits: "Correct", or "Wrong. The ans | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:53` - The options scroll with the prompt once they outgrow the screen at large text, | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:54` - A term word too wide for the prompt is drawn just small enough to stay whole; | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:55` - The options ease into their tones, surface and ink together (standard duration | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:57` ## Copy | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:59` - Context line: "{deck} · Review · round {n}". | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:60` - Prompt overline: "What is this?". | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:61` - Footer hint: "Only your first pick counts" (before the pick) · "Answer shown — | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:62` - Blocked: "This question can't be shown" · "Its options could not be built. Clo | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |
| `shared/ui/screen-handoff/18-study-guess.md:63` - TalkBack: "Option {letter}: {meaning}" · "Correct" · "Wrong. The answer is {me | moved → `screens/spec/SCR-STUDY-006-study-guess.md` |

## shared/ui/screen-handoff/19-study-recall.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/19-study-recall.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:3` # 19 · Study · Recall | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:5` A round-based graded stage: `eight_box` only (BR-MODE-004). The term is | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:13` ## Layout | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:15` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:17` \| Top bar \| `MxStudyTopBar` \| Indigo, as every mode (3c-2 R8). \| | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:18` \| Context line \| `SessionContextLine` \| "{deck} · Review · round {n}". \| | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:19` \| Turn clock \| new: `RecallCountdownBar` (feature-local; distinct from `MxStudyT | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:20` \| Term face \| `StudyFaceCard` (label "Term") \| The prompt; always visible. \| | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:21` \| Meaning face \| `StudyFaceCard` (`role: answer`) \| Blurred placeholder before r | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:22` \| CTA row \| new: `StudyCtaRow` (feature-local) \| `countingDown`: one "Show the m | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:23` \| Footer hint \| `SessionFooterHint` \| Varies by state; see Copy. \| | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:25` ## States | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:27` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:29` \| countingDown \| `study_recall_counting_light.png` \| `study_recall_counting_dark | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:30` \| revealed \| `study_recall_revealed_light.png` \| `study_recall_revealed_dark.png | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:31` \| timedOut \| `study_recall_timed_out_light.png` \| `study_recall_timed_out_dark.p | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:33` **Built (FE-A6 P4):** `StudyRecallWidget` in the session route's mode switch, ov | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:43` ## Rulings | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:45` - **BR-STUDY-032, BR-STUDY-033, BR-STUDY-066:** the ending has two branches: a s | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:46` - **FE-A6 spec D14 (P4 ruling V2):** the clock's fill and caption are a neutral | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:47` - **M3 review 2026-09-28 F2:** the clock track is 4dp, the app's thin track. | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:48` - **P2 face-label fix:** the answer face carries its "Meaning" label in flow, as | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:49` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:50` - **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-desig | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:51` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the foo | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:53` ## Accessibility | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:55` - The clock is one node: its caption, with "{n} seconds left" as its value. It i | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:56` - A timeout is announced when its write commits: "Time is up. Counted as forgot. | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:57` - Under Remove animations the clock's fill steps once a second and the meaning a | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:58` - At large text the faces scroll inside and the two self-check buttons stack (C4 | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:59` - **Open for the owner:** the 20-second turn (BR-STUDY-031) is the same for Talk | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:61` ## Copy | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:63` - Context line: "{deck} · Review · round {n}". | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:64` - Clock caption: "Time to recall" (`countingDown`) · "Revealed with time left" ( | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:65` - Meaning tag: "Counted as forgot" (`timedOut`). | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:66` - CTAs: "Show the meaning" · "Forgot" · "Remembered" · "Continue". | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |
| `shared/ui/screen-handoff/19-study-recall.md:67` - Footer hint: "Recall the meaning before the time runs out" (`countingDown`) · | moved → `screens/spec/SCR-STUDY-007-study-recall.md` |

## shared/ui/screen-handoff/20-study-fill.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/20-study-fill.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:3` # 20 · Study · Fill | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:5` A round-based graded stage: `eight_box` only (BR-MODE-004), and only for | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:13` ## Layout | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:15` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:17` \| Top bar \| `MxStudyTopBar` \| Indigo, as every mode (3c-2 R8). \| | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:18` \| Context line \| `SessionContextLine` \| "{deck} · Review · round {n}". \| | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:19` \| Prompt face \| `StudyFaceCard` \| The card's meaning. \| | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:20` \| Answer face \| `StudyFaceCard` (`role: answer`); the typed text itself: `MxText | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:21` \| Hint row \| inline row inside the answer face, shown only in `hint`, its line r | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:22` \| CTA row \| `StudyCtaRow` \| `input`: "Show hint" (only if the card has a hint) + | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:23` \| Footer hint \| `SessionFooterHint` \| Varies by state; see Copy. \| | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:25` ## Keyboard / IME | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:27` The system keyboard opens for `input`/`hint` and the CTA row sits above it; | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:35` ## States | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:37` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:39` \| input \| `study_fill_input_light.png` \| `study_fill_input_dark.png` \| No edit b | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:40` \| hint \| `study_fill_hint_light.png` \| `study_fill_hint_dark.png` \| "Show hint" | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:41` \| wrong \| `study_fill_wrong_light.png` \| `study_fill_wrong_dark.png` \| With the | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:43` Not captured: the correct-answer path has no dedicated visual — the turn | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:46` **Built (FE-A6 P4):** `StudyFillWidget` in the session route's mode switch. The | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:55` ## Rulings | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:57` - **P4 ruling V1:** the struck-through wrong answer uses the `error` ink, as Gue | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:58` - **BR-STUDY-059, BR-STUDY-069 (P4 ruling V10):** the wrong tag and footer read | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:59` - **P4:** the prompt uses the study passage role at 16, and both faces carry the | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:60` - No card can be edited mid-session, so the prompt face has no edit button. | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:61` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:62` - **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-desig | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:64` ## Accessibility | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:66` - The field reads "Your answer"; the hint row reads "Hint: {hint}"; the struck-t | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:67` - A wrong answer is announced when its write commits: "Wrong. The answer is {ter | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:68` - With the keyboard open the shell resizes above it, so Check and the footer sta | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:70` ## Copy | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:72` - Context line: "{deck} · Review · round {n}". | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:73` - CTAs: "Show hint" · "Check" · "Continue". | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:74` - Wrong tag: "Wrong · comes back next round" (see Rulings). | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |
| `shared/ui/screen-handoff/20-study-fill.md:75` - Footer hint: "Type the term for this meaning, then check" (`input`) · "Using t | moved → `screens/spec/SCR-STUDY-008-study-fill.md` |

## shared/ui/screen-handoff/21-session-summary.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/21-session-summary.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:3` # 21 · Session summary | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:5` The terminal screen of a study session: shown once `StudySessionView.status` lea | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:9` ## Layout | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:11` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:13` \| App bar \| `MxAppBar` (content density; with no leading control its title start | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:14` \| Hero \| `MxCard` (hero) + `MxIconTile` (large, tone-coloured) + `MxStatTile` × | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:15` \| Facts \| `MxListSectionHeader` + `MxCard` (full-bleed) + `MxListRow` × 3 \| "Thi | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:16` \| End note \| `MxNote` \| One calm info line, only for the states that need it. \| | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:17` \| Footer \| `MxFooterBar` + `MxButton` × 2 \| Outline "Study this deck" (hidden on | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:18` \| Loading \| `MxSkeleton` \| Hero and fact-row shapes while the summary is read. \| | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:20` ## States | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:22` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:24` \| loaded \| `summary_review_light.png` \| `summary_review_dark.png` \| `completed`, | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:25` \| learning \| `summary_learning_light.png` \| `summary_learning_dark.png` \| `compl | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:26` \| large \| `summary_large_light.png` \| `summary_large_dark.png` \| `completed` at | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:27` \| leftEarly \| `summary_left_early_light.png` \| `summary_left_early_dark.png` \| ` | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:28` \| interrupted \| `summary_interrupted_light.png` \| `summary_interrupted_dark.png` | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:29` \| reset \| `summary_reset_light.png` \| `summary_reset_dark.png` \| `invalidated`/` | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:30` \| schedulerChanged \| `summary_scheduler_changed_light.png` \| `summary_scheduler_ | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:31` \| saveError \| `summary_save_error_light.png` \| `summary_save_error_dark.png` \| ` | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:32` \| loading \| no golden \| no golden \| — \| | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:33` Other goldens: `summary_content_deleted_light.png` / `summary_content_deleted_da | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:36` `contentDeleted` (`invalidated`/`content_deleted`) is reachable since the Trash | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:40` **Built (FE-A6 P1c):** every state above but `loading`, drawn by `SessionSummary | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:48` ## Accessibility | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:50` - TalkBack reads the title, then the hero (title, body, then each stat as one no | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:51` - Touch targets are at least 48 × 48; the two footer buttons keep 8 between them | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:53` ## Nothing answered | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:55` A session that ended before its first turn shows the hero without stats and no F | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:58` ## Rulings (FE-A5) | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:60` - **Critique 2026-09-30 part 3c-1 (spec `2026-09-30-critique-fixes-part3c1-desig | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:62` - `stale_generation` never reaches this screen: the write is refused, the sessio | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:65` - "Study this deck" opens Study entry (14); both ship in FE-A6. | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:66` - The app bar title uses the content bar's title role; the hero glyph is `MxIcon | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:67` - Fact rows are `MxListRow`; the wrong-turns sub-line wraps in the note role in | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:68` - `SessionSummary` carries "answered" and "total turns" (FE-A6) for the hero's t | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:69` - **Critique 2026-09-30:** the wrong-turns value reads "{wrong} of {total}" ("{w | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:70` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:71` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** "Wrong | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:73` ## Copy | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:75` - App bar: "Session summary". | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:76` - Hero titles: "Review finished" · "Learning finished" · "You left early" · "Ses | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:78` - Hero bodies: "You reviewed {n} cards. Their next due dates are set." · | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:87` - Facts: "This session" · "Cards that finished learning" / "Cards reviewed" · "K | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:89` - End note: "Nothing was lost — the answers are in the history." (`schedulerChan | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `shared/ui/screen-handoff/21-session-summary.md:90` - Footer: "Study this deck" · "Done" · "Done returns you to the deck." · "Loadin | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |

## shared/ui/screen-handoff/22-progress.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/22-progress.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:3` # 22 · Progress | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:5` The Progress tab: what was studied today and over the last seven days, the curre | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:10` ## Entry points | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:12` - **The bottom navigation:** the Progress tab opens the library level, `/progres | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:13` - **A deck row:** opens that deck's level, `/progress/:deckId`, under the tab ba | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:15` - **The breadcrumb of a deck's level:** "Progress" returns to the library level; | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:18` ## Layout | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:20` The library level, top to bottom: | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:22` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:24` \| App bar \| `MxAppBar` (screen) \| "Progress". \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:25` \| Today \| `MxCard` \| The overline "Today", the day's card-days, and "{l} learnin | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:26` \| Streak \| `MxCard` \| One tile, "Current" (the flame in the `streak` colour, "{n | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:27` \| Range \| `MxSegmentedTray` (wide) \| "Last 7 days" · "Last 30 days", directly ab | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:28` \| List \| `MxListSectionHeader` + `MxCard` + `MxListRow`s \| "By deck" (the range | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:29` \| Note \| `MxNote` \| A quiet range: "Nothing studied in the last 7 days. Switch t | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:30` \| Footer line \| text \| "Read-only · resets change nothing here" (Today states th | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:32` A deck's level: the app bar with Back and the deck's name, the breadcrumb "Progr | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:37` Switching the range reads nothing (BR-PROGRESS-003). The numbers follow every wr | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:40` ## States | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:42` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:44` \| loaded (Last 7 days) \| `progress_week_light.png` \| `progress_week_dark.png` \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:45` \| month (Last 30 days) \| `progress_month_light.png` \| `progress_month_dark.png` | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:46` \| held \| `progress_held_light.png` \| `progress_held_dark.png` \| — \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:47` \| lost \| `progress_lost_light.png` \| `progress_lost_dark.png` \| The note names t | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:48` \| deck \| `deck_progress_deck_light.png` \| `deck_progress_deck_dark.png` \| "Whole | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:49` \| never \| `progress_never_light.png` \| `progress_never_dark.png` \| "Start studyi | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:50` \| loading \| `progress_loading_light.png` \| `progress_loading_dark.png` \| The scr | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:51` \| error \| `progress_error_light.png` \| `progress_error_dark.png` \| With Retry, u | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:52` \| quiet range \| — \| — \| (UC-PROGRESS-002 A3) the note under the list. \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:53` \| no decks \| — \| — \| (A2) only "No decks yet · Create a deck in the Library and | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:54` \| no sub-decks \| — \| — \| (A1) the total row and its note. \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:55` \| deck gone \| — \| — \| (E2) "This deck is no longer here" with Back, no Retry (UI | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:56` Other goldens: `deck_progress_leaf_light.png` / `deck_progress_leaf_dark.png` (a | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:59` Goldens: `test/features/progress/presentation/goldens/progress_{week,month,held, | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:61` ## Rulings | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:63` - **UC-PROGRESS-001 step 4, UC-PROGRESS-002 step 1, D10:** the range tray sits d | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:64` - **BR-PROGRESS-001, D2:** the list has a total row with the four numbers, no he | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:65` - **Critique P2, D11:** an idle deck row keeps full contrast and reads "No activ | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:66` - **UC-PROGRESS-001 A2, D1:** never studied shows the placeholders plus "Start s | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:67` - **UI-base row 125:** loading shows the screen's own skeleton (Today, Streak an | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:68` - **UC-PROGRESS-002 A1–A3, E2:** quiet range, no deck, leaf and gone states are | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:69` - **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:70` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:71` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:72` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** every d | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:74` ## Copy | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `shared/ui/screen-handoff/22-progress.md:76` "Progress" · "Today" · "{l} learning · {r} reviewing · a card counts once per da | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |

## shared/ui/screen-handoff/23-settings.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/23-settings.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:3` # 23 · Settings | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:5` The Settings tab: the app-wide study defaults, the Theme and Language pages, and | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:11` ## Entry points | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:13` - **The Settings tab** of the bottom bar, `/settings`. It replaces the tab's pla | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:14` - **Debug builds only:** the app bar's gallery icon opens the component gallery. | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:16` The Theme and Language rows open screens 25 and 26 on the root navigator, with n | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:19` ## Layout | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:21` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:23` \| App bar \| `MxAppBar` \| "Settings"; the gallery icon in debug builds. \| | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:24` \| Account \| `MxSection` + `MxSettingsRow` \| FE-B9, first: "Account". An anonymou | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:25` \| Study defaults \| `MxSection` + `MxSettingsRow` × 2 \| "Cards per session" / "1 | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:26` \| Card limit message \| `MxFieldMessage` (error) \| "Enter a number from 1 to 200" | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:27` \| App \| `MxSection` + `MxSettingsRow` × 3 \| "Theme" with the choice ("Follows th | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:28` \| Sync \| `MxSection` + `MxSettingsRow` \| SB-U1: "Sync", one row with the cloud-s | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:29` \| Admin \| `MxSection` + `MxSettingsRow` × 2 \| FE-B8, FE-B11: "Admin", then "Moni | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:30` \| Reset \| `MxSection` + `MxSettingsRow` (`isAction`: it opens a dialog, so no ch | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:31` \| Reset dialog \| `MxDialog` + `MxNote` + `MxSheetActions.custom` \| "Reset app op | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:32` \| Toasts \| `MxSnackbar` \| "Saved"; "Couldn't save cards per session. Still {n}." | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:34` The card limit is saved once a change settles: 600 ms after the last step, a hol | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:37` ## States | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:39` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:41` \| loaded \| `settings_loaded_light.png` \| `settings_loaded_dark.png` \| Theme is a | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:42` \| loading \| `settings_loading_light.png` \| `settings_loading_dark.png` \| Three s | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:43` \| saving \| `settings_saving_light.png` \| `settings_saving_dark.png` \| The steppe | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:44` \| saved \| `settings_saved_light.png` \| `settings_saved_dark.png` \| — \| | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:45` \| invalidLimit \| `settings_invalid_limit_light.png` \| `settings_invalid_limit_da | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:46` \| saveFailed \| `settings_save_failed_light.png` \| `settings_save_failed_dark.png | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:47` \| resetConfirm \| `settings_reset_confirm_light.png` \| `settings_reset_confirm_da | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:48` \| resetDone \| `settings_reset_done_light.png` \| `settings_reset_done_dark.png` \| | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:49` \| syncSynced \| ![](../../../../test/features/settings/presentation/goldens/setti | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:50` \| syncFailed \| ![](../../../../test/features/settings/presentation/goldens/setti | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:51` \| syncRejected \| ![](../../../../test/features/settings/presentation/goldens/set | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:52` \| account \| ![](../../../../test/features/account/presentation/goldens/settings_ | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:53` \| account, signed in \| ![](../../../../test/features/account/presentation/golden | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:54` \| account, re-auth \| ![](../../../../test/features/account/presentation/goldens/ | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:55` \| admin rows \| ![](../../../../test/features/account/presentation/goldens/settin | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:56` \| read error \| — \| — \| (UC E3) `MxErrorState` "Couldn't open Settings" with the | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:59` Goldens: `test/features/settings/presentation/goldens/settings_{loaded,loading,s | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:61` ## Rulings | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:63` - **D2 (owner), UI-base row 124:** Theme is a row naming the choice and opens sc | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:64` - **UC-SETTINGS-001 E1:** "Enter a number from 1 to 200" sits under the stepper | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:65` - **D6 (owner), UI-base row 126:** the stepper takes −/+, a hold that repeats, a | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:66` - **UI-base row 125, UC E3:** loading is three section-shaped skeleton cards (pa | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:67` - **UI-base row 127:** tray options stack when their labels do not fit. | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:68` - **ADR-015, SB-U1 (owner rulings R1, R5):** a Sync section with one row opens s | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:69` - **UI-base row 128:** the tile sits beside the label on a row with a wide contr | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:70` - **Account UI spec §5.5, R2, P3b plan ruling 1:** the attached account opens sc | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:71` - **ADR-018 §8, monitoring spec §3.1, users spec U2:** the Admin section holds M | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:72` - **Critique 2026-09-30 tone pass, T4:** the Sync row's tile is success when syn | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:73` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:74` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:76` ## Copy | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:78` - Study defaults: "Study defaults" · "Cards per session" · "1 to {max} · default | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:79` - App: "App" · "Theme" · "Follows the system setting" · "Light" · "Dark" · "Lang | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:80` - Reset: "Reset" · "Reset app options" · "Theme, language, study defaults, remin | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:81` - Sync (SB-U1): "Sync" · "{n} changes weren't accepted" · "Couldn't sync · no co | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:82` - Admin (FE-B8, FE-B11): "Admin" · "Monitoring" · "Logs of the app and the serve | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:83` - Toasts: "Saved" · "Couldn't save cards per session. Still {n}." · "Couldn't sa | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `shared/ui/screen-handoff/23-settings.md:84` - Error: "Couldn't open Settings" · "Nothing was lost. Try again in a moment." · | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |

## shared/ui/screen-handoff/24-daily-reminder.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/24-daily-reminder.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:3` # 24 · Daily reminder |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:5` The daily reminder: turn it on or off, choose its time, and see what the notific |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:12` ## Entry points |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:14` - Screen 23, App section, row "Daily reminder" ("Off" or "On · {HH:mm}"). Route |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:17` ## Layout |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:19` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:21` \| App bar \| `MxAppBar` (content density) + back `MxIconButton` \| "Daily reminder |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:22` \| Reminder section \| `MxSection` with note, two `MxSettingsRow`s \| Row bell "Dai |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:23` \| Banner \| `MxInlineBanner` \| Only after an operation left a problem: E1 `warnin |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:24` \| What it says \| `MxSection` "What it says", one `MxSettingsRow` \| The notificat |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:25` \| Time dialog \| `MxDialog` + two `MxStepper`s + `MxSheetActions` \| "Reminder tim |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:27` ## States |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:29` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:31` \| off \| `reminder_off_light.png` \| `reminder_off_dark.png` \| The toggle off; the |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:32` \| turningOn \| `reminder_turning_on_light.png` \| `reminder_turning_on_dark.png` \| |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:33` \| on \| `reminder_on_light.png` \| `reminder_on_dark.png` \| The toggle on, the tim |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:34` \| previewDue \| `reminder_preview_due_light.png` \| `reminder_preview_due_dark.png |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:35` \| changingTime \| `reminder_changing_time_light.png` \| `reminder_changing_time_da |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:36` \| permDenied \| `reminder_perm_denied_light.png` \| `reminder_perm_denied_dark.png |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:37` \| couldNotSchedule \| `reminder_could_not_schedule_light.png` \| `reminder_could_n |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:38` \| offMayShow \| `reminder_off_may_show_light.png` \| `reminder_off_may_show_dark.p |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:39` \| unavailable \| `reminder_unavailable_light.png` \| `reminder_unavailable_dark.pn |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:40` \| loading \| `reminder_loading_light.png` \| `reminder_loading_dark.png` \| `MxSkel |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:42` Built from UC-REMINDER-001: |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:44` - **E4, a save that failed:** snackbar "Couldn't save the reminder. Nothing chan |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:46` - **E7, a read that failed:** `MxErrorState` "Couldn't read the reminder setting |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:50` **Built (FE-B5):** `ReminderScreen` over `reminderStatusProvider` (the stream of |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:56` **Built (FE-B6):** "Open system settings" calls `openNotificationSettingsProvide |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:64` ## Rulings |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:66` - **Critique 2026-09-30 part 1:** the preview reads the live workload (no sample |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:67` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:68` - **UC-REMINDER-001 E6 (spec D8):** offMayShow is a `warning` `MxInlineBanner` w |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:69` - **UC-REMINDER-001 E3:** a refused Change time says "Couldn't change the time. |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:70` - **Owner 2026-09-28 (spec D2), UC A1:** the time is chosen in an `MxDialog` wit |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:71` - **UI-base ruling O3 (spec D10):** loading is `MxSkeletonList`. |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:72` - The note is the section's `MxNote.hint` footnote (critique 2026-09-30); the ti |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:73` - "What it says" is built from the notification's own strings, in en and vi, so |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:75` ## Accessibility |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:77` - The toggle is read as "Daily reminder" with its on/off state; while an operati |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:79` - The time button is read as "Reminder time, {HH:mm}"; disabled while off. |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:80` - The steppers name their buttons ("Earlier hour", "Later minute"…) and read the |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:82` - Every control is at least 48 tall; the visual-audit companion checks both them |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:85` ## Copy |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:87` - App bar and toggle: "Daily reminder" · "One notification a day at the time bel |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:89` - Time: "Time" · "Local time · stays the same if you travel" · "Turn the reminde |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:91` - Note: "Fires once a day, only when cards are due. Never for new cards, never t |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:92` - E1: "Notifications are blocked for MemoX" · "Allow them in Android Settings › |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:94` - E3: "Couldn’t schedule the reminder." · "It stays off. Try turning it on again |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:96` - E6: "Turned off. A reminder already scheduled for today may still appear once. |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:98` - E2: "Reminders are not available on this device" · "This build cannot deliver |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:100` - E4: "Couldn't save the reminder. Nothing changed." · E7: "Couldn't read the re |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:102` - What it says: the notification's sentence, e.g. "“3 cards are due in Korean.”" |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:105` - Dialog: "Reminder time" · "Hour" · "Minute" · "Cancel" · "Save". |  |
| `shared/ui/screen-handoff/24-daily-reminder.md:106` - Screen 23: "Daily reminder" · "Off" · "On · {HH:mm}"; reset body names "the da |  |

## shared/ui/screen-handoff/25-theme.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/25-theme.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:3` # 25 · Theme | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:5` The app's theme: follow the phone, always light or always dark. A tap applies it | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:10` ## Entry points | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:12` - **Screen 23's Theme row**, `/settings/theme`, on the root navigator with no bo | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:15` ## Layout | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:17` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:19` \| App bar \| `MxAppBar` \| Back and "Theme" (D7). \| | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:20` \| Cards \| `MxCard` (selected ring) + `MxRowInk` × 3 \| A preview, then "System" / | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:21` \| Note \| `MxNote.hint` \| "Applies at once — no restart, and you stay where you a | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:22` \| Toast \| `MxSnackbar` \| "Couldn't change the theme." · Retry. The stored choice | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:24` ## States | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:26` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:28` \| system \| `settings_theme_system_light.png` \| `settings_theme_system_dark.png` | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:29` \| light \| `settings_theme_light_light.png` \| `settings_theme_light_dark.png` \| A | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:30` \| dark \| `settings_theme_dark_light.png` \| `settings_theme_dark_dark.png` \| As s | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:31` \| read error \| — \| — \| (UC E3) `MxErrorState` "Couldn't open Settings" with Retr | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:33` Goldens: `test/features/settings/presentation/goldens/settings_theme_{system,lig | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:35` ## Rulings | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:37` - **D7 (owner):** the screen is titled "Theme" with no overline; the choices are | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:38` - **Build audit 2026-09-26, UI-base row 127:** the three cards go one per line w | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:40` ## Copy | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `shared/ui/screen-handoff/25-theme.md:42` "Theme" · "System" · "Match phone" · "Light" · "Always light" · "Dark" · "Always | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |

## shared/ui/screen-handoff/26-language.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/26-language.md:1` <!-- Hand-written screen record. --> | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:3` # 26 · Language | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:5` The app's language: follow the phone, English or Tiếng Việt. A tap applies it at | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:10` ## Entry points | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:12` - **Screen 23's Language row**, `/settings/language`, on the root navigator with | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:15` ## Layout | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:17` \| Region \| Widget \| Design \| | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:19` \| App bar \| `MxAppBar` \| Back and "Language". \| | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:20` \| Rows \| `MxSection` + `MxOptionRow` × 3, the note as its `MxNote` \| "Follow the | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:21` \| Note \| Text \| "Applies at once — no restart, and you stay where you are. Your | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:22` \| Toasts \| `MxSnackbar` \| After a switch, in the new language: "Switched to Engl | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:24` ## States | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:26` \| State \| Golden (light) \| Golden (dark) \| App \| | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:28` \| english \| `settings_language_english_light.png` \| `settings_language_english_d | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:29` \| vietnamese \| `settings_language_switched_light.png` \| `settings_language_switc | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:30` \| system \| `settings_language_system_light.png` \| `settings_language_system_dark | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:31` \| read error \| — \| — \| (UC E3) `MxErrorState` "Couldn't open Settings" with Retr | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:33` Goldens: `test/features/settings/presentation/goldens/settings_language_{english | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:35` ## Rulings | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:37` - **D8, BR-SETTINGS-006:** the system row says "Phone is set to {language}"; the | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:38` - The choices are `MxOptionRow` radios, the app's single-choice list; the note i | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:39` - **Critique 2026-09-26:** a row has no sub-line when it would repeat the title. | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:41` ## Copy | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `shared/ui/screen-handoff/26-language.md:43` "Language" · "Follow the system" · "Phone is set to {language}" · "Your phone's | moved → `screens/spec/SCR-SETTINGS-004-language.md` |

## shared/ui/screen-handoff/27-sync.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/27-sync.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/27-sync.md:3` # 27 · Sync |  |
| `shared/ui/screen-handoff/27-sync.md:5` What sync did and what waits: the last success, the changes not yet on the serve |  |
| `shared/ui/screen-handoff/27-sync.md:11` ## Entry points |  |
| `shared/ui/screen-handoff/27-sync.md:13` - Screen 23, Sync section, row "Sync". Route `/settings/sync`, on the root navig |  |
| `shared/ui/screen-handoff/27-sync.md:15` - Screen 13's sync banner, "Details" (`context.go`, as Study home opens the Libr |  |
| `shared/ui/screen-handoff/27-sync.md:17` - Neither exists when the build has no Supabase. |  |
| `shared/ui/screen-handoff/27-sync.md:19` ## Layout |  |
| `shared/ui/screen-handoff/27-sync.md:21` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/27-sync.md:23` \| App bar \| `MxAppBar` (content density) + back `MxIconButton` \| "Sync". \| |  |
| `shared/ui/screen-handoff/27-sync.md:24` \| Problem \| `MxInlineBanner` (warning); a network failure is an `MxNote` (critiq |  |
| `shared/ui/screen-handoff/27-sync.md:25` \| Status \| `MxSection` + two `MxSettingsRow`s + note \| "Last synced" · "{Today, |  |
| `shared/ui/screen-handoff/27-sync.md:26` \| Sync now \| `MxButton` (block, cloud-sync glyph): primary while changes wait or |  |
| `shared/ui/screen-handoff/27-sync.md:27` \| Keep dialog \| `MxDialog` + `MxSheetActions` \| "Keep {n} changes on this device |  |
| `shared/ui/screen-handoff/27-sync.md:28` \| Toasts \| `MxSnackbar` \| "Synced"; "Couldn't sync. Nothing was lost."; "Kept on |  |
| `shared/ui/screen-handoff/27-sync.md:30` Only one of Sync now, Try again and Keep on this device runs at a time; the othe |  |
| `shared/ui/screen-handoff/27-sync.md:33` ## States |  |
| `shared/ui/screen-handoff/27-sync.md:35` The images are the goldens. |  |
| `shared/ui/screen-handoff/27-sync.md:37` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/27-sync.md:39` \| synced \| ![](../../../../test/features/settings/presentation/goldens/sync_sync |  |
| `shared/ui/screen-handoff/27-sync.md:40` \| neverSynced \| ![](../../../../test/features/settings/presentation/goldens/sync |  |
| `shared/ui/screen-handoff/27-sync.md:41` \| pending \| ![](../../../../test/features/settings/presentation/goldens/sync_pen |  |
| `shared/ui/screen-handoff/27-sync.md:42` \| failedNetwork \| ![](../../../../test/features/settings/presentation/goldens/sy |  |
| `shared/ui/screen-handoff/27-sync.md:43` \| failedServer \| ![](../../../../test/features/settings/presentation/goldens/syn |  |
| `shared/ui/screen-handoff/27-sync.md:44` \| rejected \| ![](../../../../test/features/settings/presentation/goldens/sync_re |  |
| `shared/ui/screen-handoff/27-sync.md:45` \| keepDialog \| ![](../../../../test/features/settings/presentation/goldens/sync_ |  |
| `shared/ui/screen-handoff/27-sync.md:46` \| syncing \| ![](../../../../test/features/settings/presentation/goldens/sync_syn |  |
| `shared/ui/screen-handoff/27-sync.md:47` \| loading \| — \| — \| `MxSkeletonList`, two rows. \| |  |
| `shared/ui/screen-handoff/27-sync.md:48` \| read error \| — \| — \| `MxErrorState` "Couldn't open Sync" with the local-first |  |
| `shared/ui/screen-handoff/27-sync.md:50` ## Rulings |  |
| `shared/ui/screen-handoff/27-sync.md:52` - **ADR-015, SB-U1 owner rulings R1, R3, R5–R7:** sync has its own screen, and i |  |
| `shared/ui/screen-handoff/27-sync.md:53` - **Critique 2026-09-30 part 1 (spec `2026-09-30-critique-fixes-part1-design.md` |  |
| `shared/ui/screen-handoff/27-sync.md:54` - **Spec R6, FE-B5 D9:** times are 24-hour `HH:mm` in every language; dates read |  |
| `shared/ui/screen-handoff/27-sync.md:55` - **Critique 2026-09-30 tone pass (spec `2026-09-30-critique-fixes-tone-design.m |  |
| `shared/ui/screen-handoff/27-sync.md:56` - **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-desig |  |
| `shared/ui/screen-handoff/27-sync.md:57` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig |  |
| `shared/ui/screen-handoff/27-sync.md:58` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** a run t |  |
| `shared/ui/screen-handoff/27-sync.md:60` ## Copy |  |
| `shared/ui/screen-handoff/27-sync.md:62` - App bar: "Sync". |  |
| `shared/ui/screen-handoff/27-sync.md:63` - Refused rows: "{n} changes weren't accepted" · "1 change wasn't accepted" · "T |  |
| `shared/ui/screen-handoff/27-sync.md:64` - Keep dialog: "Keep {n} changes on this device only?" · "They won't sync to you |  |
| `shared/ui/screen-handoff/27-sync.md:65` - Failures: "No connection. Your changes are safe on this device and will sync w |  |
| `shared/ui/screen-handoff/27-sync.md:66` - Status: "Status" · "Last synced" · "Not yet" · "Waiting to sync" · "{n} change |  |
| `shared/ui/screen-handoff/27-sync.md:67` - Toasts: "Synced" · "Couldn't sync. Nothing was lost." · "Kept on this device" |  |
| `shared/ui/screen-handoff/27-sync.md:68` - Error: "Couldn't open Sync" · "Nothing was lost. Try again in a moment." · "Re |  |

## shared/ui/screen-handoff/28-monitoring.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/28-monitoring.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/28-monitoring.md:3` # 28 · Monitoring |  |
| `shared/ui/screen-handoff/28-monitoring.md:5` The admin's window on the app's logs: the server's, and the device's own buffer. |  |
| `shared/ui/screen-handoff/28-monitoring.md:14` ## Entry points |  |
| `shared/ui/screen-handoff/28-monitoring.md:16` - Screen 23, Admin section, row "Monitoring". Route `/settings/monitoring`, on t |  |
| `shared/ui/screen-handoff/28-monitoring.md:18` - A row opens its detail at `/settings/monitoring/:id` (`?local=1` for a row of |  |
| `shared/ui/screen-handoff/28-monitoring.md:21` - The row exists only while the session's account has `app_metadata.role = admin |  |
| `shared/ui/screen-handoff/28-monitoring.md:27` ## Layout: the list |  |
| `shared/ui/screen-handoff/28-monitoring.md:29` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/28-monitoring.md:31` \| App bar \| `MxAppBar` (content density) + back `MxIconButton` \| "Monitoring". \| |  |
| `shared/ui/screen-handoff/28-monitoring.md:32` \| Tabs \| `MxSegmentedTray` \| "Server" · "Not sent ({n})"; n is every row of the |  |
| `shared/ui/screen-handoff/28-monitoring.md:33` \| Search (Server) \| `MxSearchField` \| "Search event or message"; asks 400 ms aft |  |
| `shared/ui/screen-handoff/28-monitoring.md:34` \| Filters (Server) \| `MxChipTrigger` × 5 in a row that scrolls \| Level (default |  |
| `shared/ui/screen-handoff/28-monitoring.md:35` \| Count \| `MxListSectionHeader` \| "{n} logs" with any filter (the chip names the |  |
| `shared/ui/screen-handoff/28-monitoring.md:36` \| Rows \| `MxListRow` \| Leading `MxIconTile` with a glyph per level (debug bug, i |  |
| `shared/ui/screen-handoff/28-monitoring.md:37` \| End \| `MxSpinner` / `MxInlineBanner` / caption \| The next 100 rows load when t |  |
| `shared/ui/screen-handoff/28-monitoring.md:38` \| Not sent \| `MxNote` + one `MxChipTrigger` (Level, default warning + error) + r |  |
| `shared/ui/screen-handoff/28-monitoring.md:39` \| Filter sheets \| `MxBottomSheet` \| Level, Status and Category: a toggle per val |  |
| `shared/ui/screen-handoff/28-monitoring.md:41` Choosing Debug or Info, or no level at all (every level), clears the status filt |  |
| `shared/ui/screen-handoff/28-monitoring.md:46` ## Layout: the detail |  |
| `shared/ui/screen-handoff/28-monitoring.md:48` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/28-monitoring.md:50` \| App bar \| `MxAppBar` + back, action `MxIconButton` \| Title: the event. The act |  |
| `shared/ui/screen-handoff/28-monitoring.md:51` \| Head \| `MxIconTile` + text + `MxBadge` \| The level's glyph tile and name, the |  |
| `shared/ui/screen-handoff/28-monitoring.md:52` \| Message, Error \| `MxListSectionHeader` + `MxCard` \| Selectable text. Error: th |  |
| `shared/ui/screen-handoff/28-monitoring.md:53` \| Stack trace, Context \| `MxListSectionHeader` + `MxCard`, `code` style \| Select |  |
| `shared/ui/screen-handoff/28-monitoring.md:54` \| Details \| `MxSection` of label/value rows, last \| Fixed by, Fixed at (a fixed |  |
| `shared/ui/screen-handoff/28-monitoring.md:55` \| Triage \| `MxFooterBar` + `MxButton` (primary, block) \| "Mark fixed", or "Reope |  |
| `shared/ui/screen-handoff/28-monitoring.md:56` \| Toasts \| `MxSnackbar` \| "Marked fixed"; "Reopened"; "Couldn't change that. Not |  |
| `shared/ui/screen-handoff/28-monitoring.md:58` ## States |  |
| `shared/ui/screen-handoff/28-monitoring.md:60` The images are the goldens. |  |
| `shared/ui/screen-handoff/28-monitoring.md:62` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/28-monitoring.md:64` \| list, loaded \| ![](../../../../test/features/monitoring/presentation/goldens/m |  |
| `shared/ui/screen-handoff/28-monitoring.md:65` \| list, every level \| ![](../../../../test/features/monitoring/presentation/gold |  |
| `shared/ui/screen-handoff/28-monitoring.md:66` \| list, empty \| ![](../../../../test/features/monitoring/presentation/goldens/mo |  |
| `shared/ui/screen-handoff/28-monitoring.md:67` \| list, offline \| ![](../../../../test/features/monitoring/presentation/goldens/ |  |
| `shared/ui/screen-handoff/28-monitoring.md:68` \| Not sent \| ![](../../../../test/features/monitoring/presentation/goldens/monit |  |
| `shared/ui/screen-handoff/28-monitoring.md:69` \| Level sheet \| ![](../../../../test/features/monitoring/presentation/goldens/mo |  |
| `shared/ui/screen-handoff/28-monitoring.md:70` \| detail, open error \| ![](../../../../test/features/monitoring/presentation/gol |  |
| `shared/ui/screen-handoff/28-monitoring.md:71` \| detail, scrolled to the end \| ![](../../../../test/features/monitoring/present |  |
| `shared/ui/screen-handoff/28-monitoring.md:72` \| detail, fixed with a note \| ![](../../../../test/features/monitoring/presentat |  |
| `shared/ui/screen-handoff/28-monitoring.md:73` \| detail, a row of the buffer \| ![](../../../../test/features/monitoring/present |  |
| `shared/ui/screen-handoff/28-monitoring.md:74` \| list, loading \| — \| — \| `MxSkeletonList`, six rows. \| |  |
| `shared/ui/screen-handoff/28-monitoring.md:75` \| list, no match \| — \| — \| `MxEmptyState` "Nothing matches" with Clear filters. |  |
| `shared/ui/screen-handoff/28-monitoring.md:76` \| list, error \| — \| — \| `MxErrorState` "Couldn't load logs" with the local-first |  |
| `shared/ui/screen-handoff/28-monitoring.md:77` \| list, not an admin \| — \| — \| `MxEmptyState` "Only an admin can see this" (the |  |
| `shared/ui/screen-handoff/28-monitoring.md:78` \| detail, loading / error / offline / gone \| — \| — \| Skeleton; `MxErrorState` wi |  |
| `shared/ui/screen-handoff/28-monitoring.md:80` Goldens: `test/features/monitoring/presentation/goldens/monitoring_{list_loaded, |  |
| `shared/ui/screen-handoff/28-monitoring.md:82` ## Rulings |  |
| `shared/ui/screen-handoff/28-monitoring.md:84` - **ADR-018 §8, Impeccable shape 2026-09-29:** screen 28 is built from the share |  |
| `shared/ui/screen-handoff/28-monitoring.md:85` - **Plan ruling 1, UI-base row 147:** open and fixed are `MxBadge`s, open in the |  |
| `shared/ui/screen-handoff/28-monitoring.md:86` - **Plan ruling 2:** Level, Status and Category filter with toggles; only the on |  |
| `shared/ui/screen-handoff/28-monitoring.md:87` - **Plan ruling 3:** a category shows its stored code, from `LogCategory.values` |  |
| `shared/ui/screen-handoff/28-monitoring.md:88` - **Plan ruling 4:** the device / user filter is a sheet of two text fields, a d |  |
| `shared/ui/screen-handoff/28-monitoring.md:89` - **Plan ruling 12:** the offline state offers Retry above Not sent. |  |
| `shared/ui/screen-handoff/28-monitoring.md:90` - **Plan ruling 13:** rows sit directly in the page's scroll, with no card aroun |  |
| `shared/ui/screen-handoff/28-monitoring.md:91` - **Owner 2026-09-29, UI-base row 147:** code uses `MxTextStyles.code`: the syst |  |
| `shared/ui/screen-handoff/28-monitoring.md:92` - **Owner 2026-09-29 (Impeccable audit):** the detail shows the level and status |  |
| `shared/ui/screen-handoff/28-monitoring.md:93` - **Spec §3.2, §3.5 (ADR-008):** a row shows `HH:mm` today and "Sep 26" before; |  |
| `shared/ui/screen-handoff/28-monitoring.md:94` - **Critique 2026-09-30 tone pass, T7:** a Fixed log is success; the empty lists |  |
| `shared/ui/screen-handoff/28-monitoring.md:95` - **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-desig |  |
| `shared/ui/screen-handoff/28-monitoring.md:97` ## Copy |  |
| `shared/ui/screen-handoff/28-monitoring.md:99` - App bar and tabs: "Monitoring" · "Server" · "Not sent ({n})". |  |
| `shared/ui/screen-handoff/28-monitoring.md:100` - Search and chips: "Search event or message" · "Clear search" · "Level" · "Stat |  |
| `shared/ui/screen-handoff/28-monitoring.md:101` - List: "{n} logs" · "{n}+ logs" · "No more logs" · "Couldn't load more logs." · |  |
| `shared/ui/screen-handoff/28-monitoring.md:102` - States: "No open problems" · "Warnings and errors will show here." · "Nothing |  |
| `shared/ui/screen-handoff/28-monitoring.md:103` - Not sent: "These logs wait on this device. They are sent when MemoX is online. |  |
| `shared/ui/screen-handoff/28-monitoring.md:104` - Detail: "Log" · "Copy log" · "Copied" · "Copy device ID" · "Copy user ID" · "D |  |
| `shared/ui/screen-handoff/28-monitoring.md:105` - Triage: "Mark fixed" · "Reopen" · "Note (optional)" · "What did you do?" · "Ma |  |
| `shared/ui/screen-handoff/28-monitoring.md:106` - Detail states: "Couldn't load this log" · "Nothing was lost. Try again when yo |  |

## shared/ui/screen-handoff/29-welcome.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/29-welcome.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/29-welcome.md:3` # 29 · Welcome |  |
| `shared/ui/screen-handoff/29-welcome.md:5` The first launch invites an account: the name, one promise, three benefits, and |  |
| `shared/ui/screen-handoff/29-welcome.md:10` ## Entry points |  |
| `shared/ui/screen-handoff/29-welcome.md:12` - The launch, once per device, on a build that can sign in: `main` reads |  |
| `shared/ui/screen-handoff/29-welcome.md:15` - No back arrow: Android Back leaves the app, as on any root. |  |
| `shared/ui/screen-handoff/29-welcome.md:17` ## Layout |  |
| `shared/ui/screen-handoff/29-welcome.md:19` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/29-welcome.md:21` \| Head \| `MxIconTile` (large, tinted, deck glyph) \| Stands in for the app icon, |  |
| `shared/ui/screen-handoff/29-welcome.md:22` \| Name and promise \| `screenTitle` + `emptyBody` \| "MemoX"; "Sign in to keep you |  |
| `shared/ui/screen-handoff/29-welcome.md:23` \| Benefits \| `MxSection` + `MxSettingsRow` × 3 \| Shield "Keep your decks when yo |  |
| `shared/ui/screen-handoff/29-welcome.md:24` \| Offline note \| `MxNote` \| "Signing in needs a connection. You can do it later |  |
| `shared/ui/screen-handoff/29-welcome.md:25` \| Actions \| `MxFooterBar` + `MxButton` × 3, 12 apart \| "Continue with Google" (p |  |
| `shared/ui/screen-handoff/29-welcome.md:27` Every exit answers Welcome first, then goes on: Google and "without" to `from`, |  |
| `shared/ui/screen-handoff/29-welcome.md:31` ## States |  |
| `shared/ui/screen-handoff/29-welcome.md:33` The images are the goldens. |  |
| `shared/ui/screen-handoff/29-welcome.md:35` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/29-welcome.md:37` \| ready \| ![](../../../../test/features/account/presentation/goldens/welcome_rea |  |
| `shared/ui/screen-handoff/29-welcome.md:38` \| offline \| ![](../../../../test/features/account/presentation/goldens/welcome_o |  |
| `shared/ui/screen-handoff/29-welcome.md:40` ## Rulings |  |
| `shared/ui/screen-handoff/29-welcome.md:42` - **U1:** shown once on every device, including one that used the app before the |  |
| `shared/ui/screen-handoff/29-welcome.md:43` - **U5:** the tile until MemoX has its own icon (UI-base row 149). |  |
| `shared/ui/screen-handoff/29-welcome.md:44` - **U6:** Google's G mark on the Google button. |  |
| `shared/ui/screen-handoff/29-welcome.md:45` - **P3a plan rulings 3, 4, 6:** only on a build that can sign in; the email exit |  |
| `shared/ui/screen-handoff/29-welcome.md:47` ## Copy |  |
| `shared/ui/screen-handoff/29-welcome.md:49` - "MemoX" · "Sign in to keep your decks safe and the same on every phone." |  |
| `shared/ui/screen-handoff/29-welcome.md:50` - "Keep your decks when you reinstall" · "Study on several phones" · "Still work |  |
| `shared/ui/screen-handoff/29-welcome.md:51` - "Continue with Google" · "Continue with email" · "Continue without an account" |  |
| `shared/ui/screen-handoff/29-welcome.md:52` - "Signing in needs a connection. You can do it later in Settings." |  |
| `shared/ui/screen-handoff/29-welcome.md:53` - Toast: "Signed in as {email}" (or "Signed in"). |  |

## shared/ui/screen-handoff/30-sign-in.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/30-sign-in.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/30-sign-in.md:3` # 30 · Sign-in, the merge sheet and the transition layer |  |
| `shared/ui/screen-handoff/30-sign-in.md:5` Attach Google or an email to this device's anonymous user (`link`), or sign in a |  |
| `shared/ui/screen-handoff/30-sign-in.md:12` ## Entry points |  |
| `shared/ui/screen-handoff/30-sign-in.md:14` - Screen 23, Account section, row "Sign in". Route `/settings/sign-in?mode=link` |  |
| `shared/ui/screen-handoff/30-sign-in.md:16` - Screen 29, "Continue with email" (`go`, so Settings sits under it). |  |
| `shared/ui/screen-handoff/30-sign-in.md:17` - The transition layer, while a switch waits for its target sign-in. |  |
| `shared/ui/screen-handoff/30-sign-in.md:18` - A device that already holds an account is sent from `mode=link` to screen 32 ( |  |
| `shared/ui/screen-handoff/30-sign-in.md:19` - `reauth`: the re-auth banner's "Sign in" on 23 and 32, and the notice on 13 |  |
| `shared/ui/screen-handoff/30-sign-in.md:25` ## Layout |  |
| `shared/ui/screen-handoff/30-sign-in.md:27` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/30-sign-in.md:29` \| App bar \| `MxAppBar` (content) + back \| "Sign in". The layer has no app bar, o |  |
| `shared/ui/screen-handoff/30-sign-in.md:30` \| Mode line \| `emptyBody` \| Link: "Your decks stay on this phone and join the ac |  |
| `shared/ui/screen-handoff/30-sign-in.md:31` \| Google \| `MxButton` (outline, block, G mark) \| "Continue with Google". Its fai |  |
| `shared/ui/screen-handoff/30-sign-in.md:32` \| Divider \| two hairlines + `footerCaption` \| "or". \| |  |
| `shared/ui/screen-handoff/30-sign-in.md:33` \| Email \| `MxTextField` (form) \| "Email address". Checked on send; its problem s |  |
| `shared/ui/screen-handoff/30-sign-in.md:34` \| Send code \| `MxButton` (primary, block) \| "Send code", the form's one fill; sp |  |
| `shared/ui/screen-handoff/30-sign-in.md:35` \| Offline note \| `MxNote` \| "Signing in needs a connection. You can do it later |  |
| `shared/ui/screen-handoff/30-sign-in.md:37` ### Re-auth (`mode=reauth`, P3b) |  |
| `shared/ui/screen-handoff/30-sign-in.md:39` \| Region \| Design \| |  |
| `shared/ui/screen-handoff/30-sign-in.md:41` \| Mode line \| "Sign in again to keep syncing. Your decks are still here." \| |  |
| `shared/ui/screen-handoff/30-sign-in.md:42` \| Email \| Filled with the last account's email (the usual case signs in again to |  |
| `shared/ui/screen-handoff/30-sign-in.md:43` \| Another account, changes unsent \| A dialog "Lose {n} changes?" · "{n} changes |  |
| `shared/ui/screen-handoff/30-sign-in.md:44` \| Continue without an account \| `MxButton` (text, block) under the form (P3b pla |  |
| `shared/ui/screen-handoff/30-sign-in.md:45` \| Code step (31) \| A resend to another account names the unsent changes again, i |  |
| `shared/ui/screen-handoff/30-sign-in.md:47` ### Merge sheet (auth spec #17) |  |
| `shared/ui/screen-handoff/30-sign-in.md:49` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/30-sign-in.md:51` \| Title \| `compactTitle` \| "{email} already has an account" or "This Google acco |  |
| `shared/ui/screen-handoff/30-sign-in.md:52` \| Choices \| `MxOptionRow` × 2 \| "Merge into the account" (selected) · "Your {n} |  |
| `shared/ui/screen-handoff/30-sign-in.md:53` \| Warning \| `MxInlineBanner` (danger) \| "This phone's decks and progress go for |  |
| `shared/ui/screen-handoff/30-sign-in.md:54` \| Footer \| `MxSheetActions` \| Cancel · "Continue" (primary) or "Discard and cont |  |
| `shared/ui/screen-handoff/30-sign-in.md:56` A phone with no live deck skips the sheet and moves at once (R6). |  |
| `shared/ui/screen-handoff/30-sign-in.md:58` ### Transition layer (app root, U4) |  |
| `shared/ui/screen-handoff/30-sign-in.md:60` Over the whole app while a switch, sign-out, deletion or clear runs. It is not a |  |
| `shared/ui/screen-handoff/30-sign-in.md:65` \| Condition \| Design \| |  |
| `shared/ui/screen-handoff/30-sign-in.md:67` \| Running \| `MxSpinner` (large), the step in `screenTitle` ("Sending your change |  |
| `shared/ui/screen-handoff/30-sign-in.md:68` \| Network error \| `MxInlineBanner` (warning) "No connection. Your data is safe o |  |
| `shared/ui/screen-handoff/30-sign-in.md:69` \| Other error \| "Something went wrong. Your data is safe on this phone." + Retry |  |
| `shared/ui/screen-handoff/30-sign-in.md:70` \| Sign-out stopped offline \| "No connection. Nothing has been removed yet." + Re |  |
| `shared/ui/screen-handoff/30-sign-in.md:71` \| Target sign-in \| The form above in target mode, the address pre-filled; the co |  |
| `shared/ui/screen-handoff/30-sign-in.md:72` \| Stuck \| "Something went wrong while moving your account. Your data is safe on |  |
| `shared/ui/screen-handoff/30-sign-in.md:73` \| Before the target signs in \| "Cancel" at the top returns to where the switch s |  |
| `shared/ui/screen-handoff/30-sign-in.md:75` Notices at the app root: toasts "Couldn't merge. Your decks are still on this ph |  |
| `shared/ui/screen-handoff/30-sign-in.md:79` ## States |  |
| `shared/ui/screen-handoff/30-sign-in.md:81` The images are the goldens. |  |
| `shared/ui/screen-handoff/30-sign-in.md:83` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/30-sign-in.md:85` \| link \| ![](../../../../test/features/account/presentation/goldens/sign_in_link |  |
| `shared/ui/screen-handoff/30-sign-in.md:86` \| invalid \| ![](../../../../test/features/account/presentation/goldens/sign_in_i |  |
| `shared/ui/screen-handoff/30-sign-in.md:87` \| merge sheet, merge \| ![](../../../../test/features/account/presentation/golden |  |
| `shared/ui/screen-handoff/30-sign-in.md:88` \| merge sheet, discard \| ![](../../../../test/features/account/presentation/gold |  |
| `shared/ui/screen-handoff/30-sign-in.md:89` \| layer, sending \| ![](../../../../test/features/account/presentation/goldens/la |  |
| `shared/ui/screen-handoff/30-sign-in.md:90` \| layer, merging \| ![](../../../../test/features/account/presentation/goldens/la |  |
| `shared/ui/screen-handoff/30-sign-in.md:91` \| layer, offline \| ![](../../../../test/features/account/presentation/goldens/la |  |
| `shared/ui/screen-handoff/30-sign-in.md:92` \| layer, target sign-in \| ![](../../../../test/features/account/presentation/gol |  |
| `shared/ui/screen-handoff/30-sign-in.md:93` \| layer, sign-out offline \| ![](../../../../test/features/account/presentation/g |  |
| `shared/ui/screen-handoff/30-sign-in.md:94` \| reauth \| ![](../../../../test/features/account/presentation/goldens/sign_in_re |  |
| `shared/ui/screen-handoff/30-sign-in.md:95` \| reauth, unsent loss \| ![](../../../../test/features/account/presentation/golde |  |
| `shared/ui/screen-handoff/30-sign-in.md:96` \| reauth, continue without \| ![](../../../../test/features/account/presentation/ |  |
| `shared/ui/screen-handoff/30-sign-in.md:97` \| layer, stuck \| ![](../../../../test/features/account/presentation/goldens/laye |  |
| `shared/ui/screen-handoff/30-sign-in.md:99` ## Rulings |  |
| `shared/ui/screen-handoff/30-sign-in.md:101` - **R1:** no `mode=switch`: "Switch account" (32, P3b) signs in the target insid |  |
| `shared/ui/screen-handoff/30-sign-in.md:102` - **R3:** a wrong and an expired code read alike; a rate limit asks to wait a mi |  |
| `shared/ui/screen-handoff/30-sign-in.md:103` - **B8, B9 and P3b plan rulings 3, 10:** the re-auth's loss and way out; where f |  |
| `shared/ui/screen-handoff/30-sign-in.md:104` - **P3a plan rulings 1, 2, 7–10, 12, 14:** routes under Settings; the flow ended |  |
| `shared/ui/screen-handoff/30-sign-in.md:105` - **Impeccable after the build (F1):** the layer's content is centred, not top-a |  |
| `shared/ui/screen-handoff/30-sign-in.md:106` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** a sign- |  |
| `shared/ui/screen-handoff/30-sign-in.md:108` ## Copy |  |
| `shared/ui/screen-handoff/30-sign-in.md:110` - "Sign in" · "Your decks stay on this phone and join the account." · "Continue |  |
| `shared/ui/screen-handoff/30-sign-in.md:111` - Problems: "Enter an email address, like name@example.com." · "Too many tries. |  |
| `shared/ui/screen-handoff/30-sign-in.md:112` - Re-auth: "Sign in again to keep syncing. Your decks are still here." · "Contin |  |
| `shared/ui/screen-handoff/30-sign-in.md:113` - Toast: "Signed in as {email}" once `me()` confirmed the account, "Signed in" w |  |
| `shared/ui/screen-handoff/30-sign-in.md:114` - Merge sheet and layer: as in the tables above. |  |

## shared/ui/screen-handoff/31-code.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/31-code.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/31-code.md:3` # 31 · Code |  |
| `shared/ui/screen-handoff/31-code.md:5` The six digits sent to the address. SB-A2; spec |  |
| `shared/ui/screen-handoff/31-code.md:9` ## Entry points |  |
| `shared/ui/screen-handoff/31-code.md:11` - Screen 30, "Send code". Route `/settings/sign-in/code?mode=link&email=…`, on t |  |
| `shared/ui/screen-handoff/31-code.md:13` - The transition layer's target sign-in, on the layer's own navigator. |  |
| `shared/ui/screen-handoff/31-code.md:15` ## Layout |  |
| `shared/ui/screen-handoff/31-code.md:17` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/31-code.md:19` \| App bar \| `MxAppBar` (content) + back \| "Enter the code". \| |  |
| `shared/ui/screen-handoff/31-code.md:20` \| Lead \| `emptyBody` \| "Enter the 6-digit code sent to {email}". \| |  |
| `shared/ui/screen-handoff/31-code.md:21` \| Code \| `MxTextField` (code) \| Six digits, numeric keyboard, one-time-code auto |  |
| `shared/ui/screen-handoff/31-code.md:22` \| Resend \| `MxButton` (text) \| "Resend code in 0:42", disabled, until the 60 s w |  |
| `shared/ui/screen-handoff/31-code.md:23` \| Another email \| `MxButton` (text) \| "Use another email". \| |  |
| `shared/ui/screen-handoff/31-code.md:25` A right code attaches the account, toasts "Signed in as {email}" and closes the |  |
| `shared/ui/screen-handoff/31-code.md:30` ## States |  |
| `shared/ui/screen-handoff/31-code.md:32` The images are the goldens. |  |
| `shared/ui/screen-handoff/31-code.md:34` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/31-code.md:36` \| waiting \| ![](../../../../test/features/account/presentation/goldens/code_wait |  |
| `shared/ui/screen-handoff/31-code.md:37` \| wrong \| ![](../../../../test/features/account/presentation/goldens/code_wrong_ |  |
| `shared/ui/screen-handoff/31-code.md:38` \| verifying \| — \| — \| The field disabled, `MxSpinner` under it. \| |  |
| `shared/ui/screen-handoff/31-code.md:40` ## Rulings |  |
| `shared/ui/screen-handoff/31-code.md:42` - **R3:** "wrong or expired" is one state: GoTrue answers both alike. |  |
| `shared/ui/screen-handoff/31-code.md:43` - **P3a plan ruling 11:** a wrong code clears the field. |  |
| `shared/ui/screen-handoff/31-code.md:45` ## Copy |  |
| `shared/ui/screen-handoff/31-code.md:47` - "Enter the code" · "Enter the 6-digit code sent to {email}" · "Code, 6 digits" |  |
| `shared/ui/screen-handoff/31-code.md:48` - "That code is wrong or has expired. Check the latest email, or send a new code |  |
| `shared/ui/screen-handoff/31-code.md:49` - "Resend code in {m:ss}" · "Resend code" · "A new code is on its way." · "Use a |  |

## shared/ui/screen-handoff/32-account.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/32-account.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/32-account.md:3` # 32 · Account |  |
| `shared/ui/screen-handoff/32-account.md:5` The account this phone's data belongs to, and what can be done with it: switch, |  |
| `shared/ui/screen-handoff/32-account.md:10` ## Entry points |  |
| `shared/ui/screen-handoff/32-account.md:12` - Screen 23, the Account section's row once the device holds an account (its che |  |
| `shared/ui/screen-handoff/32-account.md:14` - The link flow (29, 30, 31) ends here (B9). |  |
| `shared/ui/screen-handoff/32-account.md:15` - On a plainly anonymous device the route redirects to 23; during a transition i |  |
| `shared/ui/screen-handoff/32-account.md:19` ## Layout |  |
| `shared/ui/screen-handoff/32-account.md:21` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/32-account.md:23` \| App bar \| `MxAppBar` (content) + back \| "Account". \| |  |
| `shared/ui/screen-handoff/32-account.md:24` \| Re-auth banner \| `MxInlineBanner` (warning) \| Only in `ReauthRequired`: "Your |  |
| `shared/ui/screen-handoff/32-account.md:25` \| Connection note \| `MxNote` \| Only in `Validating`: "Managing your account need |  |
| `shared/ui/screen-handoff/32-account.md:26` \| Account \| `MxSection` "ACCOUNT" + `MxSettingsRow` \| The person tile, the email |  |
| `shared/ui/screen-handoff/32-account.md:27` \| This phone \| `MxSection` "THIS PHONE" \| "Switch account" · "Move this phone to |  |
| `shared/ui/screen-handoff/32-account.md:28` \| Delete \| `MxSection` "DELETE" \| "Delete account" · "Your account and its data, |  |
| `shared/ui/screen-handoff/32-account.md:30` The three command rows are disabled before `Ready` (auth spec #39 needs a confir |  |
| `shared/ui/screen-handoff/32-account.md:35` \| Dialog \| Design \| |  |
| `shared/ui/screen-handoff/32-account.md:37` \| Switch \| "Switch account?" · "This phone's data is replaced by the other accou |  |
| `shared/ui/screen-handoff/32-account.md:38` \| Sign out \| Online, or nothing unsent: "Sign out?" · "Your changes are sent fir |  |
| `shared/ui/screen-handoff/32-account.md:39` \| Delete \| "Delete your account?" · "Your account and its decks, cards and progr |  |
| `shared/ui/screen-handoff/32-account.md:40` \| Last admin \| "An admin must remain" · "Give another person the admin role firs |  |
| `shared/ui/screen-handoff/32-account.md:42` A command refused before anything changed toasts "No connection. Nothing changed |  |
| `shared/ui/screen-handoff/32-account.md:45` ## States |  |
| `shared/ui/screen-handoff/32-account.md:47` The images are the goldens. |  |
| `shared/ui/screen-handoff/32-account.md:49` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/32-account.md:51` \| ready \| ![](../../../../test/features/account/presentation/goldens/account_rea |  |
| `shared/ui/screen-handoff/32-account.md:52` \| validating \| ![](../../../../test/features/account/presentation/goldens/accoun |  |
| `shared/ui/screen-handoff/32-account.md:53` \| reauth \| ![](../../../../test/features/account/presentation/goldens/account_re |  |
| `shared/ui/screen-handoff/32-account.md:54` \| switch dialog \| ![](../../../../test/features/account/presentation/goldens/acc |  |
| `shared/ui/screen-handoff/32-account.md:55` \| sign-out dialog \| ![](../../../../test/features/account/presentation/goldens/a |  |
| `shared/ui/screen-handoff/32-account.md:56` \| sign-out, loss \| ![](../../../../test/features/account/presentation/goldens/ac |  |
| `shared/ui/screen-handoff/32-account.md:57` \| delete dialog \| ![](../../../../test/features/account/presentation/goldens/acc |  |
| `shared/ui/screen-handoff/32-account.md:58` \| delete, offline \| ![](../../../../test/features/account/presentation/goldens/a |  |
| `shared/ui/screen-handoff/32-account.md:59` \| last admin \| ![](../../../../test/features/account/presentation/goldens/accoun |  |
| `shared/ui/screen-handoff/32-account.md:61` ## Rulings |  |
| `shared/ui/screen-handoff/32-account.md:63` - **B1–B4, B6, B7, B12** (spec §9): the method from the session; one network sta |  |
| `shared/ui/screen-handoff/32-account.md:66` - **P3b plan rulings 1, 2, 4–7, 9:** the banner above the section; the email wra |  |
| `shared/ui/screen-handoff/32-account.md:69` - **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** Switch |  |
| `shared/ui/screen-handoff/32-account.md:71` ## Copy |  |
| `shared/ui/screen-handoff/32-account.md:73` - "Account" · "ACCOUNT" · "THIS PHONE" · "DELETE". |  |
| `shared/ui/screen-handoff/32-account.md:74` - "Signed in with Google" · "Signed in with email" · "Signed in with Google and |  |
| `shared/ui/screen-handoff/32-account.md:75` - "Switch account" · "Move this phone to another account" · "Sign out" · "Your c |  |
| `shared/ui/screen-handoff/32-account.md:77` - The dialogs' copy is in the table above. |  |

## shared/ui/screen-handoff/33-users.md

| Source item | Outcome |
|---|---|
| `shared/ui/screen-handoff/33-users.md:1` <!-- Hand-written screen record. --> |  |
| `shared/ui/screen-handoff/33-users.md:3` # 33 · Users (admin) |  |
| `shared/ui/screen-handoff/33-users.md:5` An admin finds any signed-in account by email and makes it an admin or a user. F |  |
| `shared/ui/screen-handoff/33-users.md:9` ## Entry points |  |
| `shared/ui/screen-handoff/33-users.md:11` - Screen 23, Admin section, row "Users" · "Who can manage the app" (shown only t |  |
| `shared/ui/screen-handoff/33-users.md:13` - A deep link meets the admin gate: a non-admin sees "Only an admin can see this |  |
| `shared/ui/screen-handoff/33-users.md:16` ## Layout |  |
| `shared/ui/screen-handoff/33-users.md:18` \| Region \| Widget \| Design \| |  |
| `shared/ui/screen-handoff/33-users.md:20` \| App bar \| `MxAppBar` (content) + back \| "Users". \| |  |
| `shared/ui/screen-handoff/33-users.md:21` \| Search \| `MxSearchField` \| "Search by email"; asks 400 ms after the last keyst |  |
| `shared/ui/screen-handoff/33-users.md:22` \| Overline \| `MxListSectionHeader` \| "ACCOUNTS" (no count: `role_list` has no to |  |
| `shared/ui/screen-handoff/33-users.md:23` \| Rows \| `MxListRow` \| Person tile (tinted, the same for all), the email, "Joine |  |
| `shared/ui/screen-handoff/33-users.md:24` \| End \| as screen 28 \| The next page loads near the end; "No more users"; a fail |  |
| `shared/ui/screen-handoff/33-users.md:26` **Role sheet** (`MxBottomSheet`, the merge sheet's form): the email as title; `M |  |
| `shared/ui/screen-handoff/33-users.md:33` \| Outcome \| Shows \| |  |
| `shared/ui/screen-handoff/33-users.md:35` \| saved \| the sheet closes, the badge changes in place, toast "{email} is now an |  |
| `shared/ui/screen-handoff/33-users.md:36` \| last admin \| the sheet stays and says, in a warning `MxInlineBanner` under the |  |
| `shared/ui/screen-handoff/33-users.md:37` \| anonymous \| the sheet stays, banner "This account isn't signed in with an emai |  |
| `shared/ui/screen-handoff/33-users.md:38` \| gone \| the sheet closes, toast "That account no longer exists.", the list relo |  |
| `shared/ui/screen-handoff/33-users.md:39` \| not an admin \| the sheet closes, the screen shows the not-admin state \| |  |
| `shared/ui/screen-handoff/33-users.md:40` \| offline / other \| the sheet stays, banner "No connection. Nothing changed." / |  |
| `shared/ui/screen-handoff/33-users.md:42` ## States |  |
| `shared/ui/screen-handoff/33-users.md:44` The images are the goldens. |  |
| `shared/ui/screen-handoff/33-users.md:46` \| State \| Golden (light) \| Golden (dark) \| App \| |  |
| `shared/ui/screen-handoff/33-users.md:48` \| loaded \| ![](../../../../test/features/account/presentation/goldens/users_load |  |
| `shared/ui/screen-handoff/33-users.md:49` \| no match \| ![](../../../../test/features/account/presentation/goldens/users_em |  |
| `shared/ui/screen-handoff/33-users.md:50` \| offline \| ![](../../../../test/features/account/presentation/goldens/users_off |  |
| `shared/ui/screen-handoff/33-users.md:51` \| role sheet \| ![](../../../../test/features/account/presentation/goldens/users_ |  |
| `shared/ui/screen-handoff/33-users.md:52` \| role sheet, changed \| ![](../../../../test/features/account/presentation/golde |  |
| `shared/ui/screen-handoff/33-users.md:53` \| role sheet, refused \| ![](../../../../test/features/account/presentation/golde |  |
| `shared/ui/screen-handoff/33-users.md:54` \| loading \| — \| — \| `MxSkeletonList`. \| |  |
| `shared/ui/screen-handoff/33-users.md:55` \| no accounts \| — \| — \| "No accounts yet". \| |  |
| `shared/ui/screen-handoff/33-users.md:56` \| error \| — \| — \| "Couldn't load users" + Retry. \| |  |
| `shared/ui/screen-handoff/33-users.md:57` \| not an admin \| — \| — \| the lock empty state, no search. \| |  |
| `shared/ui/screen-handoff/33-users.md:59` ## Rulings |  |
| `shared/ui/screen-handoff/33-users.md:61` - **U1–U5** (spec §1): the own row is read-only; Settings owns the Admin section |  |
| `shared/ui/screen-handoff/33-users.md:64` - **Spec §6 (shape):** screen 28 is the pattern: pages load at the end of the sc |  |
| `shared/ui/screen-handoff/33-users.md:66` - **P4 plan rulings 1–6:** errors through core's `classifyAuthError`; the gate t |  |
| `shared/ui/screen-handoff/33-users.md:70` ## Copy |  |
| `shared/ui/screen-handoff/33-users.md:72` - "Users" · "Search by email" · "ACCOUNTS" · "Joined {date}" · "Joined {date} · |  |
| `shared/ui/screen-handoff/33-users.md:74` - The sheet's and the toasts' copy is in the tables above. |  |

## features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md

| Source item | Outcome |
|---|---|
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:2` id: UC-CARD-001 | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:3` title: Quản lý card trong deck | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:4` status: ready | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:5` rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-CARD-005, BR-CARD | superseded → FN-CARD-001…FN-CARD-012 (Business rules) |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:6` code: [lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/feat | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:10` **Actor:** Người dùng | superseded → UC-CARD-001 (Mục tiêu replaces the Trigger "mở một deck") |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:14` ## Main flow | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:16` **Main flow:** | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:17` 1. Người dùng thấy danh sách card của deck. | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:18` 2. Người dùng thêm card: nhập mặt trước và mặt sau, tuỳ chọn thêm ví dụ, gợi ý | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:20` 3. Hệ thống validate (BR-CARD-001, BR-CARD-002, BR-CARD-003). | superseded → FN-CARD-002 (Lỗi: draft limits) |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:21` 4. Hệ thống tạo card **và** study state của nó trong cùng transaction, theo | superseded → FN-CARD-002 (Kết quả) |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:23` 5. Card xuất hiện; số card đến hạn của deck tăng. | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:25` Card đầu tiên của một deck `unset` được tạo qua UC-DECK-004, và chính nó xác lập | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:28` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:30` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:31` - **A1 — Sửa card:** nội dung đổi; study state và history **không** đổi (BR-CARD | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:32` - **A2 — Xoá card:** hỏi xác nhận; xác nhận thì card vào Trash trong một | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:43` - **A3 — Deck còn card nhưng danh sách rỗng theo bộ lọc:** empty state của bộ | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:45` - **A5 — Di chuyển thẻ sang deck khác:** chọn deck đích trong cùng root; thẻ giữ | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:49` - **A6 — Chọn nhiều thẻ:** long-press một thẻ hoặc dùng action **Select** trên | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:54` - **A4 — Thêm liên tiếp nhiều card:** sau khi lưu, giữ form mở và xoá trống các | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:55` - **A7 — Cờ:** người dùng bật hoặc bỏ cờ của một thẻ (BR-CARD-009). | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:56` - **A8 — Tag:** người dùng gắn tag theo tên — dùng lại tag trùng tên đã fold, tạ | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:58` - **A9 — Mở chi tiết:** chạm một thẻ ở chế độ thường mở chi tiết chỉ đọc (UC-CAR | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:61` **Error flows:** | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:62` - **E1 — Mặt trước hoặc mặt sau rỗng:** lỗi inline ở đúng ô đó. | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:63` - **E5 — Deck đích không hợp lệ:** picker chỉ liệt kê deck cùng root, không phải | superseded → FN-CARD-006 (the targets the picker lists) + FN-CARD-007 (Lỗi); intent kept in UC-CARD-001 E5 |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:68` - **E6 — Một thẻ trong lô vi phạm:** cả lô rollback; danh sách và selection giữ | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:70` - **E2 — Vượt giới hạn độ dài** (BR-CARD-002, BR-CARD-003): lỗi inline ở đúng ô | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:71` - **E3 — Ghi thất bại:** hiện lỗi, giữ nội dung; không tạo card không có study | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:73` - **E7 — Tag không hợp lệ, hoặc thẻ đã đủ 10 tag:** lỗi có kiểu; tag của thẻ giữ | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:76` ## UI | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:78` **UI states:** loading · loaded · empty · submitting · error | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:80` ## Local | superseded → FN-CARD-002 (Kết quả) |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:82` **Postconditions:** Card tồn tại kèm đúng một study state, đúng scheduler và | superseded → FN-CARD-002 (Kết quả) |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:85` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:87` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:89` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:91` - [ ] **Given** một deck `unset` và một draft hợp lệ, **when** người dùng thêm c | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:92` - [ ] **Given** một card đã có study state và lịch sử, **when** người dùng sửa n | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:93` - [ ] **Given** người dùng xoá đúng một card, **when** xác nhận, **then** card v | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:94` - [ ] **Given** người dùng xoá nhiều card, **when** xác nhận, **then** tất cả và | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:95` - [ ] **Given** card bị xoá là card active cuối cùng của deck, **when** xoá thàn | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:96` - [ ] **Given** deck còn card nhưng bộ lọc đang bật không khớp card nào, **when* | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:97` - [ ] **Given** form thêm card, **when** Save ghi xong, **then** form vẫn mở, cá | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:98` - [ ] **Given** người dùng di chuyển card sang deck khác cùng root, **when** xác | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:99` - [ ] **Given** bộ lọc hoặc search đang áp và mới tải một phần kết quả, **when** | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:100` - [ ] **Given** một hoặc nhiều card đã chọn, **when** áp Flag hoặc Remove flag, | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:101` - [ ] **Given** một tên tag gắn cho nhiều card, **when** attach, **then** hệ thố | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:102` - [ ] **Given** card list ở chế độ thường, **when** chạm một hàng, **then** chi | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:103` - [ ] **Given** mặt trước hoặc mặt sau rỗng, hoặc vượt giới hạn độ dài, **when** | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:104` - [ ] **Given** ghi card mới thất bại, **when** người dùng thấy lỗi, **then** nộ | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:105` - [ ] **Given** deck đích không còn hợp lệ (mất, là root, giữ deck con, hoặc chí | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md:106` - [ ] **Given** một card trong lô vi phạm luật (ví dụ đã đủ 10 tag), **when** th | moved → `USE_CASES.md` |

## features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md

| Source item | Outcome |
|---|---|
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:2` id: UC-CARD-002 | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:3` title: Xem chi tiết một card và lịch sử học của nó | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:4` status: ready | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:5` rules: [BR-CARD-003, BR-CARD-005, BR-CARD-006, BR-CARD-007, BR-CARD-008, BR-CARD | superseded → FN-CARD-013, FN-CARD-014 (Business rules) |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:6` code: [lib/features/card/domain/usecases/watch_card_detail_use_case.dart, lib/fe | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:10` **Actor:** Người dùng | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:16` ## Main flow | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:18` **Main flow:** | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:19` 1. Người dùng chạm một hàng card. Hệ thống mở màn chi tiết **chỉ đọc** của đúng | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:21` 2. Hệ thống hiển thị toàn bộ nội dung thẻ: mặt trước đầy đủ, mặt sau đầy đủ, và | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:24` 3. Hệ thống hiển thị phần siêu dữ liệu và trạng thái học **hiện tại**: tag, cờ, | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:28` 4. Hệ thống tải trang lịch sử đầu tiên — 50 event gần nhất, mới nhất trước | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:31` 5. Mỗi event nói: thời điểm, chế độ học, loại lượt, hành động đã ghi, lý do kết | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:34` 6. Người dùng cuộn tới cuối danh sách lịch sử và chọn tải thêm; hệ thống nối | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:37` 7. Người dùng quay lại. Hệ thống trả về danh sách card **đúng như lúc rời đi** — | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:41` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:43` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:44` - **A1 — Sửa thẻ:** người dùng chọn hành động `Edit` tường minh trên màn chi | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:48` - **A2 — Thẻ chưa có lịch sử:** phần dòng thời gian hiện trạng thái rỗng có nội | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:51` - **A3 — Lịch sử trải nhiều generation:** sau một lần Reset (UC-SRS-001), các ev | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:54` - **A4 — Chạm khi đang ở chế độ chọn nhiều:** chạm giữ nguyên nghĩa chọn/bỏ | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:56` - **A5 — Đã tải hết lịch sử:** hệ thống nói rõ đã hết thay vì để một nút tải | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:59` **Error flows:** | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:60` - **E1 — Thẻ không tồn tại khi mở:** deep link hoặc route cũ trỏ tới một id đã | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:63` - **E2 — Thẻ bị xoá từ màn khác khi chi tiết đang mở:** stream nội dung chuyển | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:66` - **E3 — Đọc nội dung/trạng thái thất bại:** lỗi database map thành lý do có | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:69` - **E4 — Tải một trang lịch sử thất bại:** các event đã hiện **giữ nguyên**; | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:72` - **E5 — Kết quả trang tới muộn sau khi người dùng đã rời hoặc đã thử lại:** hệ | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:76` ## UI | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:78` **UI states:** loading (đọc nội dung + trạng thái) · loaded không có lịch sử · | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:83` ## Local | superseded → FN-CARD-013 (Kết quả: không ghi gì) |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:85` **Postconditions:** Database không đổi — nội dung, `updated_at`, study state, | superseded → FN-CARD-013 (Kết quả: không ghi gì) |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:89` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:91` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:93` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:95` - [ ] **Given** chạm một hàng card ở chế độ thường, **when** chi tiết mở, **then | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:96` - [ ] **Given** chi tiết đang mở, **when** tag, study state hoặc nội dung đổi, * | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:97` - [ ] **Given** một card có lịch sử, **when** chi tiết tải, **then** trang đầu l | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:98` - [ ] **Given** một event lịch sử, **when** hiển thị, **then** nó nêu thời điểm, | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:99` - [ ] **Given** đã cuộn tới cuối trang đã tải, **when** người dùng tải thêm, **t | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:100` - [ ] **Given** người dùng chọn Edit trên chi tiết, **when** editor mở, **then** | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:101` - [ ] **Given** một card chưa có lịch sử, **when** chi tiết mở, **then** dòng th | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:102` - [ ] **Given** người dùng đang ở chi tiết mở từ card list, **when** quay lại, * | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:103` - [ ] **Given** đang ở chế độ chọn nhiều, **when** chạm một hàng, **then** hàng | moved → `USE_CASES.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:104` - [ ] **Given** đã tải hết lịch sử, **when** tới cuối, **then** hệ thống nói rõ | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:105` - [ ] **Given** id card không còn tồn tại (deep link hoặc route cũ), **when** mở | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:106` - [ ] **Given** chi tiết đang mở, **when** card bị xoá ở nơi khác, **then** màn | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:107` - [ ] **Given** đọc nội dung hoặc trạng thái thất bại, **when** lỗi xảy ra, **th | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:108` - [ ] **Given** tải một trang lịch sử thất bại, **when** lỗi xảy ra, **then** cá | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/usecases/UC-CARD-002-xem-chi-tiet-card-va-lich-su-hoc.md:109` - [ ] **Given** một trang lịch sử đang tải, **when** người dùng rời màn hoặc yêu | moved → `USE_CASES.md` |

## features/deck/usecases/UC-DECK-001-tao-root-deck.md

| Source item | Outcome |
|---|---|
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:2` id: UC-DECK-001 | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:3` title: Tạo root deck | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:4` status: ready | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:5` rules: [BR-DECK-002, BR-DECK-004, BR-DECK-005, BR-DECK-020, BR-DECK-021, BR-SRS- | superseded → FN-DECK-001 (Business rules) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:6` code: [lib/features/deck/domain/usecases/create_root_deck_use_case.dart] | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:10` **Actor:** Người dùng | superseded → UC-DECK-001 (intent) + SCR-DECK-001 (the New deck button replaces the Trigger "bấm tạo deck") |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:14` ## Main flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:16` **Main flow:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:17` 1. Người dùng nhập tên deck. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:18` 2. Người dùng **chọn chế độ ôn tập**: `eight_box` hoặc `sm2` (BR-SRS-001). Bắt b | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:20` 3. Hệ thống hiển thị mô tả ngắn cho từng chế độ, kèm lưu ý rằng chế độ sẽ bị kho | superseded → UC-DECK-001 (intent) + SCR-DECK-001 (Copy of the create dialog) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:22` 4. Người dùng xác nhận. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:23` 5. Hệ thống validate tên (BR-DECK-020) và chế độ đã chọn. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:24` 6. Hệ thống tạo root deck với: `parent_id = NULL`, `root_id = id`, | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:27` 7. Deck xuất hiện trong danh sách, rỗng. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:29` **Root deck chỉ chứa deck con** (BR-DECK-004). Nút Create bên trong nó chỉ có mộ | superseded → UC-DECK-001 (root holds sub-decks only) + FN-DECK-008 (create options) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:32` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:34` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:35` - **A1 — Người dùng huỷ:** không tạo gì; nếu đã nhập, hỏi xác nhận trước khi bỏ. | superseded → UC-DECK-001 A1 (intent) + SCR-DECK-001 (Cancel, Back or tap outside: Discard this deck?) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:37` **Error flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:38` - **E1 — Tên rỗng:** lỗi inline dưới ô nhập, không phải snackbar. | superseded → UC-DECK-001 E1 (intent) + SCR-DECK-001 (UI Invariants: name error under the field, not a snackbar) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:39` - **E2 — Tên quá 200 ký tự:** lỗi inline; chặn nhập thêm thay vì cắt âm thầm. | superseded → UC-DECK-001 E2 (intent) + SCR-DECK-001 (Create deck On failure: nameTooLong; the field has no hard cap — owner ruling 2026-10-04 replaces "chặn nhập thêm") |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:40` - **E3 — Chưa chọn chế độ:** lỗi inline ở phần chọn chế độ; không tạo. | superseded → UC-DECK-001 E3 (intent) + SCR-DECK-001 (Create deck On failure: inline under the algorithm choice) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:41` - **E4 — Ghi database thất bại:** hiện lỗi, giữ nguyên form và dữ liệu đã nhập. | superseded → UC-DECK-001 E4 (intent) + SCR-DECK-001 (Create deck On failure: the dialog keeps what was typed) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:43` ## UI | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:45` **UI states:** initial · submitting · error | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:47` ## Local | superseded → FN-DECK-001 (Kết quả) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:49` **Postconditions:** Root deck tồn tại với scheduler đã chọn, `content_type = | superseded → FN-DECK-001 (Kết quả) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:52` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:54` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:56` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:58` - [ ] **Given** một tên hợp lệ và một chế độ ôn tập (`eight_box` hoặc `sm2`), ** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:59` - [ ] **Given** một root deck vừa tạo, **when** người dùng bấm Create bên trong | superseded → UC-DECK-001 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:60` - [ ] **Given** đã có một deck tên "Unit 5", **when** tạo thêm một root deck cũn | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:61` - [ ] **Given** tên rỗng hoặc chỉ có khoảng trắng, **when** xác nhận, **then** l | superseded → UC-DECK-001 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:62` - [ ] **Given** tên dài hơn 200 ký tự, **when** xác nhận, **then** lỗi hiện ngay | superseded → UC-DECK-001 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:63` - [ ] **Given** ghi database thất bại, **when** xác nhận, **then** hệ thống báo | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:64` - [ ] **Given** dialog tạo root deck đã có tên hoặc chế độ ôn, **when** người dù | superseded → UC-DECK-001 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-001-tao-root-deck.md:65` - [ ] **Given** dialog tạo root deck vừa mở, **when** người dùng chưa chọn chế đ | superseded → UC-DECK-001 (intent) + SCR-DECK-001 (presentation of the criterion) |

## features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md

| Source item | Outcome |
|---|---|
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:2` id: UC-DECK-002 | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:3` title: Sửa và xoá deck | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:4` status: ready | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:5` rules: [BR-DECK-015, BR-DECK-020, BR-DECK-022, BR-DECK-023, BR-DECK-025, BR-SRS- | superseded → FN-DECK-002…FN-DECK-006 (Business rules) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:6` code: [lib/features/deck/domain/usecases/rename_deck_use_case.dart, lib/features | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:10` **Actor:** Người dùng | superseded → UC-DECK-002 (Mục tiêu replaces the Trigger) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:14` ## Main flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:16` **Main flow (sửa tên):** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:17` 1. Người dùng đổi tên deck. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:18` 2. Hệ thống validate (BR-DECK-020) và lưu. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:20` **Main flow (đổi chế độ ôn tập — chỉ trên root deck, chỉ khi chưa có thẻ nào học | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:21` 1. Hệ thống hiển thị phần chọn chế độ ở trạng thái **mở khoá** | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:23` 2. Người dùng chọn chế độ khác. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:24` 3. Hệ thống cảnh báo study state của **toàn bộ card trong cây** sẽ được khởi tạo | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:28` 4. Người dùng xác nhận. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:29` 5. Hệ thống đổi scheduler, khởi tạo lại study state toàn cây, **và** đóng mọi | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:32` **Main flow (xoá):** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:33` 1. Hệ thống hỏi xác nhận, nêu rõ số deck con và số card sẽ vào Trash cùng deck | superseded → UC-DECK-002 (intent) + SCR-DECK-001 (Move to Trash dialog) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:35` 2. Người dùng xác nhận. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:36` 3. Hệ thống chuyển deck cùng mọi deck con và card còn active bên dưới vào Trash, | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:41` 4. Người dùng có thể Undo ngay tại chỗ (BR-TRASH-008) hoặc khôi phục về sau từ | superseded → UC-DECK-002 (intent) + SCR-DECK-001 (Undo toast where the deck was deleted, FE-B1 D7) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:44` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:46` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:47` - **A1 — Root deck đã có thẻ học xong chuỗi học mới:** phần chọn chế độ hiển thị | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:50` - **A2 — Sửa deck con:** không có phần chọn chế độ (BR-DECK-025). | superseded → UC-DECK-002 A2 (intent) + SCR-DECK-001 (Review algorithm is a root-only command of the action sheet) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:51` - **A3 — Huỷ xác nhận xoá:** không xảy ra gì. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:52` - **A4 — Xác nhận đúng chế độ deck đang chạy:** thao tác được chấp nhận và không | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:57` **Error flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:58` - **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách vớ | superseded → UC-DECK-002 E1 (intent) + SCR-DECK-001 (deck_not_found and the notFound snackbar) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:60` - **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:62` - **E3 — Xoá thất bại:** hiện lỗi; deck còn nguyên vẹn, và `content_type` của | superseded → UC-DECK-002 E3 (intent) + SCR-DECK-001 (Move to Trash On failure) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:64` - **E4 — Scheduler bị khoá trong lúc bảng chọn đang mở:** người dùng học xong mộ | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:70` ## UI | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:72` **UI states:** loaded · submitting · error | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:74` ## Local | superseded → FN-DECK-005 (Kết quả) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:76` **Postconditions:** | superseded → FN-DECK-005 (Kết quả) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:77` - Sau đổi chế độ: `scheduler_type` mới, mọi study state trong cây khởi tạo lại, | superseded → FN-DECK-003 (Kết quả) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:80` - Sau xoá: deck và mọi descendant active của nó nằm trong Trash, cùng một batch | superseded → FN-DECK-005 (Kết quả) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:85` - Sau xoá một deck con: nếu deck cha là **sub-deck** và vừa mất phần tử con | superseded → FN-DECK-005 (Kết quả) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:89` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:91` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:93` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:95` - [ ] **Given** một tên mới hợp lệ, **when** người dùng đổi tên deck, **then** t | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:96` - [ ] **Given** một root chưa có `first_answered_at`, **when** người dùng chọn c | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:97` - [ ] **Given** người dùng xoá một deck có N deck con active và M card active, * | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:98` - [ ] **Given** người dùng đã xác nhận xoá, **when** transaction xong, **then** | superseded → UC-DECK-002 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:99` - [ ] **Given** vừa xoá một deck, **when** người dùng bấm Undo, **then** deck cù | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:100` - [ ] **Given** một descendant đã ở Trash từ một batch cũ hơn, **when** xoá deck | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:101` - [ ] **Given** một deck cha không phải root vừa mất direct child active cuối cù | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:102` - [ ] **Given** một phiên `in_progress` chạm tới item của batch, **when** xoá xả | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:103` - [ ] **Given** root đã có thẻ hoàn tất chuỗi học mới (`first_answered_at` khác | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:104` - [ ] **Given** đang sửa một deck con, **when** mở phần sửa, **then** không có p | superseded → UC-DECK-002 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:105` - [ ] **Given** hộp thoại xác nhận xoá đang mở, **when** người dùng bấm Cancel, | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:106` - [ ] **Given** root đang chạy chế độ X, khoá hay chưa khoá, **when** người dùng | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:107` - [ ] **Given** deck đã bị xoá ở nơi khác, **when** người dùng đổi tên hoặc xoá | superseded → UC-DECK-002 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:108` - [ ] **Given** đổi chế độ thất bại giữa chừng, **when** transaction dừng, **the | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:109` - [ ] **Given** xoá thất bại giữa chừng, **when** transaction dừng, **then** hệ | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md:110` - [ ] **Given** bảng chọn chế độ đang mở trên một cây chưa khoá, **when** cây bị | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |

## features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md

| Source item | Outcome |
|---|---|
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:2` id: UC-DECK-003 | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:3` title: Xem danh sách deck với tiến độ | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:4` status: ready | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:5` rules: [BR-DECK-002, BR-DECK-003, BR-DECK-011, BR-DECK-026, BR-DECK-027, BR-STUD | superseded → FN-DECK-007, FN-DECK-008 (Business rules) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:6` code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/fea | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:10` **Actor:** Người dùng | superseded → UC-DECK-003 (Mục tiêu replaces the Trigger) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:14` ## Main flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:16` **Main flow:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:17` 1. Hệ thống lấy toàn bộ root deck kèm số card đến hạn — **một query gộp** theo | superseded → FN-DECK-007 (one aggregated query per emission) + UC-DECK-003 step 1 |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:19` 2. Người dùng thấy mỗi deck với tên, tổng số card trong cây, **hai** số của | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:22` 3. Deck có card đến hạn được làm nổi bật bằng **cả biểu tượng lẫn chữ**, không | superseded → UC-DECK-003 step 3 (intent) + BR-STUDY-067, BR-STUDY-068 (icon tile is the deck's identity; chips replace total Due + New and the state icon) + SCR-DECK-001 (presentation the V8 app draws) — owner ruling 2026-10-04 |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:31` 4. Mỗi deck có một thanh mastery: số thẻ `mastered` trên mọi thẻ của cây | superseded → UC-DECK-003 step 4 (intent) + SCR-DECK-001 (Accessibility: {n}% mastered; bare track) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:34` 5. Mở một deck chứa deck con hiển thị ở tóm tắt một donut mastery của cả level, | superseded → UC-DECK-003 step 5 (intent) + SCR-DECK-001 (summary card donut) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:36` 6. Mở một deck hiển thị nội dung theo `content_type`: danh sách deck con, hoặc | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:39` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:41` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:42` - **A1 — Chưa có deck nào:** empty state với hai lối đi — thư viện starter (UC-S | superseded → UC-DECK-003 A1 (intent) + SCR-DECK-001 (root_empty) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:44` - **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift, | superseded → UC-DECK-003 A2 + FN-DECK-007 (a stream that re-emits on change) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:46` - **A3 — Cây sâu nhiều cấp:** điều hướng xuống từng cấp; số liệu gộp luôn tính | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:48` - **A4 — Sắp xếp và lọc:** Manual, Newest, Name, Most due hoặc Progress | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:52` **Error flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:53` - **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại. | superseded → UC-DECK-003 E1 (intent) + SCR-DECK-001 (root_error / deck_error with Retry) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:55` ## UI | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:57` **UI states:** loading · loaded · empty · error | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:59` ## Local | superseded → FN-DECK-007 (Kết quả, Business rules) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:61` **Postconditions:** Không đổi gì — use case chỉ đọc. | superseded → FN-DECK-007 (Kết quả, Business rules) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:63` Ghi chú từ mục "Business rules" của nguồn: | superseded → FN-DECK-007 (Kết quả, Business rules) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:65` BR-STUDY-051 — hai tập "chưa học" và "đến hạn" phải khớp **hệt** UC-STUDY-001, n | superseded → FN-DECK-007 (Kết quả, Business rules) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:69` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:71` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:73` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:75` - [ ] **Given** nhiều root deck với card ở nhiều cấp, **when** danh sách deck tả | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:76` - [ ] **Given** deck có card mới, card đến hạn hôm nay và card quá hạn, **when** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:77` - [ ] **Given** cây có N card active trong đó M card `mastered`, **when** xem hà | superseded → UC-DECK-003 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:78` - [ ] **Given** một card `mastered` đang ở Trash, **when** tính mastery của deck | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:79` - [ ] **Given** một deck `content_type = 'deck'`, **when** mở nó, **then** màn h | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:80` - [ ] **Given** không deck nào có card đến hạn, **when** xem danh sách, **then** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:81` - [ ] **Given** chưa có deck nào, **when** mở danh sách, **then** hệ thống hiện | superseded → UC-DECK-003 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:82` - [ ] **Given** danh sách đang mở, **when** dữ liệu đổi ở nơi khác (thêm card, c | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:83` - [ ] **Given** các deck có mastery khác nhau và có deck không có card, **when** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:84` - [ ] **Given** bộ lọc chỉ-deck-có-thẻ-đến-hạn đang bật và không deck nào có thẻ | superseded → UC-DECK-003 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md:85` - [ ] **Given** đọc dữ liệu lỗi, **when** tải danh sách, **then** hệ thống hiện | superseded → UC-DECK-003 (intent) + SCR-DECK-001 (presentation of the criterion) |

## features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md

| Source item | Outcome |
|---|---|
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:2` id: UC-DECK-004 | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:3` title: Tạo phần tử con và xác lập `content_type` | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:4` status: ready | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:5` rules: [BR-CARD-004, BR-DECK-001, BR-DECK-002, BR-DECK-004, BR-DECK-005, BR-DECK | superseded → FN-DECK-008, FN-DECK-009 (Business rules); BR-CARD-004 → FN của feature card (Task 14) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:6` code: [lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/ | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:10` **Actor:** Người dùng | superseded → UC-DECK-004 (intent) + SCR-DECK-001 (the FAB and the unset empty-state actions replace the Trigger "bấm Create") |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:14` Đây là use case định hình toàn bộ cấu trúc cây, và là chỗ dễ cài sai nhất vì nút | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:17` ## Main flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:19` **Main flow:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:20` 1. Người dùng bấm Create trong một deck. | superseded → UC-DECK-004 step 1 (intent) + SCR-DECK-001 (New sub-deck / New card controls) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:21` 2. Hệ thống quyết định lựa chọn hiển thị: | superseded → FN-DECK-008 (create options table) + UC-DECK-004 step 2 |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:23` \| Deck \| Lựa chọn hiện ra \| | superseded → FN-DECK-008 (create options table) + UC-DECK-004 step 2 |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:24` \| root deck (`content_type = 'deck'`, bất biến) \| **chỉ** Create deck (BR-DECK-0 | superseded → FN-DECK-008 (create options table) + UC-DECK-004 step 2 |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:25` \| deck con, `content_type = 'unset'` \| Create card **và** Create deck (BR-DECK-0 | superseded → FN-DECK-008 (create options table) + UC-DECK-004 step 2 |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:26` \| deck con, `content_type = 'card'` \| **chỉ** Create card (BR-DECK-012) \| | superseded → FN-DECK-008 (create options table) + UC-DECK-004 step 2 |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:27` \| deck con, `content_type = 'deck'` \| **chỉ** Create deck (BR-DECK-012) \| | superseded → FN-DECK-008 (create options table) + UC-DECK-004 step 2 |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:29` 3. Người dùng chọn một hành động và nhập nội dung. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:30` 4. Hệ thống thực hiện **trong một transaction** (BR-DECK-008): | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:31` - nếu deck đang `unset`: đặt `content_type` theo hành động đã chọn; | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:32` - tạo phần tử con: card (kèm study state, BR-CARD-004) hoặc deck con mới với | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:36` 5. Từ đây nút Create trong deck này chỉ hiện hành động tương ứng (BR-DECK-012). | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:38` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:40` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:41` - **A1 — Deck đã `card`:** không có lựa chọn tạo deck con, ở bất kỳ đâu trong UI | superseded → UC-DECK-004 A1 (intent) + SCR-DECK-001 (UI Invariants: no New sub-deck at level 10; options from FN-DECK-008) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:43` - **A2 — Deck đã `deck`:** không có lựa chọn tạo card (BR-DECK-010). | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:44` - **A3 — Phần tử con cuối cùng rời đi:** xoá card cuối, xoá deck con cuối hoặc | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:48` - **A4 — Huỷ giữa chừng:** không tạo gì và **không** xác lập `content_type` — | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:51` **Error flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:52` - **E1 — Validate thất bại** (tên deck rỗng, card thiếu mặt): lỗi inline; không | superseded → UC-DECK-004 E1 (intent) + SCR-DECK-001 (New sub-deck On failure: field errors) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:54` - **E2 — Ghi thất bại giữa chừng:** transaction rollback. Deck giữ nguyên | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:57` - **E3 — Cố tạo card trong root deck:** không có đường nào tới được trạng thái | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:60` - **E4 — Deck cha đã ở cấp 10:** tạo deck con bị chặn trước khi ghi (BR-DECK-001 | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:64` ## UI | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:66` **UI states:** initial · submitting · error | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:68` ## Local | superseded → FN-DECK-009 (Kết quả) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:70` **Postconditions:** | superseded → FN-DECK-009 (Kết quả) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:71` - Deck có `content_type` khác `unset`, khớp với loại phần tử con vừa tạo. | superseded → FN-DECK-009 (Kết quả) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:72` - Deck không đồng thời chứa card và deck con (BR-DECK-011). | superseded → FN-DECK-009 (Kết quả) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:73` - Deck con mới có `root_id` đúng bằng root của cha (BR-DECK-002, BR-DECK-019). | superseded → FN-DECK-009 (Kết quả) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:75` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:77` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:79` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:81` - [ ] **Given** một root deck, **when** bấm Create, **then** chỉ có Create deck | superseded → UC-DECK-004 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:82` - [ ] **Given** một deck con `content_type = 'unset'`, **when** bấm Create, **th | superseded → UC-DECK-004 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:83` - [ ] **Given** một deck con `unset`, **when** tạo deck con đầu tiên, **then** n | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:84` - [ ] **Given** một deck con `unset`, **when** tạo card đầu tiên, **then** nó th | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:85` - [ ] **Given** một deck `content_type = 'card'`, **when** mở lựa chọn tạo hoặc | superseded → UC-DECK-004 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:86` - [ ] **Given** một deck `content_type = 'deck'`, **when** mở lựa chọn tạo hoặc | superseded → UC-DECK-004 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:87` - [ ] **Given** một deck con chỉ còn một phần tử con active, **when** phần tử đó | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:88` - [ ] **Given** dialog tạo deck con hoặc card đang mở, **when** người dùng huỷ, | superseded → UC-DECK-004 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:89` - [ ] **Given** tên deck con rỗng hoặc card thiếu một mặt, **when** xác nhận, ** | superseded → UC-DECK-004 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:90` - [ ] **Given** ghi thất bại giữa chừng (ví dụ không ghi được study state), **wh | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:91` - [ ] **Given** một root deck, **when** tạo card trực tiếp trong nó, **then** th | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-004-tao-phan-tu-con-va-xac-lap-content-type.md:92` - [ ] **Given** deck cha ở cấp 10, **when** tạo deck con, **then** bị chặn trước | moved → `USE_CASES.md` |

## features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md

| Source item | Outcome |
|---|---|
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:2` id: UC-DECK-005 | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:3` title: Di chuyển deck trong cây | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:4` status: ready | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:5` rules: [BR-DECK-001, BR-DECK-002, BR-DECK-008, BR-DECK-010, BR-DECK-015, BR-DECK | superseded → FN-DECK-011 (Business rules) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:6` code: [lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart, | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:10` **Actor:** Người dùng | superseded → UC-DECK-005 (Mục tiêu replaces the Trigger) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:14` ## Main flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:16` **Main flow:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:17` 1. Người dùng chọn deck nguồn và deck đích. | superseded → UC-DECK-005 step 1 (intent) + SCR-DECK-001 (move picker deck_move; FN-DECK-010) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:18` 2. Hệ thống kiểm tra, theo thứ tự: | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:19` - đích không phải chính deck nguồn hoặc descendant của nó (BR-DECK-017); | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:20` - đích có `content_type = 'deck'` hoặc `'unset'` (BR-DECK-010) — không thể đưa d | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:22` - root của đích có cùng `scheduler_type` và `generation` với root | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:24` - độ sâu sau move không vượt giới hạn (BR-DECK-001): với `targetDepth` là cấp củ | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:27` 3. Hệ thống thực hiện **trong một transaction** (BR-DECK-018): | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:28` - đặt `parent_id` của deck nguồn thành deck đích; | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:29` - cập nhật `root_id` và `depth` cho **toàn bộ subtree** của deck nguồn (BR-DECK- | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:30` - nếu đích đang `unset`, đặt `content_type = 'deck'` (BR-DECK-008); | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:31` - nếu deck cha **cũ** là sub-deck và vừa mất phần tử con cuối cùng, đặt | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:33` 4. Cây được vẽ lại. | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:35` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:37` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:38` - **A1 — Di chuyển trong cùng một cây (cùng root):** `root_id` không đổi, | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:40` - **A2 — Di chuyển lên thành root deck:** ngoài phạm vi MVP — deck nguồn sẽ cần | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:43` **Error flows:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:44` - **E1 — Đích là chính nó hoặc descendant:** chặn, lỗi rõ ràng "Không thể di | superseded → UC-DECK-005 E1 (intent) + SCR-DECK-001 (Copy: rejections, movingIntoOwnSubtree) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:46` - **E2 — Đích có `content_type = 'card'`:** chặn, giải thích deck đích chỉ chứa | superseded → UC-DECK-005 E2 (intent) + SCR-DECK-001 (Copy: rejections, notADeckContainer) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:48` - **E3 — Root đích khác scheduler hoặc generation:** **chặn**, và đề nghị đặt lạ | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:51` - **E4 — Thất bại giữa chừng:** transaction rollback (BR-DECK-018) — con trỏ cha | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:55` - **E5 — Vượt độ sâu tối đa:** `targetDepth + subtreeHeight > 10` → chặn trước | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:59` ## UI | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:61` **UI states:** loaded · submitting · error | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:63` ## Local | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:65` **Postconditions:** | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:66` - Cây không có cycle (BR-DECK-016). | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:67` - Mọi deck trong subtree đã di chuyển có `root_id` đúng bằng root mới | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:69` - Không deck nào đồng thời chứa card và deck con (BR-DECK-011). | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:70` - Deck đích `unset` nhận phần tử con đầu tiên thành `deck`; cha cũ là sub-deck | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:72` - Không có card study state nào lệch scheduler hoặc generation so với root | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:75` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:77` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:79` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:81` - [ ] **Given** deck nguồn và đích hợp lệ (đích không phải chính nó hay descenda | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:82` - [ ] **Given** đích đang `unset` và deck cha cũ (không phải root) vừa mất phần | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:83` - [ ] **Given** nguồn và đích cùng một root, **when** di chuyển, **then** `root_ | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:84` - [ ] **Given** deck nguồn là root, **when** di chuyển, **then** bị từ chối: đưa | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:85` - [ ] **Given** đích là chính deck nguồn hoặc một descendant của nó, **when** di | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:86` - [ ] **Given** đích có `content_type = 'card'`, **when** di chuyển, **then** bị | superseded → UC-DECK-005 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:87` - [ ] **Given** root của đích khác `scheduler_type` hoặc `generation` với root c | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:88` - [ ] **Given** di chuyển thất bại giữa chừng, **when** transaction dừng, **then | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-005-di-chuyen-deck-trong-cay.md:89` - [ ] **Given** cấp của đích cộng chiều cao subtree vượt 10, **when** di chuyển, | moved → `USE_CASES.md` |

## features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md

| Source item | Outcome |
|---|---|
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:2` id: UC-DECK-006 | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:3` title: Sắp xếp lại Deck cùng cấp | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:4` status: ready | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:5` rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-004, BR-DECK-027, BR-SRS- | superseded → FN-DECK-012 (Business rules) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:6` code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart] | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:10` **Actor:** Người dùng | superseded → UC-DECK-006 (intent) + SCR-DECK-001 (Reorder command, drag, TalkBack Move up / Move down) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:17` ## Main flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:19` **Main flow:** | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:20` 1. Hệ thống lấy sibling liền trước hoặc sau từ thứ tự Manual đã lưu và gửi | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:22` 2. Hệ thống mở một transaction, đọc lại source và target active, xác nhận | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:24` 3. Watch của level phát emission mới; danh sách đổi vị trí tại chỗ. Mọi parent, | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:27` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:29` **Alternative flows:** Ở chế độ Reorder, deck đầu không có action Move up của | superseded → UC-DECK-006 A1, A2 (intent) + SCR-DECK-001 (Rulings: reorder controls and when they show) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:35` **Error flows:** Source hoặc target đã stale, hoặc không còn sibling → transacti | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:39` ## UI | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:41` **UI states:** Ở Manual order, action sheet hiện mục Reorder khi level có từ hai | superseded → SCR-DECK-001 (## States) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:46` ## Local | superseded → FN-DECK-012 (Kết quả) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:48` **Postconditions:** Chỉ `sibling_position` (và timestamp audit của các sibling | superseded → FN-DECK-012 (Kết quả) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:52` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:54` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:56` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:58` - [ ] **Given** hai deck cùng `parent_id` ở Manual order, **when** hệ thống gửi | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:59` - [ ] **Given** nhiều root deck, **when** sắp xếp lại, **then** chúng đổi chỗ tr | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:60` - [ ] **Given** level đang ở Manual order và chỉ có một deck, **when** mở action | superseded → UC-DECK-006 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:61` - [ ] **Given** level đang dùng một sort chỉ để xem (tên, ngày, due hoặc tiến độ | superseded → UC-DECK-006 (intent) + SCR-DECK-001 (presentation of the criterion) |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:62` - [ ] **Given** source và target không còn cùng `parent_id`, **when** sắp xếp lạ | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:63` - [ ] **Given** deck hoặc anchor không còn, **when** sắp xếp lại, **then** thao | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:64` - [ ] **Given** một update lỗi giữa lúc đánh số lại nhóm sibling, **when** trans | moved → `USE_CASES.md` |
| `features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md:65` - [ ] **Given** level đang ở Manual order với từ hai deck, **when** người dùng c | superseded → UC-DECK-006 (intent) + SCR-DECK-001 (presentation of the criterion) |

## features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md

| Source item | Outcome |
|---|---|
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:2` id: UC-PROGRESS-001 | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:3` title: Xem tiến độ học | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:4` status: ready | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:5` rules: [BR-MODE-005, BR-PROGRESS-009, BR-PROGRESS-010, BR-PROGRESS-011, BR-PROGR | superseded → FN-PROGRESS-001 (Business rules) |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:6` code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/f | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:10` **Actor:** Người dùng | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:16` ## Main flow | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:18` **Main flow:** | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:19` 1. Người dùng mở tab Progress. Hệ thống chụp **một** snapshot của | superseded → FN-PROGRESS-001 (one clock and offset reading per emission, stated at the top of functional-spec/progress.md) |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:21` 2. Hệ thống mở **một** stream đọc lịch sử học, gộp ngay trong SQLite thành các | superseded → FN-PROGRESS-001 (one stream; card-day aggregation done in SQL is an implementation note of the BRs) |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:24` 3. Trong lúc chờ emission đầu tiên, màn hình hiện trạng thái loading có nhãn | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:26` 4. Emission tới. Hệ thống hiển thị ba khối, cùng một snapshot: | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:35` 5. Người dùng đọc xong và rời tab. Hệ thống không ghi gì trong toàn bộ luồng | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:38` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:40` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:41` - **A1 — Hôm nay chưa học nhưng hôm qua có:** Today hiện 0, và streak **vẫn | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:44` - **A2 — Chưa từng học lượt nào:** cả ba khối rỗng. Hệ thống hiện một mặt | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:47` - **A3 — Có một lượt mới ghi trong lúc màn đang mở:** người dùng học ở tab khác | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:50` - **A4 — Local midnight trôi qua trong lúc màn đang mở:** cửa sổ bảy ngày trượt | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:53` - **A5 — Reset learning progress ở màn khác rồi quay lại:** mọi con số giữ | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:55` - **A6 — Xoá một card hoặc một deck ở màn khác rồi quay lại:** hoạt động của | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:57` - **A7 — Chỉ lướt `browse` rồi thoát:** không có gì đổi — `browse` không ghi | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:60` **Error flows:** | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:61` - **E1 — Đọc lịch sử thất bại:** hệ thống map exception thành `Failure`; màn | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:64` - **E2 — Retry vẫn lỗi:** màn hình ở lại mặt lỗi; MUST NOT tự thử lại vòng lặp | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:67` ## UI | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:69` **UI states:** loading · loaded-normal (có hoạt động trong cửa sổ) · | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:75` ## Local | superseded → FN-PROGRESS-001 (read-only, stated at the top of functional-spec/progress.md) |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:77` **Postconditions:** Database không đổi ở mọi nhánh, kể cả nhánh lỗi và nhánh | superseded → FN-PROGRESS-001 (read-only, stated at the top of functional-spec/progress.md) |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:80` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:82` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:84` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:86` - [ ] **Given** người dùng mở tab Progress, **when** hệ thống đọc xong, **then** | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:87` - [ ] **Given** màn Progress đang mở, **when** người dùng chỉ đọc rồi rời tab ho | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:88` - [ ] **Given** hôm nay chưa học nhưng hôm qua có, **when** mở Progress, **then* | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:89` - [ ] **Given** đã có deck nhưng chưa từng học lượt nào, **when** mở Progress, * | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:90` - [ ] **Given** màn Progress đang mở, **when** một answer mới được ghi ở nơi khá | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:91` - [ ] **Given** màn Progress đang mở lúc gần nửa đêm, **when** local midnight tr | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:92` - [ ] **Given** đã học rồi reset learning progress ở màn khác, **when** quay lại | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:93` - [ ] **Given** một card đã được trả lời rồi bị xoá cứng (trực tiếp hoặc theo ca | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:94` - [ ] **Given** một phiên chỉ lướt `browse`, một card hoặc deck trong Trash, hoặ | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:95` - [ ] **Given** lần đọc lịch sử thất bại, **when** màn Progress nhận lỗi, **then | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md:96` - [ ] **Given** Retry vẫn lỗi, **when** người dùng ở lại màn lỗi, **then** hệ th | moved → `USE_CASES.md` |

## features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md

| Source item | Outcome |
|---|---|
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:2` id: UC-PROGRESS-002 | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:3` title: Xem tiến độ theo deck | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:4` status: ready | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:5` rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-CORE-001, BR-PROGRESS-001, BR- | superseded → FN-PROGRESS-001 + FN-PROGRESS-002 (Business rules) |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:6` code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/f | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:10` **Actor:** Người dùng | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:15` ## Main flow | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:17` **Main flow:** | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:18` 1. Người dùng mở tab Progress. Hệ thống hiển thị **cấp thư viện** ngay dưới | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:23` 2. Mỗi hàng mang tên deck, đường dẫn của nó khi có, và bốn số của khoảng đang | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:27` 3. Danh sách sắp theo số thẻ đã học giảm dần, tie-break bằng tên đã fold rồi | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:29` 4. Người dùng chạm `30 ngày`. Mọi số trên màn hình và thứ tự danh sách đổi ngay | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:32` 5. Người dùng chạm một hàng. Hệ thống mở **cấp của deck đó**: cùng bố cục, tổng | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:35` 6. Trong lúc màn hình mở, một lượt học được ghi ở nơi khác — hoặc một thẻ được | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:38` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:40` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:41` - **A1 — Deck chứa thẻ chứ không chứa deck con:** cấp đó không có hàng nào để | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:45` - **A2 — Thư viện chưa có deck nào:** hệ thống chỉ hiện empty state và **không** | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:49` - **A3 — Có deck nhưng khoảng đang chọn không có hoạt động nào:** danh sách | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:53` - **A4 — Nửa đêm địa phương đi qua khi màn hình đang mở:** cửa sổ trượt một | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:57` **Error flows:** | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:58` - **E1 — Đọc dữ liệu thất bại:** hệ thống hiện lý do đã localize theo **kiểu** | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:62` - **E2 — Deck của deep link không còn tồn tại:** đây **không** phải lỗi. Hệ | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:66` ## UI | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:68` **UI states:** loading · mixed activity (một số deck có, một số không) · | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:73` ## Local | superseded → FN-PROGRESS-001 + FN-PROGRESS-002 (read-only, stated at the top of functional-spec/progress.md) |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:75` **Postconditions:** Database không đổi — nội dung, timestamp, `content_type`, | superseded → FN-PROGRESS-001 + FN-PROGRESS-002 (read-only, stated at the top of functional-spec/progress.md) |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:79` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:81` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:83` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:85` - [ ] **Given** thư viện có ít nhất một root deck, **when** mở tab Progress, **t | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:86` - [ ] **Given** cấp thư viện hoặc cấp một deck đang mở ở khoảng 7 ngày, **when** | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:87` - [ ] **Given** người dùng chạm một hàng deck, **when** cấp của deck đó mở ra, * | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:88` - [ ] **Given** cấp của một deck đang mở, **when** một lượt học được ghi, một de | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:89` - [ ] **Given** một deck chỉ chứa thẻ (không có deck con), **when** mở cấp của d | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:90` - [ ] **Given** thư viện chưa có deck nào, **when** mở tab Progress, **then** hệ | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:91` - [ ] **Given** có deck nhưng khoảng đang chọn không có hoạt động nào, **when** | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:92` - [ ] **Given** cấp thư viện hoặc cấp một deck đang mở gần nửa đêm, **when** loc | moved → `USE_CASES.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:93` - [ ] **Given** lần đọc tiến độ theo deck thất bại, **when** màn hình nhận lỗi, | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:94` - [ ] **Given** deep link tới `/progress/:deckId` của một deck đã bị xoá, ở tron | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md:95` - [ ] **Given** lần đọc tiến độ theo deck thất bại với một `Failure`, **when** m | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |

## features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md

| Source item | Outcome |
|---|---|
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:2` id: UC-REMINDER-001 | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:3` title: Bật nhắc học hằng ngày | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:4` status: ready | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:5` rules: [BR-DECK-003, BR-CORE-001, BR-CORE-004, BR-REMINDER-001, BR-REMINDER-002, | superseded → FN-REMINDER-001…FN-REMINDER-007 (Business rules) |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:6` code: [lib/features/reminders/domain/usecases/watch_reminder_use_case.dart, lib/ | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:10` **Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2). Phần logic xong ở B | dropped — history of how the work was split (BE-B5a, BE-B5b, FE-B5); those specs stay under docs/superpowers/specs, approved PENDING |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:15` **Actor:** Người dùng | pending → SCR-REMINDER-001 (entry point: Settings → Daily reminder); intent kept in UC-REMINDER-001 (Mục tiêu, Preconditions) |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:20` ## Main flow | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:22` **Main flow:** | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:23` 1. Người dùng mở màn nhắc học từ Settings. Hệ thống hiển thị toggle **tắt**, giờ | pending → SCR-REMINDER-001 (the toggle off, 20:00 shown inactive, the two explaining lines); intent kept in UC-REMINDER-001 step 1 + FN-REMINDER-001 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:27` 2. Người dùng bật toggle. Hệ thống chuyển sang trạng thái `enabling` và **chỉ | pending → SCR-REMINDER-001 (the enabling state with the toggle locked); intent kept in UC-REMINDER-001 step 2 + FN-REMINDER-003 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:29` 3. Người dùng cấp quyền. Hệ thống lưu `enabled = true` cùng giờ đang chọn, đặt | superseded → FN-REMINDER-003 (Kết quả) + UC-REMINDER-001 step 3 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:32` 4. Đến giờ, hệ thống đọc lại workload đến hạn. Còn `overdue + due-today > 0` thì | superseded → FN-REMINDER-004 (Kết quả) + UC-REMINDER-001 step 4 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:36` 5. Người dùng chạm notification. Hệ thống mở Study Home, không mở phiên nào | superseded → FN-REMINDER-005 + UC-REMINDER-001 step 5 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:39` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:41` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:42` - **A1 — Đổi giờ nhắc:** chạm hàng giờ → dialog chọn giờ; xác nhận thì lưu giờ | pending → SCR-REMINDER-001 (a tap on the time row opens the time dialog; Cancel changes nothing); intent kept in UC-REMINDER-001 A1 + FN-REMINDER-006 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:45` - **A2 — Tắt nhắc:** tắt toggle → lịch bị huỷ và mọi notification đang chờ bị | pending → SCR-REMINDER-001 (the toggle turned off, no confirmation); intent kept in UC-REMINDER-001 A2 + FN-REMINDER-007 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:47` - **A3 — Đến giờ nhưng không còn thẻ đến hạn:** bỏ lượt nhắc, không hiện gì, vẫn | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:49` - **A4 — Chỉ còn thẻ chưa học:** như A3 — thẻ mới không làm phát notification | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:51` - **A5 — Đổi múi giờ hoặc mở lại app:** hệ thống hoà giải lịch lúc khởi động; | superseded → UC-REMINDER-001 A5 (intent) + the reconcile note at the top of functional-spec/reminders.md (not an FN, spec R6) |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:53` - **A6 — Vuốt bỏ notification:** không có mutation nào; lượt nhắc hôm sau không | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:56` **Error flows:** | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:57` - **E1 — Từ chối quyền (Android 13+):** settings giữ nguyên **tắt**, không đặt | pending → SCR-REMINDER-001 (the typed reason, the system-settings guidance and Retry); intent kept in UC-REMINDER-001 E1 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:60` - **E2 — Nền tảng không hỗ trợ:** toggle bị vô hiệu và màn nói rõ nhắc học chưa | pending → SCR-REMINDER-001 (the disabled toggle and the unavailable line); intent kept in UC-REMINDER-001 E2 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:62` - **E3 — Đặt lịch thất bại:** lỗi của nền tảng map thành lý do có kiểu; settings | pending → SCR-REMINDER-001 (the typed error with Retry, no technical detail); intent kept in UC-REMINDER-001 E3 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:65` - **E4 — Lưu settings thất bại:** không đặt lịch, trạng thái UI quay về giá trị | pending → SCR-REMINDER-001 (the screen back to the stored value, the typed reason and Retry); intent kept in UC-REMINDER-001 E4 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:67` - **E5 — Đọc workload thất bại lúc fire:** bỏ lượt nhắc thay vì hiện notificatio | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:69` - **E6 — Huỷ lịch thất bại khi tắt:** settings **đã** ở trạng thái tắt — ghi đã | pending → SCR-REMINDER-001 (Copy unlike E3: one old reminder may remain; Retry); intent kept in UC-REMINDER-001 E6 + FN-REMINDER-007 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:74` - **E7 — Đọc settings thất bại khi mở màn:** không vẽ hàng nào — không toggle, | pending → SCR-REMINDER-001 (the whole-body error with Retry and no rows; Copy about a read, not E4's); intent kept in UC-REMINDER-001 E7 |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:80` ## UI | pending → SCR-REMINDER-001 (states loading · off · enabling · on · time picker · permission denied · unavailable · schedule error · settings error · cancel error · read error; no empty) |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:82` **UI states:** loading (đọc settings) · off · enabling (đang xin quyền/đặt lịch, | pending → SCR-REMINDER-001 (states loading · off · enabling · on · time picker · permission denied · unavailable · schedule error · settings error · cancel error · read error; no empty) |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:89` ## Local | superseded → FN-REMINDER-003 + FN-REMINDER-007 (Kết quả) + the reconcile note at the top of functional-spec/reminders.md (one pending reminder when on, none when off) |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:91` **Postconditions:** `app_settings` mang đúng trạng thái bật/tắt và giờ nhắc mà | superseded → FN-REMINDER-003 + FN-REMINDER-007 (Kết quả) + the reconcile note at the top of functional-spec/reminders.md (one pending reminder when on, none when off) |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:95` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:97` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:99` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:101` - [ ] **Given** nhắc học đang tắt, **when** người dùng bật lúc 20:00 và cấp quyề | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:102` - [ ] **Given** người dùng từ chối quyền, **when** bật, **then** settings vẫn tắ | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:103` - [ ] **Given** nền tảng không hỗ trợ nhắc học, **when** mở màn hoặc bật, **then | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:104` - [ ] **Given** nền tảng từ chối đặt lịch, **when** bật hoặc đổi giờ, **then** s | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:105` - [ ] **Given** lưu settings thất bại, **when** bật, **then** lượt vừa đặt bị gỡ | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:106` - [ ] **Given** nhắc học đang bật và có thẻ đến hạn, **when** đến giờ, **then** | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:107` - [ ] **Given** không còn thẻ đến hạn, hoặc chỉ còn thẻ chưa học, **when** đến g | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:108` - [ ] **Given** đọc workload thất bại lúc fire, **when** đến giờ, **then** không | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:109` - [ ] **Given** một ngày địa phương đã có digest, **when** lượt nhắc fire lần nữ | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:110` - [ ] **Given** nhắc học đang bật, **when** người dùng đổi giờ, **then** giờ mới | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:111` - [ ] **Given** người dùng tắt nhắc học, **when** huỷ lịch thất bại, **then** se | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:112` - [ ] **Given** app mở lại nhiều lần trong ngày khi đang bật, **when** hoà giải | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:113` - [ ] **Given** đọc settings thất bại khi mở màn, **then** stream báo `Failure`, | moved → `USE_CASES.md` |
| `features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md:114` - [ ] Main 5 và A6 (chạm và vuốt bỏ notification) được kiểm ở BE-B5b và FE-B5, t | moved → `USE_CASES.md` |

## features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md

| Source item | Outcome |
|---|---|
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:2` id: UC-SEARCH-001 | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:3` title: Tìm kiếm toàn thư viện | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:4` status: ready | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:5` rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-009, BR-SEARCH-001, BR-SE | superseded → FN-SEARCH-001 (Business rules) |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:6` code: [lib/features/search/domain/usecases/search_library_use_case.dart, lib/fea | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:10` **Actor:** Người dùng | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:14` ## Main flow | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:16` **Main flow:** | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:17` 1. Hệ thống mở màn tìm kiếm như một route con của nhánh Library — thanh dưới còn | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:19` 2. Trước khi gõ, màn hình nói rõ tìm được những gì: tên deck, mặt trước và mặt | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:21` 3. Người dùng gõ. Sau 250ms im lặng, hệ thống chuẩn hoá câu truy vấn bằng đúng | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:23` 4. Kết quả hiện thành hai mục — Deck trước, Card sau (BR-SEARCH-005). Mỗi mục xế | superseded → FN-SEARCH-001 (decks first; tier order and tie-breaks) + UC-SEARCH-001 step 4 |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:26` 5. Một dòng deck hiển thị đường dẫn tổ tiên phía trên tên. Một dòng card hiển th | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:29` 6. Mở một kết quả deck đi tới deck đó. Mở một kết quả card đi tới chi tiết card | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:32` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:34` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:35` - **A1 — Còn kết quả phía sau:** cuối danh sách có hành động tải thêm; trang kế | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:37` - **A2 — Chỉ có deck, hoặc chỉ có card:** mục không có kết quả không được vẽ tiê | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:39` - **A3 — Dữ liệu đổi ở màn khác:** đổi tên, di chuyển, xoá hoặc đổi tên tag cập | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:41` - **A4 — Xoá trắng ô nhập:** về trạng thái ban đầu ngay lập tức, không chờ | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:44` **Error flows:** | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:45` - **E1 — Trang đầu đọc lỗi:** màn hình lỗi có nút thử lại; danh sách để trống, v | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:47` - **E2 — Trang sau đọc lỗi:** giữ nguyên những gì đã tìm được, chỉ dải cuối danh | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:50` ## UI | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:52` **UI states:** initial (chưa gõ) · debouncing · loading trang đầu · mixed · | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:56` ## Local | superseded → FN-SEARCH-001 (Kết quả: nothing written, no session opened) |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:58` **Postconditions:** Không đổi gì — use case chỉ đọc, và không mở phiên học nào | superseded → FN-SEARCH-001 (Kết quả: nothing written, no session opened) |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:61` Ghi chú từ mục "Business rules" của nguồn: | superseded → FN-SEARCH-001 (Business rules) |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:63` BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-003, BR-SEARCH-004, BR-SEARCH-005, BR-SE | superseded → FN-SEARCH-001 (Business rules) |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:68` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:70` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:72` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:74` - [ ] **Given** màn tìm kiếm chưa có từ nào, **when** hiển thị, **then** hệ thốn | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:75` - [ ] **Given** người dùng gõ, **when** 250 ms im lặng trôi qua, **then** từ tìm | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:76` - [ ] **Given** có kết quả, **when** hiển thị, **then** deck đứng trước card, mỗ | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:77` - [ ] **Given** nhiều kết quả khớp, **when** xếp hạng, **then** mỗi nhóm xếp khớ | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:78` - [ ] **Given** một card khớp qua nhiều trường, **when** hiển thị, **then** nó x | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:79` - [ ] **Given** một kết quả, **when** chạm, **then** kết quả deck mở deck đó, kế | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:80` - [ ] **Given** hơn 50 kết quả, **when** hiển thị, **then** số đếm báo còn nhiều | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:81` - [ ] **Given** chỉ một nhóm có kết quả, **when** hiển thị, **then** nhóm còn lạ | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:82` - [ ] **Given** deck hoặc tag của một kết quả đang hiện bị đổi tên, di chuyển ho | moved → `USE_CASES.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:83` - [ ] **Given** ô nhập đang có chữ, **when** người dùng xoá trắng, **then** màn | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:84` - [ ] **Given** đọc trang đầu thất bại, **when** lỗi xảy ra, **then** màn hiện l | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |
| `features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md:85` - [ ] **Given** đọc một trang sau thất bại, **when** lỗi xảy ra, **then** kết qu | moved → `screens/spec/SCR-SEARCH-001-library-search.md` |

## features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md

| Source item | Outcome |
|---|---|
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:2` id: UC-SETTINGS-001 | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:3` title: Đặt tuỳ chọn ứng dụng | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:4` status: ready | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:5` rules: [BR-SETTINGS-001, BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-S | superseded → FN-SETTINGS-001…FN-SETTINGS-008 (Business rules) |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:6` code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, l | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:10` **Actor:** Người dùng | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:15` ## Main flow | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:17` **Main flow:** | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:18` 1. Người dùng mở tab Settings. Hệ thống đọc dòng `app_settings` qua stream và | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:21` 2. Người dùng đổi trần thẻ mỗi phiên và/hoặc thứ tự thẻ mới. Không có nút lưu: m | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:28` 3. Hệ thống nói rõ tại chỗ rằng mặc định mới áp cho **phiên tạo sau đó**; phiên | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:30` 4. Người dùng chọn theme trong `System` / `Light` / `Dark`. Lựa chọn là một | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:33` 5. Người dùng chọn ngôn ngữ trong `System` / `English` / `Tiếng Việt`. Cùng cơ | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:35` 6. Rời tab và quay lại, hoặc khởi động lại app: mọi lựa chọn tường minh vẫn còn | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:38` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:40` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:41` - **A1 — Root deck có override:** deck đó không đổi gì khi mặc định toàn app | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:46` - **A2 — `System` khi platform đổi:** người dùng đổi dark mode hoặc ngôn ngữ của | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:49` - **A3 — Reset về mặc định:** người dùng chọn `Reset to defaults`, hệ thống hỏi | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:54` - **A4 — Bấm lưu lần thứ hai khi lần đầu chưa xong:** hệ thống bỏ qua lần bấm | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:57` **Error flows:** | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:58` - **E1 — Trần thẻ không hợp lệ:** không phải số, nhỏ hơn tối thiểu hoặc lớn hơn | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:61` - **E2 — Ghi thất bại:** thao tác ghi lỗi → thông báo có kiểu và `Retry`. Draft | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:64` - **E3 — Đọc thất bại:** stream lỗi → trạng thái lỗi của cả màn với `Retry`; | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:66` - **E4 — Xoá override của deck thất bại:** override giữ nguyên, lý do có kiểu, | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:69` ## UI | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:71` **UI states:** loading (đọc lần đầu) · loaded ở mặc định · loaded ở giá trị | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:77` ## Local | superseded → FN-SETTINGS-001 + FN-SETTINGS-005 + FN-SETTINGS-007 + FN-SETTINGS-008 (Kết quả) |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:79` **Postconditions:** `app_settings` giữ đúng một dòng với giá trị người dùng đã | superseded → FN-SETTINGS-001 + FN-SETTINGS-005 + FN-SETTINGS-007 + FN-SETTINGS-008 (Kết quả) |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:85` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:87` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:89` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:91` - [ ] **Given** app vừa cài hoặc mở tab Settings, **when** đọc xong dòng `app_se | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:92` - [ ] **Given** người dùng bấm nút −/+ hoặc giữ trên trần thẻ mỗi phiên, **when* | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:93` - [ ] **Given** người dùng đổi thứ tự thẻ mới hoặc gõ tay một trần thẻ hợp lệ (1 | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:94` - [ ] **Given** người dùng chọn theme `System`, `Light` hoặc `Dark`, **when** ch | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:95` - [ ] **Given** người dùng chọn ngôn ngữ `System`, `English` hoặc `Tiếng Việt`, | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:96` - [ ] **Given** một root deck đang có override `study_config`, **when** mặc định | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:97` - [ ] **Given** một root deck đang có override, **when** người dùng bấm "Use app | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:98` - [ ] **Given** một deck không phải root, **when** ghi hoặc xoá override qua đườ | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:99` - [ ] **Given** app đang để `System` cho theme hoặc ngôn ngữ, **when** brightnes | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:100` - [ ] **Given** người dùng chọn "Reset to defaults" và xác nhận, **when** transa | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:101` - [ ] **Given** một lần ghi của một nhóm (theme, ngôn ngữ hoặc study defaults) đ | moved → `USE_CASES.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:102` - [ ] **Given** người dùng gõ một trần thẻ không phải số, nhỏ hơn 1 hoặc lớn hơn | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:103` - [ ] **Given** một lần ghi tuỳ chọn thất bại, **when** người dùng thấy thông bá | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:104` - [ ] **Given** stream đọc `app_settings` lỗi, **when** màn Settings nhận lỗi, * | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md:105` - [ ] **Given** "Use app defaults" của một deck thất bại khi ghi, **when** người | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |

## features/srs/usecases/UC-SRS-001-reset-learning-progress.md

| Source item | Outcome |
|---|---|
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:2` id: UC-SRS-001 | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:3` title: Reset learning progress | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:4` status: ready | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:5` rules: [BR-SRS-020, BR-SRS-021, BR-SRS-022, BR-SRS-023, BR-SRS-024, BR-SRS-025, | superseded → FN-SRS-001, FN-SRS-002 (Business rules) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:6` code: [lib/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:10` **Actor:** Người dùng | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:15` ## Main flow | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:17` **Main flow:** | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:18` 1. Người dùng chọn đặt lại tiến độ học. | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:19` 2. Hệ thống hiện xác nhận nêu rõ hai danh sách (BR-SRS-030): | superseded → FN-SRS-001 (the kept / lost lists) + UC-SRS-001 step 2; the confirmation's layout pending → SCR-SRS-001 |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:20` - **Giữ nguyên:** deck, toàn bộ cây deck con, flashcard, media, tag, mọi nội | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:22` - **Mất:** lịch ôn hiện tại, ngày đến hạn, box / ease factor / interval, trạng | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:25` 3. Người dùng có thể chọn **chế độ ôn tập mới** ngay trong bước này — đây là mục | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:27` 4. Người dùng xác nhận. | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:28` 5. Hệ thống thực hiện, **trong một transaction duy nhất** (BR-SRS-027): | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:29` - tăng `generation` của root deck (BR-SRS-020); | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:30` - đặt `scheduler_type` / `version` / `config` mới nếu người dùng đã chọn; | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:31` - đặt `first_answered_at = NULL` → scheduler mở khoá (BR-SRS-024); | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:32` - khởi tạo lại study state của **toàn bộ** card trong cây (mọi cấp), theo | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:34` - mọi study session `in_progress` của cây → `invalidated`, | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:36` - **không** đụng tới `review_log` (BR-SRS-023), và **không** đụng tới | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:38` 6. Người dùng quay về deck; toàn bộ card đã trở lại trạng thái Học mới | superseded → UC-SRS-001 step 6 + FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:42` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:44` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:45` - **A1 — Reset mà không đổi chế độ:** hợp lệ. Dùng khi người dùng chỉ muốn học l | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:47` - **A2 — Reset trên deck chưa có lượt học:** vẫn cho phép, nhưng nêu rõ là không | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:49` - **A3 — Huỷ ở bước xác nhận:** không xảy ra gì. | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:50` - **A4 — Reset trên deck con:** không có thao tác này. Reset chỉ tồn tại ở root | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:53` **Error flows:** | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:54` - **E1 — Thất bại giữa chừng:** transaction rollback (BR-SRS-027). Root giữ nguy | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:57` - **E2 — Người dùng có phiên đang mở ở màn khác:** phiên đó đã bị chuyển | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:61` ## UI | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:63` **UI states:** loaded · submitting · error | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:65` ## Local | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:67` **Postconditions:** | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:68` - `generation` tăng đúng 1. | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:69` - Mọi study state trong cây có generation mới, scheduler mới, `due_at = NULL`. | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:70` - `first_answered_at IS NULL`. | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:71` - Không còn session `in_progress` nào của cây. | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:72` - `review_log` cũ còn nguyên, mang generation cũ (BR-SRS-023). | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:73` - Cấu trúc cây và `content_type` không đổi (BR-SRS-021). | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:74` - Bất biến BR-SRS-028 và BR-SRS-029 giữ nguyên. | superseded → FN-SRS-002 (Kết quả) |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:76` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:78` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:80` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:82` - [ ] **Given** một root đã khoá scheduler và đã học, **when** người dùng xác nh | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:83` - [ ] **Given** một reset vừa xong, **when** kiểm tra dữ liệu, **then** cây deck | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:84` - [ ] **Given** một reset vừa xong, **when** kiểm tra `review_log`, **then** các | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:85` - [ ] **Given** nhiều cây deck độc lập, **when** một cây được reset, **then** cá | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:86` - [ ] **Given** reset giữ nguyên chế độ đang chạy, **when** người dùng xác nhận, | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:87` - [ ] **Given** một root chưa từng học hoặc không có card, **when** hộp xác nhận | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:88` - [ ] **Given** hộp xác nhận reset đang mở, **when** người dùng bấm Huỷ, **then* | moved → `screens/spec/SCR-SRS-001-review-algorithm.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:89` - [ ] **Given** một deck con, **when** người dùng tìm thao tác đặt lại tiến độ h | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:90` - [ ] **Given** một ghi lỗi giữa transaction reset, **when** hệ thống xử lý, **t | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:91` - [ ] **Given** cây có một phiên `in_progress`, **when** reset được thực hiện, * | moved → `USE_CASES.md` |
| `features/srs/usecases/UC-SRS-001-reset-learning-progress.md:92` - [ ] **Given** một root không tồn tại hoặc đang ở Trash, **when** yêu cầu reset | moved → `USE_CASES.md` |

## features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md

| Source item | Outcome |
|---|---|
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:2` id: UC-STARTER-001 | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:3` title: Khởi động lần đầu và chọn starter deck | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:4` status: ready | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:5` rules: [BR-CARD-004, BR-DECK-002, BR-STARTER-001, BR-STARTER-002, BR-STARTER-003 | superseded → FN-STARTER-001 + FN-STARTER-002 (Business rules) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:6` code: [lib/features/starter_decks/domain/usecases/watch_starter_library_use_case | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:10` **Phạm vi:** Starter library, phần store (BE-B4, [spec](../../../superpowers/spe | dropped — history of how the work was split (BE-B4, FE-B4); those specs stay under docs/superpowers/specs, approved PENDING |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:13` **Actor:** Người dùng mới cài app | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:17` ## Main flow | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:19` **Main flow:** | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:20` 1. Người dùng mở app. | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:21` 2. Hệ thống khởi tạo database. | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:22` 3. Người dùng thấy màn hình chưa có deck, kèm hai lối đi: **chọn từ thư viện | superseded → UC-STARTER-001 step 3 (intent) + SCR-DECK-001 (root_empty: Create deck, Browse starter decks) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:24` 4. Người dùng mở thư viện starter deck. | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:25` 5. Hệ thống đọc manifest template và hiện danh sách: tên, số card, ngôn ngữ, | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:28` 6. Người dùng chọn một starter deck. | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:29` 7. Hệ thống hỏi **chế độ ôn tập** cho bản sao, gợi ý sẵn `default_scheduler_type | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:31` 8. Hệ thống **tạo bản sao** trong một transaction (BR-STARTER-009): root deck mớ | superseded → FN-STARTER-002 (one transaction: root, sub-decks in template order, cards, study states) + UC-STARTER-001 step 8 |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:35` 9. Bản sao xuất hiện trong danh sách deck. Toàn bộ card là thẻ **chưa học** | superseded → UC-STARTER-001 step 9 (intent) + SCR-DECK-001 (the deck row workload; the presentation gap is recorded there) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:38` 10. Người dùng bấm Study và bắt đầu phiên **học mới** ngay. | superseded → UC-STARTER-001 step 10 (intent); Study on a deck → SCR-DECK-001 Navigate to SCR-STUDY-002 |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:40` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:42` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:43` - **A1 — Bỏ qua thư viện, tự tạo deck:** đi thẳng UC-DECK-001. | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:44` - **A2 — Đã có bản sao từ đúng template và version đó:** hỏi xác nhận, nêu rõ đã | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:47` - **A3 — Cập nhật app có template mới hoặc version mới:** template mới xuất hiện | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:49` - **A4 — Người dùng đã xoá bản sao:** template vẫn còn trong thư viện, lấy lại | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:52` **Error flows:** | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:53` - **E1 — Không mở được database:** màn hình lỗi rõ ràng với hành động thử lại. | superseded → UC-STARTER-001 E1 (intent); the startup failure face goes to NAVIGATION.md (app shell) in Task 42 |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:55` - **E2 — Manifest hỏng hoặc thiếu:** thư viện hiện empty state; app vẫn dùng bìn | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:57` - **E3 — Một file template hỏng:** bỏ qua đúng template đó, các template khác vẫ | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:59` - **E4 — Sao chép thất bại giữa chừng:** transaction rollback (BR-STARTER-009). | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:62` ## UI | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:64` **UI states:** initial · loading · loaded · empty · submitting · error | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:66` ## Local | superseded → FN-STARTER-002 (Kết quả) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:68` **Postconditions:** | superseded → FN-STARTER-002 (Kết quả) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:69` - Bản sao có `source_template_id`, `source_template_version`, `scheduler_type` đ | superseded → FN-STARTER-002 (Kết quả) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:71` - Mọi deck trong bản sao có `root_id` trỏ đúng root mới (BR-DECK-002). | superseded → FN-STARTER-002 (Kết quả) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:72` - Mỗi card có đúng một study state khởi tạo theo scheduler đó. | superseded → FN-STARTER-002 (Kết quả) |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:74` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:76` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:78` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:80` - [ ] **Given** thư viện starter có template "English → Vietnamese · Everyday" v | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:81` - [ ] **Given** đã có một bản sao của đúng template và version đó nằm ngoài Tras | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:82` - [ ] **Given** bản sao duy nhất của một template nằm trong Trash, **when** ngườ | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:83` - [ ] **Given** bản app mới nâng version của một template đã có bản sao, **when* | moved → `USE_CASES.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:84` - [ ] **Given** manifest thiếu hoặc hỏng, **when** mở thư viện, **then** thư việ | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/usecases/UC-STARTER-001-khoi-dong-lan-dau-va-chon-starter-deck.md:85` - [ ] **Given** một lần ghi thất bại giữa chừng khi sao chép, **when** thêm temp | moved → `USE_CASES.md` |

## features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md

| Source item | Outcome |
|---|---|
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:2` id: UC-STUDY-001 | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:3` title: Ôn tập một deck — luồng chính | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:4` status: ready | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:5` rules: [BR-DECK-024, BR-MODE-002, BR-MODE-003, BR-MODE-006, BR-MODE-009, BR-SRS- | superseded → FN-STUDY-001…FN-STUDY-011 (Business rules) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:6` code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/f | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:10` **Actor:** Người dùng | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:14` Đây là luồng chạy hằng ngày và là vertical slice đầu tiên nên xây. | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:16` **Hai loại phiên, không phải một.** *Học mới* đưa thẻ chưa biết qua chuỗi stage | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:20` ## Main flow | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:22` **Main flow:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:23` 1. Người dùng bấm Study. Còn phiên `in_progress` của cùng ngày học thì màn chọn | superseded → UC-STUDY-001 step 1 (intent) + FN-STUDY-001 (two sets with counts, never mixed) + FN-STUDY-010 (continue) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:28` 2. Tập ôn tập rỗng ⇒ lối đó không mở được, kèm thời điểm thẻ gần nhất đến hạn | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:30` 3. **Chọn Học mới** — hệ thống lấy tối đa `card_limit` thẻ chưa học, theo | superseded → FN-STUDY-002 (Kết quả: card_limit, new_card_order, stage sequence) + UC-STUDY-001 step 3 |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:34` 4. **Chọn Ôn tập** — hệ thống hiện các mode chấm điểm của thuật toán: `eight_box | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:41` 5. Cả hai loại phiên ghi `card_limit` đã dùng vào phiên (BR-STUDY-024) và dựng h | superseded → FN-STUDY-002 + FN-STUDY-003 (card_limit stored and queue built in one transaction) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:43` 6. Người dùng trả lời một thẻ. Nguồn của `action` tùy mode: `self_assess` lấy | superseded → FN-STUDY-005 (action source per mode; generation check) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:48` 7. Hệ thống xác định `kind` và ghi tường minh (BR-SRS-015): | superseded → FN-STUDY-005 (kind of the turn) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:49` - phiên `learning` ⇒ `learning`, hoặc `relearning` nếu là lượt lặp trong round; | superseded → FN-STUDY-005 (kind of the turn) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:51` - phiên `reviewing` ⇒ `scheduled` ở lượt đầu của thẻ, `relearning` ở các lượt | superseded → FN-STUDY-005 (kind of the turn) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:53` 8. Lượt `scheduled` tính trạng thái mới bằng thuật toán (BR-SRS-008/BR-SRS-009 h | superseded → FN-STUDY-005 (scheduled turn updates the schedule; learning and relearning only last_answered_at) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:56` 9. Hệ thống ghi một dòng `review_log` kèm `kind` (BR-SRS-019) — ngay lập tức | superseded → FN-STUDY-005 (one review_log row, written at once) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:58` 10. **Chỉ ở phiên `learning`:** thẻ đi hết **stage cuối mà chính nó tham gia** — | superseded → FN-STUDY-005 (learning completion sets learned_at and the first schedule) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:63` 11. Nếu đây là thẻ **đầu tiên hoàn tất chuỗi học mới** của root ở generation này | superseded → FN-STUDY-005 (first_answered_at on the first card to finish learning) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:65` 12. Nếu action khác `forgotten`/`again`, card rời hàng đợi (BR-STUDY-007). | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:66` 13. Hết hàng đợi: session → `completed`, `end_reason = NULL`, `ended_at` được đặ | superseded → UC-STUDY-001 step 8 (intent) + FN-STUDY-005 (completed, end_reason NULL) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:69` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:71` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:72` - **A1 — Thẻ trả lời sai:** cách nó quay lại **tùy mode**, không tùy loại phiên. | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:76` - **A0 — Hết hàng đợi của một stage (chỉ phiên `learning`):** hệ thống chuyển | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:80` - **A0c — Hết một round của stage chấm điểm:** tập thẻ không đạt rỗng thì stage | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:84` - **A0b — Thẻ không đủ dữ liệu cho stage đang chạy:** bỏ qua **có ghi nhận** ở s | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:87` - **A2b — Thẻ chạm trần 3 lượt `relearning` ở `self_assess`:** thẻ rời hàng đợi | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:93` - **A2 — Card quay lại được đánh giá lần nữa:** lượt đó là `relearning` (BR-SRS- | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:97` - **A3 — Thoát giữa phiên:** session → `abandoned`, `end_reason = user_exit`, | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:100` - **A3b — Mở lại app khi còn phiên `in_progress`:** cùng ngày học thì cho tiếp | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:105` - **A4 — Còn card quá hạn ngoài giới hạn 50:** ở tổng kết nói rõ còn bao nhiêu v | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:107` - **A5 — Xoá deck đang ôn dở:** kết thúc phiên với `content_deleted`, hiện tổng | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:111` **Error flows:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:112` - **E1 — Không còn card nào đến hạn lúc bắt đầu:** empty state tích cực (BR-STUD | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:115` - **E2 — Ghi đánh giá thất bại nhưng còn tiếp tục được:** hiện lỗi ngay, **không | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:118` - **E3 — Lỗi ghi không thể tiếp tục:** session → `failed`, | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:121` - **E4 — Generation của session đã lỗi thời** (root bị reset ở màn khác trong lú | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:126` - **E5 — Đọc card thất bại:** màn hình lỗi có nút thử lại. | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:128` ## UI | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:130` **UI states:** loading · loaded (mặt trước) · loaded (đã lật) · submitting · | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:133` `submitting` tách khỏi `loaded` là đúng nguyên tắc "dữ liệu và trạng thái tác vụ | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:137` ## Local | superseded → FN-STUDY-005 (Kết quả) + FN-STUDY-009 + FN-STUDY-011 (how a session ends) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:139` **Postconditions:** | superseded → FN-STUDY-005 (Kết quả) + FN-STUDY-009 + FN-STUDY-011 (how a session ends) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:140` - Mỗi card đã đánh giá có trạng thái lịch đúng loại lượt, đúng scheduler và đúng | superseded → FN-STUDY-005 (Kết quả) + FN-STUDY-009 + FN-STUDY-011 (how a session ends) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:142` - Mỗi lượt đánh giá có đúng một dòng `review_log` mang `kind`, | superseded → FN-STUDY-005 (Kết quả) + FN-STUDY-009 + FN-STUDY-011 (how a session ends) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:144` - `first_answered_at` của root khác NULL sau khi **thẻ đầu tiên hoàn tất chuỗi | superseded → FN-STUDY-005 (Kết quả) + FN-STUDY-009 + FN-STUDY-011 (how a session ends) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:148` - `study_session.status` và `end_reason` phản ánh đúng cách phiên kết thúc, theo | superseded → FN-STUDY-005 (Kết quả) + FN-STUDY-009 + FN-STUDY-011 (how a session ends) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:150` - Nếu E4 xảy ra, **không** có dòng history nào được ghi cho lượt đó. | superseded → FN-STUDY-005 (Kết quả) + FN-STUDY-009 + FN-STUDY-011 (how a session ends) |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:152` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:154` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:156` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:158` - [ ] **Given** một deck có cả thẻ `learned_at IS NULL` và thẻ đến hạn, **when** | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:159` - [ ] **Given** một root có nhiều thẻ chưa học hơn `card_limit`, **when** người | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:160` - [ ] **Given** một phiên `learning` vừa mở, **when** hết hàng đợi của một stage | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:161` - [ ] **Given** một root có thẻ đến hạn, **when** người dùng mở lối Ôn tập, **th | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:162` - [ ] **Given** một phiên `reviewing` đã mở, **when** hệ thống dựng hàng đợi, ** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:163` - [ ] **Given** một lượt trả lời của mode khác mode đang chạy, hoặc mang action | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:164` - [ ] **Given** một thẻ học mới đi hết stage cuối mà nó tham gia, **when** lượt | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:165` - [ ] **Given** một thẻ được đánh giá khác `forgotten`/`again`, **when** lượt đư | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:166` - [ ] **Given** một thẻ bị đánh giá `forgotten`/`again` ở `self_assess`, **when* | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:167` - [ ] **Given** một thẻ sai trong một round của stage chấm điểm, **when** round | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:168` - [ ] **Given** một phiên `reviewing` `eight_box` có một thẻ sai ở lượt đầu rồi | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:169` - [ ] **Given** một thẻ thiếu dữ liệu cho stage đang chạy (ví dụ không có `examp | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:170` - [ ] **Given** một thẻ đã quay lại 3 lượt `relearning` ở `self_assess`, **when* | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:171` - [ ] **Given** người dùng thoát giữa phiên, **when** thoát, **then** phiên thàn | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:172` - [ ] **Given** còn một phiên `in_progress`, **when** người dùng mở lại app cùng | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:173` - [ ] **Given** deck đang ôn dở bị chuyển vào Trash, **when** việc xoá xảy ra, * | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:174` - [ ] **Given** deck đang ôn dở bị chuyển vào Trash, **when** phiên nhận việc xo | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:175` - [ ] **Given** tập ôn tập rỗng, **when** người dùng mở Study Entry, **then** lố | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:176` - [ ] **Given** ghi một đánh giá gặp database bận, **when** người dùng thử lại đ | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:177` - [ ] **Given** ghi một đánh giá gặp lỗi không thể tiếp tục, **when** hệ thống x | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:178` - [ ] **Given** root của phiên vừa bị reset ở màn khác, **when** người dùng trả | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:179` - [ ] **Given** phiên không đọc được, **when** màn hình mở, **then** hệ thống hi | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md:180` - [ ] **Given** một phiên ôn chạm giới hạn thẻ trong khi cây deck còn thẻ đến hạ | moved → `screens/spec/SCR-STUDY-009-session-summary.md` |

## features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md

| Source item | Outcome |
|---|---|
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:2` id: UC-STUDY-002 | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:3` title: Mở tab Study và chọn việc để học | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:4` status: ready | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:5` rules: [BR-STUDY-008, BR-STUDY-017, BR-STUDY-020, BR-STUDY-036, BR-STUDY-051, BR | superseded → FN-STUDY-012 (Business rules) |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:6` code: [lib/features/study/domain/usecases/watch_study_home_use_case.dart] | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:10` **Actor:** Người dùng | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:14` ## Main flow | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:16` **Main flow:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:17` 1. Hệ thống đọc **một snapshot** gồm session có thể học tiếp và toàn bộ root dec | superseded → FN-STUDY-012 (one snapshot in one transaction; read-only) + UC-STUDY-002 step 1 |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:20` 2. Nếu có đúng một session hợp lệ đang mở, Resume card đứng đầu màn hình và nói | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:23` 3. Dưới Resume là danh sách root deck, mỗi hàng có tên deck, nhãn scheduler khi | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:26` 4. Chạm Resume mở đúng session và đúng lượt đã lưu (BR-STUDY-036), không tạo ses | superseded → UC-STUDY-002 step 4 (intent) + FN-STUDY-010 (resume the saved turn) + FN-STUDY-001 |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:29` 5. Kết thúc, bỏ dở hoặc invalidate một phiên rồi quay lại: danh sách tự cập nhật | superseded → UC-STUDY-002 step 5 (intent) + FN-STUDY-012 (a stream that re-emits on change) |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:32` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:34` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:35` - **A1 — Không có session nào đang mở:** không có Resume card — không phải một | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:37` - **A2 — Session của ngày học cũ, generation đã đổi, deck hoặc card đã bị xoá:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:40` - **A3 — Mọi deck đều không còn gì đến hạn:** danh sách vẫn hiển thị, kèm một dò | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:42` - **A4 — Thư viện chưa có deck nào:** empty state dẫn tới Starter Library (UC-ST | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:44` - **A5 — Có deck nhưng chưa có card nào:** zero state riêng, dẫn về Library để t | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:47` **Error flows:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:48` - **E1 — Đọc thất bại:** trạng thái lỗi có nút thử lại, không nêu tên bảng, câu | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:52` ## UI | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:54` **UI states:** loading · loaded (resume + danh sách) · loaded (không resume) · | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:57` ## Local | superseded → FN-STUDY-012 (Kết quả: reading writes nothing) |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:59` **Postconditions:** Không đổi gì — use case chỉ đọc. Mọi write phát sinh sau đó | superseded → FN-STUDY-012 (Kết quả: reading writes nothing) |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:62` Ghi chú từ mục "Business rules" của nguồn: | superseded → FN-STUDY-012 (Business rules) |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:64` BR-STUDY-075, BR-STUDY-076, BR-STUDY-077. Ngoài ra BR-STUDY-008, BR-STUDY-017, B | superseded → FN-STUDY-012 (Business rules) |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:67` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:69` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:71` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:73` - [ ] **Given** tab Study được mở, **when** hệ thống đọc dữ liệu, **then** phiên | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:74` - [ ] **Given** đúng một phiên hợp lệ đang mở, **when** màn hình tải, **then** t | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:75` - [ ] **Given** nhiều root deck có workload khác nhau, **when** danh sách hiện, | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:76` - [ ] **Given** thẻ Resume đang hiện, **when** người dùng chạm Resume, **then** | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:77` - [ ] **Given** không có phiên nào đang mở, hoặc phiên đang mở đã kết thúc, thuộ | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:78` - [ ] **Given** mọi deck đều không còn gì đến hạn, **when** màn hình tải, **then | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:79` - [ ] **Given** thư viện có deck nhưng chưa deck nào có card, **when** màn hình | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:80` - [ ] **Given** việc đọc thất bại, **when** màn hình tải, **then** hệ thống hiện | moved → `screens/spec/SCR-STUDY-001-study-home.md` |
| `features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md:81` - [ ] **Given** thư viện chưa có root deck nào, **when** màn hình tải, **then** | moved → `screens/spec/SCR-STUDY-001-study-home.md` |

## features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md

| Source item | Outcome |
|---|---|
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:2` id: UC-STUDY-003 | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:3` title: Chọn chiều hỏi cho một phiên self-assess | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:4` status: ready | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:5` rules: [BR-MODE-013, BR-MODE-014, BR-MODE-015, BR-MODE-016, BR-MODE-017, BR-MODE | superseded → FN-STUDY-003 + FN-STUDY-004 (Business rules) |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:6` code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/f | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:10` **Actor:** Người dùng | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:16` ## Main flow | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:18` **Main flow:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:19` 1. Người dùng bấm `Review`. Vì `sm2` chỉ offer một mode, hệ thống bỏ qua màn chọ | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:21` 2. Hệ thống hiển thị ba lựa chọn — `Term first` (gắn nhãn Recommended; nhãn khôn | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:25` 3. Người dùng chạm một lựa chọn. Chạm chỉ **chọn**, không mở phiên: lựa chọn bị | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:28` 4. Người dùng bấm `Start review`. Hệ thống khoá sheet trong lúc mở phiên — cú | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:30` 5. Hệ thống mở phiên với chiều đã chọn, materialize hàng đợi trong cùng | superseded → FN-STUDY-003 (direction per queue row; mixed split once) + UC-STUDY-003 step 5 |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:33` 6. Màn phiên học mở ra. Mỗi thẻ hiện đề ở nửa trên theo chiều của dòng nó, và | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:37` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:39` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:40` - **A1 — Đóng sheet:** người dùng vuốt xuống hoặc chạm ra ngoài. Chưa có gì được | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:43` - **A2 — Deck chạy `eight_box`:** sheet này không xuất hiện. Lối vào là màn chọn | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:45` - **A3 — Còn phiên bỏ dở:** sheet ba lối của BR-STUDY-072 hiện trước. Chọn `Cont | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:48` - **A4 — Phiên `mixed` đang chạy:** hai thẻ liên tiếp có thể hỏi hai chiều khác | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:52` **Error flows:** | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:53` - **E1 — Deck đổi scheduler hoặc bị reset trong lúc sheet đang mở:** hệ thống đọ | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:58` - **E2 — Không còn thẻ đến hạn tại thời điểm bấm Start:** phiên bị từ chối và | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:60` - **E3 — Yêu cầu thiếu chiều:** không thể tạo từ UI này; use case vẫn từ chối là | superseded → FN-STUDY-003 (Lỗi: direction missing or not used by the mode) + UC-STUDY-003 E3 |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:63` ## UI | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:65` **UI states:** initial (ba lựa chọn, Term first đã chọn sẵn) · submitting | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:71` ## Local | superseded → FN-STUDY-003 (Kết quả: direction on the session, the queue rows and each review_log row; schedule unchanged) |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:73` **Postconditions:** `study_session.direction` giữ lựa chọn của phiên, | superseded → FN-STUDY-003 (Kết quả: direction on the session, the queue rows and each review_log row; schedule unchanged) |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:78` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:80` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:82` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:84` - [ ] **Given** một root dùng `sm2` có thẻ đến hạn, **when** người dùng bấm Revi | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:85` - [ ] **Given** sheet chọn chiều đang mở, **when** người dùng chọn `Meaning firs | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:86` - [ ] **Given** phiên mở với `Term first` hoặc `Meaning first`, **when** hệ thốn | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:87` - [ ] **Given** một thẻ hỏi theo `Meaning first`, **when** thẻ hiện ra, **then** | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:88` - [ ] **Given** Start review đang mở phiên, **when** người dùng bấm thêm lần nữa | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:89` - [ ] **Given** sheet chọn chiều đang mở, **when** người dùng đóng sheet mà khôn | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:90` - [ ] **Given** deck chạy `eight_box`, **when** người dùng bấm Review, **then** | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:91` - [ ] **Given** còn một phiên `self_assess` bỏ dở, **when** người dùng chọn Cont | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:92` - [ ] **Given** một phiên `Mixed` đang chạy, **when** một thẻ quay lại hàng đợi, | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:93` - [ ] **Given** không còn thẻ nào đến hạn lúc bấm Start review, **when** người d | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:94` - [ ] **Given** yêu cầu mở phiên `self_assess` không kèm chiều, hoặc kèm chiều c | moved → `USE_CASES.md` |
| `features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md:95` - [ ] **Given** sheet chọn chiều đang mở và scheduler của root đổi sang `eight_b | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |

## features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md

| Source item | Outcome |
|---|---|
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:2` id: UC-TAG-001 | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:3` title: Quản lý tag và lọc thẻ theo tag | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:4` status: ready | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:5` rules: [BR-CARD-012, BR-DECK-015, BR-TAG-001, BR-TAG-002, BR-TAG-003, BR-TAG-004 | superseded → FN-TAG-001…FN-TAG-004 + FN-CARD-001 + FN-CARD-012 (Business rules) |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:6` code: [lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart, lib/fe | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:10` **Phạm vi:** Tag Management, phần store (BE-B2, gồm BE-C4). Màn catalog và overl | dropped — history of how the work was split (BE-B2, BE-C4, FE-B2); those specs stay under docs/superpowers/specs, approved PENDING |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:13` **Actor:** Người dùng | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:20` ## Main flow | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:22` **Main flow:** | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:23` 1. Người dùng mở tag catalog. Hệ thống đọc mọi tag của owner hiện tại kèm số thẻ | superseded → FN-TAG-001 (every tag with its active card count, folded-name order) + UC-TAG-001 step 1 |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:25` 2. Hệ thống hiển thị mỗi tag thành một hàng: tên canonical, số thẻ, và một menu | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:27` 3. Người dùng gõ vào ô tìm kiếm để thu hẹp catalog. Hệ thống lọc theo cùng phép | superseded → FN-TAG-001 (the search uses the identity fold) + UC-TAG-001 step 3 |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:30` 4. Người dùng chọn `Rename` trên một hàng. Hệ thống mở form với tên hiện tại đã | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:32` 5. Người dùng sửa tên rồi xác nhận. Hệ thống validate theo BR-TAG-001 và, vì tên | superseded → FN-TAG-003 (rename on the same row; id and links kept) + UC-TAG-001 step 5 |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:35` 6. Người dùng quay lại card list và chạm pill `Tags`. Hệ thống mở overlay lọc | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:37` 7. Người dùng chọn nhiều tag rồi bấm `Apply`. Hệ thống áp vị từ **OR giữa các | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:40` 8. Card list hiển thị đúng tập thẻ khớp, mỗi thẻ đúng một lần, với count khớp | superseded → FN-CARD-001 (each card once; counts read the same query) + UC-TAG-001 step 8 |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:43` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:45` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:46` - **A1 — Đổi tên gây trùng (gộp):** tên mới fold trùng một tag khác đang tồn | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:52` - **A2 — Đổi tên chỉ đổi cách viết hoa:** `noun` → `Noun`. Tên đã fold không | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:55` - **A3 — Xoá tag:** người dùng chọn `Delete`. Hệ thống hỏi xác nhận, nêu rõ số | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:58` - **A4 — Bỏ chọn hết tag trong overlay lọc:** `Clear` đưa tập chọn về rỗng. Tập | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:61` - **A5 — Huỷ overlay lọc:** đóng overlay mà không `Apply` giữ nguyên tập tag | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:63` - **A6 — Tìm kiếm trong catalog không khớp gì:** catalog hiển thị trạng thái | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:66` - **A7 — Lọc theo tag không còn thẻ nào khớp:** card list hiển thị trạng thái | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:69` **Error flows:** | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:70` - **E1 — Đọc catalog thất bại:** hệ thống hiện trạng thái lỗi có Retry; chưa | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:72` - **E2 — Đổi tên với tên không hợp lệ:** rỗng sau trim, quá 50 ký tự, hoặc chứa | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:75` - **E3 — Tag đã biến mất:** tag bị xoá ở nơi khác giữa lúc mở form và lúc ghi → | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:77` - **E4 — Ghi thất bại giữa lúc gộp:** transaction rollback toàn bộ; cả hai tag | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:80` - **E5 — Xoá thất bại:** transaction rollback; tag và mọi liên kết còn nguyên, | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:83` ## UI | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:85` **UI states:** catalog loading · catalog populated · catalog empty (chưa có tag | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:91` ## Local | superseded → FN-TAG-003 + FN-TAG-004 (Kết quả) + FN-TAG-001 + FN-CARD-001 (counts and filter read the same links) |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:93` **Postconditions:** Chỉ hàng `tags` và hàng `card_tags` thay đổi. Nội dung thẻ, | superseded → FN-TAG-003 + FN-TAG-004 (Kết quả) + FN-TAG-001 + FN-CARD-001 (counts and filter read the same links) |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:98` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:100` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:102` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:104` - [ ] **Given** người dùng mở catalog tag, **when** đọc xong, **then** mọi tag c | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:105` - [ ] **Given** người dùng gõ vào ô tìm của catalog, **when** lọc, **then** hệ t | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:106` - [ ] **Given** đổi tên chỉ khác chữ hoa hoặc dấu và tên đã fold không trùng tag | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:107` - [ ] **Given** chọn nhiều tag trong overlay lọc, **when** bấm Apply, **then** c | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:108` - [ ] **Given** một tập tag lọc mới, **when** Apply, **then** cửa sổ phân trang | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:109` - [ ] **Given** tên mới fold trùng một tag khác, **when** xác nhận đổi tên, **th | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:110` - [ ] **Given** người dùng chọn Delete trên một tag, **when** xác nhận, **then** | moved → `USE_CASES.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:111` - [ ] **Given** overlay lọc đang có tag chọn, **when** bấm Clear rồi Apply, **th | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:112` - [ ] **Given** một tập tag đã Apply, **when** đóng overlay mà không Apply lại, | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:113` - [ ] **Given** tìm trong catalog không khớp tag nào, **when** hiển thị, **then* | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:114` - [ ] **Given** lọc theo một tag không có card nào trong deck đang mở, **when** | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:115` - [ ] **Given** đọc catalog thất bại, **when** lỗi xảy ra, **then** hệ thống hiệ | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:116` - [ ] **Given** tên mới rỗng sau khi trim, quá 50 ký tự hoặc chứa ký tự điều khi | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:117` - [ ] **Given** tag bị xoá ở nơi khác giữa lúc mở form và lúc ghi, **when** ghi | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:118` - [ ] **Given** ghi thất bại giữa lúc gộp tag, **when** lỗi xảy ra, **then** cả | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md:119` - [ ] **Given** ghi thất bại khi xoá tag, **when** lỗi xảy ra, **then** tag và m | moved → `USE_CASES.md` |

## features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md

| Source item | Outcome |
|---|---|
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:2` id: UC-TRANSFER-001 | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:3` title: Import card hàng loạt vào một deck | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:4` status: ready | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:5` rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-DECK-004, BR-DECK | superseded → FN-TRANSFER-001…FN-TRANSFER-003 (Business rules) |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:6` code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, l | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:10` **Phạm vi:** backend BE-B3 và màn import FE-B3 đã xong ([spec card transfer](../ | dropped — history of how the work was split (BE-B3, FE-B3); those specs stay under docs/superpowers/specs, approved PENDING |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:12` **Actor:** Người dùng | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:17` ## Main flow | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:19` **Main flow:** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:20` 1. Người dùng mở màn import; hệ thống hiển thị deck đích, số card hiện có và | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:22` 2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV. | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:23` 3. Người dùng bấm Preview; hệ thống parse nguồn trong bộ nhớ (BR-TRANSFER-006) — | superseded → FN-TRANSFER-001 (in memory, nothing written; the TSV and CSV delimiter rules) + UC-TRANSFER-001 step 3 |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:30` 4. Hệ thống mặc định coi hàng đầu là header và tự map các cột trùng tên | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:34` 5. Hệ thống validate toàn bộ hàng bằng đúng các rule của card (BR-TRANSFER-002), | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:37` 6. Người dùng bấm Continue rồi xác nhận ở bước Import — màn xác nhận nêu deck | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:39` 7. Hệ thống ghi toàn bộ trong một transaction (BR-TRANSFER-004): card, study sta | superseded → FN-TRANSFER-003 (one transaction: cards, a fresh study state each, tags, content type) + UC-TRANSFER-001 step 7 |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:41` 8. Hệ thống hiện kết quả — số đã ghi, số trùng bỏ qua, số invalid bị loại, và | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:46` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:48` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:49` - **A1 — Dán văn bản:** ở bước Source người dùng dán các hàng CSV/TSV vào ô | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:53` - **A2 — XLSX nhiều sheet:** hệ thống mặc định chọn sheet không rỗng đầu tiên | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:55` - **A3 — Không có header:** người dùng tắt "First row contains headers"; các | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:58` - **A4 — Bao gồm trùng lặp:** người dùng bật "Include duplicates"; số sẵn sàng | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:60` - **A5 — Đổi file:** người dùng thay file đã chọn; hủy hộp chọn file không | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:63` **Error flows:** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:64` - **E1 — File không đọc được:** file hỏng, có mật khẩu, đuôi không hỗ trợ hoặc | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:67` - **E2 — Nguồn rỗng:** file/sheet/văn bản không có hàng dữ liệu nào → thông báo | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:69` - **E3 — Không còn hàng hợp lệ:** sau validate và policy trùng lặp, số sẽ ghi | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:71` - **E4 — Deck đích không còn hợp lệ lúc ghi:** deck biến mất, thành root-level | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:74` - **E5 — Commit thất bại giữa chừng:** một write lỗi → rollback toàn bộ | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:76` - **E6 — Mọi hàng đã thành trùng lúc ghi:** giữa Preview và Import, deck nhận | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:81` ## UI | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:83` **UI states:** initial (Source trống) · source đã chọn · parsing · parse error · | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:89` ## Local | superseded → FN-TRANSFER-003 (Kết quả) |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:91` **Postconditions:** Mọi card được ghi có đúng một study state mới theo scheduler | superseded → FN-TRANSFER-003 (Kết quả) |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:95` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:97` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:99` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:101` - [ ] **Given** một sub-deck `unset` và một file CSV có header `front,back,tags` | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:102` - [ ] **Given** một hàng trùng `front`+`back` (sau fold) với card đã có trong de | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:103` - [ ] **Given** một file UTF-16 hoặc Latin-1, **when** chọn file, **then** hệ th | moved → `screens/spec/SCR-TRANSFER-001-card-import.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:104` - [ ] **Given** preview đã xong và deck vừa nhận deck con, **when** commit, **th | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md:105` - [ ] **Given** một write lỗi giữa batch, **when** commit, **then** không card, | moved → `USE_CASES.md` |

## features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md

| Source item | Outcome |
|---|---|
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:2` id: UC-TRANSFER-002 | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:3` title: Export card của một deck ra file | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:4` status: ready | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:5` rules: [BR-CARD-012, BR-DECK-015, BR-CORE-001, BR-CORE-004, BR-TAG-001, BR-TAG-0 | superseded → FN-TRANSFER-004…FN-TRANSFER-006 (Business rules) |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:6` code: [lib/features/transfer/domain/usecases/build_export_use_case.dart, lib/fea | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:10` **Phạm vi:** backend BE-B3 và sheet export FE-B3 đã xong ([spec card transfer](. | dropped — history of how the work was split (BE-B3, FE-B3); those specs stay under docs/superpowers/specs, approved PENDING |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:12` **Actor:** Người dùng | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:18` ## Main flow | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:20` **Main flow:** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:21` 1. Người dùng mở export từ một trong hai entry point; hệ thống mở một sheet và | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:25` 2. Hệ thống hiển thị ba format — CSV (mặc định, gắn nhãn Recommended), TSV, | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:28` 3. Người dùng chọn format nếu muốn khác mặc định, rồi bấm `Export N cards`. | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:29` 4. Hệ thống đọc một snapshot nhất quán gồm tên deck, nội dung sáu field và tag | superseded → FN-TRANSFER-005 (one consistent read; nothing written) + UC-TRANSFER-002 step 4 |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:31` 5. Hệ thống encode snapshot thành artifact theo format đã chọn — sáu header | superseded → FN-TRANSFER-005 (six headers, empty cells, BOM, text cells, the file name) |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:34` 6. Hệ thống ghi artifact vào vùng riêng tạm thời của ứng dụng rồi bàn giao cho | superseded → FN-TRANSFER-006 (the private temporary area, then the system share sheet) + UC-TRANSFER-002 step 5 |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:36` 7. Người dùng chọn đích ở share sheet. Hệ thống đóng sheet export và báo đã bàn | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:39` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:41` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:42` - **A1 — Scope là tập đã chọn:** vào từ thanh hành động chọn nhiều; file chứa | superseded → FN-TRANSFER-005 (the chosen set, each card once, created_at order) + UC-TRANSFER-002 A1 |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:46` - **A2 — Đổi format:** chọn TSV hoặc XLSX; canonical schema, thứ tự card và ô | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:48` - **A3 — Đóng share sheet:** người dùng thoát share sheet mà không chọn đích. | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:51` - **A4 — Bấm export lần thứ hai khi đang tạo file:** hệ thống MUST bỏ qua lần | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:54` - **A5 — Huỷ trước khi submit:** `Cancel`, chạm ra ngoài sheet hoặc Android Back | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:57` **Error flows:** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:58` - **E1 — Nền tảng không có share sheet:** hệ thống báo rằng chia sẻ không khả | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:61` - **E2 — Lỗi từ nền tảng khi chia sẻ:** exception của platform channel map | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:64` - **E3 — Đọc dữ liệu thất bại:** đọc dữ liệu lỗi khi lấy snapshot → lý do có | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:66` - **E4 — Encode thất bại:** encoder lỗi → lý do có kiểu phân biệt được với lỗi | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:68` - **E5 — Không có gì để export:** deck rỗng hoặc tập chọn rỗng → domain từ chối | superseded → FN-TRANSFER-005 (Lỗi: emptyScope) + UC-TRANSFER-002 E5; the entry point hidden on an empty deck → SCR-CARD-001 |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:71` - **E6 — Id đã chọn không còn hợp lệ:** một id trong tập chọn đã bị xoá hoặc đã | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:75` ## UI | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:77` **UI states:** initial (scope + format, primary bật) · generating (primary khoá, | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:84` ## Local | superseded → FN-TRANSFER-005 + FN-TRANSFER-006 (Kết quả: database unchanged; six content fields; the file stays in the private temporary area) |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:86` **Postconditions:** Database không đổi — nội dung, timestamp, `content_type`, | superseded → FN-TRANSFER-005 + FN-TRANSFER-006 (Kết quả: database unchanged; six content fields; the file stays in the private temporary area) |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:91` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:93` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:95` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:97` - [ ] **Given** một deck loại card, **when** export CSV, TSV hoặc XLSX, **then** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:98` - [ ] **Given** một ô bắt đầu bằng `=` hoặc một chuỗi như `001`, **when** export | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:99` - [ ] **Given** một tập chọn có một id đã bị xoá hoặc đã chuyển deck, **when** e | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:100` - [ ] **Given** bất kỳ export nào, **when** export xong hoặc thất bại, **then** | moved → `USE_CASES.md` |
| `features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md:101` - [ ] **Given** người dùng đóng share sheet, **when** share trả về, **then** đó | moved → `screens/spec/SCR-TRANSFER-002-card-export.md` |

## features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md

| Source item | Outcome |
|---|---|
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:2` id: UC-TRASH-001 | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:3` title: Trash và khôi phục item đã xoá | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:4` status: ready | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:5` rules: [BR-CARD-010, BR-CARD-012, BR-DECK-001, BR-DECK-009, BR-DECK-010, BR-DECK | superseded → FN-TRASH-001…FN-TRASH-007 + FN-DECK-005 + FN-CARD-004 (Business rules) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:6` code: [lib/features/trash/domain/usecases/watch_trash_use_case.dart, lib/feature | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:8` ## Mục tiêu / Actor / Precondition | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:10` **Phạm vi:** Trash, từ schema v3 (BE-B1). Màn Trash và snackbar Undo thuộc FE-B1 | dropped — history of how the work was split (BE-B1, FE-B1, schema v3); those specs stay under docs/superpowers/specs, approved PENDING |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:12` **Actor:** Người dùng | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:18` ## Main flow | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:20` **Main flow:** | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:21` 1. Người dùng xoá một card hoặc một deck từ luồng đã có (UC-CARD-001, UC-DECK-00 | superseded → FN-DECK-005 + FN-CARD-004 (one batch, descendants, parent back to unset, open sessions ended with content_deleted) + UC-TRASH-001 step 1 |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:26` 2. Màn đang đứng báo item đã chuyển vào Trash và hiện Undo trong một khoảng thời | superseded → SCR-DECK-001 + SCR-CARD-001 (the moved-to-Trash snackbar with Undo for a limited time; SCR-CARD-001 for cards; both specs draw it) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:29` 3. Người dùng mở `Trash` từ app bar của Library. Hệ thống chạy auto-purge trước | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:32` 4. Mỗi hàng nêu tên item, thời điểm đã xoá, đường dẫn gốc **như thông tin**, số | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:35` 5. Người dùng chọn `Restore` trên một hàng. Hệ thống mở picker target dựng từ | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:38` 6. Người dùng chọn một target và xác nhận. Hệ thống chạy một transaction: gỡ | superseded → FN-TRASH-005 + FN-TRASH-006 (one batch, root_id rewritten, target content type set) + UC-TRASH-001 step 6 |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:42` 7. Trash bỏ hàng vừa khôi phục; Library hiện item ở vị trí mới với nguyên id, | superseded → FN-TRASH-005 + FN-TRASH-006 (same id, study state, history and tags) + UC-TRASH-001 step 7 |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:45` ## Alternative / Error flow | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:47` **Alternative flows:** | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:48` - **A1 — Undo ngay sau khi xoá:** người dùng bấm Undo trên snackbar. Hệ thống | superseded → SCR-DECK-001 + SCR-CARD-001 (Undo on the snackbar; SCR-CARD-001 for cards; both specs draw it) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:50` - **A2 — Chọn nhiều:** người dùng bật chế độ chọn trong Trash. Thanh hành động | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:53` - **A3 — Purge vĩnh viễn:** người dùng chọn `Delete permanently`. Hộp thoại nêu | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:57` - **A4 — Batch hết hạn khi Trash đang mở:** auto-purge chạy lại khi màn được | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:60` - **A5 — Deck có descendant đã ở Trash từ trước:** restore batch của deck cha | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:63` - **A6 — Trash rỗng:** màn hiển thị trạng thái rỗng giải thích item đã xoá sẽ ở | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:66` **Error flows:** | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:67` - **E1 — Không có target hợp lệ:** picker mở ra rỗng và giải thích vì sao (cây | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:70` - **E2 — Target hết hợp lệ giữa chừng:** cây đổi sau khi picker mở. Transaction | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:72` - **E3 — Undo không còn dùng được:** vị trí cũ đã bị xoá, đã thành `card`, hoặc | superseded → SCR-DECK-001 + SCR-CARD-001 (the typed Undo reason pointing to the Trash; SCR-CARD-001 for cards; both specs draw it) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:75` - **E4 — Purge bị chặn:** một descendant của batch thuộc batch chưa tới hạn hoặc | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:78` - **E5 — Lỗi ghi:** bất kỳ bước nào của xoá, restore hay purge thất bại → | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:80` - **E6 — Item đã biến mất:** batch được chọn đã bị purge bởi một lần chạy khác. | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:83` ## UI | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:85` **UI states:** loading · empty · cards-only · decks-only · mixed · selection | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:91` ## Local | superseded → FN-TRASH-005 + FN-TRASH-006 + FN-TRASH-007 (Kết quả) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:93` **Postconditions:** Sau bước 7, item nằm dưới target đã chọn với đúng id cũ, và | superseded → FN-TRASH-005 + FN-TRASH-006 + FN-TRASH-007 (Kết quả) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:97` Ghi chú từ mục "Business rules" của nguồn: | superseded → FN-TRASH-001…FN-TRASH-007 (Business rules) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:99` BR-TRASH-001…BR-TRASH-012, và BR-DECK-001, BR-DECK-009, BR-DECK-010, BR-DECK-017 | superseded → FN-TRASH-001…FN-TRASH-007 (Business rules) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:103` ## API | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:105` Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/de | dropped — mục API không áp dụng: app local-only (ADR-001), approved PENDING |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:107` ## Acceptance criteria | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:109` - [ ] **Given** người dùng xoá một card hoặc một deck, **when** thao tác chạy, * | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:110` - [ ] **Given** một item vừa xoá xong, **when** người dùng nhìn Library hoặc Car | superseded → SCR-DECK-001 + SCR-CARD-001 (presentation of the criterion: the Undo snackbar; SCR-CARD-001 for cards; both specs draw it) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:111` - [ ] **Given** người dùng mở Trash từ app bar của Library, **when** màn vẽ xong | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:112` - [ ] **Given** người dùng chọn Restore trên một hàng, **when** picker target mở | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:113` - [ ] **Given** người dùng bấm Undo trên snackbar sau khi xoá, **when** Undo chạ | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:114` - [ ] **Given** Trash đang mở ở chế độ chọn nhiều, **when** người dùng chọn một | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:115` - [ ] **Given** người dùng chọn "Delete permanently" cho một hoặc nhiều item, ** | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:116` - [ ] **Given** Trash đang mở khi một batch vừa quá 30 ngày, **when** app trở lạ | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:117` - [ ] **Given** một deck cha bị xoá trong khi một descendant đã ở Trash từ một b | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:118` - [ ] **Given** Trash không có batch nào, **when** mở màn, **then** hệ thống hiệ | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:119` - [ ] **Given** một item không còn target hợp lệ để restore, **when** picker mở, | moved → `screens/spec/SCR-TRASH-001-trash.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:120` - [ ] **Given** picker restore đang mở, **when** cây deck đổi, **then** danh sác | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:121` - [ ] **Given** vị trí cũ của một batch không còn nhận nó, **when** người dùng b | superseded → SCR-DECK-001 + SCR-CARD-001 (presentation of the criterion: the typed Undo reason; SCR-CARD-001 for cards; both specs draw it) |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:122` - [ ] **Given** một deck được chọn để xoá vĩnh viễn còn giữ một batch khác không | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:123` - [ ] **Given** một bước ghi giữa chừng của purge lỗi, **when** transaction chạy | moved → `USE_CASES.md` |
| `features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md:124` - [ ] **Given** một batch được chọn để restore hoặc purge đã bị xoá vĩnh viễn tr | moved → `USE_CASES.md` |

## features/card/ui.md

| Source item | Outcome |
|---|---|
| `features/card/ui.md:1` # Card — UI | superseded → FN-CARD-001…FN-CARD-014 and UC-CARD-001/002 (the diagram's flows); navigation edges → pending SCR-CARD-001 (Task 33) |
| `features/card/ui.md:3` Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riên | superseded → FN-CARD-001 (đoạn mở đầu) |
| `features/card/ui.md:5` ## Điều hướng card | superseded → FN-CARD-001 |
| `features/card/ui.md:7` Điểm vào là một deck đã có `content_type = 'card'` (BR-DECK-009). Card **đầu tiê | superseded → FN-CARD-002 (Kết quả: the first card sets content_type) |
| `features/card/ui.md:12` flowchart TD | superseded → FN-CARD-001 |
| `features/card/ui.md:13` A["Deck có content_type = card"] --> B["Danh sách card · UC-CARD-001"] | superseded → FN-CARD-001 |
| `features/card/ui.md:14` B -->\|"Chưa có card nào"\| B1["Empty state kèm hành động Thêm card · UC-CARD-001 | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/card/ui.md:16` B --> C{"Người dùng chọn gì"} | superseded → FN-CARD-001 |
| `features/card/ui.md:18` C -->\|"Thêm"\| D["Nhập mặt trước và mặt sau"] | superseded → FN-CARD-002 (Input) |
| `features/card/ui.md:19` D --> E{"Validate · BR-CARD-001, BR-CARD-002"} | superseded → FN-CARD-002 (Lỗi) |
| `features/card/ui.md:20` E -->\|"Rỗng hoặc quá dài"\| E1["Lỗi inline ở đúng ô · UC-CARD-001 E1, E2"] | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:21` E -->\|"Hợp lệ"\| F["Tạo card và study state trong cùng transaction, theo schedule | superseded → FN-CARD-002 (Kết quả) |
| `features/card/ui.md:22` F -->\|"Ghi thất bại"\| F1["Hiện lỗi, giữ nội dung, không tạo card thiếu study sta | superseded → FN-CARD-002 (Lỗi: no card without study state); presentation pending → SCR-CARD-002 |
| `features/card/ui.md:23` F -->\|"Thành công"\| G["Giữ form mở và xoá trống các ô · UC-CARD-001 A4"] | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:24` G --> B | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:26` C -->\|"Chạm một hàng"\| J["Chi tiết card, chỉ đọc · UC-CARD-002"] | superseded → FN-CARD-013 |
| `features/card/ui.md:27` J --> J1["Lịch sử học phân trang keyset, nhóm theo generation · UC-CARD-002, BR- | superseded → FN-CARD-014 |
| `features/card/ui.md:28` J -->\|"Edit — action riêng, không phải cử chỉ chạm"\| H | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/ui.md:29` J -->\|"Back"\| B | moved → `screens/spec/SCR-CARD-004-card-detail.md` |
| `features/card/ui.md:31` C -->\|"Sửa"\| H["Đổi nội dung; study state và history không đổi · UC-CARD-001 A1, | superseded → FN-CARD-003 |
| `features/card/ui.md:32` C -->\|"Xoá"\| I["Xác nhận, xoá kèm study state và history của card đó · UC-CARD-0 | superseded → FN-CARD-004 |
| `features/card/ui.md:33` I --> I1["Card cuối cùng bị xoá → deck tự về unset trong cùng transaction · BR-D | superseded → FN-CARD-004 (Kết quả: the last card sends the deck back to unset) |
| `features/card/ui.md:36` **`J` đổi nghĩa của một lần chạm, và đó là cạnh dễ nhớ sai thứ hai ở đây.** Chạm | superseded → FN-CARD-013 (opening the detail is what selecting a card means outside selection mode); presentation pending → SCR-CARD-001 |
| `features/card/ui.md:41` **`I1` là cạnh dễ vẽ sai nhất trong tài liệu này.** Xoá card cuối cùng **có** đư | superseded → FN-CARD-004 (Kết quả) |
| `features/card/ui.md:46` **Card cũng mang cờ, tag và ba trường phụ (BR-CARD-009, BR-TAG-001, BR-TAG-002, | superseded → FN-CARD-002, FN-CARD-003 (flag, tags, optional fields) |
| `features/card/ui.md:49` ## Validation | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:51` \| Trường \| Rule \| Message hiển thị \| Enforced by \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:53` \| Card.front \| không rỗng sau trim (BR-CARD-001) \| "Mặt trước không được để trốn | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:54` \| Card.back \| không rỗng sau trim (BR-CARD-001) \| "Mặt sau không được để trống" | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:55` \| Card.front \| ≤ 60 ký tự (BR-CARD-002) \| "Mặt trước tối đa 60 ký tự" \| rule \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:56` \| Card.back \| ≤ 240 ký tự (BR-CARD-002) \| "Mặt sau tối đa 240 ký tự" \| rule \| | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:57` \| Card.example / hint / pronunciation \| ≤ 240 ký tự (BR-CARD-003) \| "Tối đa 240 | moved → `screens/spec/SCR-CARD-002-card-create.md` |
| `features/card/ui.md:59` Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server valid | superseded → ADR-015 (the server checks integrity only; business rules live in the app) |

## features/deck/ui.md

| Source item | Outcome |
|---|---|
| `features/deck/ui.md:1` # Deck — UI | superseded → FN-DECK-008, FN-DECK-009, FN-DECK-002, FN-DECK-005, FN-DECK-011, FN-DECK-003 (sơ đồ thay bằng các FN và UC-DECK-002/004/005) |
| `features/deck/ui.md:3` Màn hình, điều hướng và validation dùng chung nhiều UC của feature deck. Hành vi | superseded → FN-DECK-008 (đoạn mở đầu của sơ đồ) |
| `features/deck/ui.md:6` ## Điều hướng trên cây deck | superseded → FN-DECK-008 |
| `features/deck/ui.md:8` Mọi thao tác trên cây deck. Điểm vào là một deck bất kỳ đang mở. | superseded → FN-DECK-008 |
| `features/deck/ui.md:11` flowchart TD | superseded → FN-DECK-008 |
| `features/deck/ui.md:12` A["Một deck đang mở"] --> B{"Người dùng chọn gì"} | superseded → FN-DECK-008 |
| `features/deck/ui.md:14` B -->\|"Bấm Create"\| C{"Deck này là gì"} | superseded → FN-DECK-008 (lựa chọn tạo) |
| `features/deck/ui.md:15` C -->\|"root"\| C1["Chỉ Create deck · BR-DECK-005"] | superseded → FN-DECK-008 (bảng lựa chọn tạo) |
| `features/deck/ui.md:16` C -->\|"con · unset"\| C2["Create card và Create deck · BR-DECK-007"] | superseded → FN-DECK-008 (bảng lựa chọn tạo) |
| `features/deck/ui.md:17` C -->\|"con · card"\| C3["Chỉ Create card · BR-DECK-012"] | superseded → FN-DECK-008 (bảng lựa chọn tạo) |
| `features/deck/ui.md:18` C -->\|"con · deck"\| C4["Chỉ Create deck · BR-DECK-012"] | superseded → FN-DECK-008 (bảng lựa chọn tạo) |
| `features/deck/ui.md:19` C1 --> D["Tạo phần tử con và xác lập content_type trong một transaction · UC-DEC | superseded → FN-DECK-009 (Kết quả) |
| `features/deck/ui.md:20` C2 --> D | superseded → FN-DECK-009 |
| `features/deck/ui.md:21` C3 --> D | superseded → FN-DECK-009 |
| `features/deck/ui.md:22` C4 --> D | superseded → FN-DECK-009 |
| `features/deck/ui.md:23` D -->\|"Cha đã ở cấp 10"\| D1["Chặn trước khi ghi · UC-DECK-004 E4, BR-DECK-001"] | superseded → FN-DECK-009 (Lỗi: depthExceeded) |
| `features/deck/ui.md:24` D -->\|"Huỷ giữa chừng"\| D2["Không tạo gì và content_type không đổi · UC-DECK-004 | superseded → FN-DECK-009 (Kết quả: content_type chỉ đổi khi tạo thật) |
| `features/deck/ui.md:25` D -->\|"Thành công"\| D3["Cây được vẽ lại"] | superseded → FN-DECK-009 |
| `features/deck/ui.md:27` B -->\|"Đổi tên"\| E["Validate rồi lưu · UC-DECK-002, BR-DECK-020"] | superseded → FN-DECK-002 |
| `features/deck/ui.md:29` B -->\|"Xoá"\| F["Xác nhận, nêu rõ số deck con và số card sẽ vào Trash cùng deck · | superseded → FN-DECK-004 |
| `features/deck/ui.md:30` F -->\|"Đồng ý"\| F1["Chuyển cả cây active vào Trash thành một batch, trong một tr | superseded → FN-DECK-005 |
| `features/deck/ui.md:31` F -->\|"Huỷ"\| F2["Không xảy ra gì · UC-DECK-002 A3"] | superseded → FN-DECK-004 (không ghi gì khi huỷ; UC-DECK-002 A3 trong USE_CASES.md) |
| `features/deck/ui.md:33` B -->\|"Di chuyển"\| G{"Bốn phép kiểm, theo thứ tự · UC-DECK-005"} | superseded → FN-DECK-011 (thứ tự kiểm) |
| `features/deck/ui.md:34` G -->\|"Đích là chính nó hoặc descendant"\| G1["Chặn · E1, BR-DECK-017"] | superseded → FN-DECK-011 (Lỗi: movingIntoOwnSubtree) |
| `features/deck/ui.md:35` G -->\|"Đích có content_type card"\| G2["Chặn · E2, BR-DECK-010"] | superseded → FN-DECK-011 (Lỗi: notADeckContainer) |
| `features/deck/ui.md:36` G -->\|"Root đích khác scheduler hoặc generation"\| G3["Chặn, đề nghị reset tường | superseded → FN-DECK-011 (Lỗi: subtreeSchedulerMismatch) |
| `features/deck/ui.md:37` G -->\|"Vượt cấp 10"\| G4["Chặn · E5, BR-DECK-001"] | superseded → FN-DECK-011 (Lỗi: depthExceeded) |
| `features/deck/ui.md:38` G -->\|"Hợp lệ"\| G5["Đổi parent và root_id toàn subtree trong một transaction · B | superseded → FN-DECK-011 (Kết quả) |
| `features/deck/ui.md:41` B -->\|"Đổi chế độ ôn tập · chỉ root"\| I{"first_answered_at"} | superseded → FN-DECK-003 |
| `features/deck/ui.md:42` I -->\|"NULL"\| I1["Mở khoá: cảnh báo rồi khởi tạo lại study state toàn cây, gener | superseded → FN-DECK-003 (Kết quả) |
| `features/deck/ui.md:43` I -->\|"Đã có"\| I2["Khoá, hiện kèm lối đi sang Reset learning progress · UC-DECK- | superseded → FN-DECK-008 (trạng thái khoá) và FN-DECK-003 (Lỗi: schedulerLocked) |
| `features/deck/ui.md:44` I2 --> I3["UC-SRS-001 · mục 5"] | superseded → FN-DECK-003; Reset learning progress là FN của feature srs (Task 15) |
| `features/deck/ui.md:47` **Nhánh `I` là chỗ hai đối tượng gặp nhau.** Chế độ ôn tập là thuộc tính của dec | superseded → FN-DECK-008 (trạng thái khoá hiện, không ẩn) |
| `features/deck/ui.md:51` **`I1` và `I3` là hai thao tác, không phải một thao tác với hai cách gọi.** Cả h | superseded → FN-DECK-003 (Kết quả: không phải Reset learning progress) |
| `features/deck/ui.md:57` **Ai đặt khoá ở `I`:** chính lần một thẻ hoàn tất chuỗi học mới, trong cùng | superseded → FN-STUDY-005 (first_answered_at set in the same transaction as the first card to finish learning; no deck operation writes it) |
| `features/deck/ui.md:61` ## Validation | superseded → SCR-DECK-001 (Copy: rejections — the app's English copy; these Vietnamese messages are not the app's) |
| `features/deck/ui.md:63` \| Trường \| Rule \| Message hiển thị \| Enforced by \| | superseded → SCR-DECK-001 (Copy: rejections — the app's English copy; these Vietnamese messages are not the app's) |
| `features/deck/ui.md:65` \| Deck.name \| không rỗng sau trim (BR-DECK-020) \| "Tên deck không được để trống" | superseded → SCR-DECK-001 (Copy: rejections — the app's English copy; these Vietnamese messages are not the app's) |
| `features/deck/ui.md:66` \| Deck.name \| ≤ 200 ký tự (BR-DECK-020) \| "Tên deck tối đa 200 ký tự" \| rule \| | superseded → SCR-DECK-001 (Copy: rejections — the app's English copy; these Vietnamese messages are not the app's) |
| `features/deck/ui.md:67` \| Deck.move \| đích không phải chính nó hoặc descendant (BR-DECK-017) \| "Không th | superseded → SCR-DECK-001 (Copy: rejections — the app's English copy; these Vietnamese messages are not the app's) |
| `features/deck/ui.md:68` \| Deck.create (sub-deck) \| cấp của deck mới ≤ 10 (BR-DECK-001) \| "Deck đã ở độ s | superseded → SCR-DECK-001 (Copy: rejections — the app's English copy; these Vietnamese messages are not the app's) |
| `features/deck/ui.md:69` \| Deck.move \| cấp đích + chiều cao subtree nguồn ≤ 10 (BR-DECK-001) \| "Di chuyển | superseded → SCR-DECK-001 (Copy: rejections — the app's English copy; these Vietnamese messages are not the app's) |
| `features/deck/ui.md:71` Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server valid | superseded → ADR-015 (server chỉ kiểm tính toàn vẹn; quy tắc nghiệp vụ nằm ở app) |
| `features/deck/ui.md:73` ## Edge case | superseded → FN-DECK-008 |
| `features/deck/ui.md:75` \| Case \| Expected behaviour \| | superseded → FN-DECK-008 |
| `features/deck/ui.md:77` \| Deck rỗng (0 card) \| Empty state với hành động phù hợp `content_type` (BR-DECK | superseded → SCR-DECK-001 `deck_empty`; no study session on an empty deck → the study FNs (Task 16) |

## features/progress/ui.md

| Source item | Outcome |
|---|---|
| `features/progress/ui.md:1` # Progress — UI | superseded → UC-PROGRESS-001 + UC-PROGRESS-002 + FN-PROGRESS-001 + FN-PROGRESS-002; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/progress/ui.md:3` Màn hình và điều hướng dùng chung hai UC của feature. Hành vi riêng của từng UC | superseded → UC-PROGRESS-001 + UC-PROGRESS-002 + FN-PROGRESS-001 + FN-PROGRESS-002; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/progress/ui.md:5` ## Màn hình và điều hướng | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/ui.md:7` \| Màn \| Route \| Mở từ \| Handoff \| | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/ui.md:9` \| 22 · Progress, cấp thư viện \| `/progress` (tab Progress) \| Bottom bar \| [22-pr | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/ui.md:10` \| 22 · Progress, cấp của một deck \| `/progress/:deckId`, trong branch Progress, | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/ui.md:12` Mỗi hàng deck push thêm một cấp; Back về đúng cấp vừa rời. Khoảng 7 hoặc 30 ngày | moved → `screens/spec/SCR-PROGRESS-001-progress.md` |
| `features/progress/ui.md:18` ## Validation | superseded → FN-PROGRESS-001 + FN-PROGRESS-002 (Input: none to validate; read-only) |
| `features/progress/ui.md:20` Không có: màn chỉ đọc, không có trường nhập (BR-PROGRESS-009). | superseded → FN-PROGRESS-001 + FN-PROGRESS-002 (Input: none to validate; read-only) |

## features/reminders/ui.md

| Source item | Outcome |
|---|---|
| `features/reminders/ui.md:1` # Reminders — UI | superseded → UC-REMINDER-001 + FN-REMINDER-001…FN-REMINDER-007; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/reminders/ui.md:3` Màn hình, điều hướng và validation của nhắc học hằng ngày. Hành vi riêng nằm tro | superseded → UC-REMINDER-001 + FN-REMINDER-001…FN-REMINDER-007; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/reminders/ui.md:6` ## Màn hình và điều hướng | pending → SCR-REMINDER-001 (route and where it opens from, with NAVIGATION.md) |
| `features/reminders/ui.md:8` \| Màn \| Route \| Mở từ \| Handoff \| | pending → SCR-REMINDER-001 (route and where it opens from, with NAVIGATION.md) |
| `features/reminders/ui.md:10` \| 24 · Daily reminder \| `/settings/reminder`, trên root navigator, không có bott | pending → SCR-REMINDER-001 (route /settings/reminder on the root navigator, no bottom bar; opened from the Daily reminder row of SCR-SETTINGS-002) |
| `features/reminders/ui.md:11` \| Notification \| chạm mở `/study` (Study Home), không mở phiên nào (BR-REMINDER- | superseded → FN-REMINDER-005 (a tap opens the Study tab, no session); the deep link itself goes to NAVIGATION.md in Task 42 |
| `features/reminders/ui.md:13` Màn 24 đọc nhắc học đã lưu qua stream của `WatchReminderUseCase`; bật, tắt và đổ | superseded → FN-REMINDER-001 (the stream) + FN-REMINDER-003, FN-REMINDER-006, FN-REMINDER-007 (one operation at a time, stated at the top of functional-spec/reminders.md) |
| `features/reminders/ui.md:18` ## Validation | superseded → FN-REMINDER-003 + FN-REMINDER-006 (Input, Lỗi) |
| `features/reminders/ui.md:20` \| Trường \| Rule \| Message hiển thị \| Enforced by \| | superseded → FN-REMINDER-003 + FN-REMINDER-006 (Input, Lỗi) |
| `features/reminders/ui.md:22` \| app_settings.reminder_minute_of_day \| 0–1439, phút trong ngày địa phương (BR-R | pending → SCR-REMINDER-001 (the time dialog: hour 0–23, minute 0–59; an out-of-range number marks the stepper and locks Save; nothing written); rule kept in FN-REMINDER-006 (minuteOutOfRange) |
| `features/reminders/ui.md:23` \| app_settings.reminder_enabled \| chỉ lưu bật khi đã có quyền và đã đặt lịch (BR | pending → SCR-REMINDER-001 (the E1 or E3 banner, the toggle stays off); rule kept in FN-REMINDER-003 (on is stored only with permission and a pending reminder) |

## features/settings/ui.md

| Source item | Outcome |
|---|---|
| `features/settings/ui.md:1` # Settings — UI | superseded → UC-SETTINGS-001 + FN-SETTINGS-001…FN-SETTINGS-008; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/settings/ui.md:3` Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riên | superseded → UC-SETTINGS-001 + FN-SETTINGS-001…FN-SETTINGS-008; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/settings/ui.md:5` ## Màn hình và điều hướng | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/ui.md:7` \| Màn \| Route \| Mở từ \| Handoff \| | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/ui.md:9` \| 23 · Settings \| `/settings` (tab Settings) \| Bottom bar \| [23-settings.md](../ | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/ui.md:10` \| 25 · Theme \| `/settings/theme`, trên root navigator, không có bottom bar \| Hàn | moved → `screens/spec/SCR-SETTINGS-003-theme.md` |
| `features/settings/ui.md:11` \| 26 · Language \| `/settings/language`, trên root navigator, không có bottom bar | moved → `screens/spec/SCR-SETTINGS-004-language.md` |
| `features/settings/ui.md:12` \| 24 · Daily reminder \| `/settings/reminder`, trên root navigator, không có bott | pending → SCR-REMINDER-001 (route /settings/reminder on the root navigator, no bottom bar; opened from the Daily reminder row "Off" or "On · HH:mm") |
| `features/settings/ui.md:13` \| 15 · Study options \| `/decks/deck/:deckId/options`, trên root navigator, không | moved → `screens/spec/SCR-SETTINGS-001-study-options.md` |
| `features/settings/ui.md:15` Reset app options đưa cả nhắc học về tắt lúc 20:00 (BR-SETTINGS-008) và câu chữ | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/ui.md:18` Theme và ngôn ngữ áp cho cả app: `main()` đọc dòng `app_settings` một lần trước | superseded → FN-SETTINGS-001 (read once before the first frame, 2 s at most, then the stream) + FN-SETTINGS-003 + FN-SETTINGS-004 (applied app-wide) |
| `features/settings/ui.md:22` ## Validation | superseded → FN-SETTINGS-002 + FN-SETTINGS-003 + FN-SETTINGS-004 (Input and Lỗi) |
| `features/settings/ui.md:24` \| Trường \| Rule \| Message hiển thị \| Enforced by \| | superseded → FN-SETTINGS-002 + FN-SETTINGS-003 + FN-SETTINGS-004 (Input and Lỗi) |
| `features/settings/ui.md:26` \| app_settings.cardLimit \| cùng bound với tùy chọn của deck (BR-STUDY-003, BR-SE | moved → `screens/spec/SCR-SETTINGS-002-settings.md` |
| `features/settings/ui.md:27` \| app_settings.themeMode \| thuộc `system` \\| `light` \\| `dark` (BR-SETTINGS-005) | superseded → FN-SETTINGS-003 (Input: system, light or dark; the control offers only these) |
| `features/settings/ui.md:28` \| app_settings.language \| thuộc `system` \\| `en` \\| `vi` (BR-SETTINGS-006) \| khô | superseded → FN-SETTINGS-004 (Input: system, en or vi; the control offers only these) |
| `features/settings/ui.md:30` Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server valid | dropped — restates ADR-015 (the server checks integrity, business rules live in the app), approved PENDING |

## features/srs/ui.md

| Source item | Outcome |
|---|---|
| `features/srs/ui.md:1` # SRS scheduler — UI | superseded → FN-DECK-001, FN-DECK-011 (the rules of its validation table) |
| `features/srs/ui.md:3` Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riên | superseded → FN-DECK-001 |
| `features/srs/ui.md:5` ## Validation | superseded → FN-DECK-001 |
| `features/srs/ui.md:7` \| Trường \| Rule \| Message hiển thị \| Enforced by \| | superseded → FN-DECK-001 (Input: algorithm required) + SCR-DECK-001 (Create deck On failure: "Choose how the cards are reviewed.") |
| `features/srs/ui.md:9` \| Deck.schedulerType \| bắt buộc chọn khi tạo root deck (BR-SRS-001) \| "Hãy chọn | superseded → FN-DECK-001 (algorithm required) + SCR-DECK-001 (Copy) — the app's English copy replaces this Vietnamese message |
| `features/srs/ui.md:10` \| Deck.move \| đích cùng root scheduler và generation (BR-SRS-006) \| "Deck đích d | superseded → FN-DECK-011 (Lỗi: subtreeSchedulerMismatch) + SCR-DECK-001 (Copy: "That deck uses a different scheduler.") |
| `features/srs/ui.md:12` Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server valid | superseded → ADR-015 (the server checks integrity only) |
| `features/srs/ui.md:14` ## Edge case | superseded → ADR-008 |
| `features/srs/ui.md:16` \| Case \| Expected behaviour \| | superseded → ADR-008 |
| `features/srs/ui.md:18` \| Đổi giờ hệ thống / lệch múi giờ \| Lưu và so sánh `due_at` bằng UTC ([ADR-008]( | superseded → ADR-008 (due_at stored and compared in UTC) |

## features/starter-decks/ui.md

| Source item | Outcome |
|---|---|
| `features/starter-decks/ui.md:1` # Starter decks — UI | superseded → UC-STARTER-001 + FN-STARTER-001 + FN-STARTER-002; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/starter-decks/ui.md:3` Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riên | superseded → UC-STARTER-001 + FN-STARTER-001 + FN-STARTER-002; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/starter-decks/ui.md:5` ## Màn hình và điều hướng | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/ui.md:7` \| Màn \| Route \| Mở từ \| Handoff \| | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/ui.md:9` \| 03 · Starter decks \| `/decks/starter`, toàn màn hình trên root navigator, khôn | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/ui.md:11` Open trên toast "Added" đi tới deck gốc mới trong Thư viện; "Create a deck" (bản | moved → `screens/spec/SCR-STARTER-001-starter-decks.md` |
| `features/starter-decks/ui.md:16` ## Edge case | superseded → UC-STARTER-001 (first launch) + FN-STARTER-001 (nothing is inserted on its own) |
| `features/starter-decks/ui.md:18` \| Case \| Expected behaviour \| | superseded → UC-STARTER-001 (first launch) + FN-STARTER-001 (nothing is inserted on its own) |
| `features/starter-decks/ui.md:20` \| Mở app lần đầu \| Hiện thư viện starter deck để chọn (UC-STARTER-001). Không tự | superseded → UC-STARTER-001 steps 1–5 (the empty library offers the starter library; nothing is inserted into the person's data) + FN-STARTER-001 |

## features/study/ui.md

| Source item | Outcome |
|---|---|
| `features/study/ui.md:1` # Study session — UI | superseded → UC-STUDY-001 + FN-STUDY-005 (the shared session flow); per-feature UI files are replaced by screen specs (ADR-021) |
| `features/study/ui.md:3` Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riên | superseded → UC-STUDY-001 + FN-STUDY-005 (behaviour) + SCR-DECK-001 (screens live in screen specs, ADR-021) |
| `features/study/ui.md:5` ## Điều hướng phiên học và ôn tập | superseded → UC-STUDY-001 + FN-STUDY-005 + FN-SRS-002 (the session and the reset, linked by generation) |
| `features/study/ui.md:7` Hai UC dùng chung một đối tượng: phiên ôn tập (UC-STUDY-001) và việc đặt lại tiế | superseded → FN-STUDY-005 (Lỗi: stale generation) + FN-SRS-002 (Kết quả: open sessions invalidated); the link between the two UCs is now stated in both FNs |
| `features/study/ui.md:12` flowchart TD | superseded → UC-STUDY-001 (the flow, as text) + FN-STUDY-005 |
| `features/study/ui.md:13` A["Bấm ôn tập trên một deck"] --> B{"Còn thẻ đến hạn không · BR-STUDY-051, BR-ST | superseded → UC-STUDY-001 step 1 + FN-STUDY-001 |
| `features/study/ui.md:14` B -->\|"Không"\| B1["Empty state tích cực kèm thời điểm đến hạn gần nhất; KHÔNG tạ | moved → `screens/spec/SCR-STUDY-002-study-entry.md` |
| `features/study/ui.md:15` B -->\|"Còn"\| C["Tạo study_session in_progress mang root_id và generation hiện tạ | superseded → FN-STUDY-002 + FN-STUDY-003 (the session carries root and generation; it is created when learning or review is chosen, per the code) |
| `features/study/ui.md:16` C --> D["Chọn Học mới hoặc Ôn tập · tối đa `card_limit` thẻ · BR-STUDY-051, BR-S | superseded → FN-STUDY-002 + FN-STUDY-003 (card_limit) + UC-STUDY-001 steps 3–4 |
| `features/study/ui.md:17` D --> E["Render nút đánh giá từ supportedActions: 2 với eight_box, 4 với sm2 · B | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `features/study/ui.md:18` E --> F["Hiện mặt trước và tiến độ phiên"] | moved → `screens/spec/SCR-STUDY-003-study-browse.md` |
| `features/study/ui.md:19` F --> G["Người dùng lật rồi chọn một action"] | moved → `screens/spec/SCR-STUDY-004-study-self-assess.md` |
| `features/study/ui.md:21` G --> H{"session.generation còn khớp root không · BR-SRS-026"} | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:22` H -->\|"Lệch"\| H1["Từ chối ghi; session invalidated, end_reason stale_generation | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:23` H -->\|"Khớp"\| I{"Lượt đầu tiên của card này trong phiên"} | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:24` I -->\|"Đúng"\| J["kind = scheduled: tính lịch mới rồi ghi history · BR-SRS-016"] | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:25` I -->\|"Không"\| K["kind = relearning: chỉ cập nhật last_answered_at · BR-SRS-017" | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:27` J --> L{"Action có phải forgotten hoặc again"} | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:28` K --> L | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:29` L -->\|"Đúng"\| M["Card quay lại trong phiên sau ít nhất 3 card khác · UC-STUDY-00 | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:30` L -->\|"Không"\| N["Card rời hàng đợi · BR-STUDY-007"] | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:31` M --> F | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:32` N --> O{"Hàng đợi còn card không"} | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:33` O -->\|"Còn"\| F | superseded → FN-STUDY-005 (the turn: generation check, kind, schedule, requeue) |
| `features/study/ui.md:34` O -->\|"Hết"\| P["session completed, end_reason NULL; hiện tổng kết · BR-STUDY-013 | superseded → FN-STUDY-005 (completed, end_reason NULL) + UC-STUDY-001 step 8 |
| `features/study/ui.md:36` G -->\|"Thoát giữa phiên"\| Q["session abandoned, end_reason user_exit; mọi đánh g | superseded → FN-STUDY-009 (abandoned, user_exit; recorded turns kept) |
| `features/study/ui.md:38` R["Đặt lại tiến độ học trên root · UC-SRS-001"] --> S["Xác nhận, nêu rõ giữ gì v | superseded → FN-SRS-001 + FN-SRS-002 (reset with what it keeps and loses, and the new algorithm) |
| `features/study/ui.md:39` S --> T["Một transaction: generation +1, first_answered_at NULL, khởi tạo lại st | superseded → FN-SRS-002 (one transaction: generation +1, first_answered_at NULL, tree reinitialised, open sessions invalidated) |
| `features/study/ui.md:40` T --> U["review_log giữ nguyên, mang generation cũ · BR-SRS-023"] | superseded → FN-SRS-002 (review_log kept with the old generation) |
| `features/study/ui.md:41` T -.->\|"Phiên đang mở ở màn khác"\| H1 | superseded → FN-SRS-002 (open sessions invalidated) + FN-STUDY-005 (Lỗi: stale generation) |
| `features/study/ui.md:44` **Cạnh nét đứt `T -.-> H1` là lý do hai UC này ở chung một mục.** Reset chạy ở m | superseded → FN-STUDY-005 (Lỗi: stale generation) + FN-SRS-002; the edge between the two UCs is now stated in both FNs |

## features/tags/ui.md

| Source item | Outcome |
|---|---|
| `features/tags/ui.md:1` # Tags — UI | superseded → UC-TAG-001 + FN-TAG-001…FN-TAG-004; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/tags/ui.md:3` Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riên | superseded → UC-TAG-001 + FN-TAG-001…FN-TAG-004; per-feature UI files are replaced by screen specs (ADR-021) |
| `features/tags/ui.md:5` ## Màn hình và điều hướng | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/ui.md:7` \| Màn \| Route \| Mở từ \| Handoff \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/ui.md:9` \| 05 · Tags \| `/decks/tags`, toàn màn hình trên root navigator, không có bottom | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/ui.md:10` \| 07 · Overlay lọc theo tag \| Bottom sheet trên card list \| Chip Tags trên thanh | moved → `screens/spec/SCR-CARD-001-card-list.md` |
| `features/tags/ui.md:12` "Find cards with this tag" mở tìm kiếm thư viện với tên tag; tìm kiếm nằm trong | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/ui.md:18` ## Validation | superseded → FN-TAG-002 + FN-TAG-003 + FN-CARD-010 (Lỗi) |
| `features/tags/ui.md:20` \| Trường \| Rule \| Message hiển thị \| Enforced by \| | superseded → FN-TAG-002 + FN-TAG-003 + FN-CARD-010 (Lỗi) |
| `features/tags/ui.md:22` \| Tag.name \| không rỗng sau trim (BR-TAG-001) \| "Tên tag không được để trống" \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/ui.md:23` \| Tag.name \| ≤ 50 ký tự (BR-TAG-001) \| "Tên tag tối đa 50 ký tự" \| rule \| | moved → `screens/spec/SCR-TAG-001-tags.md` |
| `features/tags/ui.md:24` \| Tag.name \| không trùng, không phân biệt hoa thường (BR-TAG-001) \| "Tag này đã | superseded → FN-TAG-002 + FN-TAG-003 (a folded-name clash merges, BR-TAG-007) + FN-CARD-010 (attaching by name reuses the existing tag); no "already exists" error remains |
| `features/tags/ui.md:25` \| Card.tags \| ≤ 10 tag mỗi thẻ (BR-TAG-002) \| "Mỗi thẻ tối đa 10 tag" \| rule \| | superseded → FN-CARD-010 (Lỗi: tooManyTags); its copy goes to SCR-CARD-002 |
| `features/tags/ui.md:27` Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server valid | dropped — restates ADR-015 (the server checks integrity, business rules live in the app), approved PENDING |

## features/account/README.md

| Source item | Outcome |
|---|---|
| `features/account/README.md:12` ## Màn hình → Use case |  |
| `features/account/README.md:14` \| Màn hình \| UC \| |  |
| `features/account/README.md:16` \| Welcome, lần mở đầu tiên (màn 29) \| Chưa có UC; hành vi theo account UI spec § |  |
| `features/account/README.md:17` \| Đăng nhập, sheet gộp thư viện, lớp chuyển tiếp (màn 30) \| Chưa có UC; hành vi |  |
| `features/account/README.md:18` \| Nhập mã (màn 31) \| Chưa có UC; hành vi theo account UI spec §5 \| |  |
| `features/account/README.md:19` \| Tài khoản: đăng nhập lại, đổi tài khoản, đăng xuất, xoá (màn 32) \| Chưa có UC; |  |
| `features/account/README.md:20` \| Mục tài khoản trong tab Settings (màn 23) \| Lối vào \| |  |

## features/card/README.md

| Source item | Outcome |
|---|---|
| `features/card/README.md:10` ## Màn hình → Use case || superseded → SCR-CARD-001, SCR-CARD-002, SCR-CARD-003, SCR-CARD-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/card/README.md:12` \| Màn hình \| UC \| || superseded → SCR-CARD-001, SCR-CARD-002, SCR-CARD-003, SCR-CARD-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/card/README.md:14` \| Danh sách card (deck có `content_type = card`) \| UC-CARD-001 \| || superseded → SCR-CARD-001, SCR-CARD-002, SCR-CARD-003, SCR-CARD-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/card/README.md:15` \| Chi tiết card, chỉ đọc \| UC-CARD-002 \| || superseded → SCR-CARD-001, SCR-CARD-002, SCR-CARD-003, SCR-CARD-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/card/README.md:17` Nguồn: trigger của UC-CARD-001 ("Mở một deck có `content_type = 'card'`") và UC- || superseded → SCR-CARD-001, SCR-CARD-002, SCR-CARD-003, SCR-CARD-004 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/deck/README.md

| Source item | Outcome |
|---|---|
| `features/deck/README.md:13` ## Màn hình → Use case || superseded → SCR-DECK-001, SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/deck/README.md:15` \| Màn hình \| UC \| || superseded → SCR-DECK-001, SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/deck/README.md:17` \| Danh sách deck (màn gốc của tab Thư viện) \| UC-DECK-003, UC-DECK-001, UC-DECK- || superseded → SCR-DECK-001, SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/deck/README.md:18` \| Một deck đang mở \| UC-DECK-003 A3, UC-DECK-004, UC-DECK-002, UC-DECK-005 \| || superseded → SCR-DECK-001, SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/deck/README.md:20` Nguồn: trigger của UC-DECK-001 ("màn hình danh sách deck"), UC-DECK-006 || superseded → SCR-DECK-001, SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/monitoring/README.md

| Source item | Outcome |
|---|---|
| `features/monitoring/README.md:12` ## Màn hình → Use case |  |
| `features/monitoring/README.md:14` \| Màn hình \| UC \| |  |
| `features/monitoring/README.md:16` \| Monitoring, danh sách và chi tiết (màn 28) \| Chưa có UC; hành vi theo ADR-018 |  |
| `features/monitoring/README.md:17` \| Mục Admin trong tab Settings (màn 23) \| Lối vào; widget `MonitoringEntrySectio |  |

## features/progress/README.md

| Source item | Outcome |
|---|---|
| `features/progress/README.md:10` ## Màn hình → Use case || superseded → SCR-PROGRESS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/progress/README.md:12` \| Màn hình \| UC \| || superseded → SCR-PROGRESS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/progress/README.md:14` \| Tab Tiến độ / Progress \| UC-PROGRESS-001, UC-PROGRESS-002 \| || superseded → SCR-PROGRESS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/progress/README.md:15` \| Hàng deck trên màn tiến độ (drill-down) \| UC-PROGRESS-002 \| || superseded → SCR-PROGRESS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/progress/README.md:17` Màn 22 và điều hướng giữa các cấp: [ui.md](ui.md). || superseded → SCR-PROGRESS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/progress/README.md:19` Nguồn: trigger của UC-PROGRESS-001 ("Chạm tab **Tiến độ / Progress** ở bottom na || superseded → SCR-PROGRESS-001 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/reminders/README.md

| Source item | Outcome |
|---|---|
| `features/reminders/README.md:63` ## Màn hình → Use case |  |
| `features/reminders/README.md:65` \| Màn hình \| UC \| |  |
| `features/reminders/README.md:67` \| `Settings → Daily reminder` \| UC-REMINDER-001 \| |  |
| `features/reminders/README.md:69` Nguồn: trigger của UC-REMINDER-001. |  |

## features/search/README.md

| Source item | Outcome |
|---|---|
| `features/search/README.md:10` ## Màn hình → Use case || superseded → SCR-SEARCH-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/search/README.md:12` \| Màn hình \| UC \| || superseded → SCR-SEARCH-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/search/README.md:14` \| Tìm kiếm từ header của Library, ở mọi cấp \| UC-SEARCH-001 \| || superseded → SCR-SEARCH-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/search/README.md:16` Nguồn: trigger của UC-SEARCH-001 ("Bấm biểu tượng tìm kiếm ở header của Library, || superseded → SCR-SEARCH-001 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/settings/README.md

| Source item | Outcome |
|---|---|
| `features/settings/README.md:10` ## Màn hình → Use case || superseded → SCR-SETTINGS-001, SCR-SETTINGS-002, SCR-SETTINGS-003, SCR-SETTINGS-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/settings/README.md:12` \| Màn hình \| UC \| || superseded → SCR-SETTINGS-001, SCR-SETTINGS-002, SCR-SETTINGS-003, SCR-SETTINGS-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/settings/README.md:14` \| Tab Settings (màn 23) \| UC-SETTINGS-001 \| || superseded → SCR-SETTINGS-001, SCR-SETTINGS-002, SCR-SETTINGS-003, SCR-SETTINGS-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/settings/README.md:15` \| Theme (màn 25) \| UC-SETTINGS-001 \| || superseded → SCR-SETTINGS-001, SCR-SETTINGS-002, SCR-SETTINGS-003, SCR-SETTINGS-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/settings/README.md:16` \| Language (màn 26) \| UC-SETTINGS-001 \| || superseded → SCR-SETTINGS-001, SCR-SETTINGS-002, SCR-SETTINGS-003, SCR-SETTINGS-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/settings/README.md:17` \| Study options của bộ thẻ (màn 15) \| UC-SETTINGS-001 (A1, E4) \| || superseded → SCR-SETTINGS-001, SCR-SETTINGS-002, SCR-SETTINGS-003, SCR-SETTINGS-004 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/settings/README.md:19` Nguồn: trigger của UC-SETTINGS-001 ("Mở tab `Settings` của navigation shell, hoặ || superseded → SCR-SETTINGS-001, SCR-SETTINGS-002, SCR-SETTINGS-003, SCR-SETTINGS-004 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/srs/README.md

| Source item | Outcome |
|---|---|
| `features/srs/README.md:10` ## Màn hình → Use case || superseded → SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/srs/README.md:12` \| Màn hình \| UC \| || superseded → SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/srs/README.md:14` \| Xác nhận "Đặt lại tiến độ học" trên một root deck \| UC-SRS-001 \| || superseded → SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/srs/README.md:16` Nguồn: trigger của UC-SRS-001 ("thường từ chỗ giải thích vì sao chế độ ôn tập đa || superseded → SCR-SRS-001 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/starter-decks/README.md

| Source item | Outcome |
|---|---|
| `features/starter-decks/README.md:15` ## Màn hình → Use case || superseded → SCR-STARTER-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/starter-decks/README.md:17` \| Màn hình \| UC \| || superseded → SCR-STARTER-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/starter-decks/README.md:19` \| Thư viện starter (child flow trong tab Thư viện; empty state khi chưa có deck) || superseded → SCR-STARTER-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/starter-decks/README.md:21` Nguồn: trigger của UC-STARTER-001 ("Mở app lần đầu sau khi cài"); [`shared/ui/na || superseded → SCR-STARTER-001 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/study/README.md

| Source item | Outcome |
|---|---|
| `features/study/README.md:10` ## Màn hình → Use case || superseded → SCR-STUDY-001, SCR-STUDY-002, SCR-STUDY-003…SCR-STUDY-009 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/study/README.md:12` \| Màn hình \| UC \| || superseded → SCR-STUDY-001, SCR-STUDY-002, SCR-STUDY-003…SCR-STUDY-009 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/study/README.md:14` \| Tab Study (Study Home) \| UC-STUDY-002 \| || superseded → SCR-STUDY-001, SCR-STUDY-002, SCR-STUDY-003…SCR-STUDY-009 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/study/README.md:15` \| Study Entry của một deck \| UC-STUDY-001, UC-STUDY-003 \| || superseded → SCR-STUDY-001, SCR-STUDY-002, SCR-STUDY-003…SCR-STUDY-009 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/study/README.md:16` \| Phiên học / phiên ôn tập \| UC-STUDY-001 \| || superseded → SCR-STUDY-001, SCR-STUDY-002, SCR-STUDY-003…SCR-STUDY-009 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/study/README.md:18` Nguồn: trigger của UC-STUDY-001 ("bấm Study trên một deck"), UC-STUDY-002 ("Chạm || superseded → SCR-STUDY-001, SCR-STUDY-002, SCR-STUDY-003…SCR-STUDY-009 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/study-mode/README.md

| Source item | Outcome |
|---|---|
| `features/study-mode/README.md:53` ## Màn hình → Use case |  |
| `features/study-mode/README.md:55` \| Màn hình \| UC \| |  |
| `features/study-mode/README.md:57` \| Không có màn hình riêng — mode chạy trong phiên học \| UC-STUDY-001, UC-STUDY-0 |  |

## features/tags/README.md

| Source item | Outcome |
|---|---|
| `features/tags/README.md:21` ## Màn hình → Use case || superseded → SCR-TAG-001, SCR-CARD-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/tags/README.md:23` \| Màn hình \| UC \| || superseded → SCR-TAG-001, SCR-CARD-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/tags/README.md:25` \| Tag catalog (hành động `Tags` trên app bar của Library, hoặc `Manage tags`) \| || superseded → SCR-TAG-001, SCR-CARD-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/tags/README.md:27` Nguồn: trigger của UC-TAG-001. || superseded → SCR-TAG-001, SCR-CARD-001 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/transfer/README.md

| Source item | Outcome |
|---|---|
| `features/transfer/README.md:19` ## Màn hình → Use case || superseded → SCR-TRANSFER-001, SCR-TRANSFER-002 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/transfer/README.md:21` \| Màn hình \| UC \| || superseded → SCR-TRANSFER-001, SCR-TRANSFER-002 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/transfer/README.md:23` \| Card list của deck loại card — "Import cards" \| UC-TRANSFER-001 \| || superseded → SCR-TRANSFER-001, SCR-TRANSFER-002 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/transfer/README.md:24` \| Card list — `Export cards` trong overflow menu \| UC-TRANSFER-002 \| || superseded → SCR-TRANSFER-001, SCR-TRANSFER-002 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/transfer/README.md:26` Nguồn: trigger của UC-TRANSFER-001 và UC-TRANSFER-002. || superseded → SCR-TRANSFER-001, SCR-TRANSFER-002 (Related Use Cases; the reverse view is _generated/screens.md) |

## features/trash/README.md

| Source item | Outcome |
|---|---|
| `features/trash/README.md:24` ## Màn hình → Use case || superseded → SCR-TRASH-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/trash/README.md:26` \| Màn hình \| UC \| || superseded → SCR-TRASH-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/trash/README.md:28` \| `Trash` từ app bar (và thao tác xoá card/deck vào Trash) \| UC-TRASH-001 \| || superseded → SCR-TRASH-001 (Related Use Cases; the reverse view is _generated/screens.md) |
| `features/trash/README.md:30` Nguồn: trigger của UC-TRASH-001. || superseded → SCR-TRASH-001 (Related Use Cases; the reverse view is _generated/screens.md) |

## shared/ui/navigation.md

| Source item | Outcome |
|---|---|
| `shared/ui/navigation.md:1` # Điều hướng toàn app |  |
| `shared/ui/navigation.md:3` Điều hướng và hành trình dùng chung toàn app. Sơ đồ điều hướng riêng của từng |  |
| `shared/ui/navigation.md:7` ## Điều hướng top-level |  |
| `shared/ui/navigation.md:9` App dùng đúng **bốn** destination ở bottom navigation, thứ tự cố định: |  |
| `shared/ui/navigation.md:14` - Cold start mở Decks (UC-DECK-003). |  |
| `shared/ui/navigation.md:15` - **Progress** (UC-PROGRESS-001, UC-PROGRESS-002): streak, hôm nay và bảy ngày g |  |
| `shared/ui/navigation.md:21` - Thư viện starter (M6) là child flow bên trong tab Thư viện (branch Decks), khô |  |
| `shared/ui/navigation.md:22` - Không có tab Profile chừng nào chưa có auth/profile domain — nhất quán với |  |
| `shared/ui/navigation.md:25` ## Primary business flows |  |
| `shared/ui/navigation.md:27` 1. **Tạo nội dung**: mở app → tạo deck → thêm card → deck xuất hiện trong danh |  |
| `shared/ui/navigation.md:29` 2. **Ôn tập** (luồng chính, chạy hằng ngày): mở app → thấy deck có card đến hạn |  |
| `shared/ui/navigation.md:33` Luồng 2 là vertical slice đầu tiên nên xây, vì nó chạm vào toàn bộ chiều sâu |  |
| `shared/ui/navigation.md:38` ## Sơ đồ là gì, và không là gì |  |
| `shared/ui/navigation.md:40` `features/*/usecases/` đặc tả **từng** UC. Nó cố ý không vẽ đồ thị nối |  |
| `shared/ui/navigation.md:44` Tài liệu này chỉ giữ **các cạnh của đồ thị đó**. Mọi đỉnh đều trỏ về một UC hoặc |  |
| `shared/ui/navigation.md:47` **MUST NOT** đọc sơ đồ ở đây như một đặc tả. Theo mục "X viết ở đâu" của [`READM |  |
| `shared/ui/navigation.md:52` **Tách theo đối tượng, không theo hành động.** Mục 3–5 chia theo *deck*, *card*, |  |
| `shared/ui/navigation.md:57` ## Master flow — toàn app |  |
| `shared/ui/navigation.md:59` Hành trình từ lúc mở app tới lúc vào được một phiên ôn tập. Nhánh nào đi sâu vào |  |
| `shared/ui/navigation.md:63` flowchart TD |  |
| `shared/ui/navigation.md:64` A["Mở app"] --> B["Khởi tạo database"] |  |
| `shared/ui/navigation.md:65` B -->\|"Thất bại"\| B1["Màn hình lỗi có nút thử lại · UC-STARTER-001 E1"] |  |
| `shared/ui/navigation.md:66` B --> C{"Đã có deck nào chưa?"} |  |
| `shared/ui/navigation.md:68` C -->\|"Chưa"\| D["Empty state, hai lối đi · UC-DECK-003 A1"] |  |
| `shared/ui/navigation.md:69` D -->\|"Thư viện starter"\| E["Chọn starter deck và chế độ ôn tập · UC-STARTER-001 |  |
| `shared/ui/navigation.md:70` D -->\|"Tạo deck mới"\| F["Tạo root deck · UC-DECK-001"] |  |
| `shared/ui/navigation.md:72` C -->\|"Rồi"\| G["Danh sách deck kèm tiến độ · UC-DECK-003"] |  |
| `shared/ui/navigation.md:73` E --> G |  |
| `shared/ui/navigation.md:74` F --> G |  |
| `shared/ui/navigation.md:76` G --> H["Mở một deck"] |  |
| `shared/ui/navigation.md:77` H --> I{"content_type của deck"} |  |
| `shared/ui/navigation.md:78` I -->\|"deck"\| J["Danh sách deck con · UC-DECK-003 A3"] |  |
| `shared/ui/navigation.md:79` I -->\|"card"\| K["Danh sách card · UC-CARD-001"] |  |
| `shared/ui/navigation.md:80` I -->\|"unset"\| L["Deck rỗng, tạo được cả hai loại · UC-DECK-004"] |  |
| `shared/ui/navigation.md:82` J --> H |  |
| `shared/ui/navigation.md:83` L -->\|"Tạo deck con"\| J |  |
| `shared/ui/navigation.md:84` L -->\|"Tạo card"\| K |  |
| `shared/ui/navigation.md:86` H --> M["Quản lý deck: đổi tên, xoá, di chuyển · mục 3"] |  |
| `shared/ui/navigation.md:87` G --> N["Bắt đầu phiên ôn tập · mục 5"] |  |
| `shared/ui/navigation.md:88` K --> N |  |
| `shared/ui/navigation.md:89` N --> G |  |
| `shared/ui/navigation.md:92` **`J --> H` là vòng lặp cố ý.** Deck lồng tới 10 cấp (BR-DECK-001) và một cấp bấ |  |
| `shared/ui/navigation.md:96` ## UC theo đối tượng nghiệp vụ |  |
| `shared/ui/navigation.md:98` Phân loại 22 UC theo đối tượng nghiệp vụ. Mục 2–5 chỉ vẽ sơ đồ cho các UC quanh |  |
| `shared/ui/navigation.md:101` \| UC \| Đối tượng \| |  |
| `shared/ui/navigation.md:103` \| UC-STARTER-001 \| deck \| |  |
| `shared/ui/navigation.md:104` \| UC-DECK-001 \| deck \| |  |
| `shared/ui/navigation.md:105` \| UC-DECK-002 \| deck \| |  |
| `shared/ui/navigation.md:106` \| UC-CARD-001 \| card \| |  |
| `shared/ui/navigation.md:107` \| UC-STUDY-001 \| review \| |  |
| `shared/ui/navigation.md:108` \| UC-DECK-003 \| deck \| |  |
| `shared/ui/navigation.md:109` \| UC-SRS-001 \| review \| |  |
| `shared/ui/navigation.md:110` \| UC-DECK-004 \| deck \| |  |
| `shared/ui/navigation.md:111` \| UC-DECK-005 \| deck \| |  |
| `shared/ui/navigation.md:112` \| UC-TRANSFER-001 \| card \| |  |
| `shared/ui/navigation.md:113` \| UC-TRANSFER-002 \| card \| |  |
| `shared/ui/navigation.md:114` \| UC-PROGRESS-001 \| progress \| |  |
| `shared/ui/navigation.md:115` \| UC-PROGRESS-002 \| progress \| |  |
| `shared/ui/navigation.md:116` \| UC-STUDY-002 \| review \| |  |
| `shared/ui/navigation.md:117` \| UC-STUDY-003 \| review \| |  |
| `shared/ui/navigation.md:118` \| UC-SETTINGS-001 \| settings \| |  |
| `shared/ui/navigation.md:119` \| UC-REMINDER-001 \| settings \| |  |
| `shared/ui/navigation.md:120` \| UC-TAG-001 \| card \| |  |
| `shared/ui/navigation.md:121` \| UC-CARD-002 \| card \| |  |
| `shared/ui/navigation.md:122` \| UC-SEARCH-001 \| search \| |  |
| `shared/ui/navigation.md:123` \| UC-TRASH-001 \| trash \| |  |
| `shared/ui/navigation.md:124` \| UC-DECK-006 \| deck \| |  |

## README.md

| Source item | Outcome |
|---|---|
| `README.md:7` ## Sản phẩm | moved → `../PRODUCT.md` |
| `README.md:9` ### Problem | moved → `../PRODUCT.md` |
| `README.md:11` Người học từ vựng quên phần lớn những gì vừa học nếu ôn tập không đúng thời | moved → `../PRODUCT.md` |
| `README.md:15` ### Target users | moved → `../PRODUCT.md` |
| `README.md:17` \| Group \| Context \| What they need \| Not the target \| | moved → `../PRODUCT.md` |
| `README.md:19` \| Người tự học từ vựng \| Học lẻ trên điện thoại, thời gian rời rạc, kết nối khôn | moved → `../PRODUCT.md` |
| `README.md:20` \| Người ôn thi \| Khối lượng từ lớn, có deadline \| Theo dõi tiến độ, ưu tiên từ s | moved → `../PRODUCT.md` |
| `README.md:22` **Đã chốt:** người dùng tự tạo nội dung, **và** app cung cấp starter deck dưới | moved → `../PRODUCT.md` |
| `README.md:27` ### Core value | moved → `../PRODUCT.md` |
| `README.md:29` Ôn đúng từ vào đúng thời điểm, hoạt động đầy đủ khi không có mạng. | moved → `../PRODUCT.md` |
| `README.md:31` Quyết định nền tảng: [ADR-001](shared/decisions/ADR-001-quyet-dinh-nen-tang.md). | moved → `../PRODUCT.md` |
| `README.md:33` ### Phạm vi MVP | moved → `../PRODUCT.md` |
| `README.md:35` Nguyên tắc: MVP là **một vertical slice chạy được từ Drift đến màn hình**, đủ để | moved → `../PRODUCT.md` |
| `README.md:40` #### Must-have | moved → `../PRODUCT.md` |
| `README.md:42` \| # \| Feature \| Done when \| | moved → `../PRODUCT.md` |
| `README.md:44` \| M1 \| Tạo/sửa/xoá deck \| Deck tồn tại sau khi restart app; xoá deck cần xác nhậ | moved → `../PRODUCT.md` |
| `README.md:45` \| M2 \| Tạo/sửa/xoá card trong deck \| Card có mặt trước/sau; sửa không làm mất lị | moved → `../PRODUCT.md` |
| `README.md:46` \| M3 \| Phiên học theo lịch SRS \| Chỉ hiện card đến hạn; đánh giá kết quả cập nhậ | moved → `../PRODUCT.md` |
| `README.md:47` \| M4 \| Danh sách deck với tiến độ \| Mỗi deck hiện số card đến hạn hôm nay \| | moved → `../PRODUCT.md` |
| `README.md:48` \| M5 \| Hoạt động đầy đủ offline \| Bật chế độ máy bay, mọi chức năng trên vẫn chạ | moved → `../PRODUCT.md` |
| `README.md:50` Hai trục độc lập (thuật toán SRS và StudyMode) và hai loại phiên: xem [`features | moved → `../PRODUCT.md` |
| `README.md:52` #### Should-have | moved → `../PRODUCT.md` |
| `README.md:54` \| # \| Feature \| Done when \| | moved → `../PRODUCT.md` |
| `README.md:56` \| S1 \| Tìm kiếm card trong deck \| Trong phạm vi: tìm theo nội dung mặt trước/sau | moved → `../PRODUCT.md` |
| `README.md:57` \| S2 \| Thống kê ôn tập cơ bản \| Trong phạm vi (UC-PROGRESS-001, BR-PROGRESS-009… | moved → `../PRODUCT.md` |
| `README.md:58` \| S3 \| Đảo chiều card (nghĩa → từ) \| Trong phạm vi (UC-STUDY-003, BR-MODE-013…BR | moved → `../PRODUCT.md` |
| `README.md:60` #### Nice-to-have | moved → `../PRODUCT.md` |
| `README.md:62` \| # \| Feature \| Notes \| | moved → `../PRODUCT.md` |
| `README.md:64` \| N1 \| Import/export \| Trong V8.0 theo [spec card transfer](superpowers/specs/20 | moved → `../PRODUCT.md` |
| `README.md:65` \| N2 \| Nhắc nhở ôn tập hằng ngày \| Sub-project sau (UC-REMINDER-001, BR-REMINDER | moved → `../PRODUCT.md` |
| `README.md:66` \| N3 \| Tag/phân loại card \| Sub-project sau (UC-TAG-001, BR-TAG-003…BR-TAG-011): | moved → `../PRODUCT.md` |
| `README.md:68` #### Explicitly out of MVP | moved → `../PRODUCT.md` |
| `README.md:70` \| Feature \| Why deferred \| Revisit when \| | moved → `../PRODUCT.md` |
| `README.md:72` \| Đăng nhập / tài khoản \| Không có backend; thêm auth lúc này là xây UI cho thứ | moved → `../PRODUCT.md` |
| `README.md:73` \| Đồng bộ đa thiết bị \| Cần backend và conflict resolution \| Cùng lúc với auth \| | moved → `../PRODUCT.md` |
| `README.md:74` \| iOS \| Ổn định Android trước để tránh sửa lỗi trên hai nền tảng cùng lúc \| Sau | moved → `../PRODUCT.md` |
| `README.md:75` \| Phân quyền theo role \| Chỉ có một loại user, kể cả sau khi có auth \| Chưa có k | moved → `../PRODUCT.md` |
| `README.md:76` \| Chia sẻ deck giữa người dùng \| Cần backend \| Sau đồng bộ \| | moved → `../PRODUCT.md` |
| `README.md:77` \| Audio / hình ảnh trong card \| Kéo theo lưu trữ file, đồng bộ file, nén ảnh — m | moved → `../PRODUCT.md` |

## Goldens

| Source item | Outcome |
|---|---|
| `test/app/goldens/app_gallery_dark.png` |  |
| `test/app/goldens/app_gallery_light.png` |  |
| `test/app/goldens/app_library_dark.png` |  |
| `test/app/goldens/app_library_light.png` |  |
| `test/app/goldens/app_tablet_landscape_library_dark.png` |  |
| `test/app/goldens/app_tablet_landscape_library_light.png` |  |
| `test/app/goldens/app_tablet_portrait_deck_dark.png` |  |
| `test/app/goldens/app_tablet_portrait_deck_light.png` |  |
| `test/features/account/presentation/goldens/account_delete_confirm_dark.png` |  |
| `test/features/account/presentation/goldens/account_delete_confirm_light.png` |  |
| `test/features/account/presentation/goldens/account_delete_offline_dark.png` |  |
| `test/features/account/presentation/goldens/account_delete_offline_light.png` |  |
| `test/features/account/presentation/goldens/account_last_admin_dark.png` |  |
| `test/features/account/presentation/goldens/account_last_admin_light.png` |  |
| `test/features/account/presentation/goldens/account_ready_dark.png` |  |
| `test/features/account/presentation/goldens/account_ready_light.png` |  |
| `test/features/account/presentation/goldens/account_reauth_dark.png` |  |
| `test/features/account/presentation/goldens/account_reauth_light.png` |  |
| `test/features/account/presentation/goldens/account_sign_out_confirm_dark.png` |  |
| `test/features/account/presentation/goldens/account_sign_out_confirm_light.png` |  |
| `test/features/account/presentation/goldens/account_sign_out_loss_dark.png` |  |
| `test/features/account/presentation/goldens/account_sign_out_loss_light.png` |  |
| `test/features/account/presentation/goldens/account_switch_confirm_dark.png` |  |
| `test/features/account/presentation/goldens/account_switch_confirm_light.png` |  |
| `test/features/account/presentation/goldens/account_validating_dark.png` |  |
| `test/features/account/presentation/goldens/account_validating_light.png` |  |
| `test/features/account/presentation/goldens/code_waiting_dark.png` |  |
| `test/features/account/presentation/goldens/code_waiting_light.png` |  |
| `test/features/account/presentation/goldens/code_wrong_dark.png` |  |
| `test/features/account/presentation/goldens/code_wrong_light.png` |  |
| `test/features/account/presentation/goldens/layer_merging_dark.png` |  |
| `test/features/account/presentation/goldens/layer_merging_light.png` |  |
| `test/features/account/presentation/goldens/layer_offline_dark.png` |  |
| `test/features/account/presentation/goldens/layer_offline_light.png` |  |
| `test/features/account/presentation/goldens/layer_sending_dark.png` |  |
| `test/features/account/presentation/goldens/layer_sending_light.png` |  |
| `test/features/account/presentation/goldens/layer_sign_out_offline_dark.png` |  |
| `test/features/account/presentation/goldens/layer_sign_out_offline_light.png` |  |
| `test/features/account/presentation/goldens/layer_stuck_dark.png` |  |
| `test/features/account/presentation/goldens/layer_stuck_light.png` |  |
| `test/features/account/presentation/goldens/layer_target_dark.png` |  |
| `test/features/account/presentation/goldens/layer_target_light.png` |  |
| `test/features/account/presentation/goldens/merge_sheet_discard_dark.png` |  |
| `test/features/account/presentation/goldens/merge_sheet_discard_light.png` |  |
| `test/features/account/presentation/goldens/merge_sheet_merge_dark.png` |  |
| `test/features/account/presentation/goldens/merge_sheet_merge_light.png` |  |
| `test/features/account/presentation/goldens/settings_account_dark.png` |  |
| `test/features/account/presentation/goldens/settings_account_light.png` |  |
| `test/features/account/presentation/goldens/settings_account_reauth_dark.png` |  |
| `test/features/account/presentation/goldens/settings_account_reauth_light.png` |  |
| `test/features/account/presentation/goldens/settings_account_signed_in_dark.png` |  |
| `test/features/account/presentation/goldens/settings_account_signed_in_light.png` |  |
| `test/features/account/presentation/goldens/settings_admin_rows_dark.png` |  |
| `test/features/account/presentation/goldens/settings_admin_rows_light.png` |  |
| `test/features/account/presentation/goldens/sign_in_continue_without_dark.png` |  |
| `test/features/account/presentation/goldens/sign_in_continue_without_light.png` |  |
| `test/features/account/presentation/goldens/sign_in_invalid_dark.png` |  |
| `test/features/account/presentation/goldens/sign_in_invalid_light.png` |  |
| `test/features/account/presentation/goldens/sign_in_link_dark.png` |  |
| `test/features/account/presentation/goldens/sign_in_link_light.png` |  |
| `test/features/account/presentation/goldens/sign_in_reauth_dark.png` |  |
| `test/features/account/presentation/goldens/sign_in_reauth_light.png` |  |
| `test/features/account/presentation/goldens/sign_in_unsent_loss_dark.png` |  |
| `test/features/account/presentation/goldens/sign_in_unsent_loss_light.png` |  |
| `test/features/account/presentation/goldens/study_home_reauth_dark.png` | superseded → SCR-STUDY-001 `reauth` dark |
| `test/features/account/presentation/goldens/study_home_reauth_light.png` | superseded → SCR-STUDY-001 `reauth` light |
| `test/features/account/presentation/goldens/users_empty_search_dark.png` |  |
| `test/features/account/presentation/goldens/users_empty_search_light.png` |  |
| `test/features/account/presentation/goldens/users_loaded_dark.png` |  |
| `test/features/account/presentation/goldens/users_loaded_light.png` |  |
| `test/features/account/presentation/goldens/users_offline_dark.png` |  |
| `test/features/account/presentation/goldens/users_offline_light.png` |  |
| `test/features/account/presentation/goldens/users_role_sheet_changed_dark.png` |  |
| `test/features/account/presentation/goldens/users_role_sheet_changed_light.png` |  |
| `test/features/account/presentation/goldens/users_role_sheet_dark.png` |  |
| `test/features/account/presentation/goldens/users_role_sheet_light.png` |  |
| `test/features/account/presentation/goldens/users_role_sheet_refused_dark.png` |  |
| `test/features/account/presentation/goldens/users_role_sheet_refused_light.png` |  |
| `test/features/account/presentation/goldens/welcome_offline_dark.png` |  |
| `test/features/account/presentation/goldens/welcome_offline_light.png` |  |
| `test/features/account/presentation/goldens/welcome_ready_dark.png` |  |
| `test/features/account/presentation/goldens/welcome_ready_light.png` |  |
| `test/features/card/presentation/goldens/card_detail_history_dark.png` | superseded → SCR-CARD-004 `history` dark |
| `test/features/card/presentation/goldens/card_detail_history_light.png` | superseded → SCR-CARD-004 `history` light |
| `test/features/card/presentation/goldens/card_detail_top_dark.png` | superseded → SCR-CARD-004 `loaded` dark |
| `test/features/card/presentation/goldens/card_detail_top_light.png` | superseded → SCR-CARD-004 `loaded` light |
| `test/features/card/presentation/goldens/card_editor_create_dark.png` | superseded → SCR-CARD-002 `empty_form` dark |
| `test/features/card/presentation/goldens/card_editor_create_keyboard_dark.png` | superseded → SCR-CARD-002 `empty_form_keyboard` dark |
| `test/features/card/presentation/goldens/card_editor_create_keyboard_light.png` | superseded → SCR-CARD-002 `empty_form_keyboard` light |
| `test/features/card/presentation/goldens/card_editor_create_light.png` | superseded → SCR-CARD-002 `empty_form` light |
| `test/features/card/presentation/goldens/card_editor_edit_dark.png` | superseded → SCR-CARD-003 `loaded` dark |
| `test/features/card/presentation/goldens/card_editor_edit_light.png` | superseded → SCR-CARD-003 `loaded` light |
| `test/features/card/presentation/goldens/card_editor_errors_dark.png` | superseded → SCR-CARD-003 `validation_err` dark |
| `test/features/card/presentation/goldens/card_editor_errors_light.png` | superseded → SCR-CARD-003 `validation_err` light |
| `test/features/card/presentation/goldens/card_editor_more_dark.png` | superseded → SCR-CARD-003 `more` dark |
| `test/features/card/presentation/goldens/card_editor_more_light.png` | superseded → SCR-CARD-003 `more` light |
| `test/features/card/presentation/goldens/card_editor_trash_dialog_dark.png` | superseded → SCR-CARD-003 `del_confirm` dark |
| `test/features/card/presentation/goldens/card_editor_trash_dialog_light.png` | superseded → SCR-CARD-003 `del_confirm` light |
| `test/features/card/presentation/goldens/card_list_bulk_failed_dark.png` | superseded → SCR-CARD-001 `bulk_failed` dark |
| `test/features/card/presentation/goldens/card_list_bulk_failed_light.png` | superseded → SCR-CARD-001 `bulk_failed` light |
| `test/features/card/presentation/goldens/card_list_dark.png` | superseded → SCR-CARD-001 `loaded` dark |
| `test/features/card/presentation/goldens/card_list_light.png` | superseded → SCR-CARD-001 `loaded` light |
| `test/features/card/presentation/goldens/card_list_search_dark.png` | superseded → SCR-CARD-001 `search_empty` dark |
| `test/features/card/presentation/goldens/card_list_search_light.png` | superseded → SCR-CARD-001 `search_empty` light |
| `test/features/card/presentation/goldens/card_list_search_results_dark.png` | superseded → SCR-CARD-001 `search_results` dark |
| `test/features/card/presentation/goldens/card_list_search_results_light.png` | superseded → SCR-CARD-001 `search_results` light |
| `test/features/card/presentation/goldens/card_list_trash_dialog_dark.png` | superseded → SCR-CARD-001 `del_card` dark |
| `test/features/card/presentation/goldens/card_list_trash_dialog_light.png` | superseded → SCR-CARD-001 `del_card` light |
| `test/features/card/presentation/goldens/card_list_trashed_dark.png` | superseded → SCR-CARD-001 `trashed` dark |
| `test/features/card/presentation/goldens/card_list_trashed_light.png` | superseded → SCR-CARD-001 `trashed` light |
| `test/features/card/presentation/goldens/card_selection_dark.png` | superseded → SCR-CARD-001 `selection` dark |
| `test/features/card/presentation/goldens/card_selection_light.png` | superseded → SCR-CARD-001 `selection` light |
| `test/features/card/presentation/goldens/card_tag_filter_applied_dark.png` | superseded → SCR-CARD-001 `tag_filter_applied` dark |
| `test/features/card/presentation/goldens/card_tag_filter_applied_light.png` | superseded → SCR-CARD-001 `tag_filter_applied` light |
| `test/features/card/presentation/goldens/card_tag_filter_no_card_dark.png` | superseded → SCR-CARD-001 `tag_filter_no_card` dark |
| `test/features/card/presentation/goldens/card_tag_filter_no_card_light.png` | superseded → SCR-CARD-001 `tag_filter_no_card` light |
| `test/features/card/presentation/goldens/card_tag_filter_none_dark.png` | superseded → SCR-CARD-001 `tag_filter_none` dark |
| `test/features/card/presentation/goldens/card_tag_filter_none_light.png` | superseded → SCR-CARD-001 `tag_filter_none` light |
| `test/features/card/presentation/goldens/card_tag_filter_one_dark.png` | superseded → SCR-CARD-001 `tag_filter_one` dark |
| `test/features/card/presentation/goldens/card_tag_filter_one_light.png` | superseded → SCR-CARD-001 `tag_filter_one` light |
| `test/features/card/presentation/goldens/card_tag_filter_several_dark.png` | superseded → SCR-CARD-001 `tag_filter_several` dark |
| `test/features/card/presentation/goldens/card_tag_filter_several_light.png` | superseded → SCR-CARD-001 `tag_filter_several` light |
| `test/features/deck/presentation/goldens/library_algorithm_locked_dark.png` | superseded → SCR-SRS-001 `locked` dark |
| `test/features/deck/presentation/goldens/library_algorithm_locked_light.png` | superseded → SCR-SRS-001 `locked` light |
| `test/features/deck/presentation/goldens/library_algorithm_reset_dark.png` | superseded → SCR-SRS-001 `reset_confirm` dark |
| `test/features/deck/presentation/goldens/library_algorithm_reset_light.png` | superseded → SCR-SRS-001 `reset_confirm` light |
| `test/features/deck/presentation/goldens/library_algorithm_unlocked_dark.png` | superseded → SCR-SRS-001 `unlocked` dark |
| `test/features/deck/presentation/goldens/library_algorithm_unlocked_light.png` | superseded → SCR-SRS-001 `unlocked` light |
| `test/features/deck/presentation/goldens/library_deck_actions_dark.png` | superseded → SCR-DECK-001 `root_overflow` dark |
| `test/features/deck/presentation/goldens/library_deck_actions_light.png` | superseded → SCR-DECK-001 `root_overflow` light |
| `test/features/deck/presentation/goldens/library_deck_delete_dark.png` | superseded → SCR-DECK-001 `root_delete` dark |
| `test/features/deck/presentation/goldens/library_deck_delete_light.png` | superseded → SCR-DECK-001 `root_delete` light |
| `test/features/deck/presentation/goldens/library_deck_open_dark.png` | superseded → SCR-DECK-001 `deck_loaded` dark |
| `test/features/deck/presentation/goldens/library_deck_open_light.png` | superseded → SCR-DECK-001 `deck_loaded` light |
| `test/features/deck/presentation/goldens/library_deck_trashed_dark.png` | superseded → SCR-DECK-001 `root_trashed` dark |
| `test/features/deck/presentation/goldens/library_deck_trashed_light.png` | superseded → SCR-DECK-001 `root_trashed` light |
| `test/features/deck/presentation/goldens/library_deck_unset_dark.png` | superseded → SCR-DECK-001 `deck_empty` dark |
| `test/features/deck/presentation/goldens/library_deck_unset_light.png` | superseded → SCR-DECK-001 `deck_empty` light |
| `test/features/deck/presentation/goldens/library_decks_dark.png` | superseded → SCR-DECK-001 `root_loaded` dark |
| `test/features/deck/presentation/goldens/library_decks_light.png` | superseded → SCR-DECK-001 `root_loaded` light |
| `test/features/deck/presentation/goldens/library_empty_dark.png` | superseded → SCR-DECK-001 `root_empty` dark |
| `test/features/deck/presentation/goldens/library_empty_light.png` | superseded → SCR-DECK-001 `root_empty` light |
| `test/features/deck/presentation/goldens/library_reorder_dark.png` | superseded → SCR-DECK-001 `root_reorder` dark |
| `test/features/deck/presentation/goldens/library_reorder_light.png` | superseded → SCR-DECK-001 `root_reorder` light |
| `test/features/deck/presentation/goldens/library_sort_dark.png` | superseded → SCR-DECK-001 `root_sort_filter` dark |
| `test/features/deck/presentation/goldens/library_sort_light.png` | superseded → SCR-DECK-001 `root_sort_filter` light |
| `test/features/monitoring/presentation/goldens/monitoring_detail_fixed_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_detail_fixed_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_detail_local_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_detail_local_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_detail_open_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_detail_open_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_detail_open_trace_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_detail_open_trace_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_level_sheet_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_level_sheet_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_all_levels_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_all_levels_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_empty_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_empty_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_loaded_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_loaded_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_offline_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_list_offline_light.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_not_sent_dark.png` |  |
| `test/features/monitoring/presentation/goldens/monitoring_not_sent_light.png` |  |
| `test/features/progress/presentation/goldens/deck_progress_deck_dark.png` | superseded → SCR-PROGRESS-001 `deck` dark |
| `test/features/progress/presentation/goldens/deck_progress_deck_light.png` | superseded → SCR-PROGRESS-001 `deck` light |
| `test/features/progress/presentation/goldens/deck_progress_gone_dark.png` | superseded → SCR-PROGRESS-001 `deck_gone` dark |
| `test/features/progress/presentation/goldens/deck_progress_gone_light.png` | superseded → SCR-PROGRESS-001 `deck_gone` light |
| `test/features/progress/presentation/goldens/deck_progress_leaf_dark.png` | superseded → SCR-PROGRESS-001 `deck_leaf` dark |
| `test/features/progress/presentation/goldens/deck_progress_leaf_light.png` | superseded → SCR-PROGRESS-001 `deck_leaf` light |
| `test/features/progress/presentation/goldens/progress_error_dark.png` | superseded → SCR-PROGRESS-001 `error` dark |
| `test/features/progress/presentation/goldens/progress_error_light.png` | superseded → SCR-PROGRESS-001 `error` light |
| `test/features/progress/presentation/goldens/progress_held_dark.png` | superseded → SCR-PROGRESS-001 `held` dark |
| `test/features/progress/presentation/goldens/progress_held_light.png` | superseded → SCR-PROGRESS-001 `held` light |
| `test/features/progress/presentation/goldens/progress_loading_dark.png` | superseded → SCR-PROGRESS-001 `loading` dark |
| `test/features/progress/presentation/goldens/progress_loading_light.png` | superseded → SCR-PROGRESS-001 `loading` light |
| `test/features/progress/presentation/goldens/progress_lost_dark.png` | superseded → SCR-PROGRESS-001 `lost` dark |
| `test/features/progress/presentation/goldens/progress_lost_light.png` | superseded → SCR-PROGRESS-001 `lost` light |
| `test/features/progress/presentation/goldens/progress_month_dark.png` | superseded → SCR-PROGRESS-001 `month` dark |
| `test/features/progress/presentation/goldens/progress_month_light.png` | superseded → SCR-PROGRESS-001 `month` light |
| `test/features/progress/presentation/goldens/progress_never_dark.png` | superseded → SCR-PROGRESS-001 `never` dark |
| `test/features/progress/presentation/goldens/progress_never_light.png` | superseded → SCR-PROGRESS-001 `never` light |
| `test/features/progress/presentation/goldens/progress_no_decks_dark.png` | superseded → SCR-PROGRESS-001 `no_decks` dark |
| `test/features/progress/presentation/goldens/progress_no_decks_light.png` | superseded → SCR-PROGRESS-001 `no_decks` light |
| `test/features/progress/presentation/goldens/progress_quiet_dark.png` | superseded → SCR-PROGRESS-001 `quiet` dark |
| `test/features/progress/presentation/goldens/progress_quiet_light.png` | superseded → SCR-PROGRESS-001 `quiet` light |
| `test/features/progress/presentation/goldens/progress_week_dark.png` | superseded → SCR-PROGRESS-001 `week` dark |
| `test/features/progress/presentation/goldens/progress_week_light.png` | superseded → SCR-PROGRESS-001 `week` light |
| `test/features/reminders/presentation/goldens/reminder_changing_time_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_changing_time_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_could_not_schedule_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_could_not_schedule_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_loading_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_loading_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_off_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_off_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_off_may_show_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_off_may_show_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_on_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_on_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_perm_denied_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_perm_denied_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_preview_due_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_preview_due_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_read_error_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_read_error_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_turning_on_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_turning_on_light.png` |  |
| `test/features/reminders/presentation/goldens/reminder_unavailable_dark.png` |  |
| `test/features/reminders/presentation/goldens/reminder_unavailable_light.png` |  |
| `test/features/search/presentation/goldens/search_empty_query_dark.png` | superseded → SCR-SEARCH-001 `empty_query` dark |
| `test/features/search/presentation/goldens/search_empty_query_light.png` | superseded → SCR-SEARCH-001 `empty_query` light |
| `test/features/search/presentation/goldens/search_error_dark.png` | superseded → SCR-SEARCH-001 `error` dark |
| `test/features/search/presentation/goldens/search_error_light.png` | superseded → SCR-SEARCH-001 `error` light |
| `test/features/search/presentation/goldens/search_load_more_failed_dark.png` | superseded → SCR-SEARCH-001 `load_more_failed` dark |
| `test/features/search/presentation/goldens/search_load_more_failed_light.png` | superseded → SCR-SEARCH-001 `load_more_failed` light |
| `test/features/search/presentation/goldens/search_loading_dark.png` | superseded → SCR-SEARCH-001 `loading` dark |
| `test/features/search/presentation/goldens/search_loading_light.png` | superseded → SCR-SEARCH-001 `loading` light |
| `test/features/search/presentation/goldens/search_no_results_dark.png` | superseded → SCR-SEARCH-001 `no_results` dark |
| `test/features/search/presentation/goldens/search_no_results_light.png` | superseded → SCR-SEARCH-001 `no_results` light |
| `test/features/search/presentation/goldens/search_results_dark.png` | superseded → SCR-SEARCH-001 `results` dark |
| `test/features/search/presentation/goldens/search_results_light.png` | superseded → SCR-SEARCH-001 `results` light |
| `test/features/settings/presentation/goldens/settings_invalid_limit_dark.png` | superseded → SCR-SETTINGS-002 `invalid_limit` dark |
| `test/features/settings/presentation/goldens/settings_invalid_limit_light.png` | superseded → SCR-SETTINGS-002 `invalid_limit` light |
| `test/features/settings/presentation/goldens/settings_language_english_dark.png` | superseded → SCR-SETTINGS-004 `english` dark |
| `test/features/settings/presentation/goldens/settings_language_english_light.png` | superseded → SCR-SETTINGS-004 `english` light |
| `test/features/settings/presentation/goldens/settings_language_switched_dark.png` | superseded → SCR-SETTINGS-004 `vietnamese` dark |
| `test/features/settings/presentation/goldens/settings_language_switched_light.png` | superseded → SCR-SETTINGS-004 `vietnamese` light |
| `test/features/settings/presentation/goldens/settings_language_system_dark.png` | superseded → SCR-SETTINGS-004 `system` dark |
| `test/features/settings/presentation/goldens/settings_language_system_light.png` | superseded → SCR-SETTINGS-004 `system` light |
| `test/features/settings/presentation/goldens/settings_loaded_dark.png` | superseded → SCR-SETTINGS-002 `loaded` dark |
| `test/features/settings/presentation/goldens/settings_loaded_light.png` | superseded → SCR-SETTINGS-002 `loaded` light |
| `test/features/settings/presentation/goldens/settings_loading_dark.png` | superseded → SCR-SETTINGS-002 `loading` dark |
| `test/features/settings/presentation/goldens/settings_loading_light.png` | superseded → SCR-SETTINGS-002 `loading` light |
| `test/features/settings/presentation/goldens/settings_reset_confirm_dark.png` | superseded → SCR-SETTINGS-002 `reset_confirm` dark |
| `test/features/settings/presentation/goldens/settings_reset_confirm_light.png` | superseded → SCR-SETTINGS-002 `reset_confirm` light |
| `test/features/settings/presentation/goldens/settings_reset_done_dark.png` | superseded → SCR-SETTINGS-002 `reset_done` dark |
| `test/features/settings/presentation/goldens/settings_reset_done_light.png` | superseded → SCR-SETTINGS-002 `reset_done` light |
| `test/features/settings/presentation/goldens/settings_save_failed_dark.png` | superseded → SCR-SETTINGS-002 `save_failed` dark |
| `test/features/settings/presentation/goldens/settings_save_failed_light.png` | superseded → SCR-SETTINGS-002 `save_failed` light |
| `test/features/settings/presentation/goldens/settings_saved_dark.png` | superseded → SCR-SETTINGS-002 `saved` dark |
| `test/features/settings/presentation/goldens/settings_saved_light.png` | superseded → SCR-SETTINGS-002 `saved` light |
| `test/features/settings/presentation/goldens/settings_saving_dark.png` | superseded → SCR-SETTINGS-002 `saving` dark |
| `test/features/settings/presentation/goldens/settings_saving_light.png` | superseded → SCR-SETTINGS-002 `saving` light |
| `test/features/settings/presentation/goldens/settings_sync_failed_dark.png` | superseded → SCR-SETTINGS-002 `sync_failed` dark |
| `test/features/settings/presentation/goldens/settings_sync_failed_light.png` | superseded → SCR-SETTINGS-002 `sync_failed` light |
| `test/features/settings/presentation/goldens/settings_sync_rejected_dark.png` | superseded → SCR-SETTINGS-002 `sync_rejected` dark |
| `test/features/settings/presentation/goldens/settings_sync_rejected_light.png` | superseded → SCR-SETTINGS-002 `sync_rejected` light |
| `test/features/settings/presentation/goldens/settings_sync_synced_dark.png` | superseded → SCR-SETTINGS-002 `sync_synced` dark |
| `test/features/settings/presentation/goldens/settings_sync_synced_light.png` | superseded → SCR-SETTINGS-002 `sync_synced` light |
| `test/features/settings/presentation/goldens/settings_theme_dark_dark.png` | superseded → SCR-SETTINGS-003 `dark` dark |
| `test/features/settings/presentation/goldens/settings_theme_dark_light.png` | superseded → SCR-SETTINGS-003 `dark` light |
| `test/features/settings/presentation/goldens/settings_theme_light_dark.png` | superseded → SCR-SETTINGS-003 `light` dark |
| `test/features/settings/presentation/goldens/settings_theme_light_light.png` | superseded → SCR-SETTINGS-003 `light` light |
| `test/features/settings/presentation/goldens/settings_theme_system_dark.png` | superseded → SCR-SETTINGS-003 `system` dark |
| `test/features/settings/presentation/goldens/settings_theme_system_light.png` | superseded → SCR-SETTINGS-003 `system` light |
| `test/features/settings/presentation/goldens/study_options_defaults_dark.png` | superseded → SCR-SETTINGS-001 `defaults` dark |
| `test/features/settings/presentation/goldens/study_options_defaults_light.png` | superseded → SCR-SETTINGS-001 `defaults` light |
| `test/features/settings/presentation/goldens/study_options_invalid_dark.png` | superseded → SCR-SETTINGS-001 `invalid` dark |
| `test/features/settings/presentation/goldens/study_options_invalid_light.png` | superseded → SCR-SETTINGS-001 `invalid` light |
| `test/features/settings/presentation/goldens/study_options_loading_dark.png` | superseded → SCR-SETTINGS-001 `loading` dark |
| `test/features/settings/presentation/goldens/study_options_loading_light.png` | superseded → SCR-SETTINGS-001 `loading` light |
| `test/features/settings/presentation/goldens/study_options_override_dark.png` | superseded → SCR-SETTINGS-001 `override` dark |
| `test/features/settings/presentation/goldens/study_options_override_light.png` | superseded → SCR-SETTINGS-001 `override` light |
| `test/features/settings/presentation/goldens/study_options_save_failed_dark.png` | superseded → SCR-SETTINGS-001 `save_failed` dark |
| `test/features/settings/presentation/goldens/study_options_save_failed_light.png` | superseded → SCR-SETTINGS-001 `save_failed` light |
| `test/features/settings/presentation/goldens/study_options_saved_dark.png` | superseded → SCR-SETTINGS-001 `saved` dark |
| `test/features/settings/presentation/goldens/study_options_saved_light.png` | superseded → SCR-SETTINGS-001 `saved` light |
| `test/features/settings/presentation/goldens/study_options_saving_dark.png` | superseded → SCR-SETTINGS-001 `saving` dark |
| `test/features/settings/presentation/goldens/study_options_saving_light.png` | superseded → SCR-SETTINGS-001 `saving` light |
| `test/features/settings/presentation/goldens/sync_failed_network_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_failed_network_light.png` |  |
| `test/features/settings/presentation/goldens/sync_failed_server_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_failed_server_light.png` |  |
| `test/features/settings/presentation/goldens/sync_keep_dialog_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_keep_dialog_light.png` |  |
| `test/features/settings/presentation/goldens/sync_never_synced_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_never_synced_light.png` |  |
| `test/features/settings/presentation/goldens/sync_pending_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_pending_light.png` |  |
| `test/features/settings/presentation/goldens/sync_rejected_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_rejected_light.png` |  |
| `test/features/settings/presentation/goldens/sync_synced_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_synced_light.png` |  |
| `test/features/settings/presentation/goldens/sync_syncing_dark.png` |  |
| `test/features/settings/presentation/goldens/sync_syncing_light.png` |  |
| `test/features/starter_decks/presentation/goldens/starter_add_failed_dark.png` | superseded → SCR-STARTER-001 `add_failed` dark |
| `test/features/starter_decks/presentation/goldens/starter_add_failed_light.png` | superseded → SCR-STARTER-001 `add_failed` light |
| `test/features/starter_decks/presentation/goldens/starter_added_dark.png` | superseded → SCR-STARTER-001 `added` dark |
| `test/features/starter_decks/presentation/goldens/starter_added_light.png` | superseded → SCR-STARTER-001 `added` light |
| `test/features/starter_decks/presentation/goldens/starter_adding_dark.png` | superseded → SCR-STARTER-001 `adding` dark |
| `test/features/starter_decks/presentation/goldens/starter_adding_light.png` | superseded → SCR-STARTER-001 `adding` light |
| `test/features/starter_decks/presentation/goldens/starter_already_present_dark.png` | superseded → SCR-STARTER-001 `already_present` dark |
| `test/features/starter_decks/presentation/goldens/starter_already_present_light.png` | superseded → SCR-STARTER-001 `already_present` light |
| `test/features/starter_decks/presentation/goldens/starter_choose_dark.png` | superseded → SCR-STARTER-001 `choose` dark |
| `test/features/starter_decks/presentation/goldens/starter_choose_light.png` | superseded → SCR-STARTER-001 `choose` light |
| `test/features/starter_decks/presentation/goldens/starter_list_dark.png` | superseded → SCR-STARTER-001 `list` dark |
| `test/features/starter_decks/presentation/goldens/starter_list_light.png` | superseded → SCR-STARTER-001 `list` light |
| `test/features/starter_decks/presentation/goldens/starter_load_failed_dark.png` | superseded → SCR-STARTER-001 `load_failed` dark |
| `test/features/starter_decks/presentation/goldens/starter_load_failed_light.png` | superseded → SCR-STARTER-001 `load_failed` light |
| `test/features/starter_decks/presentation/goldens/starter_loading_dark.png` | superseded → SCR-STARTER-001 `loading` dark |
| `test/features/starter_decks/presentation/goldens/starter_loading_light.png` | superseded → SCR-STARTER-001 `loading` light |
| `test/features/starter_decks/presentation/goldens/starter_none_dark.png` | superseded → SCR-STARTER-001 `none` dark |
| `test/features/starter_decks/presentation/goldens/starter_none_light.png` | superseded → SCR-STARTER-001 `none` light |
| `test/features/starter_decks/presentation/goldens/starter_second_copy_dark.png` | superseded → SCR-STARTER-001 `second_copy` dark |
| `test/features/starter_decks/presentation/goldens/starter_second_copy_light.png` | superseded → SCR-STARTER-001 `second_copy` light |
| `test/features/study/presentation/goldens/study_browse_dark.png` | superseded → SCR-STUDY-003 `default` dark |
| `test/features/study/presentation/goldens/study_browse_light.png` | superseded → SCR-STUDY-003 `default` light |
| `test/features/study/presentation/goldens/study_browse_looking_back_dark.png` | superseded → SCR-STUDY-003 `looking_back` dark |
| `test/features/study/presentation/goldens/study_browse_looking_back_light.png` | superseded → SCR-STUDY-003 `looking_back` light |
| `test/features/study/presentation/goldens/study_entry_direction_sheet_dark.png` | superseded → SCR-STUDY-002 `direction_sheet` dark |
| `test/features/study/presentation/goldens/study_entry_direction_sheet_light.png` | superseded → SCR-STUDY-002 `direction_sheet` light |
| `test/features/study/presentation/goldens/study_entry_eight_box_dark.png` | superseded → SCR-STUDY-002 `eight_box` dark |
| `test/features/study/presentation/goldens/study_entry_eight_box_light.png` | superseded → SCR-STUDY-002 `eight_box` light |
| `test/features/study/presentation/goldens/study_entry_loading_dark.png` | superseded → SCR-STUDY-002 `loading` dark |
| `test/features/study/presentation/goldens/study_entry_loading_light.png` | superseded → SCR-STUDY-002 `loading` light |
| `test/features/study/presentation/goldens/study_entry_nothing_dark.png` | superseded → SCR-STUDY-002 `nothing` dark |
| `test/features/study/presentation/goldens/study_entry_nothing_light.png` | superseded → SCR-STUDY-002 `nothing` light |
| `test/features/study/presentation/goldens/study_entry_only_new_dark.png` | superseded → SCR-STUDY-002 `only_new` dark |
| `test/features/study/presentation/goldens/study_entry_only_new_light.png` | superseded → SCR-STUDY-002 `only_new` light |
| `test/features/study/presentation/goldens/study_entry_refused_dark.png` | superseded → SCR-STUDY-002 `refused` dark |
| `test/features/study/presentation/goldens/study_entry_refused_light.png` | superseded → SCR-STUDY-002 `refused` light |
| `test/features/study/presentation/goldens/study_entry_resume_dark.png` | superseded → SCR-STUDY-002 `resume` dark |
| `test/features/study/presentation/goldens/study_entry_resume_light.png` | superseded → SCR-STUDY-002 `resume` light |
| `test/features/study/presentation/goldens/study_entry_sm2_dark.png` | superseded → SCR-STUDY-002 `sm2` dark |
| `test/features/study/presentation/goldens/study_entry_sm2_light.png` | superseded → SCR-STUDY-002 `sm2` light |
| `test/features/study/presentation/goldens/study_entry_start_failed_dark.png` | superseded → SCR-STUDY-002 `start_failed` dark |
| `test/features/study/presentation/goldens/study_entry_start_failed_light.png` | superseded → SCR-STUDY-002 `start_failed` light |
| `test/features/study/presentation/goldens/study_entry_starting_dark.png` | superseded → SCR-STUDY-002 `starting` dark |
| `test/features/study/presentation/goldens/study_entry_starting_light.png` | superseded → SCR-STUDY-002 `starting` light |
| `test/features/study/presentation/goldens/study_fill_hint_dark.png` | superseded → SCR-STUDY-008 `hint` dark |
| `test/features/study/presentation/goldens/study_fill_hint_light.png` | superseded → SCR-STUDY-008 `hint` light |
| `test/features/study/presentation/goldens/study_fill_input_dark.png` | superseded → SCR-STUDY-008 `input` dark |
| `test/features/study/presentation/goldens/study_fill_input_light.png` | superseded → SCR-STUDY-008 `input` light |
| `test/features/study/presentation/goldens/study_fill_wrong_dark.png` | superseded → SCR-STUDY-008 `wrong` dark |
| `test/features/study/presentation/goldens/study_fill_wrong_light.png` | superseded → SCR-STUDY-008 `wrong` light |
| `test/features/study/presentation/goldens/study_guess_blocked_dark.png` | superseded → SCR-STUDY-006 `blocked` dark |
| `test/features/study/presentation/goldens/study_guess_blocked_light.png` | superseded → SCR-STUDY-006 `blocked` light |
| `test/features/study/presentation/goldens/study_guess_idle_dark.png` | superseded → SCR-STUDY-006 `idle` dark |
| `test/features/study/presentation/goldens/study_guess_idle_light.png` | superseded → SCR-STUDY-006 `idle` light |
| `test/features/study/presentation/goldens/study_guess_right_dark.png` | superseded → SCR-STUDY-006 `right` dark |
| `test/features/study/presentation/goldens/study_guess_right_light.png` | superseded → SCR-STUDY-006 `right` light |
| `test/features/study/presentation/goldens/study_guess_wrong_dark.png` | superseded → SCR-STUDY-006 `wrong` dark |
| `test/features/study/presentation/goldens/study_guess_wrong_light.png` | superseded → SCR-STUDY-006 `wrong` light |
| `test/features/study/presentation/goldens/study_home_error_dark.png` | superseded → SCR-STUDY-001 `error` dark |
| `test/features/study/presentation/goldens/study_home_error_light.png` | superseded → SCR-STUDY-001 `error` light |
| `test/features/study/presentation/goldens/study_home_loaded_dark.png` | superseded → SCR-STUDY-001 `loaded` dark |
| `test/features/study/presentation/goldens/study_home_loaded_light.png` | superseded → SCR-STUDY-001 `loaded` light |
| `test/features/study/presentation/goldens/study_home_loading_dark.png` | superseded → SCR-STUDY-001 `loading` dark |
| `test/features/study/presentation/goldens/study_home_loading_light.png` | superseded → SCR-STUDY-001 `loading` light |
| `test/features/study/presentation/goldens/study_home_no_cards_dark.png` | superseded → SCR-STUDY-001 `no_cards` dark |
| `test/features/study/presentation/goldens/study_home_no_cards_light.png` | superseded → SCR-STUDY-001 `no_cards` light |
| `test/features/study/presentation/goldens/study_home_no_decks_dark.png` | superseded → SCR-STUDY-001 `no_decks` dark |
| `test/features/study/presentation/goldens/study_home_no_decks_light.png` | superseded → SCR-STUDY-001 `no_decks` light |
| `test/features/study/presentation/goldens/study_home_no_resume_dark.png` | superseded → SCR-STUDY-001 `no_resume` dark |
| `test/features/study/presentation/goldens/study_home_no_resume_light.png` | superseded → SCR-STUDY-001 `no_resume` light |
| `test/features/study/presentation/goldens/study_home_sync_rejected_dark.png` | superseded → SCR-STUDY-001 `sync_rejected` dark |
| `test/features/study/presentation/goldens/study_home_sync_rejected_light.png` | superseded → SCR-STUDY-001 `sync_rejected` light |
| `test/features/study/presentation/goldens/study_home_sync_stale_dark.png` | superseded → SCR-STUDY-001 `sync_stale` dark |
| `test/features/study/presentation/goldens/study_home_sync_stale_light.png` | superseded → SCR-STUDY-001 `sync_stale` light |
| `test/features/study/presentation/goldens/study_home_zero_dark.png` | superseded → SCR-STUDY-001 `zero` dark |
| `test/features/study/presentation/goldens/study_home_zero_light.png` | superseded → SCR-STUDY-001 `zero` light |
| `test/features/study/presentation/goldens/study_match_board_dark.png` | superseded → SCR-STUDY-005 `board` dark |
| `test/features/study/presentation/goldens/study_match_board_light.png` | superseded → SCR-STUDY-005 `board` light |
| `test/features/study/presentation/goldens/study_match_wrong_dark.png` | superseded → SCR-STUDY-005 `wrong` dark |
| `test/features/study/presentation/goldens/study_match_wrong_light.png` | superseded → SCR-STUDY-005 `wrong` light |
| `test/features/study/presentation/goldens/study_recall_counting_dark.png` | superseded → SCR-STUDY-007 `counting` dark |
| `test/features/study/presentation/goldens/study_recall_counting_light.png` | superseded → SCR-STUDY-007 `counting` light |
| `test/features/study/presentation/goldens/study_recall_revealed_dark.png` | superseded → SCR-STUDY-007 `revealed` dark |
| `test/features/study/presentation/goldens/study_recall_revealed_light.png` | superseded → SCR-STUDY-007 `revealed` light |
| `test/features/study/presentation/goldens/study_recall_timed_out_dark.png` | superseded → SCR-STUDY-007 `timed_out` dark |
| `test/features/study/presentation/goldens/study_recall_timed_out_light.png` | superseded → SCR-STUDY-007 `timed_out` light |
| `test/features/study/presentation/goldens/study_self_assess_meaning_first_dark.png` | superseded → SCR-STUDY-004 `meaning_first` dark |
| `test/features/study/presentation/goldens/study_self_assess_meaning_first_light.png` | superseded → SCR-STUDY-004 `meaning_first` light |
| `test/features/study/presentation/goldens/study_self_assess_prompt_dark.png` | superseded → SCR-STUDY-004 `prompt` dark |
| `test/features/study/presentation/goldens/study_self_assess_prompt_light.png` | superseded → SCR-STUDY-004 `prompt` light |
| `test/features/study/presentation/goldens/study_self_assess_relearning_dark.png` | superseded → SCR-STUDY-004 `relearning` dark |
| `test/features/study/presentation/goldens/study_self_assess_relearning_light.png` | superseded → SCR-STUDY-004 `relearning` light |
| `test/features/study/presentation/goldens/study_self_assess_revealed_dark.png` | superseded → SCR-STUDY-004 `revealed` dark |
| `test/features/study/presentation/goldens/study_self_assess_revealed_light.png` | superseded → SCR-STUDY-004 `revealed` light |
| `test/features/study/presentation/goldens/summary_content_deleted_dark.png` | superseded → SCR-STUDY-009 `content_deleted` dark |
| `test/features/study/presentation/goldens/summary_content_deleted_light.png` | superseded → SCR-STUDY-009 `content_deleted` light |
| `test/features/study/presentation/goldens/summary_interrupted_dark.png` | superseded → SCR-STUDY-009 `interrupted` dark |
| `test/features/study/presentation/goldens/summary_interrupted_light.png` | superseded → SCR-STUDY-009 `interrupted` light |
| `test/features/study/presentation/goldens/summary_large_dark.png` | superseded → SCR-STUDY-009 `large` dark |
| `test/features/study/presentation/goldens/summary_large_light.png` | superseded → SCR-STUDY-009 `large` light |
| `test/features/study/presentation/goldens/summary_learning_dark.png` | superseded → SCR-STUDY-009 `learning` dark |
| `test/features/study/presentation/goldens/summary_learning_light.png` | superseded → SCR-STUDY-009 `learning` light |
| `test/features/study/presentation/goldens/summary_left_early_dark.png` | superseded → SCR-STUDY-009 `left_early` dark |
| `test/features/study/presentation/goldens/summary_left_early_light.png` | superseded → SCR-STUDY-009 `left_early` light |
| `test/features/study/presentation/goldens/summary_reset_dark.png` | superseded → SCR-STUDY-009 `reset` dark |
| `test/features/study/presentation/goldens/summary_reset_light.png` | superseded → SCR-STUDY-009 `reset` light |
| `test/features/study/presentation/goldens/summary_review_dark.png` | superseded → SCR-STUDY-009 `loaded` dark |
| `test/features/study/presentation/goldens/summary_review_light.png` | superseded → SCR-STUDY-009 `loaded` light |
| `test/features/study/presentation/goldens/summary_save_error_dark.png` | superseded → SCR-STUDY-009 `save_error` dark |
| `test/features/study/presentation/goldens/summary_save_error_light.png` | superseded → SCR-STUDY-009 `save_error` light |
| `test/features/study/presentation/goldens/summary_scheduler_changed_dark.png` | superseded → SCR-STUDY-009 `scheduler_changed` dark |
| `test/features/study/presentation/goldens/summary_scheduler_changed_light.png` | superseded → SCR-STUDY-009 `scheduler_changed` light |
| `test/features/tags/presentation/goldens/tags_busy_dark.png` | superseded → SCR-TAG-001 `busy` dark |
| `test/features/tags/presentation/goldens/tags_busy_light.png` | superseded → SCR-TAG-001 `busy` light |
| `test/features/tags/presentation/goldens/tags_del_dark.png` | superseded → SCR-TAG-001 `del` dark |
| `test/features/tags/presentation/goldens/tags_del_light.png` | superseded → SCR-TAG-001 `del` light |
| `test/features/tags/presentation/goldens/tags_empty_dark.png` | superseded → SCR-TAG-001 `empty` dark |
| `test/features/tags/presentation/goldens/tags_empty_light.png` | superseded → SCR-TAG-001 `empty` light |
| `test/features/tags/presentation/goldens/tags_loaded_dark.png` | superseded → SCR-TAG-001 `loaded` dark |
| `test/features/tags/presentation/goldens/tags_loaded_light.png` | superseded → SCR-TAG-001 `loaded` light |
| `test/features/tags/presentation/goldens/tags_loading_dark.png` | superseded → SCR-TAG-001 `loading` dark |
| `test/features/tags/presentation/goldens/tags_loading_light.png` | superseded → SCR-TAG-001 `loading` light |
| `test/features/tags/presentation/goldens/tags_name_too_long_dark.png` | superseded → SCR-TAG-001 `name_too_long` dark |
| `test/features/tags/presentation/goldens/tags_name_too_long_light.png` | superseded → SCR-TAG-001 `name_too_long` light |
| `test/features/tags/presentation/goldens/tags_op_error_dark.png` | superseded → SCR-TAG-001 `op_error` dark |
| `test/features/tags/presentation/goldens/tags_op_error_light.png` | superseded → SCR-TAG-001 `op_error` light |
| `test/features/tags/presentation/goldens/tags_read_error_dark.png` | superseded → SCR-TAG-001 `read_error` dark |
| `test/features/tags/presentation/goldens/tags_read_error_light.png` | superseded → SCR-TAG-001 `read_error` light |
| `test/features/tags/presentation/goldens/tags_rename_dark.png` | superseded → SCR-TAG-001 `rename` dark |
| `test/features/tags/presentation/goldens/tags_rename_light.png` | superseded → SCR-TAG-001 `rename` light |
| `test/features/tags/presentation/goldens/tags_rename_merge_dark.png` | superseded → SCR-TAG-001 `rename_merge` dark |
| `test/features/tags/presentation/goldens/tags_rename_merge_light.png` | superseded → SCR-TAG-001 `rename_merge` light |
| `test/features/tags/presentation/goldens/tags_search_empty_dark.png` | superseded → SCR-TAG-001 `search_empty` dark |
| `test/features/tags/presentation/goldens/tags_search_empty_light.png` | superseded → SCR-TAG-001 `search_empty` light |
| `test/features/tags/presentation/goldens/tags_sheet_dark.png` | superseded → SCR-TAG-001 `sheet` dark |
| `test/features/tags/presentation/goldens/tags_sheet_light.png` | superseded → SCR-TAG-001 `sheet` light |
| `test/features/tags/presentation/goldens/tags_tag_gone_dark.png` | superseded → SCR-TAG-001 `tag_gone` dark |
| `test/features/tags/presentation/goldens/tags_tag_gone_light.png` | superseded → SCR-TAG-001 `tag_gone` light |
| `test/features/transfer/presentation/goldens/export_deck_dark.png` | superseded → SCR-TRANSFER-002 `whole_deck` dark |
| `test/features/transfer/presentation/goldens/export_deck_light.png` | superseded → SCR-TRANSFER-002 `whole_deck` light |
| `test/features/transfer/presentation/goldens/export_failed_dark.png` | superseded → SCR-TRANSFER-002 `failed` dark |
| `test/features/transfer/presentation/goldens/export_failed_light.png` | superseded → SCR-TRANSFER-002 `failed` light |
| `test/features/transfer/presentation/goldens/export_stale_dark.png` | superseded → SCR-TRANSFER-002 `stale_selection` dark |
| `test/features/transfer/presentation/goldens/export_stale_light.png` | superseded → SCR-TRANSFER-002 `stale_selection` light |
| `test/features/transfer/presentation/goldens/import_mapping_dark.png` | superseded → SCR-TRANSFER-001 `mapping` dark |
| `test/features/transfer/presentation/goldens/import_mapping_light.png` | superseded → SCR-TRANSFER-001 `mapping` light |
| `test/features/transfer/presentation/goldens/import_mapping_no_header_dark.png` | superseded → SCR-TRANSFER-001 `mapping_no_header` dark |
| `test/features/transfer/presentation/goldens/import_mapping_no_header_light.png` | superseded → SCR-TRANSFER-001 `mapping_no_header` light |
| `test/features/transfer/presentation/goldens/import_partial_dark.png` | superseded → SCR-TRANSFER-001 `partial` dark |
| `test/features/transfer/presentation/goldens/import_partial_light.png` | superseded → SCR-TRANSFER-001 `partial` light |
| `test/features/transfer/presentation/goldens/import_preview_dark.png` | superseded → SCR-TRANSFER-001 `preview_mix` dark |
| `test/features/transfer/presentation/goldens/import_preview_light.png` | superseded → SCR-TRANSFER-001 `preview_mix` light |
| `test/features/transfer/presentation/goldens/import_source_dark.png` | superseded → SCR-TRANSFER-001 `empty` dark |
| `test/features/transfer/presentation/goldens/import_source_light.png` | superseded → SCR-TRANSFER-001 `empty` light |
| `test/features/trash/presentation/goldens/trash_actions_dark.png` | superseded → SCR-TRASH-001 `actions` dark |
| `test/features/trash/presentation/goldens/trash_actions_light.png` | superseded → SCR-TRASH-001 `actions` light |
| `test/features/trash/presentation/goldens/trash_all_dark.png` | superseded → SCR-TRASH-001 `all` dark |
| `test/features/trash/presentation/goldens/trash_all_light.png` | superseded → SCR-TRASH-001 `all` light |
| `test/features/trash/presentation/goldens/trash_empty_dark.png` | superseded → SCR-TRASH-001 `empty` dark |
| `test/features/trash/presentation/goldens/trash_empty_light.png` | superseded → SCR-TRASH-001 `empty` light |
| `test/features/trash/presentation/goldens/trash_error_dark.png` | superseded → SCR-TRASH-001 `error` dark |
| `test/features/trash/presentation/goldens/trash_error_light.png` | superseded → SCR-TRASH-001 `error` light |
| `test/features/trash/presentation/goldens/trash_no_target_dark.png` | superseded → SCR-TRASH-001 `no_target` dark |
| `test/features/trash/presentation/goldens/trash_no_target_light.png` | superseded → SCR-TRASH-001 `no_target` light |
| `test/features/trash/presentation/goldens/trash_purge_blocked_dark.png` | superseded → SCR-TRASH-001 `younger_inside` dark |
| `test/features/trash/presentation/goldens/trash_purge_blocked_light.png` | superseded → SCR-TRASH-001 `younger_inside` light |
| `test/features/trash/presentation/goldens/trash_purge_confirm_dark.png` | superseded → SCR-TRASH-001 `purge_confirm` dark |
| `test/features/trash/presentation/goldens/trash_purge_confirm_light.png` | superseded → SCR-TRASH-001 `purge_confirm` light |
| `test/features/trash/presentation/goldens/trash_restore_target_dark.png` | superseded → SCR-TRASH-001 `restore_target` dark |
| `test/features/trash/presentation/goldens/trash_restore_target_light.png` | superseded → SCR-TRASH-001 `restore_target` light |
| `test/features/trash/presentation/goldens/trash_selection_dark.png` | superseded → SCR-TRASH-001 `selection` dark |
| `test/features/trash/presentation/goldens/trash_selection_light.png` | superseded → SCR-TRASH-001 `selection` light |
| `test/shared/widgets/goldens/mx_app_bar_dark.png` |  |
| `test/shared/widgets/goldens/mx_app_bar_light.png` |  |
| `test/shared/widgets/goldens/mx_app_shell_dark.png` |  |
| `test/shared/widgets/goldens/mx_app_shell_light.png` |  |
| `test/shared/widgets/goldens/mx_badges_tags_dark.png` |  |
| `test/shared/widgets/goldens/mx_badges_tags_light.png` |  |
| `test/shared/widgets/goldens/mx_bottom_nav_dark.png` |  |
| `test/shared/widgets/goldens/mx_bottom_nav_light.png` |  |
| `test/shared/widgets/goldens/mx_bottom_sheet_dark.png` |  |
| `test/shared/widgets/goldens/mx_bottom_sheet_light.png` |  |
| `test/shared/widgets/goldens/mx_breadcrumb_dark.png` |  |
| `test/shared/widgets/goldens/mx_breadcrumb_light.png` |  |
| `test/shared/widgets/goldens/mx_button_dark.png` |  |
| `test/shared/widgets/goldens/mx_button_light.png` |  |
| `test/shared/widgets/goldens/mx_card_icon_tile_dark.png` |  |
| `test/shared/widgets/goldens/mx_card_icon_tile_light.png` |  |
| `test/shared/widgets/goldens/mx_chips_dark.png` |  |
| `test/shared/widgets/goldens/mx_chips_light.png` |  |
| `test/shared/widgets/goldens/mx_day_bars_dark.png` |  |
| `test/shared/widgets/goldens/mx_day_bars_light.png` |  |
| `test/shared/widgets/goldens/mx_deck_picker_dark.png` |  |
| `test/shared/widgets/goldens/mx_deck_picker_light.png` |  |
| `test/shared/widgets/goldens/mx_dialog_dark.png` |  |
| `test/shared/widgets/goldens/mx_dialog_light.png` |  |
| `test/shared/widgets/goldens/mx_empty_state_dark.png` |  |
| `test/shared/widgets/goldens/mx_empty_state_light.png` |  |
| `test/shared/widgets/goldens/mx_error_state_dark.png` |  |
| `test/shared/widgets/goldens/mx_error_state_light.png` |  |
| `test/shared/widgets/goldens/mx_fab_dark.png` |  |
| `test/shared/widgets/goldens/mx_fab_light.png` |  |
| `test/shared/widgets/goldens/mx_icon_button_dark.png` |  |
| `test/shared/widgets/goldens/mx_icon_button_light.png` |  |
| `test/shared/widgets/goldens/mx_list_row_dark.png` |  |
| `test/shared/widgets/goldens/mx_list_row_light.png` |  |
| `test/shared/widgets/goldens/mx_nav_rail_dark.png` |  |
| `test/shared/widgets/goldens/mx_nav_rail_light.png` |  |
| `test/shared/widgets/goldens/mx_option_tray_dark.png` |  |
| `test/shared/widgets/goldens/mx_option_tray_light.png` |  |
| `test/shared/widgets/goldens/mx_search_field_dark.png` |  |
| `test/shared/widgets/goldens/mx_search_field_light.png` |  |
| `test/shared/widgets/goldens/mx_section_header_note_dark.png` |  |
| `test/shared/widgets/goldens/mx_section_header_note_light.png` |  |
| `test/shared/widgets/goldens/mx_settings_command_rows_dark.png` |  |
| `test/shared/widgets/goldens/mx_settings_command_rows_light.png` |  |
| `test/shared/widgets/goldens/mx_sheet_actions_banner_dark.png` |  |
| `test/shared/widgets/goldens/mx_sheet_actions_banner_light.png` |  |
| `test/shared/widgets/goldens/mx_snackbar_dark.png` |  |
| `test/shared/widgets/goldens/mx_snackbar_light.png` |  |
| `test/shared/widgets/goldens/mx_spinner_skeleton_dark.png` |  |
| `test/shared/widgets/goldens/mx_spinner_skeleton_light.png` |  |
| `test/shared/widgets/goldens/mx_stat_tile_dark.png` |  |
| `test/shared/widgets/goldens/mx_stat_tile_light.png` |  |
| `test/shared/widgets/goldens/mx_stepper_dark.png` |  |
| `test/shared/widgets/goldens/mx_stepper_light.png` |  |
| `test/shared/widgets/goldens/mx_study_top_bar_dark.png` |  |
| `test/shared/widgets/goldens/mx_study_top_bar_light.png` |  |
| `test/shared/widgets/goldens/mx_text_field_code_dark.png` |  |
| `test/shared/widgets/goldens/mx_text_field_code_light.png` |  |
| `test/shared/widgets/goldens/mx_text_field_dark.png` |  |
| `test/shared/widgets/goldens/mx_text_field_light.png` |  |
| `test/shared/widgets/goldens/mx_toggle_checkbox_dark.png` |  |
| `test/shared/widgets/goldens/mx_toggle_checkbox_light.png` |  |
| `test/shared/widgets/goldens/mx_vietnamese_ellipsis_dark.png` |  |
| `test/shared/widgets/goldens/mx_vietnamese_ellipsis_light.png` |  |
| `test/shared/widgets/goldens/mx_workload_donut_dark.png` |  |
| `test/shared/widgets/goldens/mx_workload_donut_light.png` |  |

<!-- Notes below are kept by `ledger.py seed`. -->

## Task 12 notes — deck

Candidate FNs (plan P1 step 1); every deck use case class is an FN:

| Use case class | FN |
|---|---|
| create_root_deck | FN-DECK-001 Tạo root deck |
| rename_deck | FN-DECK-002 Đổi tên deck |
| change_deck_scheduler | FN-DECK-003 Đổi chế độ ôn tập của root deck |
| get_deck_deletion_summary | FN-DECK-004 Xem số deck con và card sẽ vào Trash cùng deck |
| delete_deck | FN-DECK-005 Chuyển deck và cây con vào Trash |
| undo_deck_deletion | FN-DECK-006 Hoàn tác xoá deck |
| watch_deck_level | FN-DECK-007 Xem một cấp của thư viện kèm tiến độ |
| watch_deck | FN-DECK-008 Xem một deck đang mở |
| create_sub_deck | FN-DECK-009 Tạo deck con |
| watch_deck_move_targets | FN-DECK-010 Xem các đích di chuyển hợp lệ |
| move_deck | FN-DECK-011 Di chuyển deck trong cây |
| reorder_deck | FN-DECK-012 Sắp xếp lại deck cùng cấp |

- The card branch of UC-DECK-004 (create a card in an `unset` deck) is a card FN: Task 14 adds it
  to UC-DECK-004's `Invokes:`. BR-CARD-004 moves there.
- Open rows of deck ui.md: line 57 (who sets the scheduler lock) goes to the study FNs (Task 16);
  lines 61–69 (validation messages) and 77 (empty deck) are checked against the app's copy in
  Task 13.
- The OPEN QUESTION on the order of the move checks (FN-DECK-011) was ruled by the owner on
  2026-10-04: code order (spec R22); UC-DECK-005 step 2 now lists depth before scheduler.
- No new "active BR is cited by no FN" warning for deck.

## Task 13a notes — owner checkpoint after the deck pilot (2026-10-04)

- Spec R19–R22 applied. The other 33 screens are catalog rows with status `pending` under their
  Phase D ids; SCR-DECK-001 navigates to them by id (11 pending-target warnings).
- UC-DECK-001…006 rewritten at the level of user intent (R20). Every presentation detail taken
  out of them is either in SCR-DECK-001 (rows `superseded → UC-DECK-… (intent) + SCR-DECK-001 (…)`)
  or waits for the Review algorithm screen (8 rows `pending → SCR-SRS-001 (…)`).
- Two OPEN QUESTIONs raised in SCR-DECK-001, where UC-DECK-001 E2 and UC-DECK-003 step 3 described
  UI the V8 app does not draw (input stopped at 200 characters; tri-state schedule icon, Due + New
  on the tile, a 2×2 summary grid).
- FN-DECK-005, FN-DECK-006 cite each other and FN-DECK-011 as contract prerequisites (R21).
- IMPLEMENTATION GAP recorded in SCR-DECK-001 (owner ruling 2026-10-04): BR-STUDY-046/068 require
  Overdue / Due / New told apart on each deck row; V8 draws one "{n} due" badge. BRs unchanged;
  no code change in this migration.

## Task 14 notes — card

Every card use case class is an FN: watch_card_list FN-CARD-001, create_card 002, edit_card 003,
delete_cards 004, undo_card_deletion 005, watch_card_move_targets 006, move_cards 007,
select_all_card_ids 008, set_cards_flagged 009, add_tag_to_cards 010, remove_tag_from_cards 011,
watch_card_tag_filter 012 (serves the card list's tag filter; UC-TAG-001 step 6 will invoke it in
Task 21), watch_card_detail 013, load_card_history_page 014.

- UC-DECK-004 now invokes FN-CARD-002 for its card branch (Task 12 note closed).
- Presentation taken out of UC-CARD-001/002 waits for SCR-CARD-001…004 (`pending` rows).
- Warning delta: 68 → 69 = +2 migrated legacy UC files, −1 BR-STUDY-047 now cited by FN-CARD-001.

## Task 15 notes — srs

get_reset_learning_summary → FN-SRS-001, reset_learning_progress → FN-SRS-002. Warning delta
69 → 69: +1 migrated UC-SRS-001, −1 BR-STUDY-050 now cited by FN-SRS-002.

## Task 16 notes — study + study-mode

Every study use case class is an FN: watch_study_entry FN-STUDY-001, open_learning_session 002,
open_review_session 003, watch_study_session 004, answer_study_turn 005, reveal_recall_answer 006,
save_recall_time 007, show_fill_hint 008, abandon_study_session 009, resume_study_session 010,
abandon_stale_sessions 011, watch_study_home 012, preview_self_assess_intervals 013.

- study-mode has no use case class of its own (`lib/features/study_mode/` holds only the domain mode models
  the study FNs run), so it gets no functional-spec file: its BR-MODE rules are cited by
  FN-STUDY-001…005. Every active BR-MODE and BR-STUDY is now cited by an FN.
- Ruling: opening a session closes the app's open session (`user_exit` if it started today,
  `interrupted` if earlier), not only the tree's — the legacy UC said "the tree's"; the code
  (`closeOpenSessions`) closes the one open session app-wide, and BR-STUDY-072 allows one open
  session — cost if wrong: one sentence in FN-STUDY-002/003.
- Ruling: legacy study/ui.md drew the session as created before Learn/Review is chosen; the code
  creates it in open_learning/open_review. FN-STUDY-002/003 follow the code; the mermaid row is
  `superseded` — cost if wrong: none to behaviour, the diagram was imprecise.
- FN-DECK-007 now cites BR-SRS-013 (its "mastered" count), found while mapping study BRs.
- `features/deck/ui.md:57` (who sets the scheduler lock) → FN-STUDY-005, as planned in Task 13.
- Presentation taken out of UC-STUDY-001…003 waits for SCR-STUDY-001 (home), SCR-STUDY-002
  (entry, mode choice, direction sheet), SCR-STUDY-004 (shared mode-screen states; the other mode
  screens SCR-STUDY-003…008 take their share in P2) and SCR-STUDY-009 (summary).
- Warning delta: 69 → 32 = −40 BR-STUDY/BR-MODE now cited by the study FNs, −1 BR-SRS-013 now
  cited by FN-DECK-007, +3 migrated legacy UC files, +1 FN-STUDY-013 invoked by no UC and no
  screen: the interval preview exists only for the self-assess buttons, so SCR-STUDY-004 will
  invoke it (P2); no use case names it.

## Task 17 notes — settings

watch_app_settings FN-SETTINGS-001, save_study_defaults 002, set_theme 003, set_language 004,
reset_app_settings 005, watch_study_options 006, save_root_study_options 007, use_app_defaults 008.

- `lib/app/startup_settings.dart` (read before the first frame, 2 s at most) is part of
  FN-SETTINGS-001's contract, so settings/ui.md:18 is superseded, not left to the app shell.
- The reminder columns live in `app_settings` but their use cases are in reminders; FN-SETTINGS-005
  names the reminder reset, and the rescheduling after it goes to Task 18.
- settings/ui.md:30 ("no server yet, client validation is UX") is dropped: ADR-015 already says
  where integrity is checked (approval PENDING until Task 43).
- Warning delta: 32 → 33 = +1 migrated legacy UC file. Every BR-SETTINGS is cited by an FN.

## Task 18 notes — reminders

| Use case class | FN |
|---|---|
| watch_reminder | FN-REMINDER-001 |
| read_reminder_preview | FN-REMINDER-002 |
| enable_reminder | FN-REMINDER-003 |
| deliver_reminder | FN-REMINDER-004 |
| (no class: `lib/app/app.dart` follows the notification tap) | FN-REMINDER-005 |
| change_reminder_time | FN-REMINDER-006 |
| disable_reminder | FN-REMINDER-007 |
| reconcile_reminder | not an FN — internal plumbing, spec R6; described once at the top of functional-spec/reminders.md |

- Ruling: deliver_reminder is an FN, against the brief's "likely not" — what the notification says,
  when it does not come and the one-a-day limit are what a QA tests on a device, and BR-REMINDER-003
  …007 would otherwise be cited by no FN — cost if wrong: one FN to fold into a note.
- Ruling: the notification tap gets FN-REMINDER-005 with `Code: lib/app/app.dart` (plan P1 step 1,
  a behaviour no class covers), so BR-REMINDER-008 has its FN; the deep link itself is written in
  NAVIGATION.md in Task 42 — cost if wrong: one FN folded into NAVIGATION.
- The one-operation-at-a-time gate (`ReminderOperationGate`) is a contract and is stated at the top
  of functional-spec/reminders.md; the digest names the top root's own due count, as the legacy AC
  and code do (BR-REMINDER-005 says MAY).
- Warning delta: 33 → 34 = +1 migrated legacy UC file. Every BR-REMINDER is cited by an FN.

## Task 19 notes — progress

watch_progress FN-PROGRESS-001 (the overview and the library level, one stream), watch_deck_progress
FN-PROGRESS-002 (a deck's level, or "deck missing" as a result, not an error).

- The card-day unit, the four numbers, the two ranges, the order, read-only and the per-emission
  clock reading are shared by both FNs; they are written once at the top of
  functional-spec/progress.md and each FN cites the BRs, so FN-PROGRESS-002 does not borrow
  FN-PROGRESS-001's text (owner ruling on FN-DECK-006).
- UC-PROGRESS-001/002 share one screen (SCR-PROGRESS-001); each UC says so at intent level and no
  longer cites the other (USE_CASES cites FN only).
- Warning delta: 34 → 36 = +2 migrated legacy UC files. Every BR-PROGRESS is cited by an FN.

## Task 20 notes — search

search_library FN-SEARCH-001. Search has no ui.md; its screen is SCR-SEARCH-001 (pending).

- Opening a result (deck, or the read-only card detail) is navigation, written as the intent in
  UC-SEARCH-001 step 6 and pending for SCR-SEARCH-001's `Navigate to:`; FN-SEARCH-001 states only
  that nothing is written and no session opens.
- Warning delta: 36 → 37 = +1 migrated legacy UC file. Every BR-SEARCH is cited by FN-SEARCH-001.

## Task 21 notes — tags

| Use case class | FN |
|---|---|
| watch_tag_catalog | FN-TAG-001 |
| plan_tag_rename | FN-TAG-002 |
| rename_tag | FN-TAG-003 |
| delete_tag | FN-TAG-004 |
| watch_deck_tag_counts | not an FN — the same read as `watch_card_tag_filter` (FN-CARD-012); only a test calls it |

- UC-TAG-001 invokes FN-CARD-012 (the filter's source) and FN-CARD-001 (the filtered list), closing
  the Task 14 note.
- BR-TAG-005 (a new tag set restarts the page window and clears the selection) is now cited by
  FN-CARD-001, whose Kết quả states that each query is its own and a stale result never replaces
  the current one — the same treatment BR-CARD-012 got in Task 14.
- Code debt for the owner, not changed here (no lib/ edits in this migration):
  `lib/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart` duplicates
  `watch_card_tag_filter_use_case.dart` and has no caller in the app.
- tags/ui.md:24 ("Tag này đã tồn tại") is superseded: a name clash merges on rename (BR-TAG-007) and
  reuses the tag on attach; no such error exists in the code.
- Warning delta: 37 → 38 = +1 migrated legacy UC file. Every BR-TAG is cited by an FN.

## Task 22 notes — trash

purge_expired_trash FN-TRASH-001, watch_trash 002, watch_deck_restore_targets 003,
watch_card_restore_targets 004, restore_decks_from_trash 005, restore_cards_from_trash 006,
purge_trash 007. Deleting and its undo stay FN-DECK-005/006 and FN-CARD-004/005; UC-TRASH-001
invokes them.

- purge_expired is an FN, not plumbing: "an item leaves the Trash after 30 days" is what a QA tests,
  and FN-TRASH-002 names it as its prerequisite (contract FN→FN, R21).
- The restore targets and errors restate the move conditions as BR citations (BR-DECK-001/009/010/
  017/018, BR-SRS-006, BR-CARD-010) and the real error names, not by borrowing FN-DECK-011's text.
- A root deck restores to the top level only (`rootRestoresToTopLevel`, `subDeckNeedsParent`), as the
  code and BR-TRASH-006 say; the legacy UC did not mention it.
- Trash has no ui.md. The Undo snackbar's presentation goes to SCR-DECK-001 and SCR-CARD-001.
- Warning delta: 38 → 39 = +1 migrated legacy UC file. Every BR-TRASH is cited by an FN.

## Task 23 notes — transfer

read_import_source FN-TRANSFER-001, preview_import 002, commit_import 003, count_export_cards 004,
build_export 005, share_export 006.

- The CSV/TSV delimiter rule (UC-TRANSFER-001 step 3 and A1, spec card transfer D9) is a contract of
  reading the source and moved into FN-TRANSFER-001.
- FN-TRANSFER-003 states that the duplicate check runs again inside the write, so E6 ("Nothing
  added", deck unchanged) is a result, not an error.
- Transfer has no ui.md; the import screen is SCR-TRANSFER-001 and the export sheet SCR-TRANSFER-002.
- Warning delta: 39 → 41 = +2 migrated legacy UC files. Every BR-TRANSFER is cited by an FN.

## Task 24 notes — starter-decks

watch_starter_library FN-STARTER-001, add_starter_deck FN-STARTER-002. UC-STARTER-001 A1 invokes
FN-DECK-001.

- The empty Library's two ways (create, browse starters) already live in SCR-DECK-001 `root_empty`,
  so those ledger rows are superseded by it, not pending.
- UC-STARTER-001 E1 (the database cannot open at start) is an app-shell face: it goes to
  NAVIGATION.md in Task 42. The Welcome screen that account builds show first is SCR-ACCOUNT-002
  (Task 25).
- Warning delta: 41 → 42 = +1 migrated legacy UC file. Every BR-STARTER is cited by an FN.

## Task 25 notes — account and sync

| Code | FN |
|---|---|
| is_welcome_seen + mark_welcome_seen + `lib/app/startup_welcome.dart` | FN-ACCOUNT-001 (one contract: Welcome once per device) |
| `lib/core/auth/auth_state.dart` (the state stream) | FN-ACCOUNT-002 |
| `AccountSwitching.requestCode` / `verifyCode` / `continueWithGoogle` | FN-ACCOUNT-003 / 004 / 005 |
| count_local_library | FN-ACCOUNT-006 |
| `beginSwitch` + `cancelSwitch` | FN-ACCOUNT-007 |
| `signOut` + `cancelSignOut` | FN-ACCOUNT-008 |
| `deleteAccount` / `continueWithoutAccount` / `retry` | FN-ACCOUNT-009 / 010 / 011 |
| search_users / set_user_role | FN-ACCOUNT-012 / 013 |
| `lib/core/sync/` scheduler + coordinator / status / syncNow / retryRejected / keepRejectedOnDevice | FN-ACCOUNT-014 / 015 / 016 / 017 / 018 |

- Ruling: the account commands of `lib/core/auth/` that screens 29–32 trigger get FN-ACCOUNT FNs,
  beyond the brief's five classes and sync — plan P1 step 1 adds an FN for a behaviour no class
  covers, PT1 already does so for `lib/core/sync/`, and without them SCR-ACCOUNT-002…005 would have
  no FN to invoke and the account behaviour would live only in retired handoffs — cost if wrong:
  eleven FNs to fold into the account specs.
- Ruling: is_welcome_seen and mark_welcome_seen are one FN (FN-ACCOUNT-001): together they are the
  one thing a QA tests, "Welcome shows once per device" — cost if wrong: one FN to split.
- `### Business rules` of each FN: "Không áp dụng — feature account chưa có BR (<spec>)" as the
  brief says; FN-ACCOUNT-014 adds what the sync code does and the specs leave implicit: a server
  copy wins over a sent row, and a refused row the server never saw is kept, never deleted.
- Warning delta: 42 → 60 = +18 FN-ACCOUNT invoked by no UC and no screen. Account has no UC; the
  SCR-ACCOUNT specs (Task 28–41) invoke FN-ACCOUNT-001…013 and 015…018. FN-ACCOUNT-014 (automatic
  sync) has no control that calls it, so its warning stays unless the owner wants an account UC;
  Task 43 lists it.

## Task 26 notes — monitoring

query_server_logs FN-MONITORING-001, get_server_log 002, set_log_status 003, watch_pending_logs 004,
get_pending_log 005. No UC, no BR; each FN cites ADR-018's decisions 5–8 and the monitoring spec.

- The filter rule "choosing debug, info or every level clears the status filter" lives in
  `LogFilter.withLevels`; it is a contract of what the server is asked for, so it is in
  FN-MONITORING-001's Input.
- Warning delta: 60 → 65 = +5 FN-MONITORING invoked by no UC and no screen; SCR-MONITORING-001
  (Task 28–41) invokes them.

## Task 27 notes — PRODUCT.md

- `## MVP Scope` (Must, Should, Nice to have, Out of scope) sits after `## Capabilities and
  Constraints`; every ID and "done when" condition is kept, translated to English. "màn 11" and
  "sheet 12" are written as SCR-TRANSFER-001 and SCR-TRANSFER-002 (no screen numbers).
- Ruling: the MVP tables are the scope as it was set, and two cells are out of date — M1's "cascade
  permanently, not via the Trash" (BR-DECK-022 now moves the tree to the Trash) and "Sign-in —
  revisit when the Spring Boot backend is ready" (ADR-015: Supabase; sign-in shipped). The cells are
  kept as the plan says, and a "Later decisions" note under the tables names the decisions that win
  — cost if wrong: the owner may prefer the cells rewritten; a one-paragraph change.
- PRODUCT.md no longer points at `docs/README.md`; the Problem paragraph was already in Product
  Purpose. The 39 rows of README.md's "Sản phẩm" section are `moved → ../PRODUCT.md`; the section
  itself stays until Task 44 (R18).
- Warning delta: 65 → 65.

## Task 28 notes — SCR-SRS-001

- Record 02 → `screens/spec/SCR-SRS-001-review-algorithm.md`; its states add `loading`,
  `load_error` and `not_found` from the record's "Beyond the states above" and the code.
- The 12 rows `pending → SCR-SRS-001` from UC-DECK-002 and UC-SRS-001 are moved into the spec
  (Layout, Controls, Rulings "moved from the UC").
- The README "Màn hình → Use case" rows of srs and deck are superseded by the specs' Related Use
  Cases (helper `fill_readme_ledger.py`); later tasks do the same for their feature.
- Warning delta: 65 → 64 = −1 SCR-DECK-001 navigating to a pending SCR-SRS-001.

## Task 29 notes — SCR-STARTER-001

- Record 03 → `screens/spec/SCR-STARTER-001-starter-decks.md`; 20 goldens superseded by its states.
- 10 rows `pending → SCR-STARTER-001` moved into the spec; starter-decks README rows superseded.
- The second-copy dialog and the `already_present` snackbar follow `starter_add_controller.dart`.
- Warning delta: 64 → 63 = −1 SCR-DECK-001 navigating to a pending SCR-STARTER-001.

## Task 30 notes — SCR-SEARCH-001

- Record 04 → `screens/spec/SCR-SEARCH-001-library-search.md`; 12 goldens superseded by its states.
- 20 rows `pending → SCR-SEARCH-001` moved into the spec; search README rows superseded. The `q` parameter (FE-B2 D11) is in Purpose.
- Warning delta: 63 → 63 = −1 SCR-DECK-001 → pending SCR-SEARCH-001, +1 SCR-SEARCH-001 → pending SCR-CARD-004 (Task 33).

## Task 31 notes — SCR-TAG-001

- Record 05 → `screens/spec/SCR-TAG-001-tags.md`; 26 goldens superseded by its states.
- 24 rows `pending → SCR-TAG-001` moved into the spec; tags README rows superseded by SCR-TAG-001 and SCR-CARD-001 (the filter).
- The legacy trigger "Manage tags" in the card list overflow does not exist in V8; recorded as a ruling (presentation, not a BR).
- Warning delta: 63 → 62 = −1 SCR-DECK-001 → pending SCR-TAG-001.

## Task 32 notes — SCR-TRASH-001

- Record 06 → `screens/spec/SCR-TRASH-001-trash.md`; 18 goldens superseded by its states (`trash_purge_blocked` → `younger_inside`).
- 21 rows `pending → SCR-TRASH-001` moved; trash README rows superseded. The rows pending to SCR-DECK-001 and SCR-CARD-001 (the Undo snackbar) stay for those screens: SCR-DECK-001 already draws it, SCR-CARD-001 in Task 33.
- Warning delta: 62 → 61 = −1 SCR-DECK-001 → pending SCR-TRASH-001.

## Task 33 notes — SCR-CARD-001…004

- Records 07–10 → `SCR-CARD-001-card-list.md`, `SCR-CARD-002-card-create.md`, `SCR-CARD-003-card-edit.md`, `SCR-CARD-004-card-detail.md`; their goldens superseded by the specs' states (`card_editor_errors`, shared by create and edit, → SCR-CARD-003 `validation_err`).
- 65 rows `pending → SCR-CARD-00x` moved; the 5 rows `pending → SCR-DECK-001` left by Task 32 (the Undo snackbar) are superseded by SCR-DECK-001 + SCR-CARD-001; card README rows superseded.
- Followed the code where the record was silent: an edit save and Back from a gone state return to the screen the editor was opened from (`maybePop`); a rejection the fields' checks let through is a snackbar.
- The legacy UC-CARD-001 A6 bar (Add tag, Flag, Remove flag, Delete) differs from V8's Move · Flag · Tag · Export · Trash; ruled in SCR-CARD-001 (presentation, no BR).
- Warning delta: 61 → 61 = −3 navigations to pending card specs, +3 SCR-CARD-001 navigations to pending study/transfer specs.

## Task 34 notes — SCR-TRANSFER-001, SCR-TRANSFER-002

- Records 11–12 → `SCR-TRANSFER-001-card-import.md`, `SCR-TRANSFER-002-card-export.md`; 16 goldens superseded.
- 35 pending rows moved; transfer README rows superseded.
- The export sheet has no route of its own: `route: []` and "—" in the catalog; it opens over SCR-CARD-001.
- The legacy UC's separate import confirm step is V8's "Import {n} cards" under the deck header (ruled in the spec).
- Warning delta: 61 → 58 = −3 navigations to pending transfer specs.

## Task 35 notes — SCR-STUDY-001, SCR-STUDY-002, SCR-STUDY-009

- Records 13, 14, 21 → `SCR-STUDY-001-study-home.md`, `SCR-STUDY-002-study-entry.md`, `SCR-STUDY-009-session-summary.md`; their goldens superseded (study home's re-auth golden lives in the account tests).
- 45 pending rows moved; study README rows superseded.
- Ruling: UC-STUDY-002 step 3 no longer says the deck rows show the review algorithm — V8 draws no scheduler label and no BR asks for one; owner precedent 2026-10-04 (tri-state icon): the UC keeps intent, the spec follows the app — cost if wrong: one clause back in the UC and an IMPLEMENTATION GAP.
- IMPLEMENTATION GAP recorded in SCR-STUDY-002: UC-STUDY-001 step 2/E1 and FN-STUDY-001 give the next due time when nothing is due; the entry's nothing-due state does not show it (Study home's zero card does). Presentation only; FN and UC unchanged, no code change.
- Warning delta: 58 → 67 = +14 navigations to specs still pending (study mode screens Task 36, settings Task 37, account Task 40), −3 navigations to SCR-STUDY-001/002, −2 FN-ACCOUNT-002/015 now invoked by SCR-STUDY-001.

## Task 36 notes — SCR-STUDY-003…008

- Records 16, 16a, 17–20 → `SCR-STUDY-003…008-*.md`; their goldens superseded.
- Ruling: record 16a is a shape brief, but FE-A6 P2 built it with goldens (`study_self_assess_{prompt,revealed,meaning_first,relearning}`), so SCR-STUDY-004 names those goldens instead of the plan's `Golden: none — shape brief`; its unbuilt states (saving, save_failed, stale) are `Golden: none` — cost if wrong: four golden lines.
- What every session screen shares (top bar, exit dialog, rounds, result after commit, unsaved-answer banner, session errors) is written once in SCR-STUDY-003 "Session screens"; the other five cite SCR-STUDY-003. The 12 pending rows saying "in every mode screen" moved to SCR-STUDY-003, the other 4 to SCR-STUDY-004.
- Followed the code where the legacy UC differed (presentation only): an unrecoverable save error shows SCR-STUDY-009 "Stopped by a save error" rather than the deck list; eight boxes never runs self-assess, so its two-button grade row does not exist.
- Record 19's open item (the 20-second turn for TalkBack users is a business-rule decision) is kept as a Pending ruling in SCR-STUDY-007.
- Warning delta: 67 → 55 = −11 navigations to pending study screens, −1 FN-STUDY-013 now invoked by SCR-STUDY-004.

## Task 37 notes — SCR-SETTINGS-001…004

- Records 15, 23, 25, 26 → `SCR-SETTINGS-001…004-*.md`; their goldens superseded (the sync_* goldens under test/features/settings belong to record 27, Task 40).
- 28 pending rows moved; settings README rows superseded.
- The legacy UC named three Settings groups; V8 draws Account, Study defaults, App, Sync, Admin and Reset — ruled in SCR-SETTINGS-002 (presentation).
- Warning delta: 55 → 59 = +6 SCR-SETTINGS-002 navigations to specs still pending (account and monitoring Tasks 40–41, reminder Task 39), −2 navigations to SCR-SETTINGS-001.

## Task 38 notes — SCR-PROGRESS-001

- Record 22 → `SCR-PROGRESS-001-progress.md`; 24 goldens superseded.
- 41 pending rows moved; progress README rows superseded.
- Warning delta: 59 → 59 (no navigation pointed at SCR-PROGRESS-001; its own targets, SCR-STUDY-001 and itself, are written).
