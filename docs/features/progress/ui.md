# Progress — UI

Màn hình và điều hướng dùng chung hai UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Màn hình và điều hướng

| Màn | Route | Mở từ | Handoff |
|---|---|---|---|
| 22 · Progress, cấp thư viện | `/progress` (tab Progress) | Bottom bar | [22-progress.md](../../shared/ui/screen-handoff/22-progress.md) |
| 22 · Progress, cấp của một deck | `/progress/:deckId`, trong branch Progress, có bottom bar | Một hàng deck ở cấp trên; một đoạn của breadcrumb | [22-progress.md](../../shared/ui/screen-handoff/22-progress.md) |

Mỗi hàng deck push thêm một cấp; Back về đúng cấp vừa rời. Khoảng 7 hoặc 30 ngày là một
lựa chọn chung cho mọi cấp của tab: mở một deck từ "Last 30 days" thì cấp đó cũng ở 30
ngày. Đổi khoảng không đọc lại database (BR-PROGRESS-003). Khi chưa từng học, nút "Start
studying" mở tab Học. Nguồn: [spec FE-A9](../../superpowers/specs/2026-09-27-progress-ui-design.md)
§3 (D1, D4, D5), §5.

## Validation

Không có: màn chỉ đọc, không có trường nhập (BR-PROGRESS-009).
