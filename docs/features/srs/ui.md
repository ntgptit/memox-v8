# SRS scheduler — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Deck.schedulerType | bắt buộc chọn khi tạo root deck | "Hãy chọn chế độ ôn tập cho deck" | rule |
| Deck.move | đích cùng root scheduler và generation | "Deck đích dùng chế độ ôn tập khác. Hãy đặt lại tiến độ học trước khi di chuyển" | rule |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.

> ⚠️ OPEN QUESTION: 2 dòng validation trên không trích BR nào trong nguồn: `Deck.schedulerType` bắt buộc chọn khi tạo root deck; `Deck.move` đích cùng root scheduler và generation. (Plan Q5)

## Edge case chưa gắn BR

| Case | Expected behaviour |
|---|---|
| Đổi giờ hệ thống / lệch múi giờ | Lưu và so sánh `due_at` bằng UTC |

> ⚠️ OPEN QUESTION: 1 dòng edge case trên không trích BR nào trong nguồn. (Plan Q5)
