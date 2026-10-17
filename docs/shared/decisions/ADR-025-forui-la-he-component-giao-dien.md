---
id: ADR-025
title: ForUI là hệ component giao diện; Material chỉ còn là hạ tầng
status: active
superseded_by:
---
## Bối cảnh

Đến 2026-10-16, giao diện V8 là một hệ Material 3 tự dựng: `ThemeData` với
`ColorScheme` 46 role, hai `ThemeExtension`, hai file component theme viết tay và
`MxFocusRingBorder`, tất cả sinh từ `design/tokens.json` bằng
`tools/design/generate.py` ([ADR-022](ADR-022-mot-nguon-token-va-theme-flutter.md)).
Mỗi widget `Mx*` phải tự vá hành vi Material (vòng focus lệch khung, scrim, tint bề
mặt, màu chữ trên nền tint), và mỗi bản vá cần một rule M3 (`tools/m3_lint`,
`M3L01`..`M3L08`) cùng một sổ đối chiếu (`docs/shared/design/m3-adoption-ledger.md`)
để giữ. Chủ dự án yêu cầu (task 2026-10-17) chuyển toàn bộ UI sang ForUI: một hệ
component có sẵn trạng thái, focus, overlay và theme, để app ngừng duy trì một design
system Material riêng.

## Quyết định

- **ForUI (`forui` 0.27.6, ghim đúng phiên bản) là hệ component giao diện.**
  `FThemeData` là theme chính của app; các widget `Mx*` trong `lib/shared/widgets/`
  là facade của app, dựng trên component ForUI (`FButton`, `FTappable`, `FCard`,
  `FTextField`, `FSwitch`, `FSlider`, `FCheckbox`, `FRadio`, `FBadge`, `FDialog`,
  route sheet của ForUI, `showFToast`, `FTooltip`, `FDivider`,
  `FBottomNavigationBar`). Không dùng Mix, Remix hay Fortal.
- **Feature chỉ dùng `Mx*`.** `package:forui` chỉ được import trong
  `lib/core/theme/`, `lib/shared/` và `lib/app/` (`tools/ui_lint` UIL06, guard
  `no_forui_in_features`).
- **Một nguồn giá trị, viết bằng Dart.** Màu chỉ được viết ở
  `lib/core/theme/app_palette.dart` (hai `FColors`: nền neutral của ForUI, `primary`
  indigo MemoX) và `mx_status_colors.dart` (success, warning, info). Thang chữ là
  `AppTypography` (`FTypography`, Be Vietnam Pro) với 12 role `MxTextRoles`; khoảng
  cách và kích thước bố cục là `AppDimens`; bo góc, độ dày viền và bóng là của ForUI.
  `design/tokens.json`, `generate.py`, `codemod.py` và `lib/core/theme/generated/`
  bị xoá.
- **Tài liệu sinh từ theme production.** Frontmatter của `DESIGN.md` và phần token
  của `.impeccable/design.json` được render từ `buildLightTheme()` /
  `buildDarkTheme()` (`tools/design/design_doc.dart`); `test/tools/design_doc_test.dart`
  đỏ khi file đã commit lệch (`MEMOX_WRITE_DESIGN_DOCS=1` ghi lại).
- **Danh sách file theme đóng** (`tools/design/check.py`): `app_theme.dart`,
  `app_palette.dart`, `app_typography.dart`, `app_dimens.dart`,
  `mx_status_colors.dart`, `app_icons.dart` (Lucide qua `FLucideIcons`),
  `color_tint.dart`, `theme_rules.dart`, `theme_context.dart`, `mastery_ramp.dart`.
  `ThemeContext` chỉ có `colors`, `texts`, `status`, `dimens`, `radii`, `hairline`.
- **Phạm vi theme.** `MaterialApp.router` (giữ vì go_router dựng page route theo
  `MaterialApp`) nhận theme host. `builder` đặt `AppThemeHost`: `FTheme` →
  `Theme` của `material_ui` (ForUI tự đọc) → `FToaster`, bọc Navigator, nên mọi route
  và overlay của root navigator kế thừa cùng một theme. Light/Dark/System đổi bằng
  `themeMode` và `resolveBrightness`, không dựng lại router (BR-SETTINGS-005).
- **Material chỉ là hạ tầng, một chiều.** `package:flutter/material.dart` chỉ được
  import qua danh sách `show` gồm tên hạ tầng (`MaterialApp`, `Scaffold` trong
  `MxAppShell`, `MaterialPageRoute`, `RefreshIndicator`, `ReorderableListView`,
  `SelectableText`, `SelectionArea`, `MaterialLocalizations`, `TimeOfDay`,
  `Durations`, `Easing`, `ThemeMode`); `material_ui` chỉ cho kiểu ForUI tự nhận
  (`ThemeExtension`, `InputBorder`). Theme host (`materialHostTheme`) được suy ra từ
  `FColors` và thang chữ ForUI, không ngược lại (`tools/ui_lint` UIL03, UIL05).
- **Overlay chỉ qua adapter.** `showMxDialog`, `showMxBottomSheet` và
  `showMxSnackbar` là nơi duy nhất mở route overlay (UIL01). Barrier là
  `FColors.barrier`; popup đang giữ (`MxHeldRoute`) chặn chạm barrier, kéo và Back.
- **Không Cupertino, chỉ Android.** iOS không thuộc phạm vi xác minh; Cupertino và
  `.adaptive` bị cấm (UIL02).
- **Cổng mới thay cổng M3.** `tools/ui_lint` (UIL00..UIL06) thay `tools/m3_lint`;
  rule guard `colors_reads_are_forui_roles` thay `color_scheme_reads_are_m3_roles`;
  `test/app/production_theme_test.dart` thay hai test M3 của `test/app/`. Danh sách
  tên bị cấm (`tools/design/removed_symbols.json`) phủ toàn bộ theme Material 3.

## Hệ quả

- [ADR-022](ADR-022-mot-nguon-token-va-theme-flutter.md) bị thay toàn bộ.
  [ADR-019](ADR-019-app-la-chuan-ui.md) giữ nguyên quyết định retire kit v3; thứ tự
  thẩm quyền thành BR/UC > theme ForUI production (`lib/core/theme/`, `DESIGN.md`
  sinh từ nó) > golden đã duyệt > file chi tiết của màn.
- Mọi golden được vẽ lại sau khi chủ dự án duyệt trang so sánh trước · sau · khác
  biệt (`golden-compare`). Kích thước, bo góc và màu đổi theo ForUI: nút cao 48 với
  bo góc `md`, card viền `border`, nền trang trắng/đen neutral, chữ phụ
  `mutedForeground`.
- API công khai đổi ở vài chỗ (`showMxSnackbar` trả `MxSnackbarController`; helper
  chip mới; `MxSlider.semanticFormatter`); danh sách đầy đủ trong
  [`docs/forui-migration/SHARED_WIDGET_INVENTORY.md`](../../forui-migration/SHARED_WIDGET_INVENTORY.md).
- Nâng ForUI là một thay đổi có review: style của nó làm golden đổi.
- `docs/shared/design/m3-adoption-ledger.md` và các skill Material 3 thành hồ sơ lịch
  sử; quy trình đổi giao diện ở [`docs/agent/visual-change.md`](../../agent/visual-change.md),
  kiến trúc ở [`docs/forui-migration/FORUI_ARCHITECTURE.md`](../../forui-migration/FORUI_ARCHITECTURE.md).
