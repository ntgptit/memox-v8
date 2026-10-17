---
id: ADR-022
title: Một nguồn token và theme theo cấu trúc Flutter thông thường
status: deprecated
superseded_by: ADR-025
---
> **Thay bởi [ADR-025](ADR-025-forui-la-he-component-giao-dien.md) (2026-10-17).**
> ForUI là hệ component; giá trị viết bằng Dart ở `lib/core/theme/`; `design/tokens.json`,
> bộ sinh và theme Material 3 đã bị xoá. Phần dưới là hồ sơ lịch sử.

## Bối cảnh

Mỗi lần đổi giao diện phải sửa tay cùng một giá trị ở sáu nơi, và nơi nào cũng là một
cổng kiểm: code theme, test ghim từng giá trị, `DESIGN.md` (Impeccable chấm UI theo
file này), `.impeccable/design.json`, tài liệu của skill và guard. Agent còn hay tạo
lại token cũ (alias, typedef, getter chuyển tiếp) để né lỗi compile thay vì sửa chỗ
dùng. Design System "Flashcard Color Tokens" (chốt 2026-10-13) thay toàn bộ giá trị
màu, chữ, kích thước và bố cục, nên cả hai vấn đề phải giải quyết cùng lúc.

## Quyết định

- **Một nguồn:** `design/tokens.json`, xuất từ Design System, không sửa tay. Giá trị
  app có mà Design System chưa có nằm ở `design/app_tokens.json`.
- **Cấu trúc theme là Flutter Material 3 thông thường.** `ThemeData` gồm `ColorScheme`
  (46 role), `TextTheme` (12 role Design System), hai `ThemeExtension`
  (`MxColorsExtension` 16 field, `AppDimens` 42 field cộng phần app-only) và các
  component theme viết tay chỉ tham chiếu token. Widget đọc chữ thẳng từ role
  `TextTheme` và chỉ đổi màu. Motion dùng `Durations` và `Easing` của Flutter. Không còn
  class `static const` cho token.
- **Sinh tự động:** `tools/design/generate.py` ghi `lib/core/theme/generated/*.g.dart`,
  frontmatter của `DESIGN.md` và phần giá trị token của `.impeccable/design.json`.
  `tools/design/check.py` sinh lại vào thư mục tạm rồi so; lệch là đỏ. Test token đọc
  `tokens.json` lúc chạy, không ghi giá trị nào.
- **Quy tắc "chế độ này dùng role A, chế độ kia role B" thành getter** trong
  `theme_rules.dart` (`accentColor`, `deckIconColor`, `screenMargin`, `windowSize`),
  nơi duy nhất ở phía widget được rẽ nhánh theo `brightness`. Nền tint chỉ tính qua
  `ColorTint.tintOver`.
- **Danh sách file theme đóng**, guard và `tools/design/check.py` giữ: `app_theme.dart`,
  `app_component_themes.dart` (nút, FAB, chip, switch), `app_surface_themes.dart` (card, field,
  điều hướng, dialog, sheet, snackbar, tooltip), `app_typography.dart`, `app_icons.dart`,
  `color_tint.dart`, `theme_rules.dart`, `theme_context.dart`, `mastery_ramp.dart` và `focus_ring_border.dart`
  (`MxFocusRingBorder`: viền bọc một `OutlinedBorder` và vẽ vòng focus lệch khỏi khung,
  dùng cho nút, FAB và chip), cộng `generated/*.g.dart`.
- **Rào chặn tạo lại token cũ:** `tools/design/removed_symbols.json` liệt kê tên đã
  xoá; hook `block_removed_theme_symbols.py`, một bước của `dod_check.sh` và các rule
  guard chặn viết lại chúng. Xoá class cũ trước, lấy lỗi compile làm danh sách việc;
  đổi tên 1:1 bằng `tools/design/codemod.py`.
- Quy trình đổi giao diện về sau: [`docs/agent/visual-change.md`](../../agent/visual-change.md).

## Hệ quả

- Thứ tự thẩm quyền của ADR-019 đổi thành: `design/tokens.json` > golden đã duyệt >
  file chi tiết của màn.
- Spec Indigo 2026-10-10 (D3, D4) và foundations V3 bị thay ở những điểm chúng định nghĩa
  giá trị.
- Bóng của dialog, sheet, FAB và thông báo nổi là elevation của Material, giống nhau ở
  hai chế độ, vì Design System không định nghĩa bóng và widget không được rẽ nhánh theo
  `brightness`. Dialog và sheet giữ giá trị elevation của Material 3 nhưng `shadowColor`
  trong suốt, đúng như Material 3 (chủ sở hữu quyết định 2026-10-14).
- `*.g.dart` trong `lib/core/theme/generated/` được commit (khác các `*.g.dart` của
  build_runner) và `check_generated.py` miễn thư mục này.
