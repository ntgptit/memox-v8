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
- **Ngữ cảnh bằng chứng:** `master` tại `86f2e0d`, ngày 2026-09-24. Thư viện phase 1–3
  đã merge qua PR #28, #29, #31; spec căn Thư viện theo screen handoff V3 ở
  [`2026-09-24-library-artifact-alignment-design.md`](superpowers/specs/2026-09-24-library-artifact-alignment-design.md).
  Head của bảy nhánh UI trên remote trùng với head lúc merge của PR #19–#25, nên không
  có commit nào được đẩy lên sau khi merge. Việc session UI còn làm dở mà chưa đẩy lên
  (nếu có) không có trong file này.

## Phạm vi và tài liệu tham chiếu

- **UI base (sub-project 2):** theme, 43 component `Mx*`, shell bốn tab và gallery
  debug. Đã xong qua PR #19–#24.
- **Màn hình feature:** không thuộc UI base (spec UI base §1, §10). Một màn hình cần
  use case của feature ([ADR-011](shared/decisions/ADR-011-cau-truc-thu-muc-v8.md)),
  nên mỗi hạng mục FE phụ thuộc hạng mục BE tương ứng.
- **Thiết kế:** Impeccable phụ trách product definition, UX, UI, design system và
  accessibility (`CLAUDE.md`).
  - Handoff V3 hiện chỉ có foundations, theme binding và 46 widget. Thứ tự chạy của nó
    kết thúc bằng SCREENS, nhưng repo chưa có screen handoff nào.
  - [Critique 2026-09-21](../.impeccable/critique/2026-09-21T06-26-58Z__handoff-out.md)
    ghi luồng học chưa được thiết kế (P1) và typography tiếng Việt/tiếng Hàn chưa được
    thiết kế (P2).
- **Điều hướng:** bốn destination Thư viện · Học · Tiến độ · Cài đặt. Thư viện starter
  là child flow trong Thư viện; nhắc học nằm trong nhánh Cài đặt. Hiện cả bốn tab đều
  hiển thị placeholder (`lib/app/placeholder_screen.dart`).
- **Gate:** từ màn hình feature đầu tiên, gate là `dod_check.sh` và danh sách
  `targets_pending` của guard phải rỗng ([`README.md` gốc](../README.md)). Hiện còn 17
  luật chờ: 15 chờ lớp `presentation`, 2 chờ lớp `visual-audit`.
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
| FE-A1 | Thư viện: danh sách deck và deck đang mở; tạo root/deck con, sửa, xoá (kèm deletion summary), di chuyển, sắp xếp, đổi scheduler (UC-DECK-001…UC-DECK-006) | đang làm | BE-03 | L | Phase 1–2 của [spec Thư viện](superpowers/specs/2026-09-24-library-screens-design.md): [PR #28](https://github.com/ntgptit/memox-v8/pull/28), [PR #29](https://github.com/ntgptit/memox-v8/pull/29); [ui.md](features/deck/ui.md), [kịch bản IT](features/deck/it-scenarios.md) | Căn theo screen handoff (FE-A11) |
| FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | đang làm | BE-04, BE-05, FE-A1 | L | Danh sách card và thao tác hàng loạt: [PR #31](https://github.com/ntgptit/memox-v8/pull/31) (phase 3); [ui.md](features/card/ui.md), [kịch bản IT](features/card/it-scenarios.md) | Phase 4 (editor, chi tiết) dựng theo màn 08–10 của screen handoff, sau FE-A11 |
| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | chưa bắt đầu | BE-A1 | M | `lib/app/app.dart` để `ThemeMode.system` tới khi feature settings lưu được lựa chọn; spec UI base §10 để việc lưu theme và ngôn ngữ ngoài phạm vi; [ui.md](features/settings/ui.md) | Sau BE-A1 |
| FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
| FE-A5 | Thiết kế luồng học (Impeccable): mặt thẻ, lật thẻ, hàng chấm điểm, tổng kết phiên, streak, cách trình bày sáu mode | chưa bắt đầu | FE-07 | M | Critique 2026-09-21, P1 "Study loop not designed"; [ui.md](features/study/ui.md) | Làm sớm, song song với BE-A3 và BE-A4 |
| FE-A6 | Study Entry, màn hình phiên học và ôn tập cho sáu mode, tổng kết phiên (UC-STUDY-001; BR-MODE-001…BR-MODE-019) | chưa bắt đầu | FE-A5, BE-A3, BE-A4 | XL | Tab Học đang là placeholder; kịch bản IT của [study](features/study/it-scenarios.md) và [study-mode](features/study-mode/it-scenarios.md) | Vertical slice đầu tiên theo `navigation.md` |
| FE-A7 | Chọn chiều hỏi trước lượt đầu của phiên self-assess (UC-STUDY-003) | chưa bắt đầu | FE-A6, BE-A5 | S | [README study](features/study/README.md) | Sau FE-A6 |
| FE-A8 | Tab Học: Study Home (UC-STUDY-002) | chưa bắt đầu | FE-A5, BE-A6 | M | Tab Học đang là placeholder | Sau BE-A6 |
| FE-A9 | Tab Tiến độ và drill-down theo deck (UC-PROGRESS-001, UC-PROGRESS-002) | chưa bắt đầu | BE-A7 | L | Tab Tiến độ đang là placeholder; nội dung theo `navigation.md`; [kịch bản IT](features/progress/it-scenarios.md) | Cần thiết kế màn hình |
| FE-A10 | Tìm kiếm toàn thư viện từ header của Thư viện, ở mọi cấp (UC-SEARCH-001) | chưa bắt đầu | BE-A8, FE-A1 | M | [README search](features/search/README.md) | Sau BE-A8 |
| FE-A11 | Căn Thư viện theo screen handoff V3 (artifact "MemoX — Mobile UI Kit v3"): màn 01, 02, 04, 07; 5 phase A–E | đang làm | FE-A1, FE-A2, BE-A2 | L | [spec](superpowers/specs/2026-09-24-library-artifact-alignment-design.md); [screen handoff](shared/ui/screen-handoff/00-index.md) | Phase A (#32), B (#34), C (#38), D (#42) xong; phase E (07) trong PR này — FE-A11 hoàn tất khi merge |

### Sub-project sau V8.0

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | [README trash](features/trash/README.md) | Sau BE-B1 |
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Sau BE-B2 |
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | chưa bắt đầu | BE-B3, FE-A2 | M | [README transfer](features/transfer/README.md), [kịch bản IT](features/transfer/it-scenarios.md) | Chọn file và chia sẻ file cần plugin nền tảng (xem Điểm chặn) |
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
| FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5, FE-A3 | S–M | [README reminders](features/reminders/README.md) | Sau BE-B5 |

### Nợ của UI base (spec UI base §9)

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-C1 | Contrast đạt ngưỡng: token của handoff đang dưới ngưỡng (dòng 1–4) và các phát hiện audit (dòng 30, 57–60) | bị chặn | — | M | §2 chốt "implement the handoff as written"; §9 | Chủ dự án quyết có sửa giá trị token của handoff không, rồi Impeccable làm |
| FE-C2 | Typography tiếng Việt: line-height 1.0–1.2 có thể cắt dấu chồng (dòng 5); chưa có fallback cho chữ Hangul | chưa bắt đầu | — | M | §9 dòng 5; critique 2026-09-21, P2 | Impeccable (typeset) |
| FE-C3 | Accessibility: `MxSpinner` và `MxSkeleton` không có semantics, `MxMasteryDonut` chỉ đọc phần trăm (dòng 61); grabber của sheet không có action cho screen reader (dòng 65) | chưa bắt đầu | — | S | §9 dòng 61, 65 | Sửa trước khi màn hình feature đầu tiên dùng các widget này |
| FE-C4 | Predictive Back trên Android 14+: đặt `android:enableOnBackInvokedCallback` (dòng 62) | chưa bắt đầu | — | S | §9 dòng 62 | — |
| FE-C5 | Adaptive: chưa có window-size class, chưa có navigation rail cho tablet và màn hình ngang (dòng 63) | chưa bắt đầu | — | M | §9 dòng 63 | Quyết phạm vi adaptive khi thiết kế màn hình |
| FE-C6 | BottomSheet không chừa chỗ cho bàn phím (dòng 64) | chưa bắt đầu | — | S | §9 dòng 64: chưa sheet nào có ô nhập | Sửa trước khi một sheet có ô nhập đầu tiên |
| FE-C7 | Chuỗi của gallery debug là literal tiếng Anh, chưa đưa vào ARB (dòng 19) | chưa bắt đầu | — | S | §9 dòng 19 | Ưu tiên thấp: chỉ có ở build debug |
| FE-C8 | Hiệu năng: mỗi `MxSkeleton` chạy ticker riêng; `context.derivedColors` dựng lại ở mỗi lần đọc (dòng 66) | chưa bắt đầu | — | S | §9 dòng 66 | — |

### Hạ tầng và kiểm chứng

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| FE-D1 | Sinh lại goldens trên Linux: 58 ảnh fail trên Linux, cả ở `master`, vì goldens được sinh trên Windows | chưa bắt đầu | BE-D2 | S | Spec UI base §8.2, §9 dòng 9; đo ngày 2026-09-24 trên `master` và trên cây đã merge (cùng 58 ảnh, cùng số pixel lệch) | Làm khi có CI Linux |
| FE-D2 | Chuyển gate sang `dod_check.sh` và làm rỗng `targets_pending`: 15 luật chờ lớp `presentation`, 2 luật chờ lớp `visual-audit` | chưa bắt đầu | — | M | [`README.md` gốc](../README.md); `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml` | Làm trong PR có màn hình feature đầu tiên (FE-A1) |
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

Tại `f28bdfd` không còn nhánh FE nào chưa merge trên remote.

## Điểm chặn và quyết định còn mở

| Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| FE-A2…FE-A10 | Screen handoff đã có ([index](shared/ui/screen-handoff/00-index.md)); file chi tiết của mỗi màn viết khi làm màn đó | Mọi màn hình feature | Viết file chi tiết của màn trước khi lập plan |
| FE-A1…FE-A10 | Mỗi màn hình cần use case của hạng mục BE tương ứng | Thứ tự làm | Theo [`wbs_BE.md`](wbs_BE.md) |
| FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ định nghĩa ở BE-A7 |
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
- **Gate:** trước màn hình feature đầu tiên là năm lệnh trong
  [`README.md` gốc](../README.md); từ màn hình đó trở đi là `dod_check.sh` (FE-D2).

## Bước tiếp theo

1. FE-A5 (thiết kế luồng học) và FE-A1 (Thư viện, backend đã sẵn) làm song song. PR
   đầu tiên của FE-A1 kèm FE-D2 và FE-C3.
2. FE-A2 (card).
3. FE-A3 sau BE-A1; FE-A4 sau BE-A2.
4. FE-A6, FE-A7, FE-A8 theo tiến độ BE-A4, BE-A5, BE-A6; FE-A9 sau BE-A7; FE-A10 sau
   BE-A8.
5. FE-C6 trước sheet có ô nhập đầu tiên; FE-C1 sau khi có quyết định; các mục FE-C còn
   lại xếp xen vào khi màn hình chạm tới.
6. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-24** theo yêu cầu của chủ dự án, từ `master` tại `f28bdfd`,
  worktree sạch.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
- **Khi nào đánh `xong`:** hạng mục đã merge; gate đang áp dụng pass; màn hình có đủ
  kiểm chứng ở mục "Trạng thái kiểm chứng".
- **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
- **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
