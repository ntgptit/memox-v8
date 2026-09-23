---
feature: progress
code: []
depends_on: [deck, srs, study, study-mode]
---
## Phạm vi

Tiến độ theo deck và Progress overview (V8.0): đọc lại lịch sử học, không ghi gì.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

> ⚠️ OPEN QUESTION: nội dung màn Progress (và điều hướng top-level) được `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` §10 liệt kê là câu hỏi mở của product definition (sub-project 2), nhưng BR-PROGRESS-* và UC-PROGRESS-* đã chốt nội dung màn hình. (Plan OQ-3)

> ⚠️ OPEN QUESTION: nguồn định nghĩa cùng khái niệm ở hai rule của hai section (Progress by Deck và Progress overview): card-day ở BR-PROGRESS-002 và BR-PROGRESS-011; phân hoạch Learning/Reviewing ở BR-PROGRESS-005 và BR-PROGRESS-014; chỉ-đọc ở BR-PROGRESS-007 và BR-PROGRESS-009. Chưa rõ rule nào là nguồn duy nhất. Nguồn: `business-rules/progress.md`. (Plan OQ-19)

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tab Tiến độ / Progress | UC-PROGRESS-001, UC-PROGRESS-002 |
| Hàng deck trên màn tiến độ (drill-down) | UC-PROGRESS-002 |

Nguồn: trigger của UC-PROGRESS-001 ("Chạm tab **Tiến độ / Progress** ở bottom navigation") và UC-PROGRESS-002 ("Mở tab Progress, hoặc chạm một hàng deck trên màn hình tiến độ").

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Accuracy, longest streak, goal, XP, heatmap, lọc theo deck, chia sẻ, hiệu ứng ăn mừng | Cần định nghĩa nghiệp vụ riêng chưa được chốt (BR-PROGRESS-010) |
