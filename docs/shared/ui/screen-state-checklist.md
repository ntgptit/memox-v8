# Checklist màn hình và state — MemoX V8

- **Trạng thái:** hiện hành, sửa cùng commit với việc làm một state đổi trạng thái.
- **Mục đích:** liệt kê mọi màn và mọi state của kit, và cho biết state nào đã phát
  triển, state nào chưa.
- **Nguồn:** artifact "MemoX — Mobile UI Kit v3",
  <https://claude.ai/artifact/UCesgHkzYHKsZwhwVshKRE>, phiên bản `1790244159-01e6`.
  Danh sách state lấy từ bộ chuyển state của từng màn trong kit, đúng tên và thứ tự.
- **Quan hệ với tài liệu khác:**
  - [Screen handoff index](screen-handoff/00-index.md) giữ trạng thái ở mức màn;
    file này đi xuống mức state.
  - Detail file của từng màn giữ thiết kế và các lệch với kit.
  - [`wbs_FE.md`](../../wbs_FE.md) giữ tiến độ theo hạng mục.
- **Ngữ cảnh bằng chứng:** `master` tại `e2ad9de`, ngày 2026-09-26. Mỗi trạng thái dựa
  trên bảng States và ghi chú "Built" của detail file, UI-base §9 và
  `tools/design/screen_states.json`.

## Quy ước

| Dấu | Trạng thái | Nghĩa |
|---|---|---|
| `[x]` | xong | Đã dựng theo detail file, kể cả các lệch đã ghi ở đó. |
| `[~]` | một phần | Đã dựng, còn một phần chờ hạng mục khác; ghi chú nói phần nào. |
| `[~]` | đã dựng, chưa đối chiếu | Dựng từ kit trước khi màn có detail file; chưa đối chiếu từng state. |
| `[ ]` | chưa làm | Chưa có trong app. |
| `[-]` | không làm | V8 thay bằng hành vi khác; ghi chú nói lý do. |

"Id ảnh" là id trong `tools/design/screen_states.json`, tức tên ảnh
`screen-handoff/img/<màn>/<id>-{light,dark}.png`. "—" là state chưa được capture.

Màn 14, 16, 16a và 17–21 là `aligned` trong index từ phase P5 của roadmap luồng học.

## Tổng hợp

Kit có **26 màn, 211 state**. Xong **209**; một phần **0**; đã dựng nhưng chưa đối chiếu **0**; chưa làm **0**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.

| # | Màn | Hạng mục FE | State | Xong | Một phần / chưa đối chiếu | Chưa làm | Không làm | Detail |
|---|---|---|---|---|---|---|---|---|
| 01 | Deck list · recursive | FE-A1 | 22 | 22 | 0 | 0 | 0 | [01-deck-list.md](screen-handoff/01-deck-list.md) |
| 02 | Review algorithm & reset | FE-A4 | 9 | 9 | 0 | 0 | 0 | [02-review-algorithm.md](screen-handoff/02-review-algorithm.md) |
| 03 | Starter decks | FE-B4 | 10 | 10 | 0 | 0 | 0 | [03-starter-decks.md](screen-handoff/03-starter-decks.md) |
| 04 | Library search | FE-A1, FE-A10 | 5 | 5 | 0 | 0 | 0 | [04-library-search.md](screen-handoff/04-library-search.md) |
| 05 | Tags | FE-B2 | 12 | 12 | 0 | 0 | 0 | [05-tags.md](screen-handoff/05-tags.md) |
| 06 | Trash | FE-B1 | 15 | 15 | 0 | 0 | 0 | [06-trash.md](screen-handoff/06-trash.md) |
| 07 | Card list | FE-A2 | 15 | 14 | 0 | 0 | 1 | [07-card-list.md](screen-handoff/07-card-list.md) |
| 08 | Card create | FE-A2 | 9 | 9 | 0 | 0 | 0 | [08-card-create.md](screen-handoff/08-card-create.md) |
| 09 | Card edit | FE-A2 | 9 | 9 | 0 | 0 | 0 | [09-card-edit.md](screen-handoff/09-card-edit.md) |
| 10 | Card detail | FE-A2 | 7 | 7 | 0 | 0 | 0 | [10-card-detail.md](screen-handoff/10-card-detail.md) |
| 11 | Card import | FE-B3 | 16 | 16 | 0 | 0 | 0 | [11-card-import.md](screen-handoff/11-card-import.md) |
| 12 | Card export | FE-B3 | 9 | 9 | 0 | 0 | 0 | [12-card-export.md](screen-handoff/12-card-export.md) |
| 13 | Study home | FE-A8 | 7 | 7 | 0 | 0 | 0 | [13-study-home.md](screen-handoff/13-study-home.md) |
| 14 | Study entry | FE-A6, FE-A7 | 9 | 9 | 0 | 0 | 0 | [14-study-entry.md](screen-handoff/14-study-entry.md) |
| 15 | Study options | FE-A3 | 7 | 7 | 0 | 0 | 0 | [15-study-options.md](screen-handoff/15-study-options.md) |
| 16 | Study · Browse | FE-A6 | 1 | 1 | 0 | 0 | 0 | [16-study-browse.md](screen-handoff/16-study-browse.md) |
| 17 | Study · Match | FE-A6 | 1 | 1 | 0 | 0 | 0 | [17-study-match.md](screen-handoff/17-study-match.md) |
| 18 | Study · Guess | FE-A6 | 1 | 1 | 0 | 0 | 0 | [18-study-guess.md](screen-handoff/18-study-guess.md) |
| 19 | Study · Recall | FE-A6 | 3 | 3 | 0 | 0 | 0 | [19-study-recall.md](screen-handoff/19-study-recall.md) |
| 20 | Study · Fill | FE-A6 | 3 | 3 | 0 | 0 | 0 | [20-study-fill.md](screen-handoff/20-study-fill.md) |
| 21 | Session summary | FE-A6 | 10 | 9 | 0 | 0 | 1 | [21-session-summary.md](screen-handoff/21-session-summary.md) |
| 22 | Progress | FE-A9 | 8 | 8 | 0 | 0 | 0 | [22-progress.md](screen-handoff/22-progress.md) |
| 23 | Settings | FE-A3 | 8 | 8 | 0 | 0 | 0 | [23-settings.md](screen-handoff/23-settings.md) |
| 24 | Daily reminder | FE-B5 | 9 | 9 | 0 | 0 | 0 | [24-daily-reminder.md](screen-handoff/24-daily-reminder.md) |
| 25 | Theme | FE-A3 | 3 | 3 | 0 | 0 | 0 | [25-theme.md](screen-handoff/25-theme.md) |
| 26 | Language | FE-A3 | 3 | 3 | 0 | 0 | 0 | [26-language.md](screen-handoff/26-language.md) |

## Theo màn

### 01 · Deck list · recursive

FE-A1 · [01-deck-list.md](screen-handoff/01-deck-list.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Root · decks | `rootLoaded` | xong | Thanh mastery trên mỗi hàng (BR-DECK-026). |
| [x] | Root · loading | `rootLoading` | xong |  |
| [x] | Root · first launch | `rootEmpty` | xong | Create deck và "Browse starter decks" (FE-B4). |
| [x] | Root · error | `rootError` | xong |  |
| [x] | Root · search | `rootSearch` | xong |  |
| [x] | Root · sort & filter | `rootSortFilter` | xong | Có sort Progress (BR-DECK-027). |
| [x] | Root · due filter, none | `rootDueEmpty` | xong |  |
| [x] | Root · deck actions | `rootOverflow` | xong |  |
| [x] | Root · create deck | `rootCreate` | xong |  |
| [x] | Root · rename | `rootRename` | xong |  |
| [x] | Root · move to Trash | `rootDelete` | xong |  |
| [x] | Root · trashed · Undo | `rootTrashed` | xong |  |
| [x] | In deck · sub-decks | `deckLoaded` | xong |  |
| [x] | In deck · empty deck | `deckEmpty` | xong |  |
| [x] | In deck · level 10 | `deckMaxDepth` | xong |  |
| [x] | In deck · loading | `deckLoading` | xong |  |
| [x] | In deck · error | `deckError` | xong |  |
| [x] | In deck · not found | `deckNotFound` | xong |  |
| [x] | In deck · sub-deck actions | `deckOverflow` | xong |  |
| [x] | In deck · move sheet | `deckMove` | xong |  |
| [x] | In deck · move to Trash | `deckDelete` | xong |  |
| [x] | In deck · trashed · Undo | `deckTrashed` | xong |  |

### 02 · Review algorithm & reset

FE-A4 · [02-review-algorithm.md](screen-handoff/02-review-algorithm.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Locked | `locked` | xong |  |
| [x] | Unlocked | `unlocked` | xong |  |
| [x] | Switching | `switching` | xong |  |
| [x] | Switched | `switched` | xong |  |
| [x] | Switch failed | `switchFailed` | xong |  |
| [x] | Reset confirm | `resetConfirm` | xong |  |
| [x] | Resetting | `resetting` | xong |  |
| [x] | Reset done | `resetDone` | xong |  |
| [x] | Nothing to lose | `nothingToLose` | xong |  |

### 03 · Starter decks

FE-B4 · [03-starter-decks.md](screen-handoff/03-starter-decks.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Templates | `list` | xong | Badge và dòng gợi ý xuống dòng thay vì bị cắt. |
| [x] | Choose algorithm | `choose` | xong |  |
| [x] | Adding | `adding` | xong | Nút quay, không kèm chữ (D13). |
| [x] | Added | `added` | xong | Open mở deck gốc mới trong Thư viện. |
| [x] | Already present | `alreadyPresent` | xong |  |
| [x] | Second copy | `secondCopy` | xong |  |
| [x] | Add failed | `addFailed` | xong |  |
| [x] | Loading | `loading` | xong | Note rồi skeleton rows (UI-base dòng 125). |
| [x] | None in build | `none` | xong |  |
| [x] | Load failed | `loadFailed` | xong |  |

### 04 · Library search

FE-A1, FE-A10 · [04-library-search.md](screen-handoff/04-library-search.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Empty | `emptyQuery` | xong |  |
| [x] | Searching | `loading` | xong |  |
| [x] | Results | `results` | xong |  |
| [x] | No results | `noResults` | xong |  |
| [x] | Error | `error` | xong |  |

### 05 · Tags

FE-B2 · [05-tags.md](screen-handoff/05-tags.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Loaded | `loaded` | xong | Thứ tự theo tên đã fold (BR-TAG-003). |
| [x] | Loading | `loading` | xong |  |
| [x] | Empty | `empty` | xong |  |
| [x] | Search empty | `searchEmpty` | xong |  |
| [x] | Tag actions | `sheet` | xong |  |
| [x] | Rename | `rename` | xong |  |
| [x] | Rename → merge | `renameMerge` | xong | Số thẻ là hợp (BE-B2 D6); nút tông warning (D15). |
| [x] | Name too long | `nameTooLong` | xong |  |
| [x] | Delete | `del` | xong |  |
| [x] | Busy row | `busy` | xong |  |
| [x] | Op error | `opError` | xong | Toast một câu, có Retry. |
| [x] | Tag gone | `tagGone` | xong |  |

### 06 · Trash

FE-B1 · [06-trash.md](screen-handoff/06-trash.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | All | `all` | xong |  |
| [x] | Cards only | `cards` | xong |  |
| [x] | Decks only | `decks` | xong |  |
| [x] | Entry actions | `actions` | xong |  |
| [x] | Choose target | `restoreTarget` | xong |  |
| [x] | No valid target | `noTarget` | xong |  |
| [x] | Restored | `restored` | xong |  |
| [x] | Undo refused | `undoRefused` | xong |  |
| [x] | Selection | `selection` | xong |  |
| [x] | Delete for good | `purgeConfirm` | xong |  |
| [x] | Deleted | `purged` | xong |  |
| [x] | Younger inside | `youngerInside` | xong |  |
| [x] | Empty | `empty` | xong |  |
| [x] | Loading | `loading` | xong |  |
| [x] | Error | `error` | xong |  |

### 07 · Card list

FE-A2 · [07-card-list.md](screen-handoff/07-card-list.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Loaded | `loaded` | xong | Chip Tags và bộ lọc tag (FE-B2 D3, D14). |
| [x] | Empty | `empty` | xong |  |
| [x] | Search empty | `searchEmpty` | xong |  |
| [x] | Loading | `loading` | xong |  |
| [x] | Error | `error` | xong |  |
| [x] | Deck not found | `notFound` | xong |  |
| [-] | Card actions | — | không làm | Chạm vào card mở card detail (#35) thay cho action sheet. |
| [x] | Deck actions | `deckActions` | xong |  |
| [x] | Selection | `selection` | xong |  |
| [x] | Move targets | `moveTargets` | xong |  |
| [x] | No move target | `noMoveTarget` | xong |  |
| [x] | Bulk failed | `bulkFailed` | xong |  |
| [x] | Card → Trash | `delCard` | xong |  |
| [x] | Trashed · Undo | `trashed` | xong |  |
| [x] | Deck → Trash | `delDeck` | xong |  |

### 08 · Card create

FE-A2 · [08-card-create.md](screen-handoff/08-card-create.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Empty | `emptyForm` | xong | Save tắt tới khi hợp lệ. |
| [x] | Valid | `valid` | xong |  |
| [x] | Details open | `details` | xong | Ba trường tùy chọn là ô nhập thật. |
| [x] | Back empty | `validationErr` | xong | Lỗi hiện sau khi chạm trường (P4a-L2). |
| [x] | Front too long | `frontTooLong` | xong | Lỗi hiện sau khi chạm trường. |
| [x] | 10 tags | `tagLimit` | xong | Rút Add tag, hiện cảnh báo (BR-TAG-002). |
| [x] | Deck rejects | `deckRejects` | xong | Câu chữ khác kit: không có đường chọn deck khác (§9 dòng 81). |
| [x] | Saving | `saving` | xong | Spinner thay nhãn nút (§9 dòng 46). |
| [x] | Save failed | `saveFailed` | xong |  |

### 09 · Card edit

FE-A2 · [09-card-edit.md](screen-handoff/09-card-edit.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Loaded | `loaded` | xong |  |
| [x] | Loading | `loading` | xong | `MxSkeletonList` chung thay skeleton theo hình trường (§9 dòng 125). |
| [x] | Load error | `loadError` | xong | Thân lỗi dùng câu chung của app. |
| [x] | Card gone | `notFound` | xong | Căn theo kit ở FE-B1 (câu chữ Trash, Open Trash). |
| [x] | Validation | `validationErr` | xong | Lỗi hiện sau khi chạm trường (P4a-L2). |
| [x] | Saving | `dirtySaving` | xong | Spinner thay nhãn nút (§9 dòng 46). |
| [x] | Save failed | `saveFailed` | xong |  |
| [x] | Discard | `discard` | xong | Thân hộp thoại nêu trường đã sửa. |
| [x] | Move to Trash | `delConfirm` | xong | Card "More" và hộp thoại của FE-B1 (D13). |

### 10 · Card detail

FE-A2 · [10-card-detail.md](screen-handoff/10-card-detail.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Loaded | `loaded` | xong | Badge và cờ nằm trên nội dung (§9 dòng 89); lịch sử không có rail (§9 dòng 86). |
| [x] | More history | `loadMore` | xong | Nút `MxButton` secondary "Load older history". |
| [x] | Load more failed | `loadMoreFailed` | xong | Retry nằm dưới câu báo (§9 dòng 50). |
| [x] | No history | `empty` | xong |  |
| [x] | Loading | `loading` | xong | `MxSkeletonList` chung (§9 dòng 125). |
| [x] | Error | `error` | xong | Thân lỗi dùng câu chung của app. |
| [x] | Not found | `notFound` | xong | Căn theo kit ở FE-B1 (Open Trash, D11). |

### 11 · Card import

FE-B3 · [11-card-import.md](screen-handoff/11-card-import.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Source | `empty` | xong |  |
| [x] | Pasted text | `pasted` | xong |  |
| [x] | File chosen | `fileSelected` | xong |  |
| [x] | Not UTF-8 | `badEncoding` | xong |  |
| [x] | Empty sheet | `emptySheet` | xong |  |
| [x] | Reading | `parsing` | xong |  |
| [x] | Map columns | `mapping` | xong |  |
| [x] | Back not mapped | `mappingIncomplete` | xong |  |
| [x] | Preview · all ready | `previewAll` | xong |  |
| [x] | Preview · mixed | `previewMix` | xong |  |
| [x] | Importing | `importing` | xong |  |
| [x] | Imported | `success` | xong |  |
| [x] | With skips | `partial` | xong |  |
| [x] | Nothing added | `none` | xong |  |
| [x] | Failed | `failed` | xong |  |
| [x] | Deck rejects | `rejects` | xong |  |

### 12 · Card export

FE-B3 · [12-card-export.md](screen-handoff/12-card-export.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Whole deck | `wholeDeck` | xong |  |
| [x] | Selection | `selection` | xong |  |
| [x] | Preparing | `preparing` | xong |  |
| [x] | Handed over | `handedOver` | xong |  |
| [x] | Share closed | `shareClosed` | xong |  |
| [x] | Failed | `failed` | xong |  |
| [x] | No share target | `noShareTarget` | xong |  |
| [x] | Stale selection | `staleSelection` | xong |  |
| [x] | Nothing to export | `nothingToExport` | xong |  |

### 13 · Study home

FE-A8 · [13-study-home.md](screen-handoff/13-study-home.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Resume + workload | `loaded` | xong | P6. |
| [x] | Workload | `noResume` | xong | P6. |
| [x] | Zero workload | `zero` | xong | P6. |
| [x] | No decks | `noDecks` | xong | P6; "Browse starter decks" theo kit và UC-STUDY-002 A4 từ audit 2026-09-28. |
| [x] | No cards | `noCards` | xong | P6. |
| [x] | Loading | `loading` | xong | P6. |
| [x] | Error | `error` | xong | P6. |

### 14 · Study entry

FE-A6, FE-A7 · [14-study-entry.md](screen-handoff/14-study-entry.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | SM-2 · direction | `sm2` | xong |  |
| [x] | Eight boxes · modes | `eightBox` | xong | Match, Guess (P3), Recall và Fill (P4) chọn được; Learn của `eight_box` mở từ P4. |
| [x] | Only new | `onlyNew` | xong |  |
| [x] | Nothing to do | `nothing` | xong |  |
| [x] | Session today | `resume` | xong |  |
| [x] | Starting | `starting` | xong |  |
| [x] | No longer due | `refused` | xong |  |
| [x] | Start failed | `startFailed` | xong |  |
| [x] | Loading | `loading` | xong |  |

### 15 · Study options

FE-A3 · [15-study-options.md](screen-handoff/15-study-options.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Deck override | `override` | xong | Save chỉ bật khi có thay đổi hợp lệ (D9). |
| [x] | App defaults | `defaults` | xong |  |
| [x] | Invalid limit | `invalid` | xong | Thông báo nằm dưới stepper (UC E1). |
| [x] | Saving | `saving` | xong | Nút chỉ có spinner, không có chữ "Saving…". |
| [x] | Saved | `saved` | xong |  |
| [x] | Save failed | `saveFailed` | xong |  |
| [x] | Loading | `loading` | xong | Skeleton list (UI-base §9 dòng 125). |

### 16 · Study · Browse

FE-A6 · [16-study-browse.md](screen-handoff/16-study-browse.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Single state | `default` | xong | P1c. |

### 16a · Study · Self-check (`self_assess`, không có trong kit)

FE-A6 · [16a-study-self-assess.md](screen-handoff/16a-study-self-assess.md)

| | State (shape brief) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | prompt | — | xong | Shape brief, không có trong kit; P2. |
| [x] | revealed | — | xong | Shape brief, không có trong kit; P2. |
| [x] | relearning | — | xong | Shape brief, không có trong kit; P2. |
| [x] | saving | — | xong | Shape brief, không có trong kit; P2. |
| [x] | saveFailed | — | xong | Shape brief, không có trong kit; P2. |
| [x] | stale | — | xong | Shape brief, không có trong kit; P2. |

### 17 · Study · Match

FE-A6 · [17-study-match.md](screen-handoff/17-study-match.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Single state | `default` | xong | P3. |

### 18 · Study · Guess

FE-A6 · [18-study-guess.md](screen-handoff/18-study-guess.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Single state | `default` | xong | P3. |

### 19 · Study · Recall

FE-A6 · [19-study-recall.md](screen-handoff/19-study-recall.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Counting down | `countingDown` | xong | P4. |
| [x] | Revealed · self-check | `revealed` | xong | P4. |
| [x] | Timed out | `timedOut` | xong | P4. |

### 20 · Study · Fill

FE-A6 · [20-study-fill.md](screen-handoff/20-study-fill.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Typing | `input` | xong | P4. |
| [x] | Hint shown | `hint` | xong | P4. |
| [x] | Wrong | `wrong` | xong | P4. |

### 21 · Session summary

FE-A6 · [21-session-summary.md](screen-handoff/21-session-summary.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Review finished | `loaded` | xong |  |
| [x] | Learning finished | `learning` | xong |  |
| [x] | 200 cards | `large` | xong | "— the session limit" khi hàng đợi của phiên ôn chạm `card_limit` (BR-STUDY-024). |
| [x] | Left early | `leftEarly` | xong |  |
| [x] | Interrupted | `interrupted` | xong |  |
| [x] | Ended by reset | `reset` | xong |  |
| [x] | Algorithm changed | `schedulerChanged` | xong |  |
| [x] | Content trashed | — | xong | `contentDeleted`, câu chữ của kit; chưa có ảnh capture. |
| [x] | Save error | `saveError` | xong |  |
| [-] | Loading | `loading` | không làm | Không tới được: tổng kết đến cùng view của phiên; lần tải đầu của route là spinner. |

### 22 · Progress

FE-A9 · [22-progress.md](screen-handoff/22-progress.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Last 7 days | `loaded` | xong | Bộ chọn khoảng nằm ngay trên danh sách (D10); một hàng tổng, header không ghi tổng (D2). |
| [x] | Last 30 days | `month` | xong |  |
| [x] | Streak held | `held` | xong |  |
| [x] | Streak lost | `lost` | xong | Ghi chú nêu tên thứ trong 6 ngày, xa hơn thì nêu ngày. |
| [x] | Inside a deck | `deck` | xong | Hàng tổng "Whole deck" (D2). |
| [x] | Never studied | `never` | xong | Thêm "Start studying" sang tab Học (D1). |
| [x] | Loading | `loading` | xong | Skeleton list (UI-base §9 dòng 125). |
| [x] | Error | `error` | xong |  |

V8 thêm bốn state kit không có: khoảng không có hoạt động (A3), chưa có deck (A2), deck
không có deck con (A1), deck đã bị xoá (E2).

### 23 · Settings

FE-A3 · [23-settings.md](screen-handoff/23-settings.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Loaded | `loaded` | xong | Theme là hàng mở màn 25 (D2); hàng Daily reminder ẩn tới FE-B5. |
| [x] | Loading | `loading` | xong | Skeleton list (UI-base §9 dòng 125). |
| [x] | Saving | `saving` | xong | Spinner trong stepper. |
| [x] | Saved | `saved` | xong |  |
| [x] | Invalid limit | `invalidLimit` | xong | Thông báo nằm dưới stepper (UC E1). |
| [x] | Save failed | `saveFailed` | xong |  |
| [x] | Reset options | `resetConfirm` | xong |  |
| [x] | Options reset | `resetDone` | xong |  |

### 24 · Daily reminder

FE-B5 · [24-daily-reminder.md](screen-handoff/24-daily-reminder.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Off | — | xong | FE-B5. |
| [x] | Turning on | — | xong | FE-B5. |
| [x] | On | — | xong | FE-B5. |
| [x] | Changing time | — | xong | FE-B5; dialog hai stepper (spec D2). |
| [x] | Permission denied | — | xong | FE-B5; không có Open system settings (spec D1, FE-B6). |
| [x] | Could not schedule | — | xong | FE-B5; khi đổi giờ có câu riêng. |
| [x] | Off · may still show | — | xong | FE-B5; banner warning có Try again (spec D8, UC E6). |
| [x] | Unavailable | — | xong | FE-B5. |
| [x] | Loading | — | xong | FE-B5; `MxSkeletonList` (spec D10). |

### 25 · Theme

FE-A3 · [25-theme.md](screen-handoff/25-theme.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | System | `system` | xong | Tiêu đề "Theme", dòng mô tả dễ hiểu (D7). |
| [x] | Light | `light` | xong |  |
| [x] | Dark | `dark` | xong |  |

### 26 · Language

FE-A3 · [26-language.md](screen-handoff/26-language.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | English | `english` | xong | Hàng radio `MxOptionRow`. |
| [x] | Switched to Vietnamese | `vietnamese` | xong | Toast viết bằng ngôn ngữ mới. |
| [x] | Follow system | `system` | xong | Dòng phụ nói `system` đang ra ngôn ngữ nào (D8). |

## Cập nhật

- **Khi một state đổi trạng thái:** sửa dòng của nó, dòng tổng hợp của màn và câu tổng
  ở trên, trong cùng commit với code.
- **Khi kit đổi phiên bản:** so lại danh sách state với bộ chuyển state của kit, rồi
  sửa dòng "Nguồn" và `tools/design/screen_states.json`.
- **Tạo ngày 2026-09-26** theo yêu cầu của chủ dự án, từ `master` tại `e2ad9de`.
- **Cập nhật ngày 2026-09-26:** FE-A3 plan 1 dựng màn 23, 25 và 26; 14 state chuyển sang
  xong.
- **Cập nhật ngày 2026-09-27:** FE-A3 plan 2 dựng màn 15; 7 state chuyển sang xong.
- **Cập nhật ngày 2026-09-27:** FE-B2 + FE-B4 dựng màn 03 và 05, `rootEmpty` của màn 01 và
  chip Tags của màn 07; 24 state chuyển sang xong.
- **Cập nhật ngày 2026-09-27:** màn 08, 09 và 10 đã đối chiếu với kit ở #103 (FE-A2), với
  detail file riêng; 22 state chuyển sang xong.
- **Cập nhật ngày 2026-09-27:** read model của phiên mang `card_limit`; `large` của màn 21
  chuyển sang xong.
- **Cập nhật ngày 2026-09-27:** BR-DECK-026 và BR-DECK-027 định nghĩa mastery của deck;
  `rootLoaded` và `rootSortFilter` của màn 01 chuyển sang xong.
