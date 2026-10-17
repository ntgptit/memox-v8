> Hồ sơ lịch sử (Design System "Flashcard Color Tokens", 2026-10-13). Từ ADR-026, giá trị chuẩn là theme ForUI trong `lib/core/theme/`; file này không còn là nguồn.

# MemoX V8 — Token spec "Flashcard Color Tokens" (bản chốt)

> **Nguồn:** Design System "Flashcard Color Tokens" (claude.ai artifact `G44xMGLk4MTRnqrKjkgVmu`), bản chốt ngày 2026-10-13, chủ dự án Giap Nguyen duyệt.
> **Trạng thái:** quyết định thiết kế của chủ dự án. File này **thay thế** mọi giá trị token hiện có trong `lib/core/theme/`, `DESIGN.md`, `.impeccable/design.json`, spec Indigo (2026-10-10, D3/D4) và foundations V3 ở những điểm nó định nghĩa.
> **Cách đọc:** mục 1–8 là đặc tả áp dụng (tên trong code, giá trị cuối cùng). Mục 9 là các token repo đang có mà DS không định nghĩa: **giữ nguyên**. Mục 10 là bảng token DS gốc để đối chiếu.

## 0. Nguyên tắc áp dụng

1. Mọi giá trị trong file này là **giá trị cuối cùng**. Không làm tròn, không "chọn bậc gần nhất", không giữ giá trị cũ vì test/golden/DESIGN.md đang ghim giá trị cũ.
2. Màu là hằng hex cố định (`Color(0xFF......)`), kể cả các nền tint 16% (đã tính sẵn ở mục 2). Không suy màu bằng alpha/lerp lúc chạy.
3. Light và dark dùng cùng độ dày nét, cùng kích thước, cùng padding. Chỉ màu đổi theo chế độ.
4. Ở đâu file này đổi tên field hoặc thêm field mới, cập nhật toàn bộ nơi dùng.
5. Token repo có mà file này không nhắc tới: giữ nguyên (mục 9).

## 1. `ColorScheme` — `AppColorSchemes.light` / `.dark`

Thay `ColorScheme.fromSeed(...).copyWith(...)` bằng `const ColorScheme(brightness: ..., ...)` khai báo **đủ 46 role** bằng literal. Không còn role nào sinh từ seed (kể cả `*Fixed`). Seed cũ `0xFF4255FF` bị bỏ.

| Role | Light | Dark |
|---|---|---|
| `primary` | `#564BCB` | `#564BCB` |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` |
| `primaryContainer` | `#564BCB` | `#564BCB` |
| `onPrimaryContainer` | `#D9D4FF` | `#D9D4FF` |
| `primaryFixed` | `#E3DFFF` | `#E3DFFF` |
| `primaryFixedDim` | `#C5C0FF` | `#C5C0FF` |
| `onPrimaryFixed` | `#130067` | `#130067` |
| `onPrimaryFixedVariant` | `#3D2FB2` | `#3D2FB2` |
| `secondary` | `#535E7A` | `#BBC6E6` |
| `onSecondary` | `#FFFFFF` | `#253049` |
| `secondaryContainer` | `#D1DCFD` | `#3B4661` |
| `onSecondaryContainer` | `#55607C` | `#AAB5D4` |
| `secondaryFixed` | `#D9E2FF` | `#D9E2FF` |
| `secondaryFixedDim` | `#BBC6E6` | `#BBC6E6` |
| `onSecondaryFixed` | `#0F1B33` | `#0F1B33` |
| `onSecondaryFixedVariant` | `#3B4661` | `#3B4661` |
| `tertiary` | `#723700` | `#FFB785` |
| `onTertiary` | `#FFFFFF` | `#502400` |
| `tertiaryContainer` | `#964A00` | `#964A00` |
| `onTertiaryContainer` | `#FFD0B2` | `#FFD0B2` |
| `tertiaryFixed` | `#FFDCC6` | `#FFDCC6` |
| `tertiaryFixedDim` | `#FFB785` | `#FFB785` |
| `onTertiaryFixed` | `#301400` | `#301400` |
| `onTertiaryFixedVariant` | `#723700` | `#723700` |
| `error` | `#BA1A1A` | `#FFB4AB` |
| `onError` | `#FFFFFF` | `#690005` |
| `errorContainer` | `#FFDAD6` | `#93000A` |
| `onErrorContainer` | `#93000A` | `#FFDAD6` |
| `surface` | `#FFFFFF` | `#0A082D` |
| `onSurface` | `#1C1B21` | `#E5E1E9` |
| `surfaceDim` | `#DFE0E0` | `#0A082D` |
| `surfaceBright` | `#FFFFFF` | `#313055` |
| `surfaceContainerLowest` | `#FFFFFF` | `#040227` |
| `surfaceContainerLow` | `#F9F9F9` | `#141337` |
| `surfaceContainer` | `#F3F3F3` | `#18173B` |
| `surfaceContainerHigh` | `#EEEEEE` | `#222145` |
| `surfaceContainerHighest` | `#E8E8E8` | `#2D2C51` |
| `onSurfaceVariant` | `#3B4661` | `#BBC6E6` |
| `outline` | `#6C7794` | `#8590AE` |
| `outlineVariant` | `#BBC6E6` | `#3B4661` |
| `shadow` | `#000000` | `#000000` |
| `scrim` | `#000000` | `#000000` |
| `inverseSurface` | `#313036` | `#E5E1E9` |
| `onInverseSurface` | `#F3EFF7` | `#313036` |
| `inversePrimary` | `#C5C0FF` | `#564BCB` |
| `surfaceTint` | `#564BCB` | `#564BCB` |

Tổng: 46 role. `brightness`: `Brightness.light` / `Brightness.dark`.

## 2. `MxSemanticColors` — 37 field hiện có + 7 field mới

Ánh xạ từng field hiện có sang DS. Cột "Nguồn DS" cho biết token gốc; giá trị đã tính sẵn. "16% trên `surface`" = màu đó phủ 16% lên `surface` của chế độ tương ứng, đã quy ra hex đặc.

Lưu ý thay đổi quy ước cũ: spec D4 "soft grounds sáng ở cả hai chế độ" **bị bỏ**. Theo DS, nền tint ở dark là tối (16% trên nền navy). `dangerSoft`/`dangerBorder` hết trong suốt, thành hex đặc.

### 2.1 Field hiện có

| Field | Nguồn DS | Light | Dark |
|---|---|---|---|
| `mastery` | `success-container` | `#17AE79` | `#17AE79` |
| `onMastery` | `success-onContainer` | `#003925` | `#003925` |
| `success` | `success-color` | `#006C49` | `#5ADDA4` |
| `warning` | `warning-container` | `#F59E0B` | `#F59E0B` |
| `onWarning` | `warning-onContainer` | `#613B00` | `#613B00` |
| `statusNew` | `outline` | `#6C7794` | `#8590AE` |
| `statusLearning` | `warning-container` | `#F59E0B` | `#F59E0B` |
| `statusReviewing` | accent (`primary` light / `primaryFixedDim` dark) | `#564BCB` | `#C5C0FF` |
| `statusMastered` | `success-container` | `#17AE79` | `#17AE79` |
| `errorFill` | `error` | `#BA1A1A` | `#FFB4AB` |
| `onErrorFill` | `onError` | `#FFFFFF` | `#690005` |
| `streak` | `warning-container` | `#F59E0B` | `#F59E0B` |
| `primaryText` | accent (`primary` light / `primaryFixedDim` dark) | `#564BCB` | `#C5C0FF` |
| `masteryText` | `success-color` | `#006C49` | `#5ADDA4` |
| `learningText` | `warning-color` | `#855300` | `#FFC174` |
| `warningText` | `warning-color` | `#855300` | `#FFC174` |
| `focusRing` | `primary` | `#564BCB` | `#564BCB` |
| `border` | `outlineVariant` | `#BBC6E6` | `#3B4661` |
| `primaryTrack` | `primary` | `#564BCB` | `#564BCB` |
| `neutralTrack` | `surfaceContainerHighest` | `#E8E8E8` | `#2D2C51` |
| `primarySoft` | `primary` (accent) 16% trên `surface` | `#E4E2F7` | `#28254F` |
| `onPrimarySoft` | accent (`primary` light / `primaryFixedDim` dark) | `#564BCB` | `#C5C0FF` |
| `successSoft` | `success-color` 16% trên `surface` | `#D6E7E2` | `#172A40` |
| `successBorder` | `success-color` | `#006C49` | `#5ADDA4` |
| `onSuccessSoft` | `success-color` | `#006C49` | `#5ADDA4` |
| `learningSoft` | `warning-color` 16% trên `surface` | `#EBE3D6` | `#312638` |
| `learningBorder` | `warning-color` | `#855300` | `#FFC174` |
| `onLearningSoft` | `warning-color` | `#855300` | `#FFC174` |
| `warningSoft` | `warning-color` 16% trên `surface` | `#EBE3D6` | `#312638` |
| `warningBorder` | `warning-color` | `#855300` | `#FFC174` |
| `onWarningSoft` | `warning-color` | `#855300` | `#FFC174` |
| `dangerSoft` | `error` 16% trên `surface` | `#F4DADA` | `#312441` |
| `dangerBorder` | `error` | `#BA1A1A` | `#FFB4AB` |
| `onDangerSoft` | `error` | `#BA1A1A` | `#FFB4AB` |
| `neutralSoft` | `secondaryContainer` | `#D1DCFD` | `#3B4661` |
| `onNeutralSoft` | `onSecondaryContainer` | `#55607C` | `#AAB5D4` |
| `onSoft` | `onSurface` | `#1C1B21` | `#E5E1E9` |

Ghi chú:
- `learning*` và `warning*` dùng cùng họ màu cam của DS (DS không có màu riêng cho "learning"). Phân biệt bằng icon và nhãn, không bằng màu.
- `streak` dùng `warning-container` (cam). DS không có màu hồng.
- `onMastery` đổi từ trắng sang `success-onContainer` (xanh đậm) theo DS: chữ trên nền `success-container`.

### 2.2 Field mới (thêm vào `MxSemanticColors`, cả `copyWith`, `lerp`, `light`, `dark`)

| Field | Nguồn DS | Light | Dark | Dùng cho |
|---|---|---|---|---|
| `cardSurface` | `cardSurface` | `#F1F1FB` | `#222145` | Nền mọi card (tonal elevation). Không bóng, không viền. |
| `searchSurface` | `searchSurface` | `#F1F1FB` | `#222145` | Nền MxSearchField. Không bóng. |
| `tileSurface` | `tileSurface` | `#EDF8FF` | `#2E3953` | Nền ô icon bộ thẻ (DeckTile, DeckCard). |
| `divider` | `divider` | `#EEEEEE` | `#18173B` | Đường kẻ trên nền trang: viền trên MxBottomNav, viền phải MxNavRail. Đường kẻ trong card dùng `border` (= outlineVariant). |
| `info` | `info-color` | `#006684` | `#A9E3FF` | Thông tin dạng chữ/icon trên nền trơn (icon hourglass "chờ Recall/Fill"). |
| `infoContainer` | `info-container` | `#50CCFC` | `#50CCFC` | Fill thông tin; icon bộ thẻ trên `tileSurface` ở dark. |
| `onInfoContainer` | `info-onContainer` | `#00546D` | `#00546D` | Chữ trên `infoContainer`. |

### 2.3 Kiểm tra tương phản (đã đo, WCAG 2)

| Cặp | Light | Dark |
|---|---|---|
| `onSurface` trên `surface` | 17.10 | 15.00 |
| `onSurfaceVariant` trên `surface` | 9.40 | 11.36 |
| `onSurface` trên `cardSurface` | 15.24 | 11.87 |
| `onSurfaceVariant` trên `cardSurface` | 8.38 | 8.99 |
| `onSuccessSoft` trên `successSoft` | 5.06 | 8.54 |
| `onWarningSoft` trên `warningSoft` | 5.10 | 8.96 |
| `onDangerSoft` trên `dangerSoft` | 4.89 | 8.48 |
| `onPrimarySoft` trên `primarySoft` | 5.06 | 8.42 |
| `onNeutralSoft` trên `neutralSoft` | 4.59 | 4.60 |
| `onMastery` trên `mastery` | 4.57 | 4.57 |
| `onWarning` trên `warning` | 4.58 | 4.58 |
| `onErrorFill` trên `errorFill` | 6.46 | 7.72 |
| `primary` trên `surface` (dark) | — | 3.01 |

Cặp dưới 4.5:1 (chữ thường) là ngoại lệ đã được chủ dự án chấp nhận cùng bảng màu: ghi vào bảng `_exceptions` của `token_contrast_test.dart` với giá trị đo thực tế, không đổi màu. Riêng `primary` trên `surface` ở dark (3.01:1): không dùng `primary` làm chữ/icon trên nền dark; dùng `primaryText` (= `primaryFixedDim` ở dark).

## 3. Typography

### 3.1 Font
- Bỏ `PlusJakartaSans`. Font mới: **Be Vietnam Pro** (Latin, tiếng Việt) + **Noto Sans KR** làm `fontFamilyFallback` (tiếng Hàn).
- Đóng gói font trong `assets/fonts/` (không dùng `google_fonts` lúc chạy, để test và golden ổn định): Be Vietnam Pro Regular 400, Medium 500, SemiBold 600; Noto Sans KR (variable hoặc 400/500/600). Nguồn: repo `google/fonts` (giấy phép OFL), kèm file `OFL.txt`.
- Khai báo trong `pubspec.yaml` (`flutter: fonts:`) với `weight:` đúng cho từng file. `AppTypography.fontFamily = 'BeVietnamPro'`, thêm `AppTypography.fontFamilyFallback = ['NotoSansKR']` và áp vào mọi slot.
- `withWeight` giữ nguyên chữ ký; với font tĩnh, `FontVariation` không gây hại.
- Cập nhật `test/flutter_test_config.dart` để nạp font mới.

### 3.2 `TextTheme` — 12 role DS
`height` = lineHeight ÷ fontSize. Bỏ `_tightTracking = -0.64` và `isTabular` mặc định; chỉ `displayMedium` giữ `FontFeature.tabularFigures()` (số liệu).

| Slot | Token DS | fontSize | lineHeight | `height` | fontWeight | letterSpacing |
|---|---|---|---|---|---|---|
| `displaySmall` | `display-term` | 24 | 32 | 1.3333 | w400 | 0 |
| `headlineSmall` | `term-tile` | 20 | 28 | 1.4000 | w400 | 0 |
| `displayMedium` | `display-stat` | 28 | 36 | 1.2857 | w500 | 0 |
| `titleLarge` | `title-section` | 20 | 28 | 1.4000 | w600 | 0 |
| `titleMedium` | `title-card` | 18 | 24 | 1.3333 | w500 | 0.15 |
| `titleSmall` | `title-item` | 14 | 20 | 1.4286 | w500 | 0.1 |
| `bodyLarge` | `body-content` | 16 | 24 | 1.5000 | w400 | 0 |
| `bodyMedium` | `body` | 14 | 20 | 1.4286 | w400 | 0.25 |
| `bodySmall` | `body-tile` | 13 | 16 | 1.2308 | w400 | 0 |
| `labelLarge` | `label-button` | 14 | 20 | 1.4286 | w400 | 0.1 |
| `labelMedium` | `label-meta` | 14 | 20 | 1.4286 | w400 | 0.5 |
| `labelSmall` | `label-nav` | 12 | 16 | 1.3333 | w500 | 0.5 |

Ba slot DS không dùng (`displayLarge`, `headlineLarge`, `headlineMedium`): giữ cỡ mặc định M3, chỉ đổi font.

Quy tắc chữ (DS):
- Chữ giao diện 14 (`titleSmall`, `bodyMedium`, `labelLarge`, `labelMedium`). Chữ nội dung học giữ cỡ riêng và letterSpacing 0: `displaySmall` (từ đang học), `headlineSmall` (từ trong ô Match), `bodyLarge` (nghĩa trên card), `bodySmall` (nghĩa trong ô Match/đáp án Guess).
- In đậm hạn chế: chỉ `titleLarge` w600; tiêu đề card, tên mục, nhãn điều hướng w500; còn lại w400, **kể cả chữ trên nút**.
- Chữ nhỏ nhất 12 (`labelSmall`).

### 3.3 `MxTextStyles` — mỗi style = đúng một role DS
Mỗi style dưới đây trả về **nguyên** role DS tương ứng (cỡ, dòng, weight, tracking), chỉ được đổi `color`. Xoá các hằng tinh chỉnh riêng (`_labelTracking`, `_titleTracking`, `_singleLineHeight`, `overline` 13/0.6, `eyebrow` 12/0.8, `studyTerm` 32/-0.5…).

| Style | Role | Style | Role |
|---|---|---|---|
| `buttonLabel` | `labelLarge` | `buttonLabelSmall` | `labelLarge` |
| `buttonDetail` | `labelMedium` | `contentTitle` | `titleMedium` |
| `screenTitle` | `titleLarge` | `emptyTitle` | `titleMedium` |
| `emptyTitleCompact` | `titleSmall` | `emptyBody` | `bodyMedium` |
| `emptyBodyStrong` | `titleSmall` | `breadcrumbAncestor` | `labelMedium` |
| `breadcrumbCurrent` | `titleSmall` | `counter` | `labelSmall` |
| `footerCaption` | `labelSmall` | `inputHint` | `bodyMedium` |
| `disclosureLabel` | `labelMedium` | `fieldCode` | `displaySmall` |
| `searchValue` | `labelMedium` | `searchHint` | `labelMedium` |
| `rowTitle` | `titleSmall` | `rowTitleMatch` | `titleSmall` |
| `rowDescription` | `bodyMedium` | `listRowTitle` | `titleSmall` |
| `rowSubtitle` | `bodyMedium` | `settingsLabel` | `titleSmall` |
| `overline` | `labelSmall` | `eyebrow` | `labelSmall` |
| `fieldLabel` | `labelMedium` | `statLabel` | `labelSmall` |
| `requiredMarker` | `bodyMedium` | `historyAgo` | `labelSmall` |
| `removableTagLabel` | `labelSmall` | `tagLabel` | `labelSmall` |
| `code` | `bodyMedium` (giữ family monospace) | `noteText` | `bodyMedium` |
| `studyTerm` | `displaySmall` | `studyMeaning` | `bodyLarge` |
| `studyDetail` | `bodyMedium` | `sessionHint` | `bodyMedium` |
| `summaryTitle` | `titleMedium` | `summaryBodyStrong` | `titleSmall` |
| `studyPassage` | `bodyLarge` | `workloadText` | `labelMedium` |
| `compactTitle` | `titleSmall` | `dialogBody` | `bodyMedium` |
| `bannerTitle` | `labelMedium` | `snackbarMessage` | `bodyMedium` |
| `snackbarAction` | `labelLarge` | | |

Style có trong file mà không có trong bảng: chọn role theo vai trò, theo đúng các cặp tương tự ở trên (tiêu đề mục → `titleSmall`, mô tả → `bodyMedium`, nhãn/chú thích nhỏ → `labelSmall`, số liệu lớn → `displayMedium`), và liệt kê lựa chọn trong báo cáo cuối. Ô Match/Guess: từ tiếng Hàn dùng `headlineSmall`, nghĩa dùng `bodySmall`.

## 4. Foundations

### 4.1 `AppSpacing`
| Field | Cũ | Mới | Ghi chú |
|---|---|---|---|
| `micro` | 4 | **4** | |
| `control` | 8 | **8** | |
| `grouped` | 12 | **12** | |
| `gutter` | 16 | **16** | Lề màn hình ở cửa sổ compact (`margin-screen`) |
| `gutterMedium` *(mới)* | — | **24** | Lề màn hình từ 600 (`margin-screen-medium`) |
| `card` | 20 | **24** | Padding card thường |
| `cardCompact` *(mới)* | — | **16** | Padding card trên màn tổng quan (Today) |
| `section` | 24 | **24** | Khoảng cách giữa các khối |
| `major` | 32 | **32** | |
| `pageEnd` | 48 | **48** | |

Thêm `extension ScreenMargin on BuildContext { double get screenMargin }`: `AppSpacing.gutter` khi bề ngang cửa sổ < 600, `AppSpacing.gutterMedium` khi ≥ 600. Mọi chỗ đang dùng `AppSpacing.gutter` làm **lề trái/phải của màn hình** chuyển sang `context.screenMargin`; chỗ dùng `gutter` làm khoảng cách giữa item giữ `gutter`.

### 4.2 `AppRadius` (thang shape M3)
| Field | Cũ | Mới | Dùng cho |
|---|---|---|---|
| `xs` | 4 | **4** | Chi tiết nhỏ |
| `sm` | 8 | **8** | Ô icon bộ thẻ, banner |
| `md` | 12 | **12** | Mọi card, ô Match, ô nhập |
| `lg` | 16 | **16** | Cạnh drawer, sheet lớn |
| `xl` | 20 | **28** | Dialog, bottom sheet |
| `full` | 999 | **999** | Nút, search, progress, pill điều hướng |

### 4.3 `AppSize`
| Field | Cũ | Mới | Ghi chú |
|---|---|---|---|
| `buttonRegular` | 48 | **40** | Button `default` (M3 Expressive S): nút đứng riêng, thanh hành động màn học, nút rộng hết card |
| `buttonSmall` | 36 | **32** | Button `small` (M3 Expressive XS): nút nằm cùng hàng với nội dung khác |
| `buttonCompact` | 32 | **32** | Bằng `buttonSmall` (DS chỉ có 2 cỡ nút) |
| `search` *(mới)* | — | **56** | `MxSearchField` (thay cho `input` 52 ở search) |
| `touchTarget` | 48 | **48** | Vùng chạm tối thiểu, kể cả nút 32/40 |
| `listRowMin` | 48 | **48** | |
| `appBar` | 56 | **64** | Thanh tiêu đề = 48 + 2 × 8 |
| `bottomNavBar` | 64 | **64** | Chiều cao toàn bộ `MxBottomNav` (M3 Expressive), chưa tính inset hệ thống |
| `bottomNavBlock` | 80 | **64** | Không còn khối 80 |
| `navIndicatorWidth` *(mới)* | — | **56** | Pill sau icon tab đang chọn |
| `navIndicatorHeight` *(mới)* | — | **32** | |
| `navRail` | 80 | **80** | |
| `navRailBreakpoint` | 600 | **600** | `breakpoint-medium` |
| `expandedBreakpoint` *(mới)* | — | **840** | `breakpoint-expanded` |
| `contentMaxWidth` | 720 | **599** | Cột một cột (compact) và mọi phiên học, ở mọi cỡ cửa sổ |
| `contentMaxWidthWide` *(mới)* | — | **1040** | Vùng nội dung từ 600 (màn tổng quan 2 cột) |
| `progressTrack` *(mới)* | — | **4** | Cao thanh tiến độ tuyến tính |
| `deckTile` *(mới)* | — | **64** | Ô icon bộ thẻ trong danh sách (DeckTile) |
| `avatar` *(mới, nếu chưa có)* | — | **48** | |

### 4.4 `AppIconSize`
`standard` 24 và `large` 32 khớp DS (`size-icon`, `size-icon-tile`). Các field khác giữ nguyên.

### 4.5 `AppStroke`
`hairline` 1, `focus` 2, `focusOffset` 2: khớp DS, giữ nguyên. Khác: giữ nguyên.

### 4.6 `AppOpacity` (state layer M3)
| Field | Cũ | Mới |
|---|---|---|
| `hover` *(mới)* | — | **0.08** |
| `pressed` | 0.12 | **0.10** |
| `focus` *(mới)* | — | **0.10** |
| `dragged` *(mới)* | — | **0.16** |
| `disabled` | 0.38 | **0.38** (chữ/icon disabled) |
| `disabledContainer` *(mới)* | — | **0.12** (nền disabled) |
| `muted`, `hidden` | | giữ nguyên |

### 4.7 Motion — `AppDurations` + `AppEasing` (mới)
| Field | Cũ | Mới | Token DS |
|---|---|---|---|
| `toggle` | 160 ms | **150 ms** | `motion-duration-short3` (đổi màu trạng thái) |
| `standard` | 200 ms | **200 ms** | `motion-duration-short4` |
| `scrimFade` | 220 ms | **200 ms** | `motion-duration-short4` |
| `sheet` | 260 ms | **300 ms** | `motion-duration-medium2` |
| `selection` *(mới)* | — | **100 ms** | `motion-duration-short2` (state layer) |
| `pageTransition` *(mới)* | — | **400 ms** | `motion-duration-medium4` (vuốt thẻ, chuyển trang; giữ kết quả đúng) |
| `longTransition` *(mới)* | — | **600 ms** | `motion-duration-long4` (giữ kết quả ghép sai) |
| `spinnerCycle`, `skeletonPulse`, `toast`, `undoWindow`, `stepperRepeat*` | | giữ nguyên | |

`AppEasing` (mới, `abstract final class`): `standard = Easing.standard`, `standardDecelerate = Easing.standardDecelerate`, `standardAccelerate = Easing.standardAccelerate`, `emphasizedDecelerate = Easing.emphasizedDecelerate`, `emphasizedAccelerate = Easing.emphasizedAccelerate`, `emphasized = Curves.easeInOutCubicEmphasized`, `linear = Curves.linear`. Vào màn hình dùng `-Decelerate`, rời màn hình dùng `-Accelerate`, đổi tại chỗ dùng `standard`, vòng đếm ngược dùng `linear`.

### 4.8 `AppShadows`
- `whisper`: trả về `const []` ở **cả hai** chế độ (không còn bóng nghỉ).
- `overlay`, `chrome`, `fab`: giữ nguyên (DS không định nghĩa bóng cho dialog/sheet/FAB).
- Không phần tử nào trong card/search/navigation dùng bóng.

## 5. Bố cục theo cỡ cửa sổ (M3 window size class)
| Cỡ | Bề ngang | Điều hướng | Nội dung |
|---|---|---|---|
| Compact | < 600 | `MxBottomNav` ở đáy | Một cột, tối đa 599, lề `AppSpacing.gutter` (16) |
| Medium | 600–839 | `MxNavRail` bên trái, ẩn bottom nav | Tối đa 1040, căn giữa, lề `gutterMedium` (24) |
| Expanded | ≥ 840 | `MxNavRail` bên trái | Như Medium |

- Phiên học (màn học toàn màn hình) giữ cột tối đa 599 căn giữa ở mọi cỡ.
- Màn tổng quan chia 2 cột khi **vùng nội dung** (đã trừ rail) rộng ≥ 672 (mỗi cột ≥ 300, khe 24). Dùng `LayoutBuilder`, không dùng cỡ cửa sổ.
- Card hẹp hơn 300: nút cạnh vòng tiến độ xuống dòng, rộng hết card, đổi sang cỡ `buttonRegular`.

## 6. Quy tắc component
| Component | Quy tắc |
|---|---|
| Card (`AppDecorations.raisedCard`, `MxCard`, mọi card) | Nền `cardSurface`, bo `AppRadius.md`, **không viền, không bóng**, light và dark như nhau. `recessedCard`/`heroCard`/các card trạng thái giữ màu riêng của chúng nhưng cũng bỏ viền hairline và bóng. Đường kẻ bên trong card dùng `border` (outlineVariant). Padding `AppSpacing.card` (24) hoặc `cardCompact` (16) trên màn tổng quan. |
| Button (`MxButton`) | Hai cỡ: regular 40 (padding ngang 24), small 32 (padding ngang 12). Chữ `labelLarge` w400 ở mọi cỡ. Bo `AppRadius.full`. Vùng chạm 48. Chọn cỡ: nút đứng riêng/rộng hết card → regular; nút cùng hàng nội dung khác → small; một card chỉ dùng một cỡ. |
| Bottom nav (`MxBottomNav`) | Cao 64. Nền `surface`, viền trên `stroke-hairline` màu `divider`, không bóng. Tab đang chọn: pill 56×32 bo full nền `secondaryContainer` sau icon, icon `onSecondaryContainer`, nhãn `onSurface`. Tab chưa chọn: icon + nhãn `onSurfaceVariant`. Nhãn `labelSmall`. Pill đổi trong `AppDurations.sheet` (300) với `AppEasing.standard`. Bỏ góc bo `AppRadius.lg` của khối nav nếu có. |
| Nav rail (`MxNavRail`) | Rộng 80, nền `surface`, viền phải hairline `divider`. Pill và màu như bottom nav. Hiện từ 600. |
| Search (`MxSearchField`) | Cao 56, nền `searchSurface`, bo full, không bóng, không viền. Placeholder `labelMedium` màu `onSurfaceVariant`, icon 24. |
| Progress (`MxLinearProgress`) | Cao 4 (cả `_height` và `_masteryHeight`), bo full. Rãnh `surfaceContainerHighest`, phần chạy `mastery` (= `success-container`). Phần chạy tối thiểu rộng bằng chiều cao. |
| App bar (`MxAppBar`) | Cao 64. Tiêu đề `titleLarge`. Lề ngang = `context.screenMargin`. |
| Focus ring | 2dp, màu `focusRing` (= `primary`), cách phần tử 2dp. |
| Nền tint trạng thái (banner, ô Match chọn/đúng/sai) | Dùng các field `*Soft` (hex đặc ở mục 2). Viền 1dp màu `*Border` khi cần (ô Match), banner không viền. |
| Chip trung tính | Nền `neutralSoft` (`secondaryContainer`), chữ `onNeutralSoft`. |

## 7. Tài liệu đi kèm (cập nhật trong cùng PR)
- `DESIGN.md`: frontmatter (colors Day, typography, rounded, spacing, components) và các Named Rule bị ảnh hưởng (One Indigo → primary `#564BCB`; 48 Floor → vùng chạm 48 nhưng nút 40/32; Seven Roles → 12 role ở mục 3.2).
- `.impeccable/design.json`: `colorMeta` (dark), `typographyMeta`, `shadows`, `motion`, `breakpoints`, `components`.
- Spec Indigo 2026-10-10 (D3, D4) và foundations V3: thêm ghi chú "superseded by Flashcard Color Tokens 2026-10-13".
- `.claude/skills/flutter-design-system/references/tokens.md`: thay ví dụ cũ bằng tên thật ở file này.
- Một ADR mới ghi quyết định này (số ADR tiếp theo).

## 8. Điều kiện hoàn tất (để kiểm)
1. Mọi giá trị ở mục 1–6 có trong code đúng như bảng, kiểm bằng test.
2. `test/core/theme/*` ghim **giá trị mới**; widget test đọc kích thước từ `AppSize` thay vì số cứng (80, 48…).
3. `token_contrast_test.dart` xanh; ngoại lệ ghi đúng tỉ lệ đo.
4. Golden sinh lại trong container Linux; trang so sánh golden-compare đã tạo.
5. `dod_check.sh` xanh toàn bộ.
6. `grep -rn "0xFF4255FF\|PlusJakartaSans" lib test` không còn kết quả.

## 9. Token repo có, DS không định nghĩa — giữ nguyên
`AppSize.chip` 28, `input` 52 (ô nhập thường), `iconButtonInk` 36, `codeSlot` 56, `fab` 52, `timelineDot` 14; `AppIconSize.inline` 16, `brandMark` 18, `compact` 20, `illustrative` 40; `AppStroke.control`, `selectedRing`, `indicator`; `AppOpacity.muted`, `hidden`; `AppEffects.scrimOpacity`; `AppShadows.overlay/chrome/fab`; `MasteryRamp` thresholds (chỉ đổi màu theo mục 2).


## 10. Bảng token DS gốc (đối chiếu)

### 10.1 Màu — `ColorScheme` (Material 3, 46 role)

Khai báo hằng `ColorScheme(...)` đủ 46 role cho mỗi chế độ. Không dùng `ColorScheme.fromSeed` lúc chạy. 

| Token DS | Field Flutter | Light | Dark |
|---|---|---|---|
| `primary` | `primary` | `#564BCB` | `#564BCB` |
| `onPrimary` | `onPrimary` | `#FFFFFF` | `#FFFFFF` |
| `primaryContainer` | `primaryContainer` | `#564BCB` | `#564BCB` |
| `onPrimaryContainer` | `onPrimaryContainer` | `#D9D4FF` | `#D9D4FF` |
| `primaryFixed` | `primaryFixed` | `#E3DFFF` | `#E3DFFF` |
| `primaryFixedDim` | `primaryFixedDim` | `#C5C0FF` | `#C5C0FF` |
| `onPrimaryFixed` | `onPrimaryFixed` | `#130067` | `#130067` |
| `onPrimaryFixedVariant` | `onPrimaryFixedVariant` | `#3D2FB2` | `#3D2FB2` |
| `secondary` | `secondary` | `#535E7A` | `#BBC6E6` |
| `onSecondary` | `onSecondary` | `#FFFFFF` | `#253049` |
| `secondaryContainer` | `secondaryContainer` | `#D1DCFD` | `#3B4661` |
| `onSecondaryContainer` | `onSecondaryContainer` | `#55607C` | `#AAB5D4` |
| `secondaryFixed` | `secondaryFixed` | `#D9E2FF` | `#D9E2FF` |
| `secondaryFixedDim` | `secondaryFixedDim` | `#BBC6E6` | `#BBC6E6` |
| `onSecondaryFixed` | `onSecondaryFixed` | `#0F1B33` | `#0F1B33` |
| `onSecondaryFixedVariant` | `onSecondaryFixedVariant` | `#3B4661` | `#3B4661` |
| `tertiary` | `tertiary` | `#723700` | `#FFB785` |
| `onTertiary` | `onTertiary` | `#FFFFFF` | `#502400` |
| `tertiaryContainer` | `tertiaryContainer` | `#964A00` | `#964A00` |
| `onTertiaryContainer` | `onTertiaryContainer` | `#FFD0B2` | `#FFD0B2` |
| `tertiaryFixed` | `tertiaryFixed` | `#FFDCC6` | `#FFDCC6` |
| `tertiaryFixedDim` | `tertiaryFixedDim` | `#FFB785` | `#FFB785` |
| `onTertiaryFixed` | `onTertiaryFixed` | `#301400` | `#301400` |
| `onTertiaryFixedVariant` | `onTertiaryFixedVariant` | `#723700` | `#723700` |
| `error` | `error` | `#BA1A1A` | `#FFB4AB` |
| `onError` | `onError` | `#FFFFFF` | `#690005` |
| `errorContainer` | `errorContainer` | `#FFDAD6` | `#93000A` |
| `onErrorContainer` | `onErrorContainer` | `#93000A` | `#FFDAD6` |
| `surface` | `surface` | `#FFFFFF` | `#0A082D` |
| `onSurface` | `onSurface` | `#1C1B21` | `#E5E1E9` |
| `surfaceDim` | `surfaceDim` | `#DFE0E0` | `#0A082D` |
| `surfaceBright` | `surfaceBright` | `#FFFFFF` | `#313055` |
| `surfaceContainerLowest` | `surfaceContainerLowest` | `#FFFFFF` | `#040227` |
| `surfaceContainerLow` | `surfaceContainerLow` | `#F9F9F9` | `#141337` |
| `surfaceContainer` | `surfaceContainer` | `#F3F3F3` | `#18173B` |
| `surfaceContainerHigh` | `surfaceContainerHigh` | `#EEEEEE` | `#222145` |
| `surfaceContainerHighest` | `surfaceContainerHighest` | `#E8E8E8` | `#2D2C51` |
| `onSurfaceVariant` | `onSurfaceVariant` | `#3B4661` | `#BBC6E6` |
| `outline` | `outline` | `#6C7794` | `#8590AE` |
| `outlineVariant` | `outlineVariant` | `#BBC6E6` | `#3B4661` |
| `shadow` | `shadow` | `#000000` | `#000000` |
| `scrim` | `scrim` | `#000000` | `#000000` |
| `inverseSurface` | `inverseSurface` | `#313036` | `#E5E1E9` |
| `onInverseSurface` | `onInverseSurface` | `#F3EFF7` | `#313036` |
| `inversePrimary` | `inversePrimary` | `#C5C0FF` | `#564BCB` |
| `surfaceTint` | `surfaceTint` | `#564BCB` | `#564BCB` |

### 10.2 Màu mở rộng — `ThemeExtension` (không thuộc ColorScheme)

| Token DS | Field Flutter | Light | Dark | Dùng cho |
|---|---|---|---|---|
| `success-color` | `success.color` | `#006C49` | `#5ADDA4` |  |
| `success-onColor` | `success.onColor` | `#FFFFFF` | `#003824` |  |
| `success-container` | `success.container` | `#17AE79` | `#17AE79` |  |
| `success-onContainer` | `success.onContainer` | `#003925` | `#003925` |  |
| `warning-color` | `warning.color` | `#855300` | `#FFC174` |  |
| `warning-onColor` | `warning.onColor` | `#FFFFFF` | `#472A00` |  |
| `warning-container` | `warning.container` | `#F59E0B` | `#F59E0B` |  |
| `warning-onContainer` | `warning.onContainer` | `#613B00` | `#613B00` |  |
| `info-color` | `info.color` | `#006684` | `#A9E3FF` |  |
| `info-onColor` | `info.onColor` | `#FFFFFF` | `#003546` |  |
| `info-container` | `info.container` | `#50CCFC` | `#50CCFC` |  |
| `info-onContainer` | `info.onContainer` | `#00546D` | `#00546D` |  |
| `cardSurface` | `cardSurface` | `#F1F1FB` | `#222145` | Nền mọi card. Card nổi bằng tông nền, không bóng, không viền |
| `searchSurface` | `searchSurface` | `#F1F1FB` | `#222145` | Nền SearchBar, cùng tông card, không bóng |
| `tileSurface` | `tileSurface` | `#EDF8FF` | `#2E3953` | Nền ô icon bộ thẻ |
| `divider` | `divider` | `#EEEEEE` | `#18173B` | Đường kẻ trên nền trang (viền trên NavigationBar, viền phải NavigationRail) |

Màu dẫn xuất (không phải token riêng, tính trong code):

- `accentIcon`: `primary` ở light, `primaryFixedDim` ở dark. Dùng cho icon mang màu nhấn, vì `primary` trên card dark chỉ đạt 2.38:1.
- Tint trạng thái: `Color.alphaBlend(color.withValues(alpha: 0.16), base)`, với `base` là `cardSurface` khi nằm trong card, `surface` khi nằm trên nền trang.

Seed dùng để sinh bảng màu (chỉ để tham chiếu, không dùng trực tiếp trong UI):

| Seed | Giá trị |
|---|---|
| `seed-background-light` | `#FFFFFF` |
| `seed-background-dark` | `#0A082D` |
| `seed-primary` | `#564BCB` |
| `seed-secondary` | `#58637F` |
| `seed-success` | `#17AE79` |
| `seed-warning` | `#F59E0B` |
| `seed-info` | `#50CCFC` |

### 10.3 Typography — `TextTheme`

Font: `Be Vietnam Pro` (Latin, tiếng Việt), fallback `Noto Sans KR` (tiếng Hàn). Nạp weight 400, 500, 600. `height` = lineHeight / fontSize.

| Token DS | TextTheme | Size | Line height | `height` | Weight | Letter-spacing | Dùng cho |
|---|---|---|---|---|---|---|---|
| `display-term` | `displaySmall` | 24 | 32 | 1.333 | w400 | 0 | The word being studied on a flashcard (Flutter displaySmall) |
| `term-tile` | `headlineSmall` | 20 | 28 | 1.400 | w400 | 0 | Korean word inside a MatchTile (Flutter headlineSmall) |
| `display-stat` | `displayMedium` | 28 | 36 | 1.286 | w500 | 0 | Key numbers that replace a sentence: due count, stat values (Flutter displayMedium) |
| `title-section` | `titleLarge` | 20 | 28 | 1.400 | w600 | 0 | Section headings on a screen (Flutter titleLarge) |
| `title-card` | `titleMedium` | 18 | 24 | 1.333 | w500 | 0.15 | Card titles and key numbers in compact stats (Flutter titleMedium) |
| `title-item` | `titleSmall` | 14 | 20 | 1.429 | w500 | 0.1 | Item and row titles: deck name, ActionRow label, card header row (Flutter titleSmall) |
| `body-content` | `bodyLarge` | 16 | 24 | 1.500 | w400 | 0 | Card content the learner reads: meaning on Review, Recall and Fill cards (Flutter bodyLarge) |
| `body` | `bodyMedium` | 14 | 20 | 1.429 | w400 | 0.25 | Interface copy: list subtitles, hints next to an icon (Flutter bodyMedium) |
| `body-tile` | `bodySmall` | 13 | 16 | 1.231 | w400 | 0 | Meaning text inside a MatchTile, on MatchScreen and as answer options on GuessScreen (Flutter bodySmall) |
| `label-button` | `labelLarge` | 14 | 20 | 1.429 | w400 | 0.1 | Button labels in both Button sizes (Flutter labelLarge) |
| `label-meta` | `labelMedium` | 14 | 20 | 1.429 | w400 | 0.5 | Progress text, search placeholder, banner message, counts (Flutter labelMedium) |
| `label-nav` | `labelSmall` | 12 | 16 | 1.333 | w500 | 0.5 | NavigationBar labels (Flutter labelSmall) |

Quy tắc: chữ giao diện 14; chữ nội dung học (`display-term`, `term-tile`, `body-content`, `body-tile`) giữ cỡ của nó và letter-spacing 0. Chữ trên nút weight 400, không in đậm.

### 10.4 Spacing

| Token DS | Field Flutter | Giá trị | Dùng cho |
|---|---|---|---|
| `space-4` | `space4` | `4` | Icon to its label inside a control |
| `space-8` | `space8` | `8` | Small gaps between related controls; chip internals |
| `space-12` | `space12` | `12` | Progress track to its label inside the continue card |
| `space-16` | `space16` | `16` | Deck tile to its text; heading to the content right under it |
| `space-24` | `space24` | `24` | Screen side margin, card inner padding, between list items, card to page indicator |
| `space-32` | `space32` | `32` | Card title block to the progress track |
| `space-48` | `space48` | `48` | Between page sections (page indicator to the next section heading) |
| `margin-screen` | `marginScreen` | `16` | Left and right screen margin on compact windows (< 600dp), Material 3 |
| `margin-screen-medium` | `marginScreenMedium` | `24` | Screen margin from 600dp (medium, expanded) |

### 10.5 Bo góc (thang shape M3)

| Token DS | Field Flutter | Giá trị | Dùng cho |
|---|---|---|---|
| `radius-xs` | `radiusXs` | `4` | Extra-small (M3) |
| `radius-sm` | `radiusSm` | `8` | Small (M3) |
| `radius-md` | `radiusMd` | `12` | Medium (M3) |
| `radius-lg` | `radiusLg` | `16` | Large (M3) |
| `radius-xl` | `radiusXl` | `28` | Extra-large (M3) |
| `radius-full` | `radiusFull` | `StadiumBorder / height ÷ 2` | Buttons, search bar, progress track and value, page dots, avatar, badge, navigation indicator |

### 10.6 Kích thước và breakpoint

| Token DS | Field Flutter | Giá trị | Dùng cho |
|---|---|---|---|
| `size-control` | `sizeControl` | `48` | Minimum touch target and icon button size (48) |
| `size-button` | `sizeButton` | `40` | Default Button height (M3 Expressive S) |
| `size-button-small` | `sizeButtonSmall` | `32` | Small Button height (M3 Expressive XS) |
| `size-search` | `sizeSearch` | `56` | SearchBar height (M3) |
| `size-avatar` | `sizeAvatar` | `48` | Profile avatar |
| `size-tile` | `sizeTile` | `64` | Deck icon tile in lists |
| `size-nav` | `sizeNav` | `64` | NavigationBar height (M3 Expressive flexible navigation bar), excluding the system gesture inset |
| `size-rail` | `sizeRail` | `80` | NavigationRail width on medium and expanded windows (600dp and up) |
| `size-nav-indicator-width` | `sizeNavIndicatorWidth` | `56` | Width of the pill behind the selected destination icon in NavigationBar and NavigationRail |
| `size-nav-indicator-height` | `sizeNavIndicatorHeight` | `32` | Height of that pill |
| `size-icon` | `sizeIcon` | `24` | Navigation, search and overflow icons |
| `size-icon-tile` | `sizeIconTile` | `32` | Deck icon inside size-tile |
| `size-track` | `sizeTrack` | `4` | Linear progress track height (M3) |
| `size-badge` | `sizeBadge` | `12` | Notification dot on the avatar, with a 2px surface ring |
| `size-dot` | `sizeDot` | `8` | Page indicator dot, 6px apart (14px pitch) |
| `size-dot-small` | `sizeDotSmall` | `4` | Trailing page indicator dot |
| `size-content-max` | `sizeContentMax` | `599` | Max width of the single content column on compact windows and of study sessions on every window |
| `size-content-max-wide` | `sizeContentMaxWide` | `1040` | Max width of the two-column content area on medium and expanded windows (600dp and up), centered |
| `breakpoint-medium` | `breakpointMedium` | `600` | Window width where the layout switches from compact (one column, NavigationBar) to medium (NavigationRail) |
| `breakpoint-expanded` | `breakpointExpanded` | `840` | Window width where medium becomes expanded |

### 10.7 Độ dày nét

| Token DS | Field Flutter | Giá trị | Dùng cho |
|---|---|---|---|
| `stroke-hairline` | `strokeHairline` | `1` | divider lines and the dark card border (outlineVariant) |
| `stroke-focus` | `strokeFocus` | `2` | Focus ring in primary, offset 2px |

### 10.8 Opacity (state layer M3)

| Token DS | Field Flutter | Giá trị | Dùng cho |
|---|---|---|---|
| `opacity-hover` | `opacityHover` | `0.08` | Hover overlay |
| `opacity-pressed` | `opacityPressed` | `0.10` | Pressed overlay |
| `opacity-focus` | `opacityFocus` | `0.10` | Focus overlay (keyboard focus), drawn together with the focus ring |
| `opacity-dragged` | `opacityDragged` | `0.16` | Dragged overlay |
| `opacity-disabled-content` | `opacityDisabledContent` | `0.38` | Disabled text and icons (onSurface) |
| `opacity-disabled-container` | `opacityDisabledContainer` | `0.12` | Disabled container fill (onSurface) |

### 10.9 Motion

| Token DS | Field Flutter | Giá trị | Dùng cho |
|---|---|---|---|
| `motion-easing-standard` | `motionEasingStandard` | `cubic-bezier(0.2, 0, 0, 1)` | Small, utility moves that start and end on screen (color, opacity changes) |
| `motion-easing-standard-decelerate` | `motionEasingStandardDecelerate` | `cubic-bezier(0, 0, 0, 1)` | Small elements entering the screen |
| `motion-easing-standard-accelerate` | `motionEasingStandardAccelerate` | `cubic-bezier(0.3, 0, 1, 1)` | Small elements leaving the screen, e.g |
| `motion-easing-emphasized` | `motionEasingEmphasized` | `cubic-bezier(0.2, 0, 0, 1)` | Expressive moves that start and end on screen: card swipe in ReviewScreen, page transitions |
| `motion-easing-emphasized-decelerate` | `motionEasingEmphasizedDecelerate` | `cubic-bezier(0.05, 0.7, 0.1, 1)` | Expressive enter: next card or screen arriving |
| `motion-easing-emphasized-accelerate` | `motionEasingEmphasizedAccelerate` | `cubic-bezier(0.3, 0, 0.8, 0.15)` | Expressive exit: card or screen leaving |
| `motion-easing-linear` | `motionEasingLinear` | `linear` | Only for progress over time, such as the 15 s countdown ring |
| `motion-duration-short2` | `motionDurationShort2` | `100ms` | Selection and state-layer changes (tile selected, hover, pressed) |
| `motion-duration-short3` | `motionDurationShort3` | `150ms` | State color changes on tiles (MatchTile selected, correct, incorrect) |
| `motion-duration-short4` | `motionDurationShort4` | `200ms` | Small exits and fades: matched MatchTile fade-out, banner dismiss |
| `motion-duration-medium2` | `motionDurationMedium2` | `300ms` | Small enters and component expand: banner appear, indicator pill move |
| `motion-duration-medium4` | `motionDurationMedium4` | `400ms` | Card swipe and page transitions; also the hold time after a correct answer |
| `motion-duration-long4` | `motionDurationLong4` | `600ms` | Large transitions; also the hold time after a wrong match before tiles reset |

Flutter có sẵn motion M3: `Easing.standard`, `Easing.standardDecelerate`, `Easing.standardAccelerate`, `Easing.emphasizedDecelerate`, `Easing.emphasizedAccelerate`, `Curves.easeInOutCubicEmphasized`, `Durations.short2/short3/short4/medium2/medium4/long4`. Dùng các hằng này, không khai báo lại số.

### 10.10 Độ nổi

- Không có bóng nghỉ (resting shadow) ở cả hai chế độ: `shadow-raised` = `none`.
- Card và SearchBar nổi bằng tông nền (`cardSurface`, `searchSurface`), không bóng, không viền, giống nhau ở light và dark.
- `Card(elevation: 0, color: cardSurface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: radiusMd))`.