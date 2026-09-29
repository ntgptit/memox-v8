# WBS frontend — MemoX V8

- **Trạng thái:** hiện hành, sửa mỗi khi một hạng mục đổi trạng thái.
- **Mục đích:** cho người và agent biết phần giao diện nào đã xong, phần nào còn lại
  và làm theo thứ tự nào.
- **Phạm vi:** `lib/app/`, `lib/core/theme/`, `lib/l10n/`, `lib/shared/`,
  `lib/features/*/presentation/` và kiểm chứng của chúng: widget test, golden, visual
  audit, kịch bản IT `HOST-WIDGET` và `DEVICE-E2E`. Không gồm domain, data và use
  case — phần đó ở [`wbs_BE.md`](wbs_BE.md).
- **Nguồn sự thật cho:** tiến độ và thứ tự của các hạng mục frontend. Thiết kế thuộc
  [`DESIGN.md`](../DESIGN.md); điều hướng thuộc
  [`navigation.md`](shared/ui/navigation.md); hành vi thuộc BR/UC trong `features/`;
  quyết định và nợ của UI base thuộc
  [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) (§2, §9).
- **Phụ thuộc:** [`wbs_BE.md`](wbs_BE.md), vì mỗi màn hình cần use case của feature
  đó; [`PRODUCT.md`](../PRODUCT.md) là product context cho Impeccable.
- **Ngữ cảnh bằng chứng:** `master` tại `7de0101` (PR #78), ngày 2026-09-26. Thư viện
  phase 1–4 và căn theo screen handoff phase A–E đã merge qua PR #28–#53; tìm kiếm toàn
  thư viện (#68), import/export (#72, #74), luồng học P1–P3 (#71, #73, #75, #76) và Trash
  (#78) đã merge. Trạng thái từng màn ở
  [screen handoff index](shared/ui/screen-handoff/00-index.md). Mọi hạng mục BE của
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
  - [`DESIGN.md`](../DESIGN.md) giữ foundations, theme binding, widget dùng chung và
    giọng copy; các màn nằm ở [screen handoff](shared/ui/screen-handoff/00-index.md), mỗi
    màn một file chi tiết liệt kê state kèm golden (ADR-019).
  - [Critique 2026-09-21](../.impeccable/critique/2026-09-21T06-26-58Z__handoff-out.md)
    ghi luồng học chưa được thiết kế (P1, đóng ở FE-A5) và typography tiếng Việt/tiếng
    Hàn chưa được thiết kế (P2, đóng ở FE-C2).
- **Điều hướng:** bốn destination Thư viện · Học · Tiến độ · Cài đặt. Thư viện starter
  là child flow trong Thư viện; nhắc học nằm trong nhánh Cài đặt. Cả bốn tab đã có màn
  thật; `PlaceholderScreen` đã bỏ ở FE-A9.
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
| FE-A1 | Thư viện: danh sách deck và deck đang mở; tạo root/deck con, sửa, xoá (kèm deletion summary), di chuyển, sắp xếp, đổi scheduler (UC-DECK-001…UC-DECK-006) | xong | BE-03 | L | [PR #28](https://github.com/ntgptit/memox-v8/pull/28), [PR #29](https://github.com/ntgptit/memox-v8/pull/29); căn theo screen handoff ở FE-A11; [ui.md](features/deck/ui.md), [kịch bản IT](features/deck/it-scenarios.md) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Thanh mastery, donut "Mastered" và sort Progress xong theo BR-DECK-026, BR-DECK-027 ([spec](superpowers/specs/2026-09-27-deck-mastery-design.md)) |
| FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | xong | BE-04, BE-05, FE-A1 | L | Danh sách: [PR #31](https://github.com/ntgptit/memox-v8/pull/31), căn màn 07 ở [PR #46](https://github.com/ntgptit/memox-v8/pull/46), [#49](https://github.com/ntgptit/memox-v8/pull/49); editor và chi tiết: [#33](https://github.com/ntgptit/memox-v8/pull/33), [#35](https://github.com/ntgptit/memox-v8/pull/35); field editor theo kit: [#51](https://github.com/ntgptit/memox-v8/pull/51), [#52](https://github.com/ntgptit/memox-v8/pull/52) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. File chi tiết handoff 08–10 và đợt căn editor theo kit xong ở [#103](https://github.com/ntgptit/memox-v8/pull/103) |
| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | xong | BE-A1 | M | [spec](superpowers/specs/2026-09-26-settings-ui-design.md); [plan 1: màn 23, 25, 26, `MxStepper`, theme và ngôn ngữ toàn app](superpowers/plans/2026-09-26-settings-ui.md); [plan 2: màn 15 và hai lối vào](superpowers/plans/2026-09-27-study-options-ui.md); screen handoff [15](shared/ui/screen-handoff/15-study-options.md), [23](shared/ui/screen-handoff/23-settings.md), [25](shared/ui/screen-handoff/25-theme.md), [26](shared/ui/screen-handoff/26-language.md); [ui.md](features/settings/ui.md) | — |
| FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
| FE-A5 | Thiết kế luồng học (Impeccable): mặt thẻ, lật thẻ, hàng chấm điểm, tổng kết phiên, streak, cách trình bày sáu mode | xong | FE-07 | S | File chi tiết handoff 13, 14, 16–21 kèm ảnh state ([screen handoff index](shared/ui/screen-handoff/00-index.md)); shape cho phiên `self_assess` ở `16a-study-self-assess.md` (chấm Again/Hard/Good/Easy, hiện khoảng ôn dự kiến ở lượt scheduled) | — |
| FE-A6 | Study Entry, màn hình phiên học và ôn tập cho sáu mode, tổng kết phiên (UC-STUDY-001; BR-MODE-001…BR-MODE-019) | xong | FE-A5, BE-A3, BE-A4, BE-A10 | XL | Backend đã sẵn (BE-A3, BE-A4, BE-A10 xong); màn 14, 16–21 trong kit; kịch bản IT của [study](features/study/it-scenarios.md) và [study-mode](features/study-mode/it-scenarios.md); [spec study UI](superpowers/specs/2026-09-26-study-ui-design.md) (đã duyệt 2026-09-26, chia phase P1–P5; D11 thêm hai phần backend nhỏ trong P1 và P2); phase P1a (nền: tone `success`/`caution`/`danger`, `MxStatTile`, read model của entry và tổng kết): [plan](superpowers/plans/2026-09-26-study-p1a-foundations.md); phase P1b (màn 14 chỉ đọc, route, lối vào từ action sheet và summary, đóng phiên cũ khi mở app): [plan](superpowers/plans/2026-09-26-study-p1b-entry.md); phase P1c (route phiên toàn màn hình, controller, màn 16 Browse, màn 21 Summary; thoát giữa phiên hiện tổng kết theo quyết định của chủ dự án về D8): [plan](superpowers/plans/2026-09-26-study-p1c-session.md); phase P2 (màn 16a self-assess với preview khoảng cách D11b, các action của màn 14: Learn, Review, Continue, starting/refused/startFailed, sheet chọn chiều hỏi FE-A7; deck `sm2` học được trọn vẹn): [plan](superpowers/plans/2026-09-26-study-p2-self-assess.md); roadmap P3→P6 đã duyệt: [roadmap](superpowers/plans/2026-09-26-study-chain-roadmap.md); phase P3 (Guess 18, Match 17, chọn mode ôn cho eight_box, sửa `MxStudyTopBar` ở chữ 2x): [plan](superpowers/plans/2026-09-26-study-p3-guess-match.md); phase P4 (Recall 19, Fill 20; deck `eight_box` học và ôn được trọn vẹn, bỏ tập mode đã dựng): [plan](superpowers/plans/2026-09-26-study-p4-recall-fill.md); phase P5 (bộ kịch bản IT tầng host của study, index 14 và 16–21 `aligned`, đóng các minor còn hoãn): [plan](superpowers/plans/2026-09-26-study-p5-it-records.md) | — |
| FE-A7 | Chọn chiều hỏi trước lượt đầu của phiên self-assess (UC-STUDY-003) | xong | FE-A6, BE-A5 | S | Sheet chọn chiều hỏi của màn 14, làm trong phase P2 của FE-A6: [plan](superpowers/plans/2026-09-26-study-p2-self-assess.md) | — |
| FE-A8 | Tab Học: Study Home (UC-STUDY-002) | xong | FE-A5, BE-A6 | M | BE-A6 (`WatchStudyHomeUseCase`); file chi tiết [13](shared/ui/screen-handoff/13-study-home.md); phase P6 của [roadmap luồng học](superpowers/plans/2026-09-26-study-chain-roadmap.md): Study Home thay placeholder của tab Học, `MxLinearProgress` dùng chung với banner resume của màn 14, số hạng thứ tư "scheduled" của `MxWorkloadBreakdownLine`: [plan](superpowers/plans/2026-09-26-study-p6-study-home.md); audit theo kit ngày 2026-09-28: `noDecks` có "Browse starter decks" (UC-STUDY-002 A4), màn 13 `aligned` | — |
| FE-A9 | Tab Tiến độ và drill-down theo deck (UC-PROGRESS-001, UC-PROGRESS-002) | xong | BE-A7 | L | [spec](superpowers/specs/2026-09-27-progress-ui-design.md) và [plan](superpowers/plans/2026-09-27-progress-ui.md); file chi tiết [22](shared/ui/screen-handoff/22-progress.md), [ui.md](features/progress/ui.md), [kịch bản IT](features/progress/it-scenarios.md); `PlaceholderScreen` không còn tab nào dùng và đã bỏ | — |
| FE-A10 | Tìm kiếm toàn thư viện từ header của Thư viện, ở mọi cấp (UC-SEARCH-001) | xong | BE-A8, FE-A1 | M | [PR #68](https://github.com/ntgptit/memox-v8/pull/68); [spec](superpowers/specs/2026-09-26-library-search-ui-design.md) và [plan](superpowers/plans/2026-09-26-library-search-ui.md); màn 04 trên `SearchLibraryUseCase` ở `lib/features/search/presentation/`: deck, card và tag, debounce 250 ms, Load more theo keyset, lỗi trang đầu (E1) và trang sau (E2); `SearchDecksUseCase` cùng phần đọc phía deck đã bỏ; IT-DISC-006/007 kiểm trên màn 04 theo nghĩa toàn thư viện; [handoff 04](shared/ui/screen-handoff/04-library-search.md) | — |
| FE-A11 | Căn Thư viện theo screen handoff V3 (artifact "MemoX — Mobile UI Kit v3"): màn 01, 02, 04, 07; 5 phase A–E | xong | FE-A1, FE-A2, BE-A2 | L | [spec](superpowers/specs/2026-09-24-library-artifact-alignment-design.md); phase A (#32), B (#34), C (#38), D (#42), E (#46, #49) | — |

### Sub-project sau V8.0

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | xong | BE-B1, FE-A1, FE-A2 | M | [spec](superpowers/specs/2026-09-26-trash-ui-design.md); [plan 1: luồng xoá, Undo, câu chữ](superpowers/plans/2026-09-26-trash-delete-flows.md); [plan 2: màn 06, lối vào, auto-purge](superpowers/plans/2026-09-26-trash-screen.md); [screen handoff 06](shared/ui/screen-handoff/06-trash.md). Hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | — |
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | xong | BE-B2, FE-A2 | M | [spec](superpowers/specs/2026-09-27-tags-starter-ui-design.md) và [plan](superpowers/plans/2026-09-27-tags-starter-ui.md) (chung với FE-B4); file chi tiết [05](shared/ui/screen-handoff/05-tags.md), bộ lọc tag ở [07](shared/ui/screen-handoff/07-card-list.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | — |
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | xong | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [plan export](superpowers/plans/2026-09-26-card-export-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md), [màn 12](shared/ui/screen-handoff/12-card-export.md); test trong `test/features/transfer/presentation/` | — |
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | xong | BE-B4, FE-A1 | M | [spec](superpowers/specs/2026-09-27-tags-starter-ui-design.md) và [plan](superpowers/plans/2026-09-27-tags-starter-ui.md) (chung với FE-B2); file chi tiết [03](shared/ui/screen-handoff/03-starter-decks.md); `rootEmpty` của màn 01 có "Browse starter decks"; [ui.md](features/starter-decks/ui.md) | — |
| FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | xong | BE-B5a, BE-B5b, FE-A3 | S–M | [spec](superpowers/specs/2026-09-28-daily-reminder-ui-design.md) và [plan](superpowers/plans/2026-09-28-daily-reminder-ui.md); màn 24 [24-daily-reminder.md](shared/ui/screen-handoff/24-daily-reminder.md) `aligned`, 9/9 state của kit; bật, tắt, đổi giờ qua `ReminderOperationGate`; hàng Daily reminder của màn 23, câu chữ reset nêu nhắc học và `app/` hoà giải sau reset (dòng 123 của sổ nợ UI-base đóng); [ui.md](features/reminders/ui.md); test trong `test/features/reminders/presentation/`, `test/features/settings/presentation/`, companion `test/visual_audit/screens/features/reminders/` | — (đã kiểm trên emulator cùng BE-B5b, 2026-09-28) |
| FE-B6 | Nút "Open system settings" ở state `permDenied` của màn 24 (D1 của [spec FE-B5](superpowers/specs/2026-09-28-daily-reminder-ui-design.md)): thao tác mới của `ReminderPlatformRepository` mở cài đặt notification của app | xong | FE-B5, BE-B5b | S | Kit 24 vẽ nút này. `ReminderPlatformRepository.openNotificationSettings` qua channel `memox/notification_settings` của `MainActivity.kt`; banner E1 có "Open system settings" (primary) rồi "Try again" (outline); D1 của spec FE-B5 đóng. Test trong `test/features/reminders/`; kiểm trên emulator API 36 (2026-09-28): nút mở trang notification của MemoX, cho phép rồi Try again thì bật | — |
| FE-B7 | Trạng thái đồng bộ trên màn hình (SB-U1): màn 27 Sync, dòng Sync ở màn 23, thẻ nổi sync ở màn 13 (`MxFloatingNotice`, quyết định của chủ dự án 2026-09-28); không có trong kit, dựng theo Impeccable `shape` ngày 2026-09-28 | xong | SB-U1 của [`wbs_supabase.md`](wbs_supabase.md) | M | [PR #138](https://github.com/ntgptit/memox-v8/pull/138); [spec](superpowers/specs/2026-09-28-sync-status-design.md) và [plan](superpowers/plans/2026-09-28-sync-status.md); màn 27 [27-sync.md](shared/ui/screen-handoff/27-sync.md) `aligned`, 7 golden light/dark; 3 golden dòng Sync ở màn 23, 2 golden thẻ nổi ở màn 13; deviation ghi ở 13, 23 và 27 | Ẩn hết khi build không có Supabase |

### Nợ của UI base (spec UI base §9)

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-C1 | Contrast đạt ngưỡng: token của handoff đang dưới ngưỡng (dòng 1–4) và các phát hiện audit (dòng 30, 57–60) | xong | — | M | Chủ dự án duyệt 2026-09-28 (ảnh trước/sau): `error` sáng `#C02447`, `inversePrimary` `#A0ACFF`, chữ mastery dùng `statusMasteredInk`, glyph banner cảnh báo dùng `warningInk`, toggle tắt có viền `outline` và núm `onSurfaceVariant`, track tiến độ `surfaceContainerLow`, grabber `onSurfaceVariant`; viền ô nhập và viền nút outline giữ như kit (miễn trừ). §9 dòng 1–4, 30, 57–60 đóng, dòng 145 ghi độ lệch; phần contrast của dòng 66 (skeleton, viền banner) nằm ngoài phạm vi đã duyệt. `textContrastGuideline` không vào `auditProductionScreen` vì đọc sai chữ 12px và nút tô nền; thay bằng `test/core/theme/token_contrast_test.dart` | — |
| FE-C2 | Typography tiếng Việt: line-height 1.0–1.2 có thể cắt dấu chồng (dòng 5); chưa có fallback cho chữ Hangul | xong | — | M | Typography tiếng Việt: text một dòng có ellipsis dùng line-height 1.5 (`screenTitle`, `listRowTitle`, `rowSubtitle`, `tagLabel`); Hangul dùng font fallback của hệ điều hành; §9 dòng 5 đã đóng, dòng 102 ghi độ lệch | — |
| FE-C3 | Accessibility: `MxSpinner` và `MxSkeleton` không có semantics, `MxMasteryDonut` chỉ đọc phần trăm (dòng 61); grabber của sheet không có action cho screen reader (dòng 65) | xong | — | S | UI-base debt, đợt 1: `MxSkeletonList`, tên cho spinner và donut, grabber có action đóng; §9 dòng 61, 65 đã đóng | — |
| FE-C4 | Predictive Back trên Android 14+: đặt `android:enableOnBackInvokedCallback` (dòng 62) | xong | — | S | UI-base debt, đợt 1: `android:enableOnBackInvokedCallback`; §9 dòng 62 đã đóng | — |
| FE-C5 | Adaptive: chưa có window-size class, chưa có navigation rail cho tablet và màn hình ngang (dòng 63) | xong | — | M | Chủ dự án chọn phương án B 2026-09-28 (ảnh mockup): [spec](superpowers/specs/2026-09-28-tablet-rail-design.md), [plan](superpowers/plans/2026-09-28-tablet-rail.md); từ 600 dp `MxNavRail` thay bottom nav (`AppTabShell`), `MxAppShell` cấp cột 720 dp, FAB bám mép cột, snackbar tối đa bằng cột; golden `app_tablet_*` và `mx_nav_rail_*`; §9 dòng 63 đóng, dòng 146 ghi độ lệch; PRODUCT.md cập nhật | — |
| FE-C6 | BottomSheet không chừa chỗ cho bàn phím (dòng 64) | xong | — | S | UI-base debt, đợt 1: sheet đặt trên IME inset; §9 dòng 64 đã đóng | — |
| FE-C7 | Chuỗi của gallery debug là literal tiếng Anh, chưa đưa vào ARB (dòng 19) | xong | — | S | Gallery l10n: 125 key `gallery…` en/vi; luật chuỗi literal của guard phủ `lib/app/`; §9 dòng 19 đã đóng | — |
| FE-C8 | Hiệu năng: mỗi `MxSkeleton` chạy ticker riêng; `context.derivedColors` dựng lại ở mỗi lần đọc (dòng 66) | xong | — | S | UI-base debt, đợt 1: một pulse cho mỗi danh sách; `derivedColors` nhớ theo theme; §9 dòng 66 (phần contrast chờ FE-C1) | — |

### Hạ tầng và kiểm chứng

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-D1 | Sinh lại goldens trên Linux | xong | — | S | Chủ dự án chốt golden là bản render Linux (2026-09-25); toàn bộ golden sinh lại trong container `.claude/skills/flutter-testing/scripts/golden.Dockerfile` (#46, #51); spec UI base §8.2, §9 dòng 9 đã đóng; job `goldens` của CI so ảnh trên mỗi pull request (BE-D2) | — |
| FE-D2 | Chuyển gate sang `dod_check.sh` và làm rỗng `targets_pending` | xong | — | M | Companion `test/visual_audit/` cho 01, 02, 04, 07–10 và placeholder; test coverage; luật V7 `not_exploratory` đã xoá; `dod_check.sh` bỏ golden, base `origin/master`; ô chi tiết của card editor cao 48 (§9 dòng 103) | — |
| FE-D3 | Kịch bản `DEVICE-E2E`: 8 kịch bản cần emulator hoặc thiết bị | xong | — | M | [spec](superpowers/specs/2026-09-28-device-e2e-design.md) và [plan](superpowers/plans/2026-09-28-device-e2e.md); `integration_test/` và `tools/device/run_device_e2e.sh`; 8/8 PASS trên emulator API 36 ngày 2026-09-28 ([device-e2e.md](shared/testing/device-e2e.md)); kèm deep link `memox://app/<route>` và màn not-found (IT-NAV-005) | — |
| FE-D4 | Đối chiếu skill `flutter-theme-design` với V8: tên widget, API và hợp đồng component so với `lib/core/theme/`, `lib/shared/widgets/` và design handoff (đã retire theo ADR-019); bỏ hoặc đổi các mục quy định widget mà V8 đã dựng dưới tên khác | xong | — | M | 10 chỗ sai tên hoặc API được sửa theo code (`MxAppShell`, `MxButton` với `MxButtonTone`/`MxButtonSize`, `MxBottomNav`, `MxListRow`, `MxSelectionCheckbox`, `MxToggle`, `MxFilterChip`/`MxTagChip`/`MxChipTrigger`, `MxDialog`/`showMxDialog`, `showMxSnackbar`, `MxSpinner`/`MxSkeleton*`/`MxLinearProgress`), bảng parity ghi slot nào có trong `app_theme.dart`, `MxIcon` (không tồn tại) thay bằng `AppIcons`/`AppIconSize`, danh sách rule guard đầy đủ; checklist ThemeData của slot chưa dựng giữ nguyên vì SKILL.md ghi rõ là đích | — |
| FE-D5 | Retire UI Kit v3 và design handoff; `DESIGN.md` sinh từ app là chuẩn UI (ADR-019); file chi tiết màn mô tả app và ghi golden | xong | — | M | [spec](superpowers/specs/2026-09-30-retire-ui-kit-design.md) và [plan](superpowers/plans/2026-09-30-retire-ui-kit.md); SP1 của đợt sửa theo critique 2026-09-30 (SP2 shared, SP3a/SP3b màn hình theo sau) | — |

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

- Mọi hạng mục FE của V8.0 đã xong; FE-A1 (mastery, BR-DECK-026, BR-DECK-027) và FE-A2
  (file chi tiết 08–10, #103) không còn phần dở.
- **FE-B5** và **FE-B6:** xong, cả bước kiểm trên thiết bị. FE-D3 cũng đã xong.

Nhánh `claude/study-large-files` không còn gì để merge: cả hai commit của nó (bỏ qua file
sinh trong công cụ kiểm kiến trúc; `study_turn_data_source.dart`) đã vào `master` ở #53.
Ghi chú ngày 2026-09-26 trước đó nói nhánh này chưa merge là sai: nó chỉ đếm commit, không
so nội dung.

## Điểm chặn và quyết định còn mở

Không còn điểm chặn nào của FE (FE-C1 và FE-D3 đã xong 2026-09-28).

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

1. Mọi màn của V8.0 đã dựng, không còn phần dở, và mọi màn trong index là `aligned`.
2. FE-C1 và FE-C5 xong (2026-09-28).
3. Sau V8.0: FE-B1 (Trash, #78), FE-B3 (import/export, #72), FE-B2 (tag), FE-B4
   (starter), FE-B5 (nhắc học, cả bước thiết bị) và FE-B6 (nút Open system
   settings) đã xong.
4. FE-D4 xong (2026-09-28).

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
- **Ngày 2026-09-26, sau #78:** FE-A10, FE-B1, FE-B3 và phase P1–P3 của FE-A6 đã xong.
  Còn lại của V8.0: FE-A3, FE-A6 (P4, P5), FE-A8, FE-A9; sau V8.0: FE-B2, FE-B4, FE-B5.
  Chưa ước lượng lại số giờ sau các phase này.
- **Ngày 2026-09-26, sau P5 của FE-A6:** FE-A6 xong (P4 #80: Recall, Fill, `eight_box`
  trọn vẹn; P5: bộ kịch bản IT tầng host). Còn lại của V8.0: FE-A3, FE-A8, FE-A9. Bốn
  kịch bản `DEVICE-E2E` của study (`IT-CONT-008`, `IT-PLAT-002`, `IT-PLAT-003`,
  `IT-PLAT-005`) vẫn chờ chạy trên thiết bị.
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
- **Cập nhật ngày 2026-09-26:** rà lại trên `master` tại `7de0101` sau #78: FE-B1 xong
  (dọn cột "Việc tiếp theo"; luồng học đã xử lý `sessionClosed` và `notFound`), FE-A6 đã
  qua P3 nên "Đang làm", FE-A8 và "Bước tiếp theo" theo roadmap P4 → P6; danh sách file
  chi tiết handoff tính cả 06, 11, 12.
- **Cập nhật ngày 2026-09-26:** thêm checklist màn hình và state (đã xoá theo ADR-019)
  theo kit (26 màn, 211 state; tại `e2ad9de`: 108 xong, 6 một phần, 22 đã dựng nhưng chưa
  đối chiếu, 73 chưa làm, 2 không làm).
- **Cập nhật cùng commit:** sửa file này, và dòng của state ở checklist màn hình và
  state, trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; gate đang áp dụng pass; màn hình có đủ
  kiểm chứng ở mục "Trạng thái kiểm chứng".
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
- **Cập nhật ngày 2026-09-26:** FE-A6 xong sau phase P5 (#80 cho P4); "Đang làm" và
  "Bước tiếp theo" chuyển sang FE-A8 (phase P6 của roadmap luồng học).
- **Cập nhật ngày 2026-09-26:** FE-A8 xong (phase P6 của roadmap luồng học): màn 13 Study
  Home ở tab Học. Còn lại của V8.0: FE-A3, FE-A9.
- **Cập nhật ngày 2026-09-26:** FE-A3 plan 1 xong: màn 23, 25, 26 thay placeholder của
  tab Settings; theme và ngôn ngữ lưu được và áp cho cả app. FE-A3 chuyển sang "đang
  làm"; còn plan 2 (màn 15).
- **Cập nhật ngày 2026-09-27:** sau khi BE-B5a (#88) vào `master`, chủ dự án giữ D4 của FE-A3:
  câu chữ reset chưa nêu nhắc học; FE-B5 thêm nó và gọi `ReconcileReminderUseCase` khi hiện
  hàng Daily reminder (dòng FE-B5 và dòng 123 của sổ nợ UI-base).
- **Cập nhật ngày 2026-09-27:** FE-A3 xong sau plan 2: màn 15 Study options mở từ action
  sheet của deck và từ app bar màn 14; Coming soon không còn nêu Study options.
- **Cập nhật ngày 2026-09-27:** FE-A9 xong: màn 22 thay placeholder cuối cùng (tab
  Progress), hai cấp `/progress` và `/progress/:deckId`; `PlaceholderScreen` đã bỏ.
- **Cập nhật ngày 2026-09-27:** FE-B2 và FE-B4 xong trong một plan: màn 03 và 05, chip Tags
  và bộ lọc tag của màn 07, app bar và `rootEmpty` của màn 01; sheet Coming soon đã bỏ.
- **Cập nhật ngày 2026-09-27:** FE-A1 xong: thanh mastery trên mỗi hàng deck, donut
  "Mastered" trên tóm tắt và sort Progress của màn 01 (BR-DECK-026, BR-DECK-027).
- **Cập nhật ngày 2026-09-28:** rà lại trên `master` tại `1d42cf5`: "Đang làm", dòng
  FE-A2, danh sách file chi tiết và "Bước tiếp theo" không còn nêu phần dở của FE-A1 và
  FE-A2 (đã xong); FE-B5 không còn chờ BE-B5b cho phần host; màn 13 còn lượt audit.
- **Cập nhật ngày 2026-09-28:** audit màn 13 theo kit: state `noDecks` có lại "Browse
  starter decks" mở Starter Library (lý do ẩn nó, màn 03 ngoài V8, đã hết từ FE-B4);
  OPEN QUESTION A4 của UC-STUDY-002 đóng; màn 13 `aligned`.
- **Cập nhật ngày 2026-09-28:** FE-B5 xong phần host: màn 24 (9/9 state của kit, cộng E4 và
  E7), hàng Daily reminder của màn 23, reset nêu nhắc học và hoà giải sau reset. Thêm FE-B6
  cho nút "Open system settings" mà FE-B5 ẩn (D1). Checklist: 209/211 state xong, 2 không
  làm.
- **Cập nhật ngày 2026-09-28:** FE-D4 xong: skill `flutter-theme-design` dùng tên và API thật của V8; bảng parity theme ↔ widget ghi slot nào đã có.
- **Cập nhật ngày 2026-09-28:** FE-D3 xong: tám kịch bản `DEVICE-E2E` chạy bằng
  `tools/device/run_device_e2e.sh` (8/8 PASS trên emulator API 36). Thêm deep link
  `memox://app/<route>` và màn not-found cho route lạ (IT-NAV-005). Điểm chặn "không có
  emulator" đóng.
- **Cập nhật ngày 2026-09-28:** FE-B6 xong: nút "Open system settings" ở `permDenied` của
  màn 24 qua thao tác mới `openNotificationSettings` của port (channel native trong
  `MainActivity.kt`, không thêm package); D1 của spec FE-B5 đóng; kiểm trên emulator.
