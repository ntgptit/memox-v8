# MemoX — UI/UX audit theo từng màn

**Status:** P1 (patterns 1, 2, 4, 6, study chrome, MxSettingsRow large text) fixed by plan 2026-09-29-ui-audit-p1-robustness; density items open.

## Tóm tắt

**Không có màn nào ở mức Critical.** Có 16 màn/khu vực Major và 14 Minor. Hầu hết lỗi Major không nằm riêng ở màn nào. Chúng đến từ 9 pattern lặp lại, phần lớn nên sửa một lần ở shared component.

| # | Chiều (Impeccable native audit) | Điểm | Phát hiện chính |
|---|---|---|---|
| 1 | Accessibility | 2/4 | Chữ lớn làm mất thông tin: tên deck/tag bị cắt 1 dòng, nội dung mặt thẻ bị cắt mà không báo còn cuộn, hàng setting vỡ chữ. Browse chỉ có cử chỉ vuốt, không có nút tương đương. Guess tự chuyển thẻ sau 1,2 giây. |
| 2 | Performance | 3/4 | Danh sách deck, tag, thùng rác và kết quả tìm kiếm dựng toàn bộ trong `MxScreenScroll`, không lazy. |
| 3 | Appearance & Theming | 3/4 | Token dùng nhất quán. Còn cờ khác màu giữa list và detail, và trạng thái disabled của option đang khóa khó đọc. |
| 4 | Platform conformance | 3/4 | Nhìn chung giống app Android thật. Route-not-found không đi qua `MxAppShell`. |
| 5 | Adaptivity | 2/4 | Các form có header và footer cố định bóp vùng cuộn khi bàn phím mở. Không có golden nào chụp lúc bàn phím mở, và rất ít golden chữ lớn. |
| | **Tổng** | **13/20** | **Acceptable**: cần xử lý có trọng tâm, không phải làm lại. |

Cách kiểm chứng: 7 agent đọc code và golden (1080 × 2400 = 360 × 800 dp, light/dark). Tôi kiểm lại các finding có tính quyết định. Hai finding sai đã được sửa trong báo cáo: vùng chạm của `MxChipTrigger` thực ra đủ 48 dp; màn Language có khoảng đệm đầu trang. Finding nào có ghi "risk (not reproduced)" nghĩa là suy ra từ code, chưa có golden chứng minh.

## Màn có nguy cơ vỡ layout cao nhất

1. **08/09 Card create & edit.**
   - **Nguyên nhân:** `DeckContextHeaderWidget` (breadcrumb + tên deck, khoảng 100 dp) và `MxFooterBar` (2 nút + caption, 130–200 dp) nằm ngoài vùng cuộn.
   - **Ảnh hưởng:** golden `card_editor_create_2x` (chưa có bàn phím) đã chỉ còn khoảng 55% màn cho form, ô Back bị footer cắt ngang. Khi bàn phím mở, vùng cuộn còn khoảng 200 dp trên máy 800 dp và gần 0 trên máy 568 dp. Người dùng gõ mà không thấy ô đang gõ.
   - **Cách sửa:** đưa context header vào đầu `MxScreenScroll`. Cho `MxFooterBar` ẩn caption và banner phụ khi `viewInsets.bottom > 0`.
2. **20 Fill.**
   - **Nguyên nhân:** bàn phím tự mở, trong khi màn chia 2 `Expanded` bằng nhau, cộng thêm CTA và footer hint.
   - **Ảnh hưởng:** mỗi mặt thẻ còn khoảng 60 dp cho nội dung. Ô nhập không có viền nên khó thấy.
   - **Cách sửa:** khi bàn phím mở, đổi tỉ lệ `flex` và ẩn footer hint. Thêm viền `outlineVariant` cho biến thể `study` của `MxTextField`.
3. **11 Import.**
   - **Nguyên nhân:** app bar, breadcrumb, tên deck và step tracker nằm ngoài vùng cuộn (khoảng 20% màn); footer chiếm thêm khoảng 12%.
   - **Ảnh hưởng:** ở trạng thái mặc định, `MxNote` đã bị footer che. Khi dán văn bản, bàn phím lấy nốt phần còn lại.
   - **Cách sửa:** như mục 1.
4. **19 Recall, 16a Self-check, 16 Browse.**
   - **Nguyên nhân:** nội dung mặt thẻ cuộn bên trong nửa màn nhưng không có dấu hiệu còn nội dung. Golden `study_recall_large_text` cắt nghĩa giữa câu.
   - **Ảnh hưởng:** người học không biết còn nghĩa hay ví dụ bên dưới.
   - **Cách sửa:** bọc bằng `StudyScrollFadeWidget`, widget đã có sẵn và đang dùng ở Guess/Match.
5. **24 Daily reminder.**
   - **Nguyên nhân:** ở chữ 2x, icon tile 44 dp + toggle 48 dp chiếm gần hết bề ngang của hàng.
   - **Ảnh hưởng:** "Daily reminder" vỡ từng từ, subtitle dài 4–5 dòng.
   - **Cách sửa:** `MxSettingsRow` chuyển control xuống dưới nội dung khi chữ ≥ 1.5 (dùng lại cơ chế `wideControl`).
6. **07 Card list (bulk bar), 06 Trash (footer).**
   - **Nguyên nhân:** nhãn 1 dòng chia 5 ô hoặc chia flex cố định.
   - **Ảnh hưởng:** nhãn tiếng Việt hoặc chữ lớn sẽ bị cắt, kể cả nhãn "Thùng rác" / "Xóa vĩnh viễn".

## Màn quá nặng thông tin

- **07 Card list:** thẻ tiến độ deck (vòng %, thanh 4 màu, legend, nút Study) đẩy thẻ đầu tiên xuống khoảng 58% màn. Nút "Study this deck" và FAB "+" là hai CTA primary cạnh tranh nhau. **Sửa:** thu gọn summary (bỏ legend, nút Study compact), và giữ khoảng tránh FAB cho cột trailing.
- **06 Trash:** mỗi hàng 3–4 dòng (khoảng 100 dp), thêm `MxNote` 3 dòng trên đầu, nên màn chỉ thấy khoảng 4 mục. **Sửa:** gộp dòng origin vào meta, chỉ hiện badge khi còn dưới 7 ngày, thu gọn note.
- **02 Review algorithm (đang khóa):** cùng một thông điệp "reset để đổi" xuất hiện ở 3 chỗ: lock strip, note và card Start over. **Sửa:** gộp note vào lock strip.
- **11 Import bước 1:** hai nút primary cùng nghĩa ("Choose file" trong card, footer "Read and map"). **Sửa:** hạ "Choose file" xuống tone outline.
- **13 Study home:** thẻ Resume và thẻ Workload chiếm khoảng 47% màn trước danh sách, và mỗi hàng deck lại lặp breakdown.
- **21 Summary, 22 Progress:** hero và phần chi tiết lặp lại cùng con số (Reviewed/Answered/Wrong; "Today 17" xuất hiện hai lần).
- **09 Card edit:** breadcrumb, tên deck, tóm tắt lịch sử, legend, 5 trường, tags, More và footer dồn chung một màn. Nút Save có hai lần (app bar + footer).
- **Khung phiên học ở chữ 2x:** top bar, context line (3 dòng) và footer hint (3 dòng) chiếm hơn 30% màn.

## Màn quá trống trải

| Màn | Loại | Nhận định |
|---|---|---|
| 25 Theme, 26 Language | Có chủ đích | Chọn 1 trong N, nội dung ngắn, căn trên là đúng. Nên ghi quy ước này vào design handoff để khỏi bị báo lại. |
| 04 Search idle, 03 Starter (ít template) | Có chủ đích | Chấp nhận. |
| **27 Sync (khi lỗi)** | **Không mong muốn** | Nút "Sync now" ở giữa trang, thông báo lỗi nổi ở đáy, khoảng trống lớn ở giữa làm đứt mạch lỗi → hành động. **Sửa:** đưa CTA vào `MxFooterBar` hoặc đặt thông báo ngay dưới hàng trạng thái. |
| **14 Study entry (SM-2)** | **Không mong muốn** | Khoảng 40% màn trống giữa nội dung và footer, không có điểm neo. Chấp nhận được, miễn không lấp bằng nội dung giả. |
| 17 Match ít cặp | Rủi ro | Hàng `Expanded` chia đều, nên 1–2 cặp sẽ thành ô khổng lồ. Nên giới hạn chiều cao ô. |

## Pattern lỗi lặp lại

1. **Header và footer cố định kẹp vùng cuộn** (08, 09, 10, 11, 15, 20): `DeckContextHeaderWidget` và `MxFooterBar` không phản ứng khi bàn phím mở. Không có golden nào chụp bàn phím.
2. **Nội dung người dùng bị giới hạn 1 dòng** (01, 05, 13, 22): `MxListRow` title/subtitle `maxLines: 1`, meta của hàng deck, `MxTagChip` giới hạn 140 dp, subtitle của `MxActionSheetCommandRow` (cắt cả cảnh báo merge tag).
3. **Hai CTA primary cùng lúc** (07, 08/09 Save ×2, 11, 14 resume, 01 unset + FAB). Quy tắc nên là một primary mỗi màn; hành động còn lại dùng outline/secondary.
4. **Khoảng cách đầu trang và giữa các khối không có mặc định** (04/06 empty và error dính app bar, 15 note dính section, 24 thiếu đệm): `MxScreenScroll` không có khoảng cách mặc định, nên mỗi màn tự thêm `SizedBox`.
5. **Hero lặp lại chi tiết** (13, 21, 22).
6. **Nội dung mặt thẻ cuộn im lặng** (16, 16a, 19, 20). `StudyScrollFadeWidget` có sẵn nhưng chỉ Guess và Match dùng.
7. **Hành động chỉ qua cử chỉ hoặc tự tiến** (16 Browse vuốt, 18 Guess tự chuyển sau 1,2 giây) trong khi Recall/Fill có nút Continue rõ ràng.
8. **Danh sách không lazy** (01, 04, 05, 06, 13).
9. **Thiếu golden chữ lớn, bàn phím và tiếng Việt.** Chỉ 9 màn có golden chữ lớn; không có golden bàn phím hay tiếng Việt. Vì vậy nhiều rủi ro trên chưa tái hiện được.

## Nên sửa ở shared component / design system

| Component | Sửa | Màn hưởng lợi |
|---|---|---|
| `MxFooterBar` + `MxAppShell` | Ẩn caption và banner phụ khi bàn phím mở | 08, 09, 11, 15, 20 |
| `DeckContextHeaderWidget` | Đưa vào đầu vùng cuộn thay vì cố định | 08, 09, 10, 11 |
| `MxListRow` | Thêm `titleMaxLines`, tự nới lên 2 dòng khi chữ ≥ 1.3; giới hạn dòng cho `meta` | 05, 13, 22, danh sách deck |
| `MxSettingsRow` | Chuyển trailing xuống dưới khi chữ ≥ 1.5; thêm `tone: destructive` cho Reset | 23, 24, 15 |
| `MxScreenScroll` | Khoảng đệm đầu trang mặc định và khoảng cách giữa các khối | 04, 06, 15, 24 |
| `StudyFaceCardWidget` | Luôn bọc `StudyScrollFadeWidget` | 16, 16a, 19, 20 |
| `SessionContextLineWidget`, `SessionFooterHintWidget`, `MxStudyTopBar` | Giới hạn 2 dòng; hạ trọng lượng context line; chip mode không bị cắt ở chữ lớn | Mọi mode học |
| `MxActionSheetCommandRow`, `MxTagChip` | Subtitle 2 dòng; nới giới hạn độ rộng tag | 05, các sheet |
| `MxWorkloadBreakdownLine` | Wrap không để dấu "·" treo cuối dòng | 01, 13 |
| `MxOptionRow` | Trạng thái read-only (đọc được, không mờ 0.38) | 02 |
| `StudyCtaRowWidget` | Một nút thì giữ bề rộng ổn định giữa các trạng thái | 16a, 19, 20 |
| Test | Golden chữ 2.0, 320 dp, `viewInsets` 300 dp và tiếng Việt cho mỗi màn Major | Tất cả |

## Thứ tự đề xuất

1. **[P1] `/impeccable adapt`**: bàn phím và chữ lớn cho form, wizard và Fill (pattern 1, 6), kèm golden bàn phím và chữ lớn.
2. **[P1] `/impeccable harden`**: nội dung dài và tiếng Việt: `MxListRow`, `MxSettingsRow`, bulk bar, footer Trash, breakdown line (pattern 2).
3. **[P1] `/impeccable layout`**: khoảng cách mặc định của `MxScreenScroll` và empty/error states (pattern 4).
4. **[P2] `/impeccable distill`**: giảm density ở Card list, Trash, Summary, Progress, Study home, màn khóa của Review algorithm (pattern 3, 5).
5. **[P2] `/impeccable clarify`**: copy "Schedules updated" sai ngữ cảnh khi phiên bị reset; Sync để lỗi cách xa hành động.
6. **[P2] `/impeccable polish`**: rà một lượt cuối sau khi sửa.


## Chỉ mục màn

| Màn | Severity | Density |
|---|---|---|
| 01 Deck list (Library root + deck level, sort/filter, reorder, unset/empty, action sheet, dialogs) | Major | Balanced |
| 02 Review algorithm & reset | Major | Too Dense |
| 03 Starter decks | Minor | Balanced |
| 04 Tìm kiếm thư viện (Library search) | Minor | Balanced |
| 05 Thẻ (Tags) | Minor | Balanced |
| 06 Thùng rác (Trash) | Major | Too Dense |
| 07 Card list (kèm sheet/dialog, bulk mode) | Major | Too Dense |
| 08 Card create | Major | Balanced |
| 09 Card edit | Major | Too Dense |
| 10 Card detail | Minor | Balanced |
| 11 Card import | Major | Too Dense |
| 12 Card export (sheet) | Minor | Balanced |
| 13 Study home | Major | Balanced / Too Dense |
| 14 Study entry (+ Direction sheet) | Minor | Balanced / Too Empty |
| 15 Study options | Minor | Balanced |
| 16 Study · Browse | Major | Balanced |
| 16a Study · Self-check | Major | Balanced |
| 17 Study · Match | Major | Balanced / Too Empty |
| 18 Study · Guess | Major | Balanced |
| Shell phiên học (StudySessionScreen, MxStudyTopBar, exit dialog, footer hint, context line) | Major | Balanced / Too Dense |
| 19 Study · Recall | Major | Balanced |
| 20 Study · Fill | Major | Balanced / Too Dense |
| 21 Session summary | Minor | Too Dense |
| 22 Progress (overview + deck progress) | Minor | Balanced |
| 23 Settings | Minor | Balanced |
| 24 Daily reminder (+ time dialog) | Major | Balanced |
| 25 Theme | Minor | Too Empty |
| 26 Language | Minor | Too Empty |
| 27 Sync | Minor | Too Empty |
| App shell (bottom nav, tablet rail, cột 720dp, route not found) | Minor | Balanced |

# Chi tiết từng màn

### 01 Deck list (Library root + deck level, sort/filter, reorder, unset/empty, action sheet, dialogs)
- **Layout break risks:**
    1. Meta của hàng deck cắt ở 2x text: `library_decks_2x_light.png` cho "2 sub-decks · …" (deck_row_widget.dart:~85 `maxLines:1` + ellipsis). Tiêu đề + badge "N due" ở cùng một Row (dòng ~70-80): badge không co, tên deck dài (tiếng Hàn/Việt) bị nén còn vài ký tự; ở 2x tên còn "Korean" sát badge. Số thẻ, số con — thông tin chính của hàng — bị giấu.
    2. Dòng breakdown "3 overdue · 1 today · 2 new · 1 sched…" cắt ellipsis ngay ở 1x trên `library_deck_open_light.png`, `library_deck_actions_light.png` (mất "scheduled"; đã ghi nhận trong detail file nên chỉ báo là ở 1x cũng cắt, tiếng Việt sẽ cắt sâu hơn). Dòng due strip root cũng cắt ở 2x ("1 today…").
    3. Nút sort `MxChipTrigger` vẽ cao 28dp, `softWrap:false`: nhãn "Manual · Due only" (VN "Thủ công · Chỉ đến hạn") + tiêu đề "N SUB-DECKS" trong cùng Row có thể tràn ở 320dp/text lớn — risk (not reproduced). *(Đã kiểm: vùng chạm vẫn đủ 48dp nhờ `tapTargetSize: padded` trong `appButtonStyle`.)*
    4. `DeckLevelListWidget` (deck_level_list_widget.dart:~120) dựng `Column(for tile ...)` trong `MxScreenScroll` — không lazy/builder; thư viện hàng trăm deck build hết một lượt (chế độ reorder thì dùng `ReorderableListView.builder`, nên hai chế độ không nhất quán). Risk hiệu năng, không reproduced.
    5. Chế độ reorder (`library_reorder_light.png`): vẫn hiện ô Search dạng trigger (tap sẽ rời màn giữa lúc sắp xếp), mất due strip/header/sort; tay cầm kéo `=` ở ~40dp bên phải, không có hint/instruction "kéo để sắp xếp". Người dùng chỉ thấy nút Done.
    6. Action sheet (`library_deck_actions_light.png`) nội dung cắt sát đáy: hàng "Move to Trash" chạm mép dưới; sheet đã cuộn được (MxBottomSheet maxHeight 85% + child cuộn) nhưng không có dấu hiệu còn nội dung; với deck root có thêm Review algorithm/Reorder/Import/Export, 8-9 hàng ở 360x800 chắc chắn phải cuộn, hàng nguy hiểm (Trash) nằm cuối bị ẩn.
- **Information density:** Balanced — root: 1 strip + 1 header + hàng deck; nhưng mỗi hàng chứa tile+tên+badge+meta+thanh mastery+⋮ (6 phần tử) nên hàng deck hơi Dense; deck-level: summary card có donut + 3 dòng text + CTA + header + list là 5 vùng trước danh sách.
- **Visual hierarchy issues:**
    - Root: hai khối cùng "nặng" (search + due strip card) trước danh sách; due strip không tương tác (chờ FE-A8) nhưng trông như card bấm được, cạnh tranh với hàng deck. Không có CTA chính trừ FAB (FAB ẩn khi rỗng, đúng).
    - Deck-level: CTA "Study this deck · N due" đặt trong card, đúng, mắt nhìn thấy trước; nhưng "MASTERED · EIGHT BOXES" (caps) vs "2 sub-decks · 6 cards" (lớn hơn) đảo thứ bậc: nhãn caps nhỏ ở trên số liệu lớn, donut 17% nhỏ (chữ ~10sp) khó đọc — `library_deck_open_light.png`.
    - Trạng thái unset (`library_deck_unset_light.png`): vừa FAB "+" vừa empty state có 3 nút (New card/New sub-deck/Import) + note — hai lối vào cho cùng một việc, FAB là bản sao dư thừa.
    - Sort sheet (`library_sort_light.png`): "Only decks with due cards" là hàng toggle nằm sát footer Done, tiêu đề toggle 16sp lớn hơn tiêu đề các option row (không có header nhóm "Filter") — 2 nhóm không được phân định; căn lề toggle (40px) lệch với option rows (44px/126px).
- **Responsive / dynamic-content risks:** Tablet (`app_tablet_landscape_library_light.png`): cột giữa ≤720dp cách rail ~190dp trái, thanh mastery/hàng kéo dài trên 500dp — hàng chỉ có 3 dòng chữ ở trái và ⋮ ở xa phải, khoảng trắng lớn giữa; FAB trôi ở đáy cột, cách list ~500dp. Root rỗng: nội dung dồn nửa trên, nửa dưới trống (`library_empty_light.png`) — chấp nhận được (intentional). Phím: sheet cộng viewInsets đã xử lý (mx_bottom_sheet.dart), dialog dùng SingleChildScrollView — OK.
- **Cross-screen consistency issues:** Hint search "Search decks, cards, tags" trong golden trong khi detail file ghi "Search decks" (spec A11) — lệch tài liệu/code. Hàng deck 3 dòng + thanh mastery cao ~92dp so với hàng card-list/tag-list (2 dòng) — density khác nhau cho cùng kiểu danh sách. Reorder đổi meta thành "No cards yet" khác với browse ("1 sub-deck · 6 cards") — cùng deck hai chuỗi khác nhau (golden fixture, nhưng nếu là code thật thì nhất quán kém).
- **Recommended fixes:**
    1. Tên deck + badge chung Row, meta 1 dòng → ở text ≥1.5x mất số thẻ → cho meta `maxLines: 2` khi `MediaQuery.textScalerOf > 1.3` (hoặc bỏ maxLines hẳn) và cho badge xuống dưới tên (Wrap) → người dùng vẫn thấy số thẻ → sửa trong `deck_row_widget.dart` (Row tên → `Wrap`/hai dòng khi scale lớn), dùng token `AppSpacing`.
    2. Breakdown line cắt ở 1x → mất "scheduled" → dùng `Wrap` (MxWorkloadBreakdownLine cho wrap tại text lớn/VN) hoặc rút "N scheduled" thành "N later"; chỉ ellipsis khi ≥2 dòng.
    3. Nhãn sort không co → tràn ở 320dp/VN → cho tiêu đề `Expanded` + chip `Flexible` với ellipsis trong header danh sách.
    4. Reorder: ẩn `MxSearchField.trigger` khi `isReordering`, thêm `MxNote`/hint một dòng "Kéo ⋮⋮ để sắp xếp" dưới app bar → tránh rời màn nhầm và thiếu hướng dẫn.
    5. Deck unset: ẩn FAB khi `content type == unset` (đã có 3 lựa chọn trong empty state) → giảm hai lối vào trùng.
    6. Action sheet dài: thêm phân nhóm (Trash cách xa bằng `MxSectionDivider`/khoảng lớn) và giữ hàng Trash cuối; ở sheet có >7 hàng cân nhắc fade cuối để báo còn cuộn.
    7. Sort sheet: thêm `MxListSectionHeader` "Filter" trước hàng toggle để tách nhóm + căn lề giống option row.
    8. Danh sách deck lớn: chuyển sang `SliverList.builder` (MxScreenScroll với slivers) để thống nhất với reorder builder — cải thiện hiệu năng thư viện lớn.
- **Severity:** Major

### 02 Review algorithm & reset
- **Layout break risks:**
    1. Nút "Reset learning progress…" (deck_start_over_widget.dart, `MxButton outline` không block) bị ellipsis ngay ở 1x — `library_algorithm_locked_light.png` hiện "Reset learning progress…" chỉ rộng ~2/3 card, không full-width; tiếng Việt dài hơn sẽ cắt thêm hoặc wrap. Nút không `isBlock` nhưng label bị cắt dù còn chỗ trong card (do tính chiều rộng tự nhiên).
    2. Dialog Reset: hai `MxOutcomeTile` Kept/Lost đặt song song trong `IntrinsicHeight`+`Row` (deck_reset_dialog_widget.dart:~190). Ở 360dp mỗi tile ~150dp, chữ đã 5 dòng (`library_algorithm_reset_light.png`); ở 2x text/VN mỗi tile 12+ dòng, ép hẹp, và `IntrinsicHeight` tốn chi phí. Dialog cuộn được (MxDialog SingleChildScrollView) nhưng nút Cancel/Confirm cũng cuộn mất khỏi màn hình — hành động chính bị đẩy xuống.
    3. Dialog có hai nút xếp dọc full-width (Cancel + "Reset and start cycle 2") cao ~120px mỗi nút, chiếm gần 1/3 dialog.
- **Information density:** Too Dense — màn khóa có: breadcrumb + lock strip + header + 2 option row mô tả 4 dòng + note + header "Start over" + card reset (tiêu đề, 3 dòng mô tả, nút); nhắc đi nhắc lại cùng một thông điệp (lock strip, note "To change the algorithm now, reset…", card Start over đều nói cách đổi).
- **Visual hierarchy issues:** (a) Lock strip nền amber + tile cam đậm là điểm mắt đầu tiên — hợp lý cho trạng thái; nhưng hai option row bị disabled, mô tả (`library_algorithm_locked_light.png`) màu xám nhạt cỡ 2:1 — nội dung quan trọng (mô tả thuật toán đang dùng) gần như không đọc được, SM-2 đang chọn nhìn như "không chọn". (b) Nút reset outline nhỏ là hành động nguy hiểm duy nhất của màn nhưng nhìn như thứ yếu, không có cảnh báo tone; hiện nằm cuối cùng sau 2 lớp text lặp. (c) Ba khối text dài cùng cấp (note, reset body, option desc).
- **Responsive / dynamic-content risks:** Mô tả thuật toán 4 dòng ở 360dp (Eight boxes: "1·2·4·8·16·32·64·128 days…") → ~8-10 dòng ở 2x, VN dài hơn; màn cuộn được nên không vỡ, nhưng dồn vị trí nút reset xuống rất sâu. Dialog kèm bàn phím không có trường nhập → không ảnh hưởng. Breadcrumb 3 tầng với tên deck dài — MxBreadcrumb có ellipsis (thấy "sched…" kiểu cắt ở màn khác), risk (not reproduced).
- **Cross-screen consistency issues:** Màn có breadcrumb + app bar tiêu đề trùng nội dung ("Review algorithm" hiện ở cả app bar và tầng cuối breadcrumb — `library_algorithm_locked_light.png`), trong khi Starter decks/Trash không dùng breadcrumb. Hai dialog destructive: Move to Trash (`library_deck_delete_light.png`) và Reset dùng nút confirm primary (không destructive) — ghi nhận là quyết định (Trash recoverable), nhưng Reset mất tiến độ không phục hồi vẫn dùng màu primary → thiếu tín hiệu nguy hiểm.
- **Recommended fixes:**
    1. Tô tương phản trạng thái disabled quá thấp → mô tả thuật toán đang khóa không đọc được (WCAG 1.4.3 cho nội dung cần thông tin) → dùng `MxOptionRow` state "locked" thay vì disabled: giữ chữ `onSurfaceVariant` bình thường, chỉ bỏ ripple, hiện icon khóa nhỏ; token `colors.onSurfaceVariant`.
    2. Nút Reset bị cắt → mất nhãn ở VN → `isBlock: true` (hoặc bỏ dấu "…" khỏi nhãn và cho `MxButton` wrap 2 dòng như starter `_AddButton`) → bảo đảm đọc được toàn bộ nhãn.
    3. Kept/Lost side-by-side → chuyển thành cột dọc (`Column`) khi `textScaler > 1.3` hoặc chiều rộng <400dp; bỏ `IntrinsicHeight` → dialog ngắn hơn, không ép chữ.
    4. Gộp `MxNote` khóa vào lock strip (cùng một nội dung) → bớt 1 khối lặp, giảm mật độ.
    5. Reset là hành động phá hủy → dùng `MxButtonTone.danger` cho confirm của dialog Reset (đúng với BR: mất tiến độ) → tín hiệu đúng mức nguy hiểm.
    6. Bỏ tầng cuối breadcrumb trùng tên màn hoặc bỏ tiêu đề app bar lặp → giảm nhiễu đầu màn.
- **Severity:** Major

### 03 Starter decks
- **Layout break risks:** Thẻ template (`starter_template_card_widget.dart`) nhìn chung tốt: tiêu đề `Wrap`, badge rơi xuống dòng khi đầy, `_AddButton` tự đổi cỡ theo `naturalWidth`. Rủi ro: `Text(entry.title, style: contentTitle)` không có `maxLines` — tiêu đề dữ liệu dài (fixture đã 2 dòng ở 360dp: "English → Vietnamese · Everyday") có thể chiếm 3-4 dòng ở 2x, vẫn trong Wrap nên không tràn (risk chỉ là chiều cao). Facts `footerCaption` không giới hạn dòng: an toàn. Sheet chọn thuật toán (`starter_choose_light.png`): tiêu đề `Add "Korean → Romanisation · Hangul basics"` 2 dòng chiếm ~90px; ở 2x và VN header có thể ăn hết 85% chiều cao, chỉ child cuộn nhưng header cố định — nguy cơ hết chỗ cho danh sách option và footer (risk, not reproduced).
- **Information density:** Balanced — nhưng mỗi thẻ có 6 phần tử: tile, tiêu đề, badge, facts, nút, "Suggests …"; note fixture đầu màn chiếm 3 dòng ~190px trước nội dung đầu tiên.
- **Visual hierarchy issues:**
    - Thẻ đã trong thư viện ("In library") vẫn có nút chính đặc `Add another copy` cùng cấp với thẻ chưa thêm (`starter_list_light.png`): hai CTA filled y hệt nhau → mất phân biệt "chưa có" và "đã có"; lặp lại hành động thứ cấp (bản sao thứ 2) thành primary.
    - Nút CTA nhỏ, canh trái theo indent 90px, còn ~40% chiều rộng thẻ bỏ trống; "Suggests Eight boxes" nằm dưới nút với chữ caption — thông tin quyết định (thuật toán gợi ý) yếu hơn nút.
    - Note "practice fixtures for development and testing" khung viền nổi chiếm vị trí đầu nhưng không có hành động — nặng hơn cần với người dùng cuối (chỉ là cảnh báo build dev).
- **Responsive / dynamic-content risks:** Màn trống rất nhiều (chỉ 2 thẻ: `starter_list_light.png` để ~25% dưới màn trắng; `starter_none_light.png` card empty ở trên, 55% màn dưới trống) — intentional cho ít nội dung nhưng khi có 2 template, không có vùng neo. Tablet ≥600dp: cột ≤720dp chứa thẻ với nút nhỏ canh trái — khoảng trắng phải lớn (risk, chưa có golden tablet cho starter).
- **Cross-screen consistency issues:** Thẻ starter dùng `MxCard` padding lớn (~40px) khác hàng deck (padding gutter 16dp, tile 44 large) — tile `medium` 40 vs deck `large` 44, tiêu đề `contentTitle` (lớn hơn) vs `rowTitle` deck → cùng loại "hàng deck" nhưng kích thước/nhịp khác. `MxEmptyState` của starter-none có một nút, root-empty có 2 nút + footnote — chấp nhận. Header màn dùng `density: content` (title nhỏ, back button) đồng nhất với Algorithm.
- **Recommended fixes:**
    1. Nút của thẻ "In library" → thứ cấp → hai CTA đặc giống nhau khó phân biệt → dùng `MxButtonTone.tonal`/outline cho "Add another copy", giữ filled cho "Add to library" (widget `MxButton` tone).
    2. Note fixture → chiếm đầu màn → chuyển xuống cuối danh sách hoặc thu gọn 1 dòng (`MxNote` compact) để thẻ đầu vào ngay tầm mắt.
    3. Sheet: header 2 dòng → cắt tiêu đề với `maxLines: 2` + ellipsis (như deck action sheet) và đưa "N cards in M sub-decks" lên phụ đề nhỏ → chắc chắn còn chỗ cho option/footer ở text lớn.
    4. Thẻ: cho nút `isBlock` khi thẻ hẹp (<360dp) hoặc căn lề nút bằng lề tiêu đề (đã thế) — cân nhắc đặt "Suggests …" cạnh thuật toán trong facts thay vì dòng riêng để giảm 1 hàng.
- **Severity:** Minor

### 04 Tìm kiếm thư viện (Library search)
- **Layout break risks:** (1) Trạng thái `no results` và `error` bọc trong `MxScreenScroll` mà không có `SizedBox(height: AppSpacing.control)` đầu trang như `idle/loading/results` (`search_body_widget.dart:~60-85` so với `search_hints_widget.dart:22`, `search_results_widget.dart:52`). Golden `search_no_results_light.png`: card empty-state dính sát đáy app bar (khoảng cách ~0 dp), trong khi golden `search_results_light.png` có khoảng thở. (2) `MxSearchField` cao 52 trong app bar 56 (đã ghi ở Deviations) nên chỉ còn ~2 dp lề trên/dưới; golden `search_results_light.png` thấy viền field gần chạm mép trên. (3) Hàng thẻ chỉ 1 dòng tiêu đề, `searchPairTitle` bị ellipsis; khớp ở mặt sau của thẻ dài bị cắt (đã ghi D22, chỉ nhắc lại rủi ro với tiếng Việt/Hàn dài: người dùng thấy kết quả mà không thấy chỗ khớp). (4) Nhiều kết quả: `SearchResultsWidget` dựng cả `Column` không lazy; an toàn vì có phân trang "Load more" nên chỉ là rủi ro nhỏ (risk, not reproduced) với trang lớn. (5) Font scale 2.0: `meta` của hàng thẻ là `Row` gồm chip tag + path `softWrap:false` – chip có `_maxWidth 140` (mx_tag_chip.dart:20) nên path còn rất ít chỗ; chưa có golden large_text để xác nhận (risk, not reproduced).
- **Information density:** Balanced — kết quả rõ, mỗi hàng 2 dòng; khối đầu trang hơi nặng (2 overline liên tiếp).
- **Visual hierarchy issues:** Hai header overline xếp liền nhau "RESULTS FOR “HỌC”" rồi "DECKS 1" (`search_results_widget.dart:53-59`, golden `search_results_light.png`) – cùng kiểu chữ, cùng trọng lượng nên mắt không biết đâu là nhãn nhóm; dòng "Results for" lặp lại đúng từ khóa đang nằm ngay trong ô tìm kiếm. Footer caption "Decks first, then cards · case-insensitive…" là chú thích cấu hình cho người dùng mới, nằm dưới danh sách như dữ liệu, tạo nhiễu. Trạng thái idle: ~55% màn hình trống bên dưới `MxNote` (golden `search_empty_query_light.png`), không có mục tiêu hành động (không có "tìm gần đây"); chấp nhận được vì cố ý (BR-SEARCH-003) nhưng vẫn là khoảng trống không có điểm neo.
- **Responsive / dynamic-content risks:** Bàn phím: field nằm trên app bar nên không bị che; danh sách cuộn được (`MxScreenScroll`) nên OK. Tablet ≥600 dp: cột 720 dp căn giữa của shell, không thấy vấn đề. Load-more-failed: `MxInlineBanner` có Retry ở dưới cùng danh sách dài (golden `search_load_more_failed_light.png` bị cắt ở đáy) – người dùng phải cuộn hết ~50 hàng mới thấy lỗi (banner không sticky).
- **Cross-screen consistency issues:** Các state đầu trang không nhất quán về khoảng cách (xem trên) – cùng lỗi này lặp ở Trash `empty` và `error`. Search field ở đây trắng, viền primary, nằm trong app bar; ở Tags (05) là field xám đặt trong body → hai cách dùng `MxSearchField` khác nhau. Hàng kết quả ở đây nằm chung một `MxCard` có divider; Trash dùng mỗi entry một card riêng (`trash_entry_row_widget.dart`), Tags dùng `MxSection`.
- **Recommended fixes:**
    1. Thiếu spacer đầu trang ở `SearchScreenNoResults`/`SearchScreenFailed` → card empty/error dính app bar, lệch với các state khác → thêm `const SizedBox(height: AppSpacing.control)` (hoặc đưa spacer vào `MxScreenScroll` mặc định top padding) cho mọi state.
    2. Hai overline liền nhau + lặp từ khóa → nặng đầu trang, hạ ưu tiên nhóm → bỏ `searchResultsFor` khi ô tìm kiếm đã hiển thị từ khóa (hoặc gộp vào `MxListSectionHeader` của nhóm đầu bằng `MxBadge`), giữ header nhóm là điểm nhấn.
    3. Banner load-more lỗi nằm cuối danh sách dài → khó thấy → khi `more == failed`, đẩy `MxInlineBanner` lên ngay dưới hàng cuối (đã vậy) và thêm snackbar `showMxSnackbar` có nút Retry một lần, hoặc đảm bảo scroll-to-end khi lỗi.
    4. Chip tag 140 dp + path không wrap ở scale lớn → mất đường dẫn deck → khi `textScaler > 1.3` chuyển `meta` sang `Column` (chip trên, path dưới) hoặc để path `Flexible` với `maxLines: 2`.
- **Severity:** Minor

### 05 Thẻ (Tags)
- **Layout break risks:** (1) `TagRowWidget`: `MxListRow` `maxLines: 1` (mx_list_row.dart:131) cắt tên tag tới 50 ký tự; golden `tags_loaded_light.png` "Cấu trúc thường gặp trong …" bị cắt dù còn ~70 px trống bên phải trước nút ⋮ – người dùng không phân biệt hai tag chung tiền tố dài (chỉ mở sheet mới thấy tên đầy đủ, vì sheet chip `MxTagChip` cũng `_maxWidth 140`, `maxLines:1` → tên tag dài vẫn bị cắt ở cả sheet và dialog merge: `mx_tag_chip.dart:20,41`). (2) `MxActionSheetCommandRow` `maxLines: 1` (dòng 100): golden `tags_sheet_light.png` "Renaming onto an existing name merges t…" bị cắt mất nội dung cảnh báo merge – thông tin quan trọng; tiếng Việt dài hơn sẽ cắt nhiều hơn. (3) Toàn bộ màn hình là một `MxScreenScroll` với `MxSection` dựng tất cả tag (không builder) – thư viện có hàng trăm tag sẽ dựng hết (risk, not reproduced); ô tìm kiếm cuộn đi cùng danh sách (`tags_screen.dart:~127-133`), không ghim. (4) Dialog rename/merge: `MxDialog` có `SingleChildScrollView` (mx_dialog.dart:106) nên bàn phím không gây overflow, nhưng ở dạng merge cao ~500 dp (golden `tags_rename_merge_light.png`), khi bàn phím mở hầu như chỉ còn field+nút lộ ra, phải cuộn để thấy panel cảnh báo trước khi bấm "Merge tags" (risk, not reproduced).
- **Information density:** Balanced — mỗi hàng 2 dòng ~66 dp, hơi cao cho một danh sách chỉ có tên + số thẻ nhưng chấp nhận được; dialog merge hơi dày (5 khối: tiêu đề, mô tả, nhãn, field, gợi ý, panel).
- **Visual hierarchy issues:** Trong `tags_name_too_long_light.png` lỗi được báo hai lần (bộ đếm đỏ "61 / 50" và dòng lỗi đỏ "A tag name can be at most 50 characters.") trong khi field cũng đỏ – dư. Hàng tag: cả hàng và nút ⋮ mở cùng một sheet (`tag_row_widget.dart:33-39`) → hai điểm chạm cho một hành động, ⋮ không thêm giá trị. Trạng thái empty (`tags_empty_light.png`) vẫn hiện ô "Search tags" và nhãn "A→Z" dù không có tag để tìm/sắp xếp; CTA "Go to library" là nút primary đúng, nhưng phần dưới ~45% màn hình trống (chấp nhận được).
- **Responsive / dynamic-content risks:** Font scale 2.0: `MxListRow` với trailing 48 dp + tile leading còn lại rất ít chỗ cho tên (chỉ 1 dòng) – nên cho tên tối đa 2 dòng. Tablet: OK (cột giữa). Phần tách chip trong merge panel dùng `Wrap` (tốt). Tag tiếng Hàn/Việt xếp chồng dấu: line-height của `rowTitle` chưa xác nhận trên golden (không có golden large_text) – risk, not reproduced.
- **Cross-screen consistency issues:** Ô tìm kiếm là loại trong body (xám) còn Search (04) đặt trong app bar. Danh sách một `MxSection` dùng chung với Trash dùng card-per-item; khoảng cách đầu trang ở đây có `SizedBox(control)` nhưng empty/error của Search/Trash thì không. Sheet hành động ở đây dùng `MxActionSheetCommandRow` với subtitle 1 dòng, còn Trash actions sheet cần kiểm tra cùng mẫu.
- **Recommended fixes:**
    1. Subtitle 1 dòng cắt cảnh báo merge → người dùng bỏ sót hậu quả rename → cho `MxActionSheetCommandRow` subtitle `maxLines: 2` (thay đổi ở widget dùng chung) hoặc rút gọn copy `tagsRenameHint`.
    2. Tên tag bị cắt 1 dòng khi còn chỗ → khó phân biệt tag dài → `MxListRow` cho `titleMaxLines: 2` ở `TagRowWidget`, và tăng `_maxWidth` `MxTagChip` trong sheet/dialog (hoặc cho phép `maxLines: 2`).
    3. Ô tìm kiếm cuộn mất → với nhiều tag phải cuộn lên → ghim `MxSearchField` + header vào phần cố định phía trên và chỉ cuộn danh sách bằng `ListView.builder`/sliver.
    4. Lỗi độ dài hiển thị hai lần → nhiễu → bỏ bộ đếm đỏ ở nhãn khi đã có `errorText`, hoặc đưa số đếm vào `errorText` duy nhất (`tagsNameTooLong`).
    5. Ẩn ô tìm kiếm và "A→Z" khi `tags.isEmpty` (`tags_screen.dart` nhánh empty) → bớt điều khiển vô nghĩa.
    6. Bỏ ⋮ hoặc bỏ `onTap` của hàng (giữ một) → giảm mục tiêu chạm trùng lặp.
- **Severity:** Minor

### 06 Thùng rác (Trash)
- **Layout break risks:** (1) `TrashSelectionBarWidget` dùng hai `MxButton` `isSingleLine: true` chia flex 13:10 (trash_selection_bar_widget.dart:~30-46). Ở 360 dp mỗi nút ~150-170 dp gồm icon + "Restore (2)"/"Delete (2)" (golden `trash_selection_light.png` vừa khít). Tiếng Việt "Khôi phục (2)" / "Xóa vĩnh viễn (2)" dài hơn 30-40% và text scale 1.5-2.0 sẽ bị ellipsis hoặc tràn (risk, not reproduced; chưa có golden large_text). (2) Hàng entry (`trash_entry_row_widget.dart`) xếp 3 dòng + badge: tiêu đề `maxLines 1` cạnh badge "30 days left" bằng `Row` baseline; nếu tên dài + badge cảnh báo tiếng Việt ("Còn 2 ngày"), tên gần như biến mất. Dòng meta 2 dòng, origin `maxLines 1` cắt đường dẫn gốc (nơi khôi phục). (3) Toàn bộ danh sách dựng bằng `MxScreenScroll` + `for` (không lazy) – Trash có thể chứa hàng trăm entry trong 30 ngày (`trash_screen.dart:~172`, risk, not reproduced). (4) Empty/Error: `MxEmptyState` dính sát đáy app bar (golden `trash_empty_light.png`, card bắt đầu ngay dưới bar, không có `SizedBox(control)` như nhánh `_list`).
- **Information density:** Too Dense — mỗi entry ~95-110 dp với 3-4 dòng chữ + tile + badge + ⋮; đầu trang lại có `MxNote` 3 dòng + filter chips + header trước khi tới dòng đầu tiên (`trash_all_light.png`: hàng đầu bắt đầu ở y≈590/2000 ≈ 236 dp trên 800 dp; chỉ thấy ~4 entry).
- **Visual hierarchy issues:** Mắt đầu tiên rơi vào MxNote lớn (nền + viền + 3 dòng) thay vì danh sách; chú thích "Kept for 30 days…" là thông tin tĩnh chiếm ~70 dp trong khi mỗi hàng đã có "N days left". Trong hàng, icon tile căn giữa dọc còn tiêu đề ở đỉnh, tạo cảm giác lệch (golden `trash_all_light.png`: tile ở y≈710, tiêu đề y≈648). Badge cảnh báo chỉ tô màu khi <3 ngày, còn lại là chữ đậm xám cùng độ nổi với tiêu đề → "30 days left" tranh sự chú ý dù không khẩn cấp. Ở chế độ chọn, hàng "khác loại" bị mờ bằng `Opacity` (disabled) rất nhạt nhưng vẫn chiếm chỗ, kèm `MxNote` "Cards and decks can't be selected together" xuất hiện dưới cùng (golden `trash_selection_light.png`) – người dùng chỉ thấy lý do sau khi cuộn hết danh sách dài.
- **Responsive / dynamic-content risks:** Nút "Select" compact ở app bar: cần xác nhận chạm ≥48 dp (`MxButtonSize.compact`, golden cao ~80 px = 27 dp? thực đo ≈ 32 dp) – nhỏ hơn 48 dp (risk, cần đo); có thể đạt bằng hit-slop của `MxButton` nếu có. Text scale 2.0: mỗi hàng thành 6-7 dòng, header + note + chips chiếm gần hết viewport đầu tiên. Bàn phím: không có input. Footer `MxFooterBar` cố định dưới, có `Semantics` tốt.
- **Cross-screen consistency issues:** Card-per-entry (khoảng cách 8 dp) khác với Search/Tags dùng một `MxCard`/`MxSection` với divider → cùng dạng danh sách nhưng mật độ khác hẳn (Trash ~100 dp/hàng, Tags ~66 dp, Search ~65 dp). Thanh footer hai nút chia flex 13:10 khác các footer dùng `MxActionPair` cân bằng ở nơi khác (cần đối chiếu Card create/edit). Empty/error thiếu spacer đầu trang như Search 04.
- **Recommended fixes:**
    1. Hàng 3-4 dòng gây mật độ cao → gộp origin vào dòng meta (Card · deleted 4 minutes ago · Korean › Words) hoặc bỏ dòng origin khỏi danh sách (giữ trong sheet hành động) → giảm còn 2 dòng, thấy nhiều entry hơn; dùng `MxListRow` chuẩn.
    2. `MxNote` cố định to ở đầu → đẩy nội dung xuống → thu gọn thành một dòng phụ ở header ("Giữ 30 ngày") hoặc chỉ hiện `MxNote` lần đầu / dùng `MxInlineBanner` compact; `MxNote` đã có `state.isSelecting` ẩn nên logic sẵn.
    3. Footer hai nút single-line → tràn khi Việt hóa/scale lớn → cho `isSingleLine: false` và xếp dọc (`Column`) khi `textScaler > 1.3` hoặc rút nhãn ("Khôi phục" / "Xóa") kèm số đếm ở tiêu đề app bar (đã có "2 cards selected").
    4. Badge "N days left" luôn lớn → tranh hierarchy → chỉ hiển thị badge khi <7 ngày, còn lại chuyển vào dòng meta dạng chữ nhạt (`rowDescription`).
    5. Danh sách không lazy → dựng `SliverList.builder` trong `CustomScrollView` (đưa note/filter vào sliver đầu).
    6. Empty/error thiếu spacer → thêm `SizedBox(height: AppSpacing.control)`.
    7. Đặt `MxNote` "kind lock" lên trên danh sách khi đang chọn (ngay dưới header) → người dùng thấy ngay lý do hàng bị mờ.
- **Severity:** Major

### 07 Card list (kèm sheet/dialog, bulk mode)
- **Layout break risks:** Thanh bulk `CardBulkBarWidget` (`card_bulk_bar_widget.dart:21-52`) chia 5 ô `Expanded` (~72dp ở 360dp), nhãn `maxLines: 1` + ellipsis. Tiếng Việt ("Di chuyển", "Gắn thẻ", "Thùng rác") hoặc text scale 1.5-2.0 sẽ bị cắt thành "Thùng r…", mất nhãn của hành động phá huỷ (risk, chưa tái hiện; không có golden large_text cho bulk). Ở 320dp còn hẹp hơn. Banner lỗi bulk (`card_list_section_widget.dart:~283`) đặt ngoài vùng cuộn, cộng với bulk bar cố định làm vùng cuộn hẹp khi bàn phím/scale lớn. Filter chip (`card_list_toolbar_widget.dart:74`) cuộn ngang: chip "Tags" có thể nằm ngoài màn hình, không có dấu hiệu còn nội dung (fade/peek) — chưa tái hiện.
- **Information density:** Too Dense — trước khi thấy thẻ đầu tiên người dùng đi qua app bar, breadcrumb, thẻ tiến độ deck (vòng %, thanh 4 màu, legend, nút Study), chip lọc, header "Showing", rồi mới đến card (card_list_light.png: hàng đầu tiên bắt đầu ở ~58% chiều cao màn hình).
- **Visual hierarchy issues:** Thẻ tiến độ (~290dp) lớn hơn nội dung chính (danh sách). Có hai CTA mạnh: nút "Study this deck" đầy chiều ngang và FAB "+" cùng màu primary, FAB đè lên chip "Due today" và cờ của hàng cuối khi cuộn giữa chừng (card_list_light.png, hàng gamsahamnida: "Due t…" bị FAB che). Trong hàng, trạng thái (MASTERED/REVIEWING) là dòng thứ 3 tách xa front/back nên hàng cao ~82dp, ít hàng/màn hình.
- **Responsive / dynamic-content risks:** Hàng dùng `Text` 1 dòng cho front/back với ellipsis (tốt cho nội dung dài). Cột trailing (cờ + due chip) không co được: với scale lớn hoặc nhãn due dài ("Due today" tiếng Việt) chiếm chiều ngang của `Expanded` content, front bị ép còn vài ký tự (risk). Danh sách dùng `ListView(children:)` (`MxScreenScroll`) với toàn bộ hàng dựng sẵn ở `_children` — không phải builder; comment "built only in view" đúng cho ListView children eager? Thực tế `ListView(children)` vẫn tạo mọi widget cho tới windowSize (có phân trang cửa sổ `windowSize`), nên chấp nhận được nhưng không lazy thật (risk khi cửa sổ lớn).
- **Cross-screen consistency issues:** Selection app bar nút "Select all N" dùng `MxButton compact secondary`, trong khi màn khác dùng `MxIconButton`; chấp nhận. Bulk bar là 5 icon+nhãn tự vẽ (`_BulkCommand`) thay vì `MxFooterBar` như editor — hai kiểu thanh đáy khác nhau (không viền nút, không caption).
- **Recommended fixes:**
    1. Bulk bar nhãn bị ellipsis → mất nghĩa hành động phá huỷ → cho nhãn `maxLines: 2` hoặc chuyển bar sang cuộn ngang/overflow menu khi `textScaler > 1.3` hoặc nhãn không vừa (`card_bulk_bar_widget.dart`), giữ tap target ≥48dp.
    2. Thẻ tiến độ chiếm quá nhiều chiều cao → đẩy danh sách xuống → thu gọn summary (bỏ legend hoặc gộp vào 1 dòng, nút Study nhỏ lại/`MxButtonSize.compact`) hoặc cho summary cuộn đi khỏi màn (đã cuộn) nhưng giảm padding; dùng token `AppSpacing.grouped`.
    3. FAB đè trailing của hàng → `MxScrollClearance.fab` chỉ chừa cuối danh sách → thêm padding phải cho trailing của hàng cuối hoặc dùng extended FAB ẩn khi cuộn; hoặc bỏ FAB khi đã có "Add card" trong empty/app bar menu.
    4. Cột trailing cố định → front bị ép ở scale lớn → cho `_Trailing` wrap xuống dưới nội dung khi `textScaler >= 1.5` (LayoutBuilder), hoặc đặt due chip vào dòng trạng thái (dòng 3) để giải phóng chiều ngang.
- **Severity:** Major

### 08 Card create
- **Layout break risks:** Footer `MxFooterBar` (Cancel + Save + caption, + banner lỗi) nằm trong cột thân `MxAppShell` nên đi lên cùng bàn phím (`Scaffold` resizeToAvoidBottomInset mặc định true). Khi bàn phím mở: app bar (~56) + `DeckContextHeaderWidget` (breadcrumb + hàng tên deck, ~100dp, ngoài vùng cuộn: `card_editor_form_widget.dart:324-334`) + footer (~130dp, ~200dp ở scale 2.0 hoặc khi banner lỗi) + bàn phím (~300dp) trên màn 800dp chỉ còn ~200dp cho vùng cuộn; ở 320x568 hoặc landscape gần như bằng 0 → không thấy ô đang gõ. Golden `card_editor_create_2x_light.png` (không có bàn phím!) đã cho thấy vùng cuộn chỉ còn ~55% màn hình, ô Back bị footer cắt ngang giữa ô và placeholder bị cắt "comma…". Breadcrumb ở 2x bị cuộn ngang cắt mất "Library ›" (cùng golden).
- **Information density:** Balanced — form ngắn, 2 trường bắt buộc + disclosure "Add details"; tuy vậy có 3 dòng "meta" trước ô đầu tiên (breadcrumb, tên deck, legend REQUIRED).
- **Visual hierarchy issues:** Nút Save xuất hiện HAI lần (app bar compact và footer "Save card") cùng trạng thái disabled → hai CTA chính cạnh tranh, không rõ nút nào chính (card_editor_create_light.png). Legend "REQUIRED" (overline đậm) trùng lặp với nhãn "Required" trên từng trường. Khoảng trống lớn ~25% màn giữa "Add tag" và footer là vô hại (form ngắn) nhưng cho thấy không cần footer đôi.
- **Responsive / dynamic-content risks:** Ô `term` và `meaning` tăng theo nội dung? (không xác minh min/max lines của `MxTextField`; ở 2x golden ô front bọc "gamsahamn/ida" giữa từ do chữ lớn — nhìn được, không tràn). Caption footer tiếng Việt dài sẽ bọc 2 dòng, đẩy footer cao thêm. Chip tag dài có `Flexible` + ellipsis (tốt). Hint ô "meaning" bị bọc/cắt ở 2x.
- **Cross-screen consistency issues:** Cùng pattern "app bar Save + footer Save" với các form khác? Cần đối chiếu (Tag/Deck editor) — nếu các form khác chỉ có một nút Save thì đây là ngoại lệ. Footer dùng `MxFooterBar` (nhất quán với màn commit khác), nhưng bulk bar list không dùng (xem 07).
- **Recommended fixes:**
    1. Footer + header cố định ăn hết chiều cao khi có bàn phím → vùng cuộn ≈ 0 ở màn nhỏ/scale lớn → khi `MediaQuery.viewInsetsOf(context).bottom > 0` ẩn caption và banner phụ của `MxFooterBar` (hoặc thu về một hàng nút), và đưa `deckContext` vào bên trong `MxScreenScroll` (đầu danh sách) như kit gốc thay vì header cố định (deviation §9 row 81 gây hậu quả thật ở đây); thêm golden/widget test với viewInsets 300dp + textScale 2.0 + 320dp.
    2. Hai nút Save → CTA mơ hồ, tốn chỗ → bỏ nút Save trong app bar (giữ footer) hoặc ngược lại; giữ một CTA chính duy nhất.
    3. Legend "REQUIRED" dư → thêm một dòng meta → bỏ `CardRequiredLegendWidget` vì mỗi trường đã có "Required".
    4. Breadcrumb 2x bị cắt đầu → dùng `MxBreadcrumb` cuộn tới cuối (đã cuộn) nhưng thêm ellipsis giữa (collapse ancestor thành "…") khi >3 cấp.
- **Severity:** Major

### 09 Card edit
- **Layout break risks:** Như 08 nhưng nặng hơn vì form dài: chèn `CardEditSummaryWidget` + 5 trường + tags + "Move to Trash" trong vùng cuộn còn lại sau header cố định + footer. Bàn phím + footer 3 lớp (banner lỗi + nút + caption) khi lưu thất bại có thể chiếm >50% màn hình. `card_editor_edit_light.png`: footer đã che ô Pronunciation ở trạng thái không có bàn phím, người dùng phải cuộn để thấy ô cuối; khi bàn phím mở ô Pronunciation/Tags gần như không tới được nếu không cuộn tay (Flutter tự cuộn ô focus vào view, nhưng vùng nhìn quá bé). Nút flag trong app bar và Save compact: ở scale 2.0 app bar `content` density cao lên, cộng title "Edit card" — không có golden large_text cho edit (risk).
- **Information density:** Too Dense — chồng: breadcrumb, deck row, summary lịch sử, legend, 2 trường bắt buộc, 3 trường tuỳ chọn luôn mở (edit không có disclosure), tags, thẻ "More/Move to Trash", footer với caption "Editing content never changes the schedule or history." (caption ngắn nhưng dài với tiếng Việt).
- **Visual hierarchy issues:** Hai Save (app bar + footer) như 08; thêm nút Flag ngay cạnh Save trong app bar. Summary lịch sử (thẻ full-bleed có chevron) trông như hàng có thể bấm nhưng thực chất mở màn detail và ĐÓNG editor — hành động phá luồng đang sửa (mất thay đổi chưa lưu? PopScope hỏi discard — hợp lý nhưng bất ngờ).
- **Responsive / dynamic-content risks:** Ô optional có placeholder dài bọc 2 dòng (hint ô Hint trong golden), OK. Tags: 10 chip dài bọc tốt. Tên deck dài: breadcrumb cuộn ngang, hàng deck ellipsis (ok). Trạng thái loading `MxSkeletonList` chung vẫn ok. Không có loi lỗi bố cục khác trong golden edit.
- **Cross-screen consistency issues:** Create mở "Add details" disclosure, Edit mở luôn — lệch có chủ ý (ghi trong 09). Ô optional trong edit dùng cùng `CardFieldWidget` nên nhất quán.
- **Recommended fixes:**
    1. Cùng fix 08-#1 (đưa `deckContext` vào vùng cuộn; thu footer khi có bàn phím) → ưu tiên cao nhất → người sửa thẻ dài mới nhìn được ô đang gõ.
    2. Bỏ nút Save thừa trong app bar hoặc footer → CTA rõ ràng.
    3. Chuyển "Move to Trash" xuống cuối và giữ ngoài tầm bàn phím (đã ở cuối) — giữ; nhưng đổi hàng summary thành text-only nếu không muốn mất luồng sửa, hoặc thêm chú thích "Opens details" (semantic hint).
    4. Thêm golden edit + large_text + keyboard để khoá hồi quy.
- **Severity:** Major

### 10 Card detail
- **Layout break risks:** Không thấy vỡ. `CardDetailContentWidget` cho front/back `Text` không giới hạn dòng (đúng vì màn đọc) và `_OptionalField` có `Expanded`; tag dùng `Wrap`. Nút Edit compact ở app bar có nhãn + icon: ở scale 2.0 + tiêu đề "Chi tiết thẻ" có thể chật (risk, chưa tái hiện). Header cố định (breadcrumb + hàng deck ~100dp) ngoài vùng cuộn: ở scale 2.0 breadcrumb đã cắt "Library" (xem golden 2x của editor cùng `DeckContextHeaderWidget`), chiếm nhiều chiều cao vùng nhìn.
- **Information density:** Balanced đến hơi dày — thẻ nội dung, thẻ "Current schedule" (thanh 8 hộp, 6 fact tile 2 cột), rồi lịch sử dài; card_detail_top_light.png: nội dung chính (front/back) chỉ chiếm ~15% màn, lịch trình chiếm ~35%.
- **Visual hierarchy issues:** Front (screenTitle) là điểm nhìn đầu tiên — tốt. Nhưng thẻ schedule lớn hơn thẻ nội dung, và fact tile 2 cột có giá trị bọc dòng bất đối xứng ("Eight boxes · cycle 1" bọc 2 dòng ở ô phải, khiến hàng cuối cao hơn: `card_detail_top_light.png`). Trạng thái `Reviewing` badge + cờ đen (không màu cảnh báo như ở list, nơi cờ màu warning) → cờ khác màu giữa list và detail.
- **Responsive / dynamic-content risks:** Fact tile 2 cột cố định ở 320dp/scale lớn: giá trị ngày dài ("29 tháng 9, 2026") sẽ bọc; nên chuyển 1 cột khi scale ≥1.5 (risk, chưa tái hiện, xem `card_schedule_widget.dart`). Ở tablet ≥600 dùng cột ≤720 chung của shell, ok.
- **Cross-screen consistency issues:** Cờ: đen ở detail/edit (app bar), cam ở list row → thiếu nhất quán tone (lý do §9 row 80: không có token streak). Header deck path cố định lặp lại giống 08/09 (nhất quán trong nhóm).
- **Recommended fixes:**
    1. Fact tile 2 cột → bọc lệch, chật ở scale lớn → chuyển 1 cột (hoặc `Wrap` với minWidth) khi `textScaler >= 1.3` trong `card_schedule_widget.dart`.
    2. Cờ khác màu list/detail → dùng cùng `semanticColors.warning` như `_Trailing` của `card_row_widget.dart` cho `AppIcons.flagged` trong content widget.
    3. Header path cố định chiếm chỗ ở scale lớn → đưa vào đầu vùng cuộn hoặc chỉ giữ breadcrumb 1 dòng.
- **Severity:** Minor

### 11 Card import
- **Layout break risks:** Đầu trang cố định quá cao: AppBar + breadcrumb + tên deck + step tracker nằm ngoài vùng cuộn (`card_import_screen.dart:97-104`, golden `import_source_light.png`: tracker kết thúc ~y=400/2000, tức ~20% màn hình), footer (2 nút + caption) chiếm thêm ~12% (`import_commit_bar_widget.dart:64-90`). Bước Source dạng paste: MxTextField `detail` tự cao lên nằm trong `MxScreenScroll` (`import_source_section_widget.dart:~215`), nhưng khi bàn phím mở (~300dp) trên máy 360x800 vùng cuộn còn ~200dp, trên máy 320x568 gần như bằng 0 (risk, not reproduced; không có golden có bàn phím). Ở `import_source_light.png` MxNote bị footer cắt ngay ở trạng thái mặc định (thấy "You will map columns to term, meaning," bị cắt) - người dùng phải cuộn chỉ để đọc ghi chú. Caption footer có thể 2 dòng tiếng Việt (`import_mapping_light.png` đã 2 dòng ở tiếng Anh) làm footer cao thêm ở font lớn.
- **Information density:** Too Dense — bước 1 xếp 4 khối (2 option card + empty-state card có CTA "Choose file" + note + footer CTA "Read and map columns") và có 2 nút chính cùng nghĩa: "Choose file" (xanh đặc) và "Read and map columns" (footer, đang disabled).
- **Visual hierarchy issues:** Ở `import_source_light.png` có hai nút primary đặc cùng lúc trên màn hình (Choose file trong thẻ và footer). Thẻ "Choose a file" option đã chọn + empty-state card bên dưới lặp lại cùng một hành động (chọn file) -> mắt không biết bấm đâu. Step tracker ở trạng thái nhỏ, chữ nhãn `stepLabel` nhỏ hơn breadcrumb; đỉnh trang có 3 tầng nhãn (title, breadcrumb, tên deck "Words") lặp thông tin ngữ cảnh.
- **Responsive / dynamic-content risks:** Tracker có LayoutBuilder chuyển sang Wrap khi font lớn (tốt) nhưng khi wrap thì càng chiếm thêm chiều cao vùng cố định -> ở text scale 2.0 phần cố định có thể > 50% màn hình (risk, not reproduced; không có golden large_text cho import). `ImportSourceSection` dùng `IntrinsicHeight` + Row 2 option (`:~95`) - hint tiếng Việt dài sẽ làm cả 2 thẻ cao lên, ở 320dp chữ bị bẻ nhiều dòng. Hàng mapping (`import_mapping_row_widget.dart:40-84`): `MxChipTrigger` không nằm trong Flexible, nhãn field tiếng Việt dài ("Ý nghĩa (mặt sau)") + tên cột 2 dòng có thể đẩy chip tràn ở 320dp/font lớn (risk, not reproduced). Source chip: tên file maxLines 2 ok.
- **Cross-screen consistency issues:** Footer 2 nút (Cancel outline + primary) khớp card editor nhưng ở màn kết quả (`import_partial_light.png`) đổi thành cặp 50/50 (`MxActionPair`) trong khi wizard dùng Cancel co theo nội dung - vị trí/độ rộng CTA chính nhảy giữa các bước. Màn kết quả có khoảng trống lớn (y 1360-1820, ~23% màn) nhưng là chủ ý vì footer ghim đáy.
- **Recommended fixes:**
    1. Vùng header cố định quá cao → bàn phím/font lớn làm mất vùng nhập → đưa `deckContext` + `ImportStepTrackerWidget` vào trong `MxScreenScroll` (hoặc thu gọn: chỉ giữ tracker cố định, breadcrumb cuộn cùng nội dung); ẩn caption footer khi `MediaQuery.viewInsets.bottom > 0`.
    2. Hai CTA chính cùng lúc ở bước Source → người dùng không rõ bấm đâu → hạ nút "Choose file" trong `MxEmptyState` xuống tone outline/secondary (hoặc bỏ actionLabel và để cả thẻ bấm được), giữ footer là primary duy nhất.
    3. MxNote bị footer che ở trạng thái mặc định → thông tin quan trọng ("nothing is added until you confirm") bị giấu → bỏ note lặp (đã có trong hint empty-state) hoặc gộp vào caption footer.
    4. Hàng mapping có thể tràn ở 320dp/font 2.0 → bọc `MxChipTrigger` trong `Flexible` và cho nhãn ellipsis, hoặc chuyển hàng sang Column (tên cột trên, chip block dưới) khi `textScaler > 1.3`.
    5. Thiếu golden large_text/keyboard cho import → thêm `import_source_paste_keyboard` và `import_*_large_text` để khoá hồi quy.
- **Severity:** Major

### 12 Card export (sheet)
- **Layout break risks:** Sheet dùng `MxBottomSheet` với header/footer, nội dung là Column trong sheet (`card_export_sheet_widget.dart:96-135`). Golden `export_deck_light.png` khớp (sheet ~64% chiều cao). Khi có banner lỗi + font 2.0 + tiếng Việt, tổng nội dung (header 2 dòng, banner, 3 hàng format 2 dòng, note 4-5 dòng, footer) vượt chiều cao; chưa xác nhận `MxBottomSheet` cuộn phần child (risk, not reproduced; không có golden large_text/failed ở 2.0). Badge "Recommended" nằm cạnh mô tả CSV làm mô tả bẻ dòng ("Comma-separated · opens / anywhere") - tiếng Việt sẽ 3 dòng.
- **Information density:** Balanced — 3 lựa chọn + 1 note + 1 CTA, gọn.
- **Visual hierarchy issues:** Tiêu đề, mô tả phạm vi, overline "FORMAT" rõ; CTA primary ở đáy đúng. Note nội dung (6 cột) ở dưới cùng khá dài so với vai trò phụ (4 dòng), hơi nặng hơn cần.
- **Responsive / dynamic-content risks:** Tên deck trong mô tả header ("Every card in {deck}…") không thấy maxLines; deck tên dài Hàn/Việt có thể đẩy header thành 4-5 dòng (risk). Nhãn nút "Export {n} cards" tiếng Việt kèm icon trong nửa chiều rộng ở 320dp có thể bị cắt.
- **Cross-screen consistency issues:** Lề nội dung 20dp có chủ ý (ghi trong 12-card-export.md); hàng option có divider full-bleed trong khi note/banner thụt vào - lề chưa thống nhất với các sheet khác (`import_option_sheet_widget` và `study_direction_sheet_widget` cũng full-bleed, nhất quán nội bộ nhóm này).
- **Recommended fixes:**
    1. Header dài với tên deck → thêm `maxLines: 2` + ellipsis cho mô tả, hoặc bỏ tên deck khi > 1 dòng.
    2. Nội dung có thể vượt chiều cao → xác nhận `MxBottomSheet` bọc child bằng `SingleChildScrollView` với footer ghim; thêm golden `export_large_text`.
    3. Note 4 dòng → rút ngắn copy hoặc giảm còn 2 dòng.
- **Severity:** Minor

### 13 Study home
- **Layout break risks:** Deck row (`study_home_decks_widget.dart:77`, `MxListRow` title `maxLines: 1` tại `mx_list_row.dart:131`): tên deck bị cắt cứng - `study_home_loaded_light.png` "Tiếng Anh giao tiếp hằng ng…" và `study_home_large_text_light.png` chỉ còn "IELTS Aca…" (tên deck mất nghĩa) khi font lớn, trong khi phần meta wrap thoải mái; badge "5 due" chiếm chỗ tiêu đề. Resume card: `Text(session.deckName, style: rowTitle)` không có maxLines/overflow (`study_home_resume_widget.dart:~63`) → tên dài tự do xuống nhiều dòng (risk, not reproduced) ; ở large_text icon pause căn dưới, lệch so với khối chữ 3 dòng (golden `study_home_large_text_light.png` y≈450-540 vs chữ y≈360-620). Meta workload có dấu "·" treo cuối dòng (loaded: "3 overdue · 2 today ·" rồi xuống dòng "4 new") - dấu chấm cuối dòng lẻ.
- **Information density:** Balanced ở màn thường; Too Dense ở đầu trang: Resume card + Workload hero (hai thẻ lớn) chiếm ~47% màn 800dp trước khi thấy danh sách deck, mỗi deck lại lặp breakdown overdue/today/new mà hero cũng vừa liệt kê.
- **Visual hierarchy issues:** Hai thẻ hero cạnh nhau: Resume (nút primary đặc "Resume") và Workload ("10 cards due" chữ lớn nhất) cạnh tranh làm điểm nhìn đầu; workload lại không có CTA (không biết "học 10 thẻ" ở đâu, phải chọn từng deck). Nhãn phụ ("5 overdue · 5 today · …") nhỏ hơn hẳn số hero và wrap 2 dòng. `study_home_no_decks_light.png`: thẻ empty co ~ 45% trên, ~55% dưới trống - chấp nhận được nhưng không có điểm neo dưới; tiêu đề "Study" chỉ chữ, không còn gì khác.
- **Responsive / dynamic-content risks:** Large text: chỉ 1 golden, thể hiện tốt hero; deck row mất tên (xem trên). Danh sách deck có phải builder không - `MxCard` full-bleed chứa `MxListRow` bên trong (`study_home_decks_widget.dart:49`) → nhiều deck (>100) build hết một lượt (risk, not reproduced). Tablet ≥600: cột 720 nên ổn.
- **Cross-screen consistency issues:** Deck row ở đây ("meta 3 thuật ngữ + icon, badge due") dày hơn hàng deck ở Library (01-deck-list) cho cùng một loại nội dung; nút "Library" là nút secondary compact ở header khối trong khi các danh sách khác dùng link/text action. Title "Study" dạng large title trong khi màn có AppBar khác (Import, Study entry) dùng AppBar content.
- **Recommended fixes:**
    1. Tên deck bị cắt cứng 1 dòng khi font lớn → mất khả năng nhận diện deck → cho `MxListRow.title` `maxLines: 2` (thêm tham số `titleMaxLines`) chỉ ở màn này, hoặc ≥1.3x scale.
    2. Dấu "·" treo cuối dòng ở `MxWorkloadBreakdownLine` khi wrap → nhìn lộn xộn → bỏ separator ở cuối dòng bằng Wrap không separator (dùng khoảng cách), hoặc đặt "·" đầu term kế tiếp.
    3. Resume deckName không giới hạn → có thể đẩy nút Resume xuống → `maxLines: 2, overflow: ellipsis`; căn icon `crossAxisAlignment.start`.
    4. Hai hero chiếm gần nửa màn → gộp Resume thành thẻ gọn hơn (ẩn thanh progress hoặc thu nhỏ) hoặc để hero workload là điểm chính và Resume thành hàng compact.
    5. Thêm golden large_text cho no_decks/zero và có ≥30 deck để kiểm tra builder.
- **Severity:** Major

### 14 Study entry (+ Direction sheet)
- **Layout break risks:** Không thấy overflow trong goldens sm2/resume/direction. Tiêu đề AppBar là tên deck (ellipsis trong AppBar?) và breadcrumb; deck tên dài + breadcrumb 4 cấp có thể wrap (risk, chưa có golden). Hero: nhãn overline "SM-2 · CARDS PER SESSION 20" là chuỗi dài, tiếng Việt sẽ wrap (risk). Learn row: mô tả 2 dòng + nút "Learn" cố định bên phải, tiếng Việt 3-4 dòng (risk).
- **Information density:** Balanced ở sm2 nhưng Too Empty ở `study_entry_sm2_light.png`: nội dung chỉ chiếm y 270-940 / 2000, khoảng trống ~40% màn giữa nội dung và footer; ở `study_entry_resume_light.png` đầy hơn nhưng có 3 nơi có CTA (Continue, Learn, footer).
- **Visual hierarchy issues:** Ở state resume có hai nút primary đặc: "Continue" (trong thẻ) và "Start a new review instead" (footer, cũng primary đặc, nhãn dài) → hành động phá hủy (kết thúc phiên cũ) lại mang trọng lượng lớn hơn/ngang "Continue"; người dùng dễ bấm nhầm. Nút "Learn" nhỏ tone secondary ở hàng "Learn new cards" đúng thứ bậc. Ở sm2 CTA "Review 4 due cards" rõ ràng.
- **Responsive / dynamic-content risks:** Footer + caption ghim đáy tốt; font 2.0 - hai thẻ stat NEW/DUE boxed cạnh nhau (`study_entry_hero_widget.dart:45-60`) giá trị lớn + nhãn viết hoa có thể tràn ở 320dp (risk, không golden large_text cho entry). Direction sheet: hàng option full-bleed, note 3 dòng, ok; sheet che phần nền nhưng có thể cao > 60% ở tiếng Việt/font lớn (risk).
- **Cross-screen consistency issues:** Thẻ hero có viền + nền tint (giống Workload hero của Study home) - nhất quán; nhưng Direction sheet dùng `MxOptionRow` lề full-bleed trong khi export sheet dùng lề 12+20 (thụt) → hai sheet radio cạnh nhau có lề khác nhau. Header entry (AppBar + breadcrumb + hero) khớp card import (breadcrumb) tốt.
- **Recommended fixes:**
    1. Resume: hai CTA primary → nhầm hành động → đổi footer "Start a new review instead" thành tone `outline`/secondary khi có phiên resume (`study_entry_footer_widget.dart`), giữ Continue là primary duy nhất.
    2. Khoảng trống lớn ở sm2 → thiếu neo trực quan → chấp nhận (footer ghim) hoặc đưa footer CTA lên ngay sau thẻ trong màn cao; tối thiểu không thêm nội dung giả.
    3. Overline hero dài → cho `Text` overline `maxLines: 2` và bỏ "CARDS PER SESSION 20" thành chip riêng.
    4. Thêm golden large_text cho entry (sm2, resume) và direction sheet để kiểm chứng tile NEW/DUE và footer.
- **Severity:** Minor

### 15 Study options
- **Layout break risks:** Không thấy tràn. `MxScreenScroll` cuộn được; footer `MxFooterBar` cố định nên khi bàn phím mở (nhập số vào `MxStepper`) footer + caption có thể ăn hết chiều cao ở 320dp / cỡ chữ 2.0 (rủi ro, chưa tái hiện; chưa có golden large_text cho màn này). `study_options_form_widget.dart` `wideControl` Column chứa stepper + `MxFieldMessage` — message dài tiếng Việt sẽ wrap, ổn.
- **Information density:** Balanced — 3 khối (toggle, 2 dòng tuỳ chọn, note) + footer; hơi nhiều note (MxNote đầu trang + note "Changes apply…" cuối section).
- **Visual hierarchy issues:** (1) Trong `study_options_override_light.png` MxNote "These options belong to…" dính sát ngay trên card "Use app defaults" (khoảng cách ~0-2dp giữa note và card, y≈405 so với 260-405), trong khi các section khác cách nhau ~48px — nhịp spacing lệch. (2) Stepper (−/50/+) căn giữa-trái lệch so với cột text (thụt vào x≈235, text bắt đầu x≈220) và không thẳng hàng với segmented tray bên dưới (x=220) — control không neo cùng lề. (3) Khoảng trống lớn giữa note cuối và footer (y 1580–1760) là vô hại, nội dung ngắn.
- **Responsive / dynamic-content risks:** Tên deck gốc dài trong `MxNote` và breadcrumb: breadcrumb đã cuộn/cắt (chưa kiểm tra chi tiết, thuộc `MxBreadcrumb`). Không thấy maxLines cho subtitle "Following Settings · {n} cards, {order}" — wrap, ổn. Tablet: dùng cột giữa, không vấn đề.
- **Cross-screen consistency issues:** Cùng pattern với màn 23 Settings (đã ghi nhận, ruling M3-E1). Stepper căn trái nội dung trong hàng nhưng Settings cũng vậy — nhất quán. Khoảng cách MxNote→MxSection khác các MxSection→MxSection.
- **Recommended fixes:**
    1. MxNote không có margin dưới → card "Use app defaults" dính sát → trông như một khối lỗi → thêm `AppSpacing.grouped` giữa MxNote/MxInlineBanner và MxSection (trong `MxScreenScroll` spacing hoặc bọc note bằng padding dưới).
    2. Stepper thụt 15px so với lề text → điều khiển không thẳng cột → căn `MxStepper` start-aligned với label (bỏ padding thừa / `Align` start) để cùng lề x với `MxSegmentedTray`.
    3. Không có golden large_text → thêm golden 2.0x cho override/invalid để chốt hành vi footer + bàn phím.
- **Severity:** Minor

### 16 Study · Browse
- **Layout break risks:** `_Half` bọc `SingleChildScrollView` trong `Expanded` nên term/meaning dài cuộn được, không tràn; nhưng mỗi nửa cuộn riêng trong một thẻ đang có `GestureDetector` vuốt ngang — cuộn dọc và vuốt ngang cùng thẻ ổn về hướng, nhưng không có dấu hiệu "còn nội dung" (không có `StudyScrollFadeWidget` như Guess/Match) → nội dung dài bị cắt im lặng (`study_browse_widget.dart` `_Half`). Nhãn TERM/MEANING nằm ngoài vùng cuộn, tốt. Badge "Looking back" `Positioned` góc phải có thể chồng lên nhãn TERM khi chữ lớn (rủi ro, chưa tái hiện; không có golden large_text cho Browse).
- **Information density:** Balanced — hai nửa thẻ, hint 1 dòng.
- **Visual hierarchy issues:** Trong `study_browse_light.png` thẻ chiếm gần hết màn hình, mỗi nửa chỉ có 1–2 dòng chữ nằm giữa (khoảng trống ~350px trên/dưới mỗi nửa) — đây là ý đồ (thẻ mặt kép), nhưng khối hint cuối ở x≈45 icon `>>` tách xa text 2 dòng, icon căn giữa dọc dòng đầu trông lệch. Không có CTA nhìn thấy: hành động chính (vuốt) chỉ được gợi ý bằng một dòng chữ nhỏ; không có nút "Next" cho người không vuốt được (chỉ có custom semantics action) — vi phạm khả năng tiếp cận thao tác thay thế (WCAG 2.5.1 single-pointer alternative).
- **Responsive / dynamic-content risks:** Hint dài tiếng Việt (~+30%) sẽ wrap 3 dòng (đã thấy 2 dòng ở tiếng Anh) → ăn chiều cao thẻ. Ở 2.0x, hai nửa mỗi nửa ~1/2 chiều cao còn lại rất nhỏ → cuộn trong cuộn.
- **Cross-screen consistency issues:** Self-assess (16a) và Guess dùng `StudyFaceCardWidget` + CTA/hint; Browse dùng `MxCard` tự dựng `_Half` — padding nhãn (`AppSpacing.gutter` trên) khác nhau chút, nhưng ảnh golden nhìn thấy đồng nhất. Browse không có nút hành động trong khi 16a có `StudyCtaRowWidget`.
- **Recommended fixes:**
    1. Chỉ có vuốt để tiếp tục → người dùng không vuốt được (TalkBack đã có custom action, nhưng Switch Access/tap-only thì không) → thêm `MxButton(size: study)` "Next" trong `StudyCtaRowWidget` (đã có) như 16a, hoặc chạm nửa dưới.
    2. Nội dung dài cuộn im lặng → bọc mỗi nửa bằng `StudyScrollFadeWidget` (đã dùng ở Guess/Match).
    3. Thiếu golden large_text/long text → thêm.
- **Severity:** Major

### 16a Study · Self-check
- **Layout break risks:** Ổn ở 1.0. Ở 2.0 (`study_self_assess_large_text_light.png`): chip mode bị cắt "SELF-A…" (ellipsis trong `MxStudyTopBar`, tên mode không đọc được đầy đủ, dù context line bên dưới nhắc lại); hai thẻ mặt bằng `Expanded` cùng nhau nên thẻ TERM/MEANING chỉ vừa khít nội dung (không có vùng cuộn: `StudySelfAssessWidget` dùng `Expanded(child: prompt)` không có `SingleChildScrollView`) → term dài / example dài ở 2.0 sẽ overflow hoặc bị cắt (rủi ro, kiểm tra `StudyFaceCardWidget` chưa thấy scroll). Hàng grade 4 nút xếp 2x2 ở 1.3+ (tốt), nhưng nút Again/Hard cao khít chữ "Again/1d" (sát viền trên/dưới ở ảnh large).
- **Information density:** Balanced.
- **Visual hierarchy issues:** Ở `study_self_assess_revealed_light.png` 4 nút grade có cùng trọng lượng, chỉ Again có tint đỏ; thẻ answer nền xám nhạt có viền — hierarchy ổn. Khoảng trống lớn trong mỗi thẻ (prompt: ~300px trên/dưới chữ) là chủ ý. Nút grade 48dp ở 1080 = ~120px cao, đạt.
- **Responsive / dynamic-content risks:** Ở 320dp, 4 nút grade cạnh nhau mỗi nút ~68dp rộng, nhãn "Again"/"Khó" ổn nhưng interval "24d" tiếng Việt "24 ngày" có thể wrap (rủi ro, chưa tái hiện). Footer hint wrap 2 dòng ở 2.0 (thấy trong ảnh).
- **Cross-screen consistency issues:** Grade row của 16a (4 nút chip nhỏ, ~62dp cao) khác `MxButton(size: study)` ở Show answer (nút lớn 160 rộng) — chiều cao/kiểu nút chính thay đổi giữa 2 trạng thái cùng vị trí (`study_self_assess_prompt` vs `revealed`), CTA "nhảy" hình dạng.
- **Recommended fixes:**
    1. Thẻ mặt trong `Expanded` không cuộn → term/example dài ở chữ 2.0 bị cắt → bọc nội dung `StudyFaceCardWidget` bằng `SingleChildScrollView` + `StudyScrollFadeWidget` như Guess.
    2. Chip mode ellipsis ở 2.0 → mất nhãn → nâng `_badgeShare` lên khi text scale ≥1.5 hoặc cho chip wrap 1 dòng bằng FittedBox scaleDown (`MxStudyTopBar`).
    3. Nút Show answer vs grade khác kích thước → thống nhất chiều cao (cùng `MxButtonSize.study`) hoặc để grade dùng cùng chiều cao.
- **Severity:** Major

### 17 Study · Match
- **Layout break risks:** `_Tile` nằm trong `Row` của `Expanded` rows trong `SliverFillRemaining(hasScrollBody:false)`: chiều cao mỗi hàng chia đều theo tổng intrinsic, nên một tile có meaning dài (nhiều dòng) có thể vượt phần chia của hàng và bị cắt/overflow (rủi ro, chưa tái hiện; golden chỉ có từ ngắn). Ở `study_match_large_text_light.png` hàng thứ 5 (tip/tiền boa) bị cắt bởi fade ở đáy khi cuộn — đúng thiết kế nhưng chỉ ~40% hàng cuối thấy được, và người dùng không thấy dấu hiệu rõ ràng ngoài fade mờ. Context line chiếm 3 dòng ở 2.0 (~90px/dòng), đẩy bảng xuống.
- **Information density:** Balanced — 10 tile là đúng thiết kế; mỗi tile ~150dp cao ở 1.0 khá rộng với 1 từ ngắn (`study_match_board_light.png`: chữ nhỏ giữa ô lớn), gần "Too Empty" bên trong tile nhưng được chủ đích để vùng chạm lớn.
- **Visual hierarchy issues:** Tile term đang selected (nền xanh đậm đặc "waiter") mạnh hơn nhiều so với matched (xanh nhạt) → mắt bị kéo vào tile đang chọn, hợp lý. Term (đậm) và meaning (thường) phân biệt chỉ bằng font weight; không có nhãn cột nên người mới có thể không biết cột nào là term (chỉ dựa vào hint dưới đáy).
- **Responsive / dynamic-content risks:** 320dp: mỗi cột ~140dp, tile Hàn/Việt dài dùng `StudyWholeWordTextWidget` (thu nhỏ để không cắt từ) — từ rất dài sẽ co rất nhỏ (rủi ro, chưa tái hiện). Bảng ít hơn 5 cặp: `Expanded` chia đều → tile giãn rất cao (1 cặp = 1 tile cao ~cả màn hình, cần kiểm tra; rủi ro visual emptiness).
- **Cross-screen consistency issues:** Tile idle padding `grouped/gutter` khác option Guess (`gutter/control`); hint icon dùng `AppIcons.check` cho cả Guess/Match/16a nhưng ý nghĩa khác nhau (check = hướng dẫn) — icon `>>` chỉ Browse. Hint 1 dòng ở 1.0 nhưng 2 dòng ở 2.0 giống các màn còn lại.
- **Recommended fixes:**
    1. Row `Expanded` chia đều không theo nội dung → tile dài bị cắt → dùng `IntrinsicHeight` hàng + `minHeight: 48` thay Expanded khi text scale > 1.3 hoặc để ScrollView tự cuộn với hàng có chiều cao theo nội dung (`ConstrainedBox(minHeight)`).
    2. Ít cặp (1–2) → tile khổng lồ → giới hạn chiều cao tile tối đa (vd. `AppSize` token) và căn giữa/đầu.
    3. Thêm nhãn cột nhỏ "Term / Meaning" (đã có l10n `studyBrowseTerm/Meaning`) hoặc nhấn mạnh phân biệt.
- **Severity:** Major

### 18 Study · Guess
- **Layout break risks:** Ổn ở 1.0 (`study_guess_idle_light.png`: face card giãn, 5 option đủ, hint 1 dòng). Ở 2.0 (`study_guess_large_text_light.png`): face card co còn ~430px, "reservation" gần chạm mép hai bên (từ dài hơn sẽ co nhờ `StudyWholeWordTextWidget`); 5 option ~140px mỗi cái, tổng vẫn cuộn được nhờ `SliverFillRemaining`; nhìn thấy đủ 5 option nhưng đã vào vùng fade — tốt. Option text `Text(option.meaning)` không có maxLines nhưng wrap — OK. Icon tick/x sát mép phải (x≈800) trong `_Letter` row — khoảng trắng đều.
- **Information density:** Balanced — 1 câu hỏi + 5 lựa chọn + hint, đúng cho quiz; face card chiếm ~45% màn hình (khoảng trống lớn quanh một từ) là chủ ý nhưng lấn vùng đáp án ở màn thấp (ở 320x568 sẽ ép rất mạnh, chưa tái hiện).
- **Visual hierarchy issues:** Trạng thái đã trả lời (`large_text`): option không liên quan bị fade nhạt (contrast thấp, ≈2:1) — chủ ý, nhưng chúng vẫn phải đọc được đáp án đúng; hint đáp án hiển thị 3 dòng ở 2.0 (`study_guess_large_text`: "Answer shown — the correct option is highlighted") chiếm ~200px, gần bằng một option. Tắt hold 1200ms tự tiếp tục: người dùng có tay chậm/TalkBack tắt vẫn bị chuyển thẻ tự động (WCAG 2.2.1 — có tap để tiếp tục nhưng người dùng không kịp đọc "correct answer" khi sai; chỉ có nút Next khi accessibleNavigation).
- **Responsive / dynamic-content risks:** Meaning dài tiếng Việt/Hàn nhiều dòng: mỗi option cao theo nội dung, tổng có thể vượt màn hình → cuộn (đã hỗ trợ). Khi bị chặn (`isBlocked`) `MxErrorState` với nút Close — ổn.
- **Cross-screen consistency issues:** Nút Next chỉ hiện với TalkBack; các mode khác (Recall/Fill) dùng Continue rõ ràng → Guess là mode duy nhất tự tiến sau 1.2s. Hint icon check nhất quán với 16a/17.
- **Recommended fixes:**
    1. Tự tiếp tục sau 1.2s ngắn khi trả lời sai → người đọc chậm không kịp thấy đáp án đúng → với đáp án sai nên giữ đến khi chạm (hoặc kéo dài hold, hoặc hiện nút `MxButton` "Next" cho mọi người dùng, như Recall/Fill).
    2. Hint thay đổi 3 dòng ở 2.0 chiếm chỗ → rút gọn copy `studyGuessHintAnswered` (l10n) hoặc `maxLines: 2`.
    3. Face card giãn không giới hạn → đặt `flex` nhỏ hơn / `ConstrainedBox(maxHeight)` để đáp án không bị ép trên màn thấp.
- **Severity:** Major

### Shell phiên học (StudySessionScreen, MxStudyTopBar, exit dialog, footer hint, context line)
- **Layout break risks:** `MxStudyTopBar`: chip mode giới hạn 40% chiều rộng và ellipsize (thấy "SELF-A…" ở `study_self_assess_large_text_light.png`); counter thu nhỏ bằng FittedBox nên "1 / 5" vẫn đọc được nhưng chữ nhỏ lại so với chip (ở 2.0 counter cùng cỡ chip, nút close thu nhỏ trông nhỏ hơn chữ — icon 24dp vs chữ 2x). `SessionContextLineWidget` không giới hạn dòng: 3 dòng ở 2.0 (~270px = 11% chiều cao màn) trong `study_match_large_text_light.png`/`study_guess_large_text_light.png`; tên deck rất dài sẽ đẩy nội dung học xuống thêm (rủi ro, chưa tái hiện). `SessionFooterHintWidget` wrap 3 dòng ở 2.0 (~200px) — hint là thông tin phụ nhưng ăn ~10% màn hình. Banner lỗi `turn.unsaved` chèn giữa context line và body làm co nội dung.
- **Information density:** Balanced ở 1.0; ở 2.0 chrome (top bar + context + hint) chiếm >30% màn hình → Too Dense về phần khung so với nội dung học.
- **Visual hierarchy issues:** Context line (overline in hoa, đậm, màu chữ chính) trông quá nổi so với vai trò phụ, cạnh tranh với thẻ (`study_match_board_light.png`: 2 dòng in hoa đậm ngay dưới top bar). Hint dưới đáy ở màu phụ, cỡ nhỏ — ổn. Nút close 48dp ở góc trái, thao tác thoát gần với vùng chạm chip — ổn. Exit dialog dùng `MxDialog` + `MxSheetActions` (Keep studying / Stop) chuẩn, không phát hiện lỗi (chưa có golden).
- **Responsive / dynamic-content risks:** Mode chip: nhãn tiếng Việt "Tự đánh giá" dài hơn → ellipsis sớm hơn. Ngang (landscape)/tablet: thẻ mode giãn theo cột 720dp — không có `ConstrainedBox` riêng trong shell (kiểm tra `MxAppShell`, chưa thấy) → face card cao ~90% màn hình trên tablet (rủi ro, chưa tái hiện).
- **Cross-screen consistency issues:** Top bar riêng cho phiên học so với `MxAppBar`: OK, nhất quán qua các mode. Context line + hint mỗi mode dùng cùng widget — nhất quán. Khoảng cách hint→đáy `gutter` đều.
- **Recommended fixes:**
    1. Context line dùng `overline` in hoa đậm, tối đa 3 dòng ở 2.0 → khung ăn chỗ nội dung → giảm trọng lượng (màu `onSurfaceVariant`), `maxLines: 2` + ellipsis (`SessionContextLineWidget`).
    2. Chip mode ellipsis mất nhãn → tăng `_badgeShare` theo text scale hoặc cho phép chip xuống hàng; `MxStudyTopBar`.
    3. Hint 3 dòng ở 2.0 → `maxLines: 2` hoặc ẩn icon để lấy chỗ; `SessionFooterHintWidget`.
    4. Trên ≥600dp giới hạn chiều rộng/cao thân phiên học (đã có cột ≤720dp; kiểm tra chiều cao thẻ) bằng `ConstrainedBox(maxHeight)` trong face card.
- **Severity:** Major

### 19 Study · Recall
- **Layout break risks:** `study_recall_widget.dart:~150-190` chia đôi chiều cao còn lại bằng 2 `Expanded` (Term / Meaning), mỗi face là `StudyFaceCardWidget` (`study_face_card_widget.dart:47-58`: label + `Center(SingleChildScrollView)`). Ở large text, golden `study_recall_large_text_light.png` cho thấy mặt Meaning bị cắt giữa câu ("sự đặt chỗ trước — / booking a table," rồi hết), không có dấu hiệu cuộn (không fade/scrollbar). Người dùng không biết còn nội dung bên dưới. Đồng thời thanh đồng hồ ở large text: caption "Revealed with time left" wrap 2 dòng, "20s / 20s" lệch dòng (golden, ~y=380-500). Bản dịch Việt của caption dài hơn sẽ wrap tương tự ở 1.0x.
- **Information density:** Balanced — 1 hành động chính rõ, footer hint ngắn.
- **Visual hierarchy issues:** Ở countingDown/revealed, hai face cao bằng nhau (~350dp mỗi face) nhưng nội dung chỉ 1-2 dòng → vùng trống lớn trong mỗi card (`study_recall_revealed_light.png`), mắt hướng vào term (đúng) nhưng "Meaning" vừa được lộ lại nằm nhỏ giữa khoảng trắng. Đồng hồ (4dp) xám trung tính ở top, khó nhận ra là thời gian gấp (chỉ đổi màu khi hết giờ).
- **Responsive / dynamic-content risks:** Từ/nghĩa dài (đoạn văn, chữ Hàn dài) dựa hoàn toàn vào scroll trong face nửa màn hình; màn 320x568 hoặc landscape: 2 face + clock + CTA + footer + banner "unsaved" (`study_session_screen.dart:~312-333`) chia ≈ 100dp/face — risk (not reproduced). Chưa có tablet ≥600dp constraint: face cao bất tận, chữ giữa nền trống.
- **Cross-screen consistency issues:** Nút "Show the meaning" đứng một mình, width tự nhiên, căn giữa (`study_cta_row_widget.dart:33 Center(child: only)`) trong khi Forgot/Remembered là 2 nút tối đa 160 → CTA nhảy kích thước giữa các trạng thái; Summary/Progress dùng CTA block full-width. Footer hint dùng icon check cho câu "Recall the meaning..." (icon không phản ánh nội dung).
- **Recommended fixes:**
    1. Face dùng chung chiều cao 1:1 dù nội dung ngắn → trống, nhưng nội dung dài bị cắt không báo → đặt `StudyScrollFadeWidget` (đã có ở `support/study_scroll_fade_widget.dart`) bọc `SingleChildScrollView` trong `StudyFaceCardWidget` → người dùng thấy còn nội dung; hoặc dùng `flex` theo nội dung (term nhỏ hơn meaning).
    2. CTA đơn lẻ → nhảy width → cho `StudyCtaRowWidget` với 1 action dùng `ConstrainedBox(maxWidth: 2*160+gap)` + `isBlock` để giữ chiều rộng ổn định giữa 3 trạng thái.
    3. Caption đồng hồ wrap ở large text → cho `RecallCountdownBarWidget` đưa "{s}s / 20s" lên cùng hàng bằng `Row` + `Flexible`/`Wrap`, hoặc `crossAxisAlignment: start` để số không lệch giữa dòng.
- **Severity:** Major

### 20 Study · Fill
- **Layout break risks:** Golden `study_fill_input_light.png` KHÔNG mô phỏng bàn phím, nhưng màn này mở keyboard ngay khi vào lượt (`study_fill_widget.dart:~71 requestFocus`). Bố cục 2 `Expanded` 1:1 + CTA + footer: trên 360x800 + IME ~300dp còn ~250dp cho 2 face (mỗi face ~120dp, trừ label+padding 2×16 → vùng nội dung ~60dp); khi có hint (thêm `_HintRow` trên `MxTextField`) hoặc Meaning dài, ô nhập bị đẩy vào scroll — risk (not reproduced, không golden nào có viewInsets). Ở 320x568 hầu như không còn chỗ. Large text golden (`study_fill_large_text_light.png`): Meaning bị cắt "seat or room in" giữa câu, không dấu hiệu cuộn; 2 nút xếp dọc + footer 2 dòng chiếm ~1/3 màn hình.
- **Information density:** Balanced (ở màn thường); Too Dense khi có bàn phím vì 5 khối (context line, 2 face, CTA, footer) cùng tranh không gian.
- **Visual hierarchy issues:** Ô nhập nằm giữa card Term rất cao (~350dp) với chữ "reserv" nhỏ ở giữa; không có viền/underline nào (`MxTextFieldVariant.study` borderless) → không rõ đây là ô nhập, chỉ có caret nhấp nháy (golden input). Nút "Check" (hành động chính) và "Show hint" (phụ) cùng kích thước 160, chỉ khác tô/viền; "Check" disabled khi trống nên hầu như vô hình khác biệt. Footer icon bút chì (AppIcons.edit) trùng hình ảnh "edit" nhưng không có hành động sửa.
- **Responsive / dynamic-content risks:** Footer ở large text: icon bút chì nằm sát mép trái, chữ căn giữa cách xa (Row `mainAxisAlignment.center` + `Flexible` chiếm hết → icon lệch, `session_footer_hint_widget.dart:33-40`). Term/đáp án dài (cụm từ) trong `MxTextField` một dòng? — risk (not reproduced). Trạng thái wrong: `_Corrected` ba khối text (typed gạch ngang, term, tag) trong face scroll, ổn.
- **Cross-screen consistency issues:** Cùng khung với Recall/Guess (OK). Khác Recall: không có đồng hồ nên khoảng trống phía trên lớn hơn. Các màn form khác dùng `MxTextField` có viền + label nổi; ở đây nhập liệu "vô hình" là ngoại lệ.
- **Recommended fixes:**
    1. Bàn phím + 2 face bằng nhau → ô nhập không còn chỗ → khi `MediaQuery.viewInsets.bottom > 0` đổi tỉ lệ: prompt face `flex` nhỏ/thu gọn (hoặc `Expanded(flex:1)` vs `flex:2` cho answer) và ẩn `SessionFooterHintWidget` → ô nhập luôn thấy; thêm golden có `viewInsets` ~300dp và 320x568.
    2. Ô nhập vô hình → người dùng không biết chạm vào đâu → thêm underline/viền mảnh dùng token `outlineVariant` trong biến thể `study` của `MxTextField`.
    3. Face bị cắt ở large text → dùng `StudyScrollFadeWidget` như mục 19.1.
    4. Footer lệch icon ở nhiều dòng → `Row` với `crossAxisAlignment.start` và `Flexible` bọc trong `Center`, hoặc icon + text trong `Text.rich` WidgetSpan; đổi icon sang `AppIcons.info`/keyboard thay cho bút chì.
- **Severity:** Major

### 21 Session summary
- **Layout break risks:** Thấp. Nội dung nằm trong `MxScreenScroll` + `MxFooterBar` cố định (`session_summary_widget.dart:47-90`) nên không tràn dọc. `MxActionPair` tự xếp dọc khi nhãn không vừa (đúng). Hero stats: 3 `MxStatTile` `Expanded` trong Row, giá trị "41 / 241" đã sát mép ở 360dp (`summary_large_light.png`); với "200 / 1 240" hoặc large text/320dp có thể wrap hoặc tràn — risk (not reproduced, không golden large text cho màn này). Nhãn "REVIEWED/ANSWERED" tiếng Việt (ĐÃ ÔN / ĐÃ TRẢ LỜI / SAI) dài hơn — risk.
- **Information density:** Too Dense (về lặp thông tin) — cùng ba số (Reviewed 20, Answered 20, Wrong 3/23) xuất hiện hai lần: trong hero (3 stat tile) và ngay dưới trong card "This session" (3 row) (`summary_review_light.png`). "Reviewed" và "Answered" thường bằng nhau nên hàng thứ hai càng thừa.
- **Visual hierarchy issues:** Hero card chiếm ~40% màn hình rồi tới facts card; sau đó là ~230dp khoảng trống (~y=1370-1620 trong golden `summary_review_light.png`, `summary_reset_light.png`) trước footer. Đây là khoảng trống có chủ đích của footer cố định nhưng vùng trống lớn cùng dữ liệu trùng lặp nghĩa là bố cục nên thu bớt thay vì lặp. Hai nút cuối xếp dọc (Study this deck outline trên, Done dưới) trên 360dp vì `MxActionPair` không đủ chỗ — ổn, nhưng nút phụ ở trên nút chính là thứ tự ngược với các màn khác (xem dưới). Ở màn reset/leftEarly hero xám-cam với đoạn body 5 dòng, số liệu nằm ở card riêng → mắt đọc câu dài trước.
- **Responsive / dynamic-content risks:** Row "Wrong turns" có `meta` 2 dòng ("of 23 turns · wrong cards came back in later rounds") cạnh giá trị "3 / 23" (golden): ở large text/Việt sẽ 3-4 dòng, giá trị bị đẩy — vẫn co giãn nhưng cao. Tên deck dài trong overline "REVIEW SESSION · {deck}" (`session_summary_hero_widget.dart:~44-58`) không `maxLines`, wrap tự do — chấp nhận được nhưng làm hero cao thêm.
- **Cross-screen consistency issues:** Trạng thái `reset`/`interrupted` vẫn ghi "Cards reviewed — Schedules updated" (golden `summary_reset_light.png`) trong khi hero nói phiên bị hủy → thông điệp mâu thuẫn (lịch KHÔNG cập nhật với phiên bị reset). Kiểu hero có icon tile + overline + title + body giống MxEmptyState nhưng padding khác. Footer: quy ước "Primary bên phải/dưới" của `MxActionPair` khớp các dialog khác — OK.
- **Recommended fixes:**
    1. Lặp số liệu hero/facts → giảm nhận thức, trông thừa → bỏ `SessionSummaryFactsWidget` khi hero đã có stats, hoặc bỏ stats trong hero và giữ card facts (giữ ưu tiên "Reviewed"/"Wrong"); nếu giữ cả hai, bỏ hàng "Cards answered" (trùng Reviewed).
    2. Copy sai ngữ cảnh ở reset/interrupted/leftEarly → người dùng hiểu nhầm lịch đã cập nhật → dùng subtitle theo `SummaryOutcome` (chỉ hiển thị "Schedules updated" khi `reviewFinished`/`learningFinished`).
    3. Chuẩn bị large text: thêm golden `summary_large_text` và cho `_Stats` chuyển sang cột (`Wrap`/`Column`) khi text scale ≥ 1.3, như `StudyCtaRowWidget._stackTextScale`.
    4. Giá trị "3 / 23" → đặt `FittedBox(scaleDown)` hoặc `maxLines:1` để không xuống dòng.
- **Severity:** Minor (lặp dữ liệu và copy lệch ngữ cảnh: Major nếu tính nội dung — mức tổng: Minor)

### 22 Progress (overview + deck progress)
- **Layout break risks:** Tốt: `MxListRow` title/subtitle `maxLines:1 + ellipsis` (`mx_list_row.dart:131-142`) nên tên deck dài bị cắt — nhưng dòng `meta` số liệu ("{d} active days · {l} learning · {r} reviewing") dùng `Text.rich` không giới hạn (`progress_deck_row_widget.dart`); tiếng Việt ("6 ngày hoạt động · 16 đang học · 72 đang ôn") sẽ wrap 2-3 dòng, hàng cao không đều so với hàng "No activity" 1 dòng — risk (not reproduced). Streak tiles tự xếp dọc bằng `TextPainter` (`progress_streak_widget.dart:~120-160`) — cách này là giải pháp tùy biến, chấp nhận. `MxStackedDayBars`: 7 cột + nhãn "Today" ở 320dp/large text — risk (not reproduced).
- **Information density:** Balanced đến hơi Dense ở màn tổng quan: Today card (số + 2 dòng + biểu đồ + legend), Streak card (2 tile + ghi chú), tray, danh sách — 4 khối lớn trước khi tới danh sách deck (thực sự "nhiều nhất"); danh sách chỉ bắt đầu ở y≈1540/2000 (`progress_week_light.png`), ~75% màn hình đầu bị hai card thống kê chiếm.
- **Visual hierarchy issues:** Số "17" Today và tile "Today · 17 cards" trong card Streak lặp cùng con số, cùng nhãn "TODAY" (`progress_week_light.png` y≈200-280 và y≈1020-1090). Streak — thông tin động lực chính — lại là card thứ hai, tile nhỏ recessed với nhãn cỡ nhỏ; tile "Current 4 days" có chữ phụ "includes today" wrap 2 dòng ngay ở 360dp. Ở golden `progress_never_light.png` nút "Start studying" (secondary, xám nhạt) là CTA duy nhất nhưng gần như chìm trong nền recessed; cùng lúc hai hộp đứt nét lặp lại thông điệp "chưa học".
- **Responsive / dynamic-content risks:** Card Today sub-line dài ("5 learning · 12 reviewing · a card counts once per day") đã wrap sang "day" mồ côi ở 360dp (golden, y≈342-385); tiếng Việt sẽ 2-3 dòng. Ở màn deck (`deck_progress_deck_light.png`) khoảng trống lớn phía dưới (>40% màn hình) là trống tự nhiên của danh sách ngắn — không phải lỗi; breadcrumb dài có `MxBreadcrumb` cuộn hay cắt chưa kiểm chứng — risk (not reproduced) với 3-4 cấp thư mục tên dài; tên deck trong app bar bị cắt ellipsis (đúng).
- **Cross-screen consistency issues:** Card Today/Streak padding gutter (20dp?) khác kiểu card của Study Home workload; overline "TODAY" dùng lại 2 lần với nghĩa khác nhau. Tray phân đoạn căn trái, rộng ~60% (golden) trong khi mọi card khác full width → mép phải lộn xộn; ở deck screen tray cũng căn trái nhưng không có gì để cân bằng. Không có tablet layout riêng (chỉ cột giữa chung).
- **Recommended fixes:**
    1. Trùng "Today 17" → bỏ tile "Today" trong `_tiles` (chỉ giữ tile Streak full-width) hoặc bỏ số lớn ở `ProgressTodayWidget` → giảm 1 khối, danh sách deck lên cao hơn.
    2. Sub-line Today dài → tách "a card counts once per day" ra khỏi dòng số liệu (đã có trong footer "Read-only · a card studied several times…" của danh sách) → còn "5 learning · 12 reviewing", 1 dòng cả tiếng Việt.
    3. Meta hàng deck wrap khác nhau → cho `meta` `maxLines: 2 + ellipsis`, hoặc đưa "active days" xuống chỉ hiển thị ở tổng; giữ hàng cao ổn định.
    4. Tray căn trái không cân → dùng `MxSegmentedTray(isWide)` full width (`Align` → `SizedBox(width: double.infinity)`) để khớp mép card.
    5. Never state: đổi "Start studying" sang `MxButtonTone.primary` (hoặc bỏ hộp đứt nét thứ 2 ở Streak) để CTA duy nhất nổi bật.
- **Severity:** Minor

### 23 Settings
- **Layout break risks:** Không thấy overflow. `MxSettingsRow` (label + subtitle) wrap tốt (golden `settings_loaded_light.png`: subtitle Reset xuống 2 dòng). Màn cuộn bằng `MxScreenScroll` (settings_screen.dart:82) nên không cắt ở 2.0x. Chưa có golden `*large_text*` cho Settings: risk (not reproduced) với hàng Study defaults, khi `MxSegmentedTray` (maxLines:1, mx_segmented_tray.dart:213) và `MxStepper` ở font 2.0 + chuỗi tiếng Việt; UI-base row 127 nói tray tự xếp dọc, nhưng chưa có golden chứng minh.
- **Information density:** Balanced. 4 section (Study defaults, App, Sync, Reset) chia đều, mỗi section 1-3 hàng. Chỉ có golden 800dp và nó cắt ngay giữa section Reset (note và Sync không thấy trong `settings_loaded_light.png`).
- **Visual hierarchy issues:** (1) Hàng Sync có tiêu đề section "Sync" trùng nhãn hàng "Sync" (settings_sync_section_widget.dart:28-31), lặp chữ mà section 1 hàng không thêm ngữ cảnh. (2) Hàng Reset có kiểu giống hàng điều hướng (icon tile + chevron) nên hành động phá huỷ nhìn ngang hàng Theme/Language; chỉ có dialog xác nhận cứu. Không có màu cảnh báo/destructive.
- **Responsive / dynamic-content risks:** Cột 720dp do `MxAppShell` lo (mx_app_shell.dart:62), ổn. Snackbar Retry ổn. Subtitle Language "System · {language}" ngắn, an toàn.
- **Cross-screen consistency issues:** Tiêu đề lớn "Settings" (tab gốc) vs `MxAppBarDensity.content` có nút Back ở 24/25/26/27: khác nhau có chủ đích (tab gốc vs trang con), nhất quán với Library. Khoảng cách trên section đầu Settings (title → nhãn "STUDY DEFAULTS" sát) khác với 25/26/27 có thêm `SizedBox(control)` đầu trang, còn 24 thì không: khoảng đệm đầu trang không đồng nhất giữa các trang con. *(Đã kiểm: 26 có đệm; 24 không.)*
- **Recommended fixes:**
    1. Trùng "Sync" → người dùng thấy lặp chữ, tốn một dòng → bỏ `title` của `MxSection` hoặc đổi nhãn hàng thành trạng thái ("Đồng bộ dữ liệu") ở `SettingsSyncSectionWidget`.
    2. Reset là hành động phá huỷ nhưng trông như điều hướng → dễ bấm nhầm, nhất là khi lướt → dùng tông lỗi (`colors.error`) cho label/icon của hàng Reset qua tham số của `MxSettingsRow` nếu có, nếu không thì ghi nhận là nợ cho `MxSettingsRow` (thêm `tone: destructive`).
    3. Thêm golden `settings_large_text` (2.0x, vi) để khoá hành vi tray/stepper.
- **Severity:** Minor

### 24 Daily reminder (+ time dialog)
- **Layout break risks:** (1) Ở 2.0x (`reminder_large_text_light.png`) tiêu đề hàng "Daily reminder" vỡ từng từ (Daily / reminder) và subtitle thành 4-5 dòng hẹp, chỉ ~ 150dp chữ vì icon tile 44dp + toggle 48dp + padding chiếm phần lớn bề ngang 360dp: hàng cao ~220dp, hàng Time tương tự với nút giờ "20:00" bị ép. Không overflow nhưng đọc khó. Với tiếng Việt dài hơn 20-40% sẽ tệ hơn. (2) Dialog chọn giờ (reminder_time_dialog_widget.dart:96-117): mỗi hàng là `Row(Expanded(label), MxStepper)`; stepper gồm 2 nút 36dp + cột giá trị (~50dp+), khoảng 130-180dp cố định. Golden 1x cho nhãn còn rộng. Risk (not reproduced): ở 2.0x nhãn "Minute"/"Phút" chỉ còn <90dp nên bị wrap/ép; dialog có `SingleChildScrollView` (mx_dialog.dart:106) nên không cắt nhưng có thể xấu. Chưa có golden large-text cho dialog.
- **Information density:** Balanced. 2 hàng + note + preview; hơi nhiều chữ phụ (mỗi hàng có subtitle 2 dòng + note + preview 2 khối chữ), nhưng đây là màn giải thích quyền riêng tư nên chấp nhận.
- **Visual hierarchy issues:** Khối "WHAT IT SAYS" dùng chữ trích dẫn cỡ lớn (`reminder_on_light.png`, ~3 dòng tiêu đề) to hơn cả nhãn hàng "Daily reminder"; mắt bị kéo xuống ví dụ thay vì công tắc. Dưới preview còn khoảng trống lớn (y 1260-2000): chủ đích (màn ít nội dung), không nghiêm trọng. Hàng Time khi tắt chỉ mờ đi (isEnabled), nút giờ vẫn ở đó: ổn.
- **Responsive / dynamic-content risks:** Tên deck trong preview là chuỗi mẫu cố định nên không có nội dung người dùng dài; nhưng thông báo thật chứa tên deck tuỳ ý (ngoài phạm vi màn này). Banner lỗi (`ReminderBannersWidget`) xen giữa hai section làm đẩy preview xuống, tự nhiên.
- **Cross-screen consistency issues:** Nút giờ dùng `MxButton compact` (36dp vẽ, 48dp chạm) làm control bên phải hàng, trong khi Settings dùng hàng có chevron mở trang/dialog cho cùng kiểu "chọn giá trị". Stepper giờ/phút khác với time picker Material chuẩn Android mà người dùng quen; đã là quyết định D2 có chủ đích, chỉ ghi nhận.
- **Recommended fixes:**
    1. Text scale lớn ép trailing → chữ vỡ từng từ → ở `MxSettingsRow` khi `textScaler >= 1.5` xếp `trailing` xuống dưới dòng nội dung (đã có cơ chế `wideControl`; dùng lại cho toggle/nút giờ) hoặc bỏ icon tile khi scale lớn.
    2. Dialog Row nhãn/stepper ở 2.0x → nhãn bị bóp → đổi `_labelled` thành `Wrap`/Column khi `MediaQuery.textScalerOf(context).scale(1) > 1.3`, thêm golden `reminder_time_dialog_large_text`.
    3. Preview trích dẫn quá nổi → đổi `label` của `MxSettingsRow` preview sang kiểu `contentTitle` nhỏ hơn hoặc dùng `MxNote`, để công tắc là điểm nhìn đầu tiên.
- **Severity:** Major (large text làm hàng chính khó đọc; dialog chưa có bằng chứng ở 2.0x)

### 25 Theme
- **Layout break risks:** Thiết kế tốt: `LayoutBuilder` tính `minWidth` bằng TextPainter và tự xếp dọc khi hẹp (theme_screen.dart:69-78), đủ cho 320dp/2.0x. `_Preview` cao cố định 62 và khối 28/18dp là hình minh hoạ, không phải chữ nên an toàn. Ở 3 thẻ ngang trên 360dp mỗi thẻ ~ 85dp: nhãn "System" + dấu check + gợi ý "Match phone" sát mép (`settings_theme_system_light.png`), gợi ý tiếng Việt dài hơn sẽ kích hoạt xếp dọc, hợp lý.
- **Information density:** Too Empty (chủ đích). 3 thẻ + 1 note chiếm ~ 1/3 trên; 2/3 màn hình dưới trống (y 660-2000 trong `settings_theme_system_light.png`). Đây là trang chọn 1-trong-3 nên chấp nhận, nhưng thẻ có thể lớn hơn/cao hơn ở phone.
- **Visual hierarchy issues:** Thẻ được chọn có viền primary + dấu check: rõ. Note "Applies at once" đứng ngay dưới thẻ với khoảng cách nhỏ (16dp) và nhìn như phần của thẻ chứ không phải chú thích trang.
- **Responsive / dynamic-content risks:** Tablet: cột 720 nên 3 thẻ ~ 230dp mỗi thẻ, trông ổn. Chế độ xếp dọc ở 2.0x: 3 thẻ x ~ 250dp cao, cuộn được. Không có golden large-text cho màn này, risk (not reproduced).
- **Cross-screen consistency issues:** Đây là một trong hai trang chọn (cùng 26) nhưng dùng thẻ lưới còn Language dùng danh sách radio: khác kiểu tương tác cho cùng loại việc. Có lý do (xem trước màu) nên chấp nhận. Note chú thích dùng `MxNote` với padding ngang `micro` (theme_screen.dart:106-110), khác căn lề với `MxSection` note ở Settings (rộng hơn thẻ 4dp so với thẻ ở 25).
- **Recommended fixes:**
    1. Note dính thẻ → nhìn như phần của thẻ → tăng `top` thành `AppSpacing.gutter` (như 24 dùng `gutter`).
    2. Bổ sung golden `settings_theme_large_text` để chứng minh chế độ xếp dọc.
- **Severity:** Minor

### 26 Language
- **Layout break risks:** Không thấy. Hàng radio wrap theo `MxOptionRow` (golden ổn). Không có golden large-text: risk (not reproduced) thấp vì là danh sách dọc.
- **Information density:** Too Empty (chủ đích): 3 hàng + note, nửa dưới trống (`settings_language_system_light.png` y 820-2000).
- **Visual hierarchy issues:** Chiều cao 3 hàng không đều: "Follow the system" và "Tiếng Việt" có 2 dòng, "English" chỉ 1 dòng (không có phụ đề) nên nhịp danh sách lệch (y 160-320, 320-443, 443-605). Phụ đề "Vietnamese" dưới "Tiếng Việt" nhưng "English" không có phụ đề tương ứng ("Tiếng Anh"), thiếu đối xứng.
- **Responsive / dynamic-content risks:** Ở giao diện tiếng Việt, note "Applies at once … Your cards stay in their own language." dài hơn, wrap 4-5 dòng: an toàn vì ở dưới.
- **Cross-screen consistency issues:** Cùng note "Applies at once — no restart, and you stay where you are" lặp nguyên văn ở 25 và 26: nhất quán tốt. Radio bên trái (26) vs dấu check bên phải trong thẻ (25) vs chevron ở Settings: 3 kiểu chỉ báo lựa chọn ở nhóm này, chấp nhận vì mỗi kiểu hợp ngữ cảnh.
- **Recommended fixes:**
    1. Hàng thiếu phụ đề làm lệch chiều cao → thêm phụ đề cho English (tên bằng ngôn ngữ đối lập, ví dụ "Tiếng Anh"/"English" theo locale hiện hành) trong `LanguageScreen` để 3 hàng cùng nhịp.
- **Severity:** Minor

### 27 Sync
- **Layout break risks:** Notice (`MxFloatingNotice`) nổi ở đáy, body được đệm dưới bằng chiều cao notice (mx_app_shell.dart doc) nên không che nội dung khi cuộn: đúng. Khi notice dài (tiếng Việt + 2.0x) sẽ chiếm 1/3 màn hình; risk (not reproduced), không có golden large-text.
- **Information density:** Too Empty. Chỉ 2 hàng trạng thái + note + nút; khoảng trống lớn giữa nút Sync now (y ~940) và notice ở đáy (y ~1820) trong `sync_failed_network_light.png`. Thông tin lỗi ("No connection…") nằm cách xa nút hành động (Sync now) nên mối liên hệ nguyên nhân/hành động bị đứt.
- **Visual hierarchy issues:** (1) CTA "Sync now" là khối primary rộng full-width nhưng đặt phía trên, trong khi cảnh báo (thông tin quan trọng nhất khi lỗi) ở đáy màn hình; mắt đi từ nút xuống trống rồi mới tới cảnh báo. (2) Hàng "Last synced / Waiting to sync" có nhãn cỡ lớn và giá trị nhỏ: giá trị (thứ người dùng cần) bị nhỏ hơn nhãn. (3) Note "MemoX syncs on its own…" và notice lỗi là 2 khối chữ dày liền nhau khi có lỗi.
- **Responsive / dynamic-content risks:** Nút block full-width trên tablet bị cột 720 giới hạn: ổn. Hàng trạng thái không có icon tile (khác Settings/24): gọn hơn nhưng đổi nhịp.
- **Cross-screen consistency issues:** CTA đặt trong nội dung cuộn (không phải `footer` `MxFooterBar`) trong khi các màn khác (form thẻ, study options) đặt hành động chính ở footer bar. Với màn ít nội dung thì chấp nhận, nhưng nút ở giữa trang + notice ở đáy là bố cục khác mọi màn còn lại.
- **Recommended fixes:**
    1. Lỗi cách xa hành động → đưa `MxButton` Sync now xuống `footer: MxFooterBar` (hoặc đặt notice ngay dưới hàng trạng thái) để hành động và lý do lỗi ở cùng vùng, khớp cách các màn commit khác.
    2. Giá trị trạng thái nhỏ hơn nhãn → dùng kiểu chữ giá trị lớn hơn cho giá trị ("Today, 07:30") trong `SyncStatusSectionWidget`, hoặc đảo vai trò nhãn/giá trị.
- **Severity:** Minor

### App shell (bottom nav, tablet rail, cột 720dp, route not found)
- **Layout break risks:** (1) `RouteNotFoundScreen` dùng `Scaffold` + `SafeArea` trực tiếp (route_not_found_screen.dart:17), không qua `MxAppShell`: không có cột 720dp và không có app bar/nút Back. Trên tablet, trạng thái rỗng bị kéo full-width; risk (not reproduced) vì không có golden cho màn này. Ngoài ra `MxEmptyState` không cuộn ở đây nên ở 2.0x/màn hình ngang thấp có thể tràn: risk (not reproduced). (2) Shell tablet: `AppTabShell` chỉnh MediaQuery (`_besideRail`) để cột 720 tự canh giữa phần còn lại: đúng (`app_tablet_landscape_library_light.png` cột nằm giữa vùng bên phải rail, lề trái ~ 380dp, phải ~ 385dp).
- **Information density:** Balanced. Rail 80dp, 4 điểm đến, nhãn hiện luôn.
- **Visual hierarchy issues:** Trên tablet ngang (1920dp) cột 720dp nằm giữa với lề trống ~ 380dp mỗi bên: chủ đích (FE-C5), nhưng rail dính mép trái tách khỏi nội dung một khoảng lớn nên mối liên hệ rail-nội dung yếu; FAB neo theo mép phải cột (đúng) nhưng cách rail rất xa.
- **Responsive / dynamic-content risks:** Ngưỡng rail 600dp; ở 600-720dp cột chiếm gần hết (600-80=520dp) nên không còn lề: ổn. Nhãn bottom nav tiếng Việt ("Thư viện", "Tiến độ") cần kiểm tra ở 2.0x với 4 mục trên 320dp: risk (not reproduced), không có golden bottom nav large-text.
- **Cross-screen consistency issues:** Route-not-found là màn duy nhất trong nhóm không dùng `MxAppShell`. Các trang con dùng `MxAppBar density: content` + Back đồng nhất.
- **Recommended fixes:**
    1. Không qua shell → mất cột 720 và app bar → bọc `RouteNotFoundScreen` bằng `MxAppShell(appBar: MxAppBar(title:…, leading: back))` và `MxScreenScroll` quanh `MxEmptyState`.
    2. Thêm golden bottom nav ở 320dp/2.0x (vi) và golden route-not-found.
- **Severity:** Minor