# SRS scheduler — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Deck.schedulerType | bắt buộc chọn khi tạo root deck (BR-SRS-001) | "Hãy chọn chế độ ôn tập cho deck" | rule |
| Deck.move | đích cùng root scheduler và generation (BR-SRS-006) | "Deck đích dùng chế độ ôn tập khác. Hãy đặt lại tiến độ học trước khi di chuyển" | rule |

Toàn bộ enforce ở tầng nghiệp vụ của app. Server chỉ kiểm lại tính toàn vẹn (CHECK, khoá ngoại, bất biến cây, [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md) #2) — client validation là trải nghiệm, không phải bảo mật.

## Edge case

| Case | Expected behaviour |
|---|---|
| Đổi giờ hệ thống / lệch múi giờ | Lưu và so sánh `due_at` bằng UTC ([ADR-008](../../shared/decisions/ADR-008-datetime-luu-utc.md)) |
