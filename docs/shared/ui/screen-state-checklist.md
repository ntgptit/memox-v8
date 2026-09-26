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

Index vẫn ghi màn 14, 16–21 là `built`. Theo roadmap luồng học, P5 đổi các màn này sang
`aligned` sau khi audit.

## Tổng hợp

Kit có **26 màn, 211 state**. Xong **108**; một phần **6**; đã dựng nhưng chưa đối chiếu **22**; chưa làm **73**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.

| # | Màn | Hạng mục FE | State | Xong | Một phần / chưa đối chiếu | Chưa làm | Không làm | Detail |
|---|---|---|---|---|---|---|---|---|
| 01 | Deck list · recursive | FE-A1 | 22 | 19 | 3 | 0 | 0 | [01-deck-list.md](screen-handoff/01-deck-list.md) |
| 02 | Review algorithm & reset | FE-A4 | 9 | 9 | 0 | 0 | 0 | [02-review-algorithm.md](screen-handoff/02-review-algorithm.md) |
| 03 | Starter decks | FE-B4 | 10 | 0 | 0 | 10 | 0 | — |
| 04 | Library search | FE-A1, FE-A10 | 5 | 5 | 0 | 0 | 0 | [04-library-search.md](screen-handoff/04-library-search.md) |
| 05 | Tags | FE-B2 | 12 | 0 | 0 | 12 | 0 | — |
| 06 | Trash | FE-B1 | 15 | 15 | 0 | 0 | 0 | [06-trash.md](screen-handoff/06-trash.md) |
| 07 | Card list | FE-A2 | 15 | 13 | 1 | 0 | 1 | [07-card-list.md](screen-handoff/07-card-list.md) |
| 08 | Card create | FE-A2 | 9 | 0 | 9 | 0 | 0 | — |
| 09 | Card edit | FE-A2 | 9 | 2 | 7 | 0 | 0 | — |
| 10 | Card detail | FE-A2 | 7 | 1 | 6 | 0 | 0 | — |
| 11 | Card import | FE-B3 | 16 | 16 | 0 | 0 | 0 | [11-card-import.md](screen-handoff/11-card-import.md) |
| 12 | Card export | FE-B3 | 9 | 9 | 0 | 0 | 0 | [12-card-export.md](screen-handoff/12-card-export.md) |
| 13 | Study home | FE-A8 | 7 | 0 | 0 | 7 | 0 | [13-study-home.md](screen-handoff/13-study-home.md) |
| 14 | Study entry | FE-A6, FE-A7 | 9 | 8 | 1 | 0 | 0 | [14-study-entry.md](screen-handoff/14-study-entry.md) |
| 15 | Study options | FE-A3 | 7 | 0 | 0 | 7 | 0 | — |
| 16 | Study · Browse | FE-A6 | 1 | 1 | 0 | 0 | 0 | [16-study-browse.md](screen-handoff/16-study-browse.md) |
| 17 | Study · Match | FE-A6 | 1 | 1 | 0 | 0 | 0 | [17-study-match.md](screen-handoff/17-study-match.md) |
| 18 | Study · Guess | FE-A6 | 1 | 1 | 0 | 0 | 0 | [18-study-guess.md](screen-handoff/18-study-guess.md) |
| 19 | Study · Recall | FE-A6 | 3 | 0 | 0 | 3 | 0 | [19-study-recall.md](screen-handoff/19-study-recall.md) |
| 20 | Study · Fill | FE-A6 | 3 | 0 | 0 | 3 | 0 | [20-study-fill.md](screen-handoff/20-study-fill.md) |
| 21 | Session summary | FE-A6 | 10 | 8 | 1 | 0 | 1 | [21-session-summary.md](screen-handoff/21-session-summary.md) |
| 22 | Progress | FE-A9 | 8 | 0 | 0 | 8 | 0 | — |
| 23 | Settings | FE-A3 | 8 | 0 | 0 | 8 | 0 | — |
| 24 | Daily reminder | FE-B5 | 9 | 0 | 0 | 9 | 0 | — |
| 25 | Theme | FE-A3 | 3 | 0 | 0 | 3 | 0 | — |
| 26 | Language | FE-A3 | 3 | 0 | 0 | 3 | 0 | — |

## Theo màn

### 01 · Deck list · recursive

FE-A1 · [01-deck-list.md](screen-handoff/01-deck-list.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [~] | Root · decks | `rootLoaded` | một phần | Thanh mastery ẩn: chờ BR/UC của deck định nghĩa mastery (điểm chặn trong `wbs_BE.md`). |
| [x] | Root · loading | `rootLoading` | xong |  |
| [~] | Root · first launch | `rootEmpty` | một phần | Chỉ có Create deck; starter decks nằm dưới Coming soon, chờ FE-B4. |
| [x] | Root · error | `rootError` | xong |  |
| [x] | Root · search | `rootSearch` | xong |  |
| [~] | Root · sort & filter | `rootSortFilter` | một phần | Chưa có sort "Progress" (Coming soon), cùng điểm chặn mastery. |
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

FE-B4 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | Templates | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Choose algorithm | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Adding | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Added | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Already present | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Second copy | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Add failed | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Loading | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | None in build | — | chưa làm | Sau V8.0; BE-B4 đã xong. |
| [ ] | Load failed | — | chưa làm | Sau V8.0; BE-B4 đã xong. |

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

FE-B2 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | Loaded | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Loading | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Empty | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Search empty | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Tag actions | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Rename | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Rename → merge | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Name too long | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Delete | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Busy row | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Op error | — | chưa làm | Sau V8.0; BE-B2 đã xong. |
| [ ] | Tag gone | — | chưa làm | Sau V8.0; BE-B2 đã xong. |

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
| [~] | Loaded | `loaded` | một phần | Chưa có chip Tags: chờ FE-B2. |
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

FE-A2 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [~] | Empty | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Valid | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Details open | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Back empty | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Front too long | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | 10 tags | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Deck rejects | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Saving | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Save failed | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |

### 09 · Card edit

FE-A2 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [~] | Loaded | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Loading | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Load error | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [x] | Card gone | `notFound` | xong | Căn theo kit ở FE-B1 (câu chữ Trash, Open Trash). |
| [~] | Validation | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Saving | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Save failed | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [~] | Discard | — | đã dựng, chưa đối chiếu | Dựng ở #33; lệch ghi ở UI-base §9 dòng 79–84; chưa có detail file. |
| [x] | Move to Trash | `delConfirm` | xong | Card "More" và hộp thoại của FE-B1 (D13). |

### 10 · Card detail

FE-A2 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [~] | Loaded | — | đã dựng, chưa đối chiếu | Dựng ở #35, #36; lệch ghi ở UI-base §9 dòng 85–90; chưa có detail file. |
| [~] | More history | — | đã dựng, chưa đối chiếu | Dựng ở #35, #36; lệch ghi ở UI-base §9 dòng 85–90; chưa có detail file. |
| [~] | Load more failed | — | đã dựng, chưa đối chiếu | Dựng ở #35, #36; lệch ghi ở UI-base §9 dòng 85–90; chưa có detail file. |
| [~] | No history | — | đã dựng, chưa đối chiếu | Dựng ở #35, #36; lệch ghi ở UI-base §9 dòng 85–90; chưa có detail file. |
| [~] | Loading | — | đã dựng, chưa đối chiếu | Dựng ở #35, #36; lệch ghi ở UI-base §9 dòng 85–90; chưa có detail file. |
| [~] | Error | — | đã dựng, chưa đối chiếu | Dựng ở #35, #36; lệch ghi ở UI-base §9 dòng 85–90; chưa có detail file. |
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
| [ ] | Resume + workload | `loaded` | chưa làm | Phase P6 của roadmap luồng học; detail file đã có. |
| [ ] | Workload | `noResume` | chưa làm | Phase P6 của roadmap luồng học; detail file đã có. |
| [ ] | Zero workload | `zero` | chưa làm | Phase P6 của roadmap luồng học; detail file đã có. |
| [ ] | No decks | `noDecks` | chưa làm | Phase P6 của roadmap luồng học; detail file đã có. |
| [ ] | No cards | `noCards` | chưa làm | Phase P6 của roadmap luồng học; detail file đã có. |
| [ ] | Loading | `loading` | chưa làm | Phase P6 của roadmap luồng học; detail file đã có. |
| [ ] | Error | `error` | chưa làm | Phase P6 của roadmap luồng học; detail file đã có. |

### 14 · Study entry

FE-A6, FE-A7 · [14-study-entry.md](screen-handoff/14-study-entry.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | SM-2 · direction | `sm2` | xong |  |
| [~] | Eight boxes · modes | `eightBox` | một phần | Match và Guess chọn được (P3); Recall, Fill và Learn của `eight_box` là Coming soon tới P4. |
| [x] | Only new | `onlyNew` | xong |  |
| [x] | Nothing to do | `nothing` | xong |  |
| [x] | Session today | `resume` | xong |  |
| [x] | Starting | `starting` | xong |  |
| [x] | No longer due | `refused` | xong |  |
| [x] | Start failed | `startFailed` | xong |  |
| [x] | Loading | `loading` | xong |  |

### 15 · Study options

FE-A3 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | Deck override | — | chưa làm |  |
| [ ] | App defaults | — | chưa làm |  |
| [ ] | Invalid limit | — | chưa làm |  |
| [ ] | Saving | — | chưa làm |  |
| [ ] | Saved | — | chưa làm |  |
| [ ] | Save failed | — | chưa làm |  |
| [ ] | Loading | — | chưa làm |  |

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
| [ ] | Counting down | `countingDown` | chưa làm | Phase P4. |
| [ ] | Revealed · self-check | `revealed` | chưa làm | Phase P4. |
| [ ] | Timed out | `timedOut` | chưa làm | Phase P4. |

### 20 · Study · Fill

FE-A6 · [20-study-fill.md](screen-handoff/20-study-fill.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | Typing | `input` | chưa làm | Phase P4. |
| [ ] | Hint shown | `hint` | chưa làm | Phase P4. |
| [ ] | Wrong | `wrong` | chưa làm | Phase P4. |

### 21 · Session summary

FE-A6 · [21-session-summary.md](screen-handoff/21-session-summary.md)

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [x] | Review finished | `loaded` | xong |  |
| [x] | Learning finished | `learning` | xong |  |
| [~] | 200 cards | `large` | một phần | Thiếu vế "— the session limit": read model của phiên chưa có `card_limit`. |
| [x] | Left early | `leftEarly` | xong |  |
| [x] | Interrupted | `interrupted` | xong |  |
| [x] | Ended by reset | `reset` | xong |  |
| [x] | Algorithm changed | `schedulerChanged` | xong |  |
| [x] | Content trashed | — | xong | `contentDeleted`, câu chữ của kit; chưa có ảnh capture. |
| [x] | Save error | `saveError` | xong |  |
| [-] | Loading | `loading` | không làm | Không tới được: tổng kết đến cùng view của phiên; lần tải đầu của route là spinner. |

### 22 · Progress

FE-A9 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | Last 7 days | — | chưa làm |  |
| [ ] | Last 30 days | — | chưa làm |  |
| [ ] | Streak held | — | chưa làm |  |
| [ ] | Streak lost | — | chưa làm |  |
| [ ] | Inside a deck | — | chưa làm |  |
| [ ] | Never studied | — | chưa làm |  |
| [ ] | Loading | — | chưa làm |  |
| [ ] | Error | — | chưa làm |  |

### 23 · Settings

FE-A3 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | Loaded | — | chưa làm |  |
| [ ] | Loading | — | chưa làm |  |
| [ ] | Saving | — | chưa làm |  |
| [ ] | Saved | — | chưa làm |  |
| [ ] | Invalid limit | — | chưa làm |  |
| [ ] | Save failed | — | chưa làm |  |
| [ ] | Reset options | — | chưa làm |  |
| [ ] | Options reset | — | chưa làm |  |

### 24 · Daily reminder

FE-B5 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | Off | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | Turning on | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | On | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | Changing time | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | Permission denied | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | Could not schedule | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | Off · may still show | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | Unavailable | — | chưa làm | Sau V8.0; chờ BE-B5. |
| [ ] | Loading | — | chưa làm | Sau V8.0; chờ BE-B5. |

### 25 · Theme

FE-A3 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | System | — | chưa làm |  |
| [ ] | Light | — | chưa làm |  |
| [ ] | Dark | — | chưa làm |  |

### 26 · Language

FE-A3 · chưa có detail file

| | State (kit) | Id ảnh | Trạng thái | Ghi chú |
|---|---|---|---|---|
| [ ] | English | — | chưa làm |  |
| [ ] | Switched to Vietnamese | — | chưa làm |  |
| [ ] | Follow system | — | chưa làm |  |

## Cập nhật

- **Khi một state đổi trạng thái:** sửa dòng của nó, dòng tổng hợp của màn và câu tổng
  ở trên, trong cùng commit với code.
- **Khi kit đổi phiên bản:** so lại danh sách state với bộ chuyển state của kit, rồi
  sửa dòng "Nguồn" và `tools/design/screen_states.json`.
- **Tạo ngày 2026-09-26** theo yêu cầu của chủ dự án, từ `master` tại `e2ad9de`.
