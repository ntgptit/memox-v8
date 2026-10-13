---
id: ADR-022
title: Token "Flashcard Color Tokens" là chuẩn giá trị của hệ thống hình ảnh
status: active
superseded_by:
---
## Bối cảnh

Đến 2026-10-12, giá trị token của V8 nằm ở `lib/core/theme/`, `DESIGN.md`,
`.impeccable/design.json`, spec Indigo 2026-10-10 (D3, D4) và phần foundations của spec
UI base 2026-09-23 (§4). Ngày 2026-10-13 chủ dự án chốt Design System "Flashcard Color
Tokens" (màu Material 3 đủ 46 role, màu mở rộng, Be Vietnam Pro, spacing, bo góc, kích
thước, opacity, motion, bố cục theo cỡ cửa sổ và quy tắc component), ghi tại
[`docs/shared/design/memox-design-tokens.md`](../design/memox-design-tokens.md).

## Quyết định

- File token trên là nguồn sự thật cao nhất về giá trị token. Thứ tự ưu tiên của
  [ADR-019](ADR-019-app-la-chuan-ui.md) đổi thành: BR/UC > file token >
  [`DESIGN.md`](../../../DESIGN.md) > golden đã duyệt > file chi tiết của màn. Khi tài
  liệu, skill, test, comment hay guard nào mâu thuẫn với file token, file token thắng và
  chỗ mâu thuẫn được sửa theo nó.
- `ColorScheme` khai báo đủ 46 role bằng literal, không còn `fromSeed`; seed
  `0xFF4255FF` bị bỏ. `MxSemanticColors` có 44 field; nền tint là màu 16% trên
  `surface` của từng chế độ, quy ra hex đặc (spec D4 "soft ground sáng ở cả hai chế độ"
  bị bỏ, `MxSoftGround` bị xoá).
- Font: Be Vietnam Pro (400, 500, 600) và Noto Sans KR làm fallback, đóng gói trong
  `assets/fonts/` (OFL). Plus Jakarta Sans bị bỏ.
- Mỗi `MxTextStyles` là đúng một trong 12 role của `TextTheme`; chỉ màu được đổi.
- Card, search, navigation nổi bằng tông nền, không viền, không bóng; nút có hai cỡ (40
  và 32) trong vùng chạm 48; lề màn hình là `context.screenMargin` (16 dưới 600, 24 từ
  600); cột nội dung tối đa 599 (compact và phiên học), 1040 từ 600.
- Hai quyết định của chủ dự án cùng ngày, cho chỗ file token không nói rõ:
  - hero card dùng `primarySoft`, vì `primaryContainer` của file token là màu nhấn đặc,
    nút primary và chữ của nội dung không đứng được trên nó;
  - cặp nút footer giữ cạnh nhau khi hai nhãn cùng vừa hàng (chia theo bề rộng nhãn khi
    tỉ lệ flex không vừa); Trash từ 100 mục và kết quả Import tiếng Anh được xếp chồng
    như ngoại lệ ghi nhận.

## Hệ quả

- `test/core/theme/flashcard_tokens_spec_test.dart` ghim mọi giá trị ở mục 1–4 của file
  token; `token_contrast_test.dart` ghi ngoại lệ bằng tỉ lệ đo thực tế.
- `DESIGN.md`, `.impeccable/design.json`, skill `flutter-design-system` cập nhật theo
  file token; spec Indigo 2026-10-10 (D3, D4) và §4 của spec UI base 2026-09-23 mang ghi
  chú "superseded by Flashcard Color Tokens 2026-10-13".
- Với line-height của file token (ví dụ 20/14), dấu chồng tiếng Việt in hoa (Ẳ, Ổ) của
  Be Vietnam Pro cao hơn hộp dòng khoảng 0,12em; một dòng bị cắt bằng ellipsis sẽ cắt
  phần dấu đó. Đây là hệ quả đã biết của quyết định này.
