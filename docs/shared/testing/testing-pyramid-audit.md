# Audit tháp kiểm thử cho toàn bộ kịch bản IT

Ma trận ở mục C đang áp dụng: danh mục mang đúng profile của nó,
Nhóm "Ranh giới nền tảng" giữ sáu kịch bản `IT-PLAT`, và mỗi kịch bản bị
tách ghi "Tách thành" ngay dưới tiêu đề của nó.

## B. Phân bố theo hồ sơ thực thi

| Profile | Số kịch bản | Tỉ lệ |
|---|---|---|
| `HOST-FLOW` | **88** | 54% |
| `HOST-WIDGET` | **67** | 41% |
| `DEVICE-E2E` | **8** | 5% |
| | **163** | |

`DEVICE-E2E` chiếm **5%**, dưới ngưỡng khuyến nghị 20–25% cho lớp cần
emulator/thiết bị.

**Khởi động lại không phải một luật nghiệp vụ; nó là một ranh giới nền
tảng.** Chứng minh một lần rằng dữ liệu đã ghi sống sót qua một lần chết
tiến trình thật là đủ — lặp lại với nội dung khác chỉ chứng minh lại cùng
ranh giới đó, và nội dung thì `HOST-FLOW` đã chứng minh rẻ hơn.

| ID | Profile | Nội dung | Nguồn |
|---|---|---|---|
| IT-PLAT-001 | `DEVICE-E2E` | Cold start of the installed app reaches the deck list | derived from IT-NAV-001 |
| IT-PLAT-002 | `DEVICE-E2E` | State written before a real process death is still there after relaunch | derived from IT-NAV-006, IT-DECK-001, IT-CARD-002, IT-CARD-008, IT-CARD-010, IT-ORG-004, IT-STUDY-008 |
| IT-PLAT-003 | `DEVICE-E2E` | A session interrupted by process death resumes at its cursor | derived from IT-CONT-001, IT-LEARN-003, IT-LEARN-004, IT-LEARN-012, IT-MODE-007, IT-MODE-009 |
| IT-PLAT-004 | `DEVICE-E2E` | A deep link entering from the OS lands on the right screen | derived from IT-NAV-005 |
| IT-PLAT-005 | `DEVICE-E2E` | The Android system back gesture inside a session exits like the X | derived from IT-NAV-010 |
| IT-PLAT-006 | `DEVICE-E2E` | Release smoke: install, open, create a deck and a card, study one card | new — the critical journey the release gate needs |

Hai kịch bản offline (`IT-NAV-007`, `IT-CONT-008`) giữ `DEVICE-E2E` nhưng ở
phạm vi hẹp: nền tảng không có dependency mạng nào, nên app không phát
request nào cả. Hai kịch bản này không kiểm "app chạy được khi offline" mà
là "chưa ai lén thêm một lời gọi mạng nào" — một smoke trước phát hành.

## C. Phân loại theo hồ sơ thực thi

Mỗi kịch bản trong danh mục ứng với đúng một hàng dưới đây: hồ sơ thực thi
và lý do chọn hồ sơ đó. `/` trong cột ID nghĩa là kịch bản đã được tách
thành hai ID độc lập (xem tiêu đề kịch bản gốc), vẫn cùng một dòng lý do.

| ID | Profile | Lý do |
|---|---|---|
| IT-CARD-001 | `HOST-WIDGET` | Empty state offers the first card. |
| IT-CARD-002 / IT-CARD-002F | `HOST-WIDGET + HOST-FLOW` | Form vs persisted row. |
| IT-CARD-003 | `HOST-WIDGET` | Front/back validation presentation. |
| IT-CARD-004 | `HOST-WIDGET` | Length limits. |
| IT-CARD-005 | `HOST-WIDGET` | Optional fields on the form. |
| IT-CARD-006 | `HOST-WIDGET` | Per-field 240 limit. |
| IT-CARD-007 | `HOST-WIDGET` | Save-and-add-another keeps the sheet open. |
| IT-CARD-008 / IT-CARD-008F | `HOST-WIDGET + HOST-FLOW` | Editing keeps list position (UI) and the edited row persists (SQL). |
| IT-CARD-009 | `HOST-FLOW` | Editing content MUST NOT touch card_schedule — the single most important cross-table invariant here, and only the DB can show it. |
| IT-CARD-010 / IT-CARD-010F | `HOST-WIDGET + HOST-FLOW` | Confirm dialog vs the delete actually landing. |
| IT-CARD-011 | `HOST-FLOW` | Deleting the last card puts the deck back to `unset` in one transaction (BR-DECK-015). |
| IT-CONT-001 / IT-PLAT-003 | `HOST-FLOW + DEVICE-E2E` | Resuming at the stored cursor (BR-STUDY-010/102/103) is a DB read; being killed by the OS is the platform boundary. |
| IT-CONT-002 | `HOST-FLOW` | Starting a new session abandons the same-day one (BR-STUDY-014/103) — a status transition. |
| IT-CONT-003 | `HOST-FLOW` | A session from a previous study day is closed as interrupted (BR-STUDY-011/86/103) — needs an injected clock, not a device. |
| IT-CONT-004 | `HOST-WIDGET` | The X is a deliberate exit — the write it causes is asserted at HOST-FLOW by IT-CONT-002. |
| IT-CONT-005 | `HOST-FLOW` | A finished session has a summary and an empty queue (BR-STUDY-013). |
| IT-CONT-006 | `HOST-FLOW` | The queue is frozen against later content changes (BR-STUDY-021/139). Two surfaces were never needed — two writes against one database are. |
| IT-CONT-007 / IT-CONT-007W | `HOST-FLOW + HOST-WIDGET` | Deleting a deck mid-session ends the session (DB); recovering navigation is the screen. |
| IT-CONT-008 | `DEVICE-E2E` | Whole session offline. Same note as IT-NAV-007: kept as a release smoke because there is nothing to fail. |
| IT-CONT-009 | `HOST-FLOW` | Reset invalidates the open session with scheduler_reset (BR-STUDY-015/152) — one transaction. |
| IT-CONT-010 | `HOST-FLOW` | A stale-generation session is refused atomically (BR-SRS-026/84) — the reset-un-resets-itself guard. |
| IT-CONT-011 | `HOST-FLOW` | A transient write failure does not advance and a retry writes once (BR-STUDY-004) — inject the failure at the store, not at the UI. |
| IT-CONT-012 | `HOST-FLOW` | An unrecoverable failure closes the session as failed and keeps prior turns (BR-STUDY-018/86). |
| IT-CONT-013 / IT-CONT-013W | `HOST-FLOW + HOST-WIDGET` | The read failure and the retry are store; the Retry affordance keeping the cursor is the screen. |
| IT-CONT-014 | `HOST-FLOW` | Choosing review with a same-day session open abandons it (BR-STUDY-014/103). |
| IT-DECK-001 / IT-DECK-001F | `HOST-WIDGET + HOST-FLOW` | Creating through the form is UI; that the row persists with scheduler=eight_box is SQL. |
| IT-DECK-002 | `HOST-WIDGET` | Duplicate names allowed (BR-DECK-021) — form submits, list shows two. |
| IT-DECK-003 | `HOST-WIDGET` | Validation presentation. |
| IT-DECK-004 | `HOST-WIDGET` | Length limit and field preservation are presentation. |
| IT-DECK-005 | `HOST-WIDGET` | Cancel with and without changes — dialog behaviour. |
| IT-DECK-006 / IT-DECK-006F | `HOST-WIDGET + HOST-FLOW` | Rename through the sheet is UI; the renamed row surviving a read is SQL. |
| IT-DECK-007 | `HOST-WIDGET` | Cancelling a destructive dialog. |
| IT-DECK-008 / IT-DECK-008F | `HOST-WIDGET + HOST-FLOW` | The confirm dialog is UI; cascading the whole subtree is a SQL/transaction assertion. |
| IT-DISC-001 / IT-DISC-001F | `HOST-WIDGET + HOST-FLOW` | Tile composition is UI; the due/total pair is the two-query agreement that must stay consistent. |
| IT-DISC-002 | `HOST-WIDGET` | Zero due is an ordinary empty state. |
| IT-DISC-003 / IT-DISC-003F | `HOST-WIDGET + HOST-FLOW` | The filter chip is UI; which decks match is SQL. |
| IT-DISC-004 | `HOST-WIDGET` | Empty-filter recovery is presentation. |
| IT-DISC-005 / IT-DISC-005F | `HOST-WIDGET + HOST-FLOW` | Sort control vs ORDER BY. |
| IT-DISC-006 / IT-DISC-006F | `HOST-WIDGET + HOST-FLOW` | Search field vs subtree-scoped query (BR-DECK-002/57). |
| IT-DISC-007 | `HOST-WIDGET` | No-match state names its scope and offers a clear. |
| IT-DISC-008 | `HOST-WIDGET` | watch() stream refreshes the list — a Riverpod/stream assertion the host can make. |
| IT-LEARN-001 / IT-LEARN-001W | `HOST-FLOW + HOST-WIDGET` | The five-stage sequence is queue construction (BR-MODE-007/108/109/110); the screens showing each stage is one widget walk. |
| IT-LEARN-002 | `HOST-FLOW` | SM-2 sequence is Browse then Self assess — queue construction. |
| IT-LEARN-003 | `HOST-WIDGET` | Browse shows both faces and grades nothing (BR-MODE-005/112) — a screen fact plus an absent write. |
| IT-LEARN-004 | `HOST-FLOW` | Same card set, independent orders (BR-STUDY-022/117/127) — seeded permutations over the queue. |
| IT-LEARN-005 | `HOST-FLOW` | Fill skips a card without an example and learning still completes (BR-STUDY-071/140/144). |
| IT-LEARN-006 | `HOST-FLOW` | Guess skipped below five distinct meanings (BR-MODE-009/121/124/140). |
| IT-LEARN-007 | `HOST-FLOW` | Match skipped at one pair (BR-MODE-009/153). |
| IT-LEARN-008 | `HOST-FLOW` | The fail set only clears after a clean round (BR-STUDY-059/116/119) — round algorithm. |
| IT-LEARN-009 | `HOST-FLOW` | Self-assess spacing and the relearning-ceiling flag (BR-STUDY-005/28/92/104). |
| IT-LEARN-010 | `HOST-FLOW` | Only a completed sequence writes the first schedule and locks the algorithm (BR-SRS-003/27/105/144/145/149). Fixed clock, asserted due_at. |
| IT-LEARN-011 | `HOST-FLOW` | The card limit is a per-session ceiling, not a daily quota (BR-STUDY-003/139). |
| IT-LEARN-012 | `HOST-FLOW` | Abandoning learning writes no half schedule and restarts at Browse (BR-STUDY-014/86/144). |
| IT-MODE-001 | `HOST-WIDGET` | The session frame names mode, set, kind and progress — chrome, already widget-tested. |
| IT-MODE-002 | `HOST-WIDGET` | Browse shows both faces and only moves on. |
| IT-MODE-003 | `HOST-WIDGET` | Board keeps its tiles and tells three states apart. |
| IT-MODE-004 / IT-MODE-004F | `HOST-WIDGET + HOST-FLOW` | Tapping term-then-meaning is UI; that the turn is attributed to the term and the card stays in the fail set (BR-MODE-012/116/118/120) is what the DB records. |
| IT-MODE-005 / IT-MODE-005F | `HOST-WIDGET + HOST-FLOW` | One tap counted (BR-STUDY-042) is UI; exactly five distinct meanings (BR-STUDY-037/125) is question construction. |
| IT-MODE-006 | `HOST-FLOW` | Guess skipped for the whole session set (BR-MODE-009/121/124). |
| IT-MODE-007 | `HOST-FLOW` | Stable-on-resume, independent permutations (BR-STUDY-061/127) — seeded Random over persisted order. |
| IT-MODE-008 / IT-MODE-008F | `HOST-WIDGET + HOST-FLOW` | The countdown UI is a widget with an injected clock; which outcome is recorded at the mark (BR-STUDY-031/129) is domain. |
| IT-MODE-009 / IT-MODE-009F | `HOST-WIDGET + HOST-FLOW` | Auto-reveal is UI; the locked-wrong outcome and remaining_ms persistence (BR-STUDY-033/131/133) are DB facts. |
| IT-MODE-010 | `HOST-FLOW` | Fill folding rules (BR-STUDY-026/137/138) — a pure comparison plus what is written. |
| IT-MODE-011 | `HOST-FLOW` | Hint recorded without changing the action, one submission only (BR-STUDY-027/136/137/138). |
| IT-MODE-012 | `HOST-WIDGET` | Self assess shows actions only after a flip. |
| IT-MODE-013 | `HOST-WIDGET` | Screen reader and large text — meetsGuideline and textScaler are host matchers. No device needed. |
| IT-MODE-014 | `HOST-FLOW` | Atomic block when a question cannot be built (BR-STUDY-037/124) — a store refusal, not a fault-injection UI. |
| IT-MODE-015 | `HOST-FLOW` | Distractors come from the same tree and never leak an unseen new card (BR-STUDY-037/122/123). |
| IT-NAV-001 | `HOST-WIDGET` | Router lands on the deck list. Real cold start is proved once by IT-PLAT-001. |
| IT-NAV-002 | `HOST-WIDGET` | Shell keeps branch state; pure GoRouter + widget. |
| IT-NAV-003 | `HOST-WIDGET` | Back pops one level; router only. |
| IT-NAV-004 | `HOST-WIDGET` | Breadcrumb navigates to an ancestor; router + widget. |
| IT-NAV-005 / IT-PLAT-004 | `HOST-WIDGET + DEVICE-E2E` | The 404 route and its recovery are router behaviour; an OS-originated deep link is the only part needing a device. |
| IT-NAV-006 / IT-PLAT-002 | `HOST-FLOW + DEVICE-E2E` | Deck/Card CRUD persistence is SQLite; surviving a real process death is the platform boundary. |
| IT-NAV-007 | `DEVICE-E2E` | Airplane mode is an OS control. Kept minimal: the app makes no network request at all, so this is a release smoke that nothing was added. |
| IT-NAV-008 | `HOST-WIDGET` | Back from the study entry creates no session — the assertion is a route pop plus an absent write, both host-provable. |
| IT-NAV-009 | `HOST-WIDGET` | Fixture is DB state (a reviewing EB deck); no device needed once the builder exists. |
| IT-NAV-010 / IT-PLAT-005 | `HOST-WIDGET + DEVICE-E2E` | The exit contract (BR-STUDY-014 writes abandoned/user_exit) is host-provable via PopScope; the physical Android back gesture is not. |
| IT-ORG-001 / IT-ORG-001F | `HOST-WIDGET + HOST-FLOW` | Search field vs the front/back LIKE query. |
| IT-ORG-002 | `HOST-WIDGET` | Empty search recovery. |
| IT-ORG-003 | `HOST-FLOW` | Sort by created/due is ORDER BY over learned_at and due_at (BR-STUDY-047). |
| IT-ORG-004 / IT-ORG-004F | `HOST-WIDGET + HOST-FLOW` | Toggling the flag is UI; it persisting is SQL (BR-CARD-009). |
| IT-ORG-005 | `HOST-FLOW` | All/Due/New/Flagged counts are four predicates that must agree with the lists they head. |
| IT-ORG-006 | `HOST-WIDGET` | An empty filter is not an empty deck — presentation. |
| IT-ORG-007 / IT-ORG-007F | `HOST-WIDGET + HOST-FLOW` | Tag entry is UI; case-insensitive reuse is a query/uniqueness rule (BR-TAG-001). |
| IT-ORG-008 | `HOST-FLOW` | Removing a tag must not touch the card row. |
| IT-ORG-009 | `HOST-WIDGET` | Tag name validation and the 10-tag cap are presentation of BR-TAG-001/94. |
| IT-ORG-010 / IT-ORG-010F | `HOST-WIDGET + HOST-FLOW` | Panel rendering vs the distribution query (BR-CARD-006/90/91). |
| IT-ORG-011 | `HOST-WIDGET` | Breadcrumb refresh after a rename — stream + widget. |
| IT-ORG-012 | `HOST-WIDGET` | Windowed loading of a large list is a scroll/viewport behaviour; the fixture is DB state, so no device. |
| IT-REVIEW-001 | `HOST-FLOW` | The review queue takes learned and due cards only (BR-STUDY-051) — the due predicate at a fixed clock. |
| IT-REVIEW-002 / IT-REVIEW-002W | `HOST-FLOW + HOST-WIDGET` | One chosen mode runs the whole session (BR-MODE-003/146) is queue construction; the screen showing that mode is a widget walk. |
| IT-REVIEW-003 | `HOST-WIDGET` | SM-2 takes the action straight from the user (BR-STUDY-009/106/146) — four buttons and the action they emit. |
| IT-REVIEW-004 | `HOST-FLOW` | Earlier due served first and the limit counted per distinct card (BR-STUDY-002/24/102/139) — ORDER BY plus a cap. |
| IT-REVIEW-005 | `HOST-FLOW` | First turn scheduled, repeats relearning, no second schedule (BR-SRS-018/21/75-78/141/143). The densest scheduler assertion in the catalog. |
| IT-REVIEW-006 | `HOST-FLOW` | Eight Box box/interval transitions (BR-SRS-008/16/105) with an asserted due_at. |
| IT-REVIEW-007 | `HOST-FLOW` | SM-2 update order for the four actions (BR-SRS-010/18/19/105). |
| IT-REVIEW-008 | `HOST-FLOW` | No re-review before the schedule just written (BR-STUDY-074/145). |
| IT-REVIEW-009 | `HOST-FLOW` | Summary separates handled cards from due-but-over-limit (BR-STUDY-003) — a counting rule. |
| IT-REVIEW-010 | `HOST-FLOW` | Per-mode counts and queues must not share one fake number. |
| IT-STUDY-001 / IT-STUDY-001F | `HOST-WIDGET + HOST-FLOW` | Two disjoint sets (BR-STUDY-051) is a query rule; the entry screen only prints the two numbers. |
| IT-STUDY-002 | `HOST-FLOW` | Looking at counts creates no session row — an absence in the DB, not a screen state. |
| IT-STUDY-003 | `HOST-FLOW` | No due card and no study-ahead (BR-STUDY-008/145) is a due predicate at a fixed clock. |
| IT-STUDY-004 / IT-STUDY-004F | `HOST-WIDGET + HOST-FLOW` | Which modes are offered is BR-MODE-009/146/154 in the domain; the chooser reflects it. |
| IT-STUDY-005 | `HOST-FLOW` | SM-2 has one review mode (BR-STUDY-009/146) — a scheduler fact. |
| IT-STUDY-006 / IT-STUDY-006F | `HOST-WIDGET + HOST-FLOW` | Disabled-with-a-reason is presentation; the eligibility itself is BR-MODE-009/100/121/153. |
| IT-STUDY-007 | `HOST-FLOW` | Per-mode counts must come from each mode capacity (BR-STUDY-071/154), not one shared number. |
| IT-STUDY-008 / IT-PLAT-002 | `HOST-FLOW + DEVICE-E2E` | App-wide options persisting is a store read; surviving a real restart is the platform boundary and is proved once. |
| IT-STUDY-009 | `HOST-FLOW` | Root override beats default (BR-DECK-025/139/147) — pure resolution over DB rows. The UI-MULTI profile was never needed. |
| IT-STUDY-010 | `HOST-FLOW` | The card limit is frozen at open (BR-STUDY-003/139) — a session-row assertion. |
| IT-STUDY-011 | `HOST-FLOW` | Session scope is the deck subtree (BR-STUDY-002/142) — a recursive query. |
| IT-STUDY-012 | `HOST-FLOW` | Created/Random selection and stability on resume (BR-STUDY-021/139/148) needs a seeded Random and the DB. |
| IT-STUDY-013 | `HOST-FLOW` | Unreadable root config falls back to defaults (BR-STUDY-003/147/148) — a store failure path, not a fault-injection UI. |
| IT-TREE-001 / IT-TREE-001F | `HOST-WIDGET + HOST-FLOW` | BR-DECK-004/59 is a store rule inside runInTransaction; the chooser only reflects it. |
| IT-TREE-002 | `HOST-WIDGET` | An unset deck offers both actions — presentation of BR-DECK-006/61. |
| IT-TREE-003 / IT-TREE-003F | `HOST-WIDGET + HOST-FLOW` | First-child locking is a transaction rule (BR-DECK-008/63); the UI only stops offering the other kind. |
| IT-TREE-004 / IT-TREE-004F | `HOST-WIDGET + HOST-FLOW` | Same rule, the other branch. |
| IT-TREE-005 | `HOST-FLOW` | A refused write must leave content_type unset — provable only against the DB. |
| IT-TREE-006 | `HOST-FLOW` | Emptying a sub-deck resets its type in the same transaction; pure persistence (BR-DECK-015). |
| IT-TREE-007 | `HOST-FLOW` | Manual reset is gone (BR-DECK-015); the ID now covers the move transition, which is pure persistence. |
| IT-TREE-008 | `HOST-FLOW` | Refusal to reset a non-empty deck is a store guard. |
| IT-TREE-009 / IT-TREE-009F | `HOST-WIDGET + HOST-FLOW` | Move UI vs the subtree rewrite (root_id, depth) in one transaction. |
| IT-TREE-010 | `HOST-FLOW` | Cycle refusal (BR-DECK-016/70) is checked inside the write. |
| IT-TREE-011 | `HOST-FLOW` | BR-DECK-010 refusal at the store. |
| IT-TREE-012 | `HOST-FLOW` | Cross-scheduler move refusal (BR-SRS-005/74) — never silently converted. |
| IT-TREE-013 | `HOST-FLOW` | Depth-10 refusal (BR-DECK-001) is checked before anything is written. |
| IT-TREE-014 | `HOST-FLOW` | Reset after the last card — persistence. |

## E. Điều tài liệu này *không* làm

- Không đổi một luật nghiệp vụ nào. Mọi BR/UC ở cột truy vết giữ nguyên.
- Không làm yếu assertion nào. Kịch bản bị tách thì assertion đi theo tầng nào
  chứng minh được nó, không bị bỏ.
