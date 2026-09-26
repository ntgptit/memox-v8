# WBS frontend — MemoX V8

- **Trạng thái:** hiện hành, sửa mỗi khi một hạng mục đổi trạng thái.
- **Mục đích:** cho người và agent biết phần giao diện nào đã xong, phần nào còn lại
  và làm theo thứ tự nào.
- **Phạm vi:** `lib/app/`, `lib/core/theme/`, `lib/l10n/`, `lib/shared/`,
  `lib/features/*/presentation/` và kiểm chứng của chúng: widget test, golden, visual
  audit, kịch bản IT `HOST-WIDGET` và `DEVICE-E2E`. Không gồm domain, data và use
  case — phần đó ở [`wbs_BE.md`](wbs_BE.md).
- **Nguồn sự thật cho:** tiến độ và thứ tự của các hạng mục frontend. Thiết kế thuộc
  [handoff V3](shared/ui/design-handoff/00-index.md); điều hướng thuộc
  [`navigation.md`](shared/ui/navigation.md); hành vi thuộc BR/UC trong `features/`;
  quyết định và nợ của UI base thuộc
  [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) (§2, §9).
- **Phụ thuộc:** [`wbs_BE.md`](wbs_BE.md), vì mỗi màn hình cần use case của feature
  đó; [`PRODUCT.md`](../PRODUCT.md) là product context cho Impeccable.
- **Ngữ cảnh bằng chứng:** `master` tại `867819b`, ngày 2026-09-26 (rà soát độ sẵn sàng
  backend của từng màn). Thư viện phase 1–4 và căn theo screen handoff phase A–E đã merge
  qua PR #28–#53; màn 01, 02, 04, 07 `aligned`, màn 08–10 `built`
  ([screen handoff index](shared/ui/screen-handoff/00-index.md)). Mọi hạng mục BE của
  V8.0 đã xong ([`wbs_BE.md`](wbs_BE.md)). Việc session khác còn làm dở mà chưa đẩy lên
  (nếu có) không có trong file này.

## Phạm vi và tài liệu tham chiếu

- **UI base (sub-project 2):** theme, 43 component `Mx*`, shell bốn tab và gallery
  debug. Đã xong qua PR #19–#24.
- **Màn hình feature:** không thuộc UI base (spec UI base §1, §10). Một màn hình cần
  use case của feature ([ADR-011](shared/decisions/ADR-011-cau-truc-thu-muc-v8.md)),
  nên mỗi hạng mục FE phụ thuộc hạng mục BE tương ứng.
- **Thiết kế:** Impeccable phụ trách product definition, UX, UI, design system và
  accessibility (`CLAUDE.md`).
  - Handoff V3 có foundations, theme binding và 46 widget; các màn nằm ở
    [screen handoff](shared/ui/screen-handoff/00-index.md). File chi tiết đã có cho 01,
    02, 04, 07, 13, 14, 16–21; màn 08–10, 15, 22, 23, 25, 26 chưa có.
  - [Critique 2026-09-21](../.impeccable/critique/2026-09-21T06-26-58Z__handoff-out.md)
    ghi luồng học chưa được thiết kế (P1, đóng ở FE-A5) và typography tiếng Việt/tiếng
    Hàn chưa được thiết kế (P2, đóng ở FE-C2).
- **Điều hướng:** bốn destination Thư viện · Học · Tiến độ · Cài đặt. Thư viện starter
  là child flow trong Thư viện; nhắc học nằm trong nhánh Cài đặt. Tab Thư viện đã có màn
  thật; ba tab Học, Tiến độ, Cài đặt còn hiển thị placeholder
  (`lib/app/placeholder_screen.dart`).
- **Gate:** gate là `dod_check.sh` (FE-D2); danh sách `targets_pending` của guard đã
  rỗng ([`README.md` gốc](../README.md)).
- **Quy trình:** mỗi nhóm hạng mục qua thiết kế của Impeccable, rồi brainstorm → spec
  → plan → thực thi → review của Superpowers. Một hạng mục ở đây là đơn vị lập kế
  hoạch, không phải một task của plan.

## Hạng mục

Quy ước giống [`wbs_BE.md`](wbs_BE.md):

- **Trạng thái:** `xong` · `đang làm` · `chưa bắt đầu` · `bị chặn`.
- **Cỡ:** S < M < L < XL, là ước lượng chứ không phải cam kết.
- **Phụ thuộc:** hạng mục phải xong trước, cùng nghĩa như trong `wbs_BE.md`. Các ID
  `BE-…` trỏ vào `wbs_BE.md`.

### Đã xong

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-01 | Theme foundations: font Plus Jakarta Sans, `lib/core/theme/` sáng và tối | xong | BE-01 | — | [PR #19](https://github.com/ntgptit/memox-v8/pull/19) | — |
| FE-02 | Chrome và layout: 11 component (Button, IconButton, EmptyState, AppBar, BottomNav, Breadcrumb, StudyTopBar, Fab, AppShell, ScreenScroll, FooterBar) | xong | FE-01 | — | [PR #20](https://github.com/ntgptit/memox-v8/pull/20) | — |
| FE-03 | App wiring: l10n en/vi, `main`, `app`, router, shell bốn tab với placeholder, gallery debug | xong | FE-02 | — | [PR #21](https://github.com/ntgptit/memox-v8/pull/21) | — |
| FE-04 | Hành động và nhập liệu: 10 component (FilterChip, ChipTrigger, SearchField, TextField, FieldMessage, Toggle, OptionRow, SelectionCheckbox, SegmentedTray, Stepper) | xong | FE-03 | — | [PR #22](https://github.com/ntgptit/memox-v8/pull/22) | — |
| FE-05 | Surface, row, trạng thái, metadata: 13 component (Card, Section, ListRow, SettingsRow, IconTile, ActionSheetCommandRow, ListSectionHeader, Badge, StatusBadge, TagChip, Note, WorkloadBreakdownLine, MasteryDonut) | xong | FE-04 | — | [PR #23](https://github.com/ntgptit/memox-v8/pull/23) | — |
| FE-06 | Overlay, loading, lỗi: 9 component (Dialog, BottomSheet, SheetActions, Snackbar, InlineBanner, DeckPickerSheet, Skeleton, Spinner, ErrorState); audit UI base | xong | FE-05 | — | [PR #24](https://github.com/ntgptit/memox-v8/pull/24); spec UI base §9 dòng 56 (13/20) | — |
| FE-07 | Product context cho Impeccable (`PRODUCT.md`) | xong | — | — | [PR #25](https://github.com/ntgptit/memox-v8/pull/25) | — |

### V8.0 — còn lại

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-A1 | Thư viện: danh sách deck và deck đang mở; tạo root/deck con, sửa, xoá (kèm deletion summary), di chuyển, sắp xếp, đổi scheduler (UC-DECK-001…UC-DECK-006) | đang làm | BE-03 | L | [PR #28](https://github.com/ntgptit/memox-v8/pull/28), [PR #29](https://github.com/ntgptit/memox-v8/pull/29); căn theo screen handoff ở FE-A11; [ui.md](features/deck/ui.md), [kịch bản IT](features/deck/it-scenarios.md) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: panel "Mastered x/y" và sort theo progress chờ BR/UC của deck định nghĩa (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
| FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | đang làm | BE-04, BE-05, FE-A1 | L | Danh sách: [PR #31](https://github.com/ntgptit/memox-v8/pull/31), căn màn 07 ở [PR #46](https://github.com/ntgptit/memox-v8/pull/46), [#49](https://github.com/ntgptit/memox-v8/pull/49); editor và chi tiết: [#33](https://github.com/ntgptit/memox-v8/pull/33), [#35](https://github.com/ntgptit/memox-v8/pull/35); field editor theo kit: [#51](https://github.com/ntgptit/memox-v8/pull/51), [#52](https://github.com/ntgptit/memox-v8/pull/52) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: file chi tiết handoff cho màn 08–10 |
| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | chưa bắt đầu | BE-A1 | M | `lib/app/app.dart` để `ThemeMode.system` tới khi feature settings lưu được lựa chọn; spec UI base §10 để việc lưu theme và ngôn ngữ ngoài phạm vi; [ui.md](features/settings/ui.md); backend sẵn: 8 use case trong `lib/features/settings/domain/usecases/` | Đọc màn 15, 23, 25, 26 trong kit, viết file chi tiết handoff, rồi lập plan |
| FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
| FE-A5 | Thiết kế luồng học (Impeccable): mặt thẻ, lật thẻ, hàng chấm điểm, tổng kết phiên, streak, cách trình bày sáu mode | xong | FE-07 | S | File chi tiết handoff 13, 14, 16–21 kèm ảnh state ([screen handoff index](shared/ui/screen-handoff/00-index.md)); shape cho phiên `self_assess` ở `16a-study-self-assess.md` (chấm Again/Hard/Good/Easy, hiện khoảng ôn dự kiến ở lượt scheduled) | — |
| FE-A6 | Study Entry, màn hình phiên học và ôn tập cho sáu mode, tổng kết phiên (UC-STUDY-001; BR-MODE-001…BR-MODE-019) | chưa bắt đầu | FE-A5, BE-A3, BE-A4, BE-A10 | XL | Backend đã sẵn (BE-A3, BE-A4, BE-A10 xong); màn 14, 16–21 trong kit; kịch bản IT của [study](features/study/it-scenarios.md) và [study-mode](features/study-mode/it-scenarios.md); [spec study UI](superpowers/specs/2026-09-26-study-ui-design.md) (draft, chia phase P1–P5; D11 thêm hai phần backend nhỏ trong P1 và P2) | Chủ dự án duyệt spec, rồi lập plan P1 |
| FE-A7 | Chọn chiều hỏi trước lượt đầu của phiên self-assess (UC-STUDY-003) | chưa bắt đầu | FE-A6, BE-A5 | S | BE-A5 xong; nằm trong các trạng thái của màn 14; [README study](features/study/README.md) | Gộp vào phase P2 của FE-A6 (spec study UI §3) |
| FE-A8 | Tab Học: Study Home (UC-STUDY-002) | chưa bắt đầu | FE-A5, BE-A6 | M | Tab Học đang là placeholder; BE-A6 xong (`WatchStudyHomeUseCase`); file chi tiết [13](shared/ui/screen-handoff/13-study-home.md) có | Sau phase P1 của FE-A6: Resume và chạm vào deck cần route của phiên và của Study entry (spec study UI D1, D2) |
| FE-A9 | Tab Tiến độ và drill-down theo deck (UC-PROGRESS-001, UC-PROGRESS-002) | chưa bắt đầu | BE-A7 | L | Tab Tiến độ đang là placeholder; nội dung theo `navigation.md`; [kịch bản IT](features/progress/it-scenarios.md); BE-A7 xong (`WatchProgressUseCase`, `WatchDeckProgressUseCase`) | Đọc màn 22 trong kit, viết file chi tiết handoff (chưa có `ui.md` của progress), rồi lập plan |
| FE-A10 | Tìm kiếm toàn thư viện từ header của Thư viện, ở mọi cấp (UC-SEARCH-001) | xong | BE-A8, FE-A1 | M | [PR #68](https://github.com/ntgptit/memox-v8/pull/68); [spec](superpowers/specs/2026-09-26-library-search-ui-design.md) và [plan](superpowers/plans/2026-09-26-library-search-ui.md); màn 04 trên `SearchLibraryUseCase` ở `lib/features/search/presentation/`: deck, card và tag, debounce 250 ms, Load more theo keyset, lỗi trang đầu (E1) và trang sau (E2); `SearchDecksUseCase` cùng phần đọc phía deck đã bỏ; IT-DISC-006/007 kiểm trên màn 04 theo nghĩa toàn thư viện; [handoff 04](shared/ui/screen-handoff/04-library-search.md) | — |
| FE-A11 | Căn Thư viện theo screen handoff V3 (artifact "MemoX — Mobile UI Kit v3"): màn 01, 02, 04, 07; 5 phase A–E | xong | FE-A1, FE-A2, BE-A2 | L | [spec](superpowers/specs/2026-09-24-library-artifact-alignment-design.md); phase A (#32), B (#34), C (#38), D (#42), E (#46, #49) | — |

### Sub-project sau V8.0

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | BE-B1 xong: hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | BE-B2 xong: hợp đồng cho UI ở §9 của [spec gói 8](superpowers/specs/2026-09-26-tag-management-backend-design.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Màn 05 trên 5 use case của `tags`: gọi `PlanTagRenameUseCase` khi tên đổi, xác nhận gộp bằng `mergeIntoTagId`, gặp `mergeNotConfirmed` thì xem trước lại; ghi lệch với kit ở `renameMerge`: số thẻ sau gộp là hợp các thẻ (spec D6), không phải tổng `31 + 46`; overlay lọc của màn 07 đọc `WatchDeckTagCountsUseCase`, đặt `CardListQuery.tagIds` và bỏ khỏi lựa chọn tag không còn trong danh sách; hành động `Tags` trên app bar của Library; "Find cards with this tag" là tìm kiếm thư viện theo tên tag (spec D12) |
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | chưa bắt đầu | BE-B3, FE-A2 | M | [README transfer](features/transfer/README.md), [kịch bản IT](features/transfer/it-scenarios.md) | Chọn file và chia sẻ file cần plugin nền tảng (xem Điểm chặn) |
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
| FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5, FE-A3 | S–M | [README reminders](features/reminders/README.md) | Sau BE-B5 |

### Nợ của UI base (spec UI base §9)

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-C1 | Contrast đạt ngưỡng: token của handoff đang dưới ngưỡng (dòng 1–4) và các phát hiện audit (dòng 30, 57–60) | bị chặn | — | M | §2 chốt "implement the handoff as written"; §9; khi quyết xong, `textContrastGuideline` vào `auditProductionScreen` | Chủ dự án quyết có sửa giá trị token của handoff không, rồi Impeccable làm |
| FE-C2 | Typography tiếng Việt: line-height 1.0–1.2 có thể cắt dấu chồng (dòng 5); chưa có fallback cho chữ Hangul | xong | — | M | Typography tiếng Việt: text một dòng có ellipsis dùng line-height 1.5 (`screenTitle`, `listRowTitle`, `rowSubtitle`, `tagLabel`); Hangul dùng font fallback của hệ điều hành; §9 dòng 5 đã đóng, dòng 102 ghi độ lệch | — |
| FE-C3 | Accessibility: `MxSpinner` và `MxSkeleton` không có semantics, `MxMasteryDonut` chỉ đọc phần trăm (dòng 61); grabber của sheet không có action cho screen reader (dòng 65) | xong | — | S | UI-base debt, đợt 1: `MxSkeletonList`, tên cho spinner và donut, grabber có action đóng; §9 dòng 61, 65 đã đóng | — |
| FE-C4 | Predictive Back trên Android 14+: đặt `android:enableOnBackInvokedCallback` (dòng 62) | xong | — | S | UI-base debt, đợt 1: `android:enableOnBackInvokedCallback`; §9 dòng 62 đã đóng | — |
| FE-C5 | Adaptive: chưa có window-size class, chưa có navigation rail cho tablet và màn hình ngang (dòng 63) | chưa bắt đầu | — | M | §9 dòng 63 | Quyết phạm vi adaptive khi thiết kế màn hình |
| FE-C6 | BottomSheet không chừa chỗ cho bàn phím (dòng 64) | xong | — | S | UI-base debt, đợt 1: sheet đặt trên IME inset; §9 dòng 64 đã đóng | — |
| FE-C7 | Chuỗi của gallery debug là literal tiếng Anh, chưa đưa vào ARB (dòng 19) | xong | — | S | Gallery l10n: 125 key `gallery…` en/vi; luật chuỗi literal của guard phủ `lib/app/`; §9 dòng 19 đã đóng | — |
| FE-C8 | Hiệu năng: mỗi `MxSkeleton` chạy ticker riêng; `context.derivedColors` dựng lại ở mỗi lần đọc (dòng 66) | xong | — | S | UI-base debt, đợt 1: một pulse cho mỗi danh sách; `derivedColors` nhớ theo theme; §9 dòng 66 (phần contrast chờ FE-C1) | — |

### Hạ tầng và kiểm chứng

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-D1 | Sinh lại goldens trên Linux | xong | — | S | Chủ dự án chốt golden là bản render Linux (2026-09-25); toàn bộ golden sinh lại trong container `.claude/skills/flutter-testing/scripts/golden.Dockerfile` (#46, #51); spec UI base §8.2, §9 dòng 9 đã đóng; job `goldens` của CI so ảnh trên mỗi pull request (BE-D2) | — |
| FE-D2 | Chuyển gate sang `dod_check.sh` và làm rỗng `targets_pending` | xong | — | M | Companion `test/visual_audit/` cho 01, 02, 04, 07–10 và placeholder; test coverage; luật V7 `not_exploratory` đã xoá; `dod_check.sh` bỏ golden, base `origin/master`; ô chi tiết của card editor cao 48 (§9 dòng 103) | — |
| FE-D3 | Kịch bản `DEVICE-E2E`: 8 kịch bản cần emulator hoặc thiết bị | bị chặn | — | M | [host-coverage-map.md](shared/testing/host-coverage-map.md); §9 dòng 18: máy phát triển không có emulator | Cần môi trường có emulator hoặc thiết bị |

## Đã xong và đã kiểm chứng

- **Viết và review:** UI base (FE-01…FE-06) đã merge. Mỗi component có widget test và
  golden sáng/tối; ứng dụng chạy bằng tiếng Anh và tiếng Việt. Audit ở phase 6 cho
  13/20, chi tiết ở §9 dòng 56–66.
- **Kiểm chứng ngày 2026-09-24 trên cây `f28bdfd`:**
  - toàn bộ test không phải golden pass 701/701, gồm cả test UI;
  - `TZ=UTC flutter test --tags golden` fail 58 ảnh trên Linux, trùng khớp với
    `master` trước khi merge PR #26.
  - Goldens chưa được chạy lại trên Windows, máy đã sinh ra chúng, trong đợt kiểm này.

## Đang làm

Tại `867819b` không còn nhánh FE nào chưa merge trên remote. Spec study UI của FE-A6 và
FE-A7 ([spec](superpowers/specs/2026-09-26-study-ui-design.md)) đã merge ở #65, ở dạng
draft chờ chủ dự án duyệt.

Nhánh `claude/study-large-files` có 2 commit chưa merge và không thuộc hạng mục nào.
Commit đầu sửa công cụ kiểm kiến trúc; commit sau tách phần ghi lượt trả lời của
`study_session_repository_impl.dart` sang `study_turn_data_source.dart`. Phase P1 của
FE-A6 sửa `SessionSummary` trong backend study (spec study UI D11), nên cần merge hoặc
bỏ nhánh này trước P1.

## Điểm chặn và quyết định còn mở

| Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| FE-A6, FE-A7 | [Spec study UI](superpowers/specs/2026-09-26-study-ui-design.md) còn là draft | Toàn bộ luồng học, và Resume của FE-A8 | Chủ dự án duyệt spec |
| FE-A2, FE-A3, FE-A9 | Chưa có file chi tiết handoff cho màn 08–10, 15, 22, 23, 25, 26 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi lập plan |
| FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ BR/UC của deck định nghĩa nó (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
| FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
| FE-B3 | Chọn file và chia sẻ file cần plugin nền tảng | Import/export | Quyết trong spec, kèm lý do và cách rollback |
| FE-D3 | Không có emulator hoặc thiết bị | 8 kịch bản `DEVICE-E2E` | Môi trường chạy |

## Trạng thái kiểm chứng

- **Mỗi màn hình production cần có:**
  - widget test và golden sáng/tối;
  - companion trong `test/visual_audit/` (2 luật guard của lớp `visual-audit`);
  - chuỗi en/vi trong ARB;
  - các kịch bản IT `HOST-WIDGET` của UC. host-coverage-map có 71 kịch bản
    `HOST-WIDGET` và 8 kịch bản `DEVICE-E2E`.
- **Gate:** `dod_check.sh` ([`README.md` gốc](../README.md)). CI chạy nó cùng goldens
  trên mỗi pull request, và `CI gate` phải xanh trước khi merge (BE-D2 trong
  [`wbs_BE.md`](wbs_BE.md)).

## Bước tiếp theo

Mọi hạng mục FE của V8.0 đã có backend (BE-A1…BE-A10 xong). Thứ tự còn lại do thiết kế
và phụ thuộc giữa các màn quyết định:

1. FE-A6 kèm FE-A7 (luồng học), sau khi chủ dự án duyệt spec study UI và nhánh
   `claude/study-large-files` được xử lý; P1 → P5.
2. FE-A8 (Study Home), sau phase P1 của FE-A6.
3. FE-A3 (Cài đặt) và FE-A9 (Tiến độ), làm song song được: mỗi hạng mục viết file chi
   tiết handoff của màn trước khi lập plan.
4. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
5. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng. BE-B1 và BE-B2 xong
   trong gói 7 và gói 8, nên FE-B1 và FE-B2 không còn chờ backend; BE-B3…BE-B5 chưa bắt
   đầu.

## Ước lượng effort (rà soát 2026-09-25)

Đơn vị là **giờ agent**: một session theo quy trình của repo (plan, TDD, golden trong
container, review opus). Không gồm thời gian chủ dự án duyệt, khoảng 10–15% thêm.

**Hiệu chỉnh:** Thư viện có 7 màn với 76 trạng thái trong kit (01, 02, 04, 07–10). Khi
backend đã sẵn, nó mất khoảng 14 PR và khoảng 16 giờ agent (#28…#53), tức khoảng 0,2
giờ mỗi trạng thái, cộng thêm phần tương tác phức tạp.

| ID | Trạng thái kit | Chờ | Giờ agent | PR |
|---|---|---|---|---|
| FE-A5 | 13, 14, 16–21 có; thiếu `self_assess` | — | 2–3 | 1 |
| FE-A6 | 14 (9), 16–20 (9), 21 (10), `self_assess` | — | 12–18 | 5–6 |
| FE-A7 | trong 14 | — | 1–2 | 0–1 |
| FE-A3 | 23 (8), 25 (3), 26 (3), 15 (7) | — | 4–6 | 2 |
| FE-A8 | 13 (7) | FE-A6 P1 | 2–3 | 1 |
| FE-A9 | 22 (8) | — | 4–6 | 2 |
| FE-A10 | 04 (mở rộng) | — | 2–3 | 1 |
| FE-C2, C3, C4, C6, C7, C8 | — | — | 7–10 | 2–3 |
| FE-D2 | — | — | 2–4 | 1 |
| FE-C1 | — | quyết định contrast | 2–3 | 1 |
| FE-C5 | — | mở lại phạm vi tablet | 4–8 | 1–2 |
| FE-D3 | — | emulator hoặc thiết bị | 3–5 | 1 |
| FE-B1…FE-B5 | 06, 05, 11–12, 03, 24 | BE-B1…BE-B5 | 15–22 | 5–7 |

- **V8.0**, không tính C1, C5, D3: khoảng **36–55 giờ agent** theo ước lượng ban đầu.
  Ngày 2026-09-26, FE-A5, FE-C2, FE-C3, FE-C4, FE-C6, FE-C7, FE-C8 và FE-D2 đã xong;
  phần còn lại (FE-A3, FE-A6…FE-A10) khoảng **25–38 giờ agent**, và không phần nào còn
  chờ backend.
- **Rủi ro lớn nhất:** FE-A6. Đó là luồng nhiều tương tác nhất; màn `self_assess` không
  có trong kit và dựng theo shape brief 16a.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-24** theo yêu cầu của chủ dự án, từ `master` tại `f28bdfd`,
  worktree sạch.
- **Cập nhật ngày 2026-09-26:** rà soát độ sẵn sàng backend của từng màn trên `master`
  tại `867819b`. Đưa "Việc tiếp theo", "Đang làm", điểm chặn và "Bước tiếp theo" về
  đúng trạng thái: FE-A5, FE-D2 và backend BE-A6…BE-A8 đã xong; ghi rằng FE-A10 chưa
  làm dù màn 04 `aligned`, và FE-A8 cần route của FE-A6 P1.
- **Cập nhật ngày 2026-09-26:** FE-A10 xong: màn 04 tìm toàn thư viện trên
  `SearchLibraryUseCase` ([spec](superpowers/specs/2026-09-26-library-search-ui-design.md),
  [plan](superpowers/plans/2026-09-26-library-search-ui.md)); phần còn lại của V8.0
  (FE-A3, FE-A6…FE-A9) khoảng 23–35 giờ agent.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; gate đang áp dụng pass; màn hình có đủ
  kiểm chứng ở mục "Trạng thái kiểm chứng".
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
