---
feature: progress
code: []
depends_on: [deck, srs, study, study-mode]
---
## Phạm vi

Tiến độ theo deck và Progress overview (V8.0): đọc lại lịch sử học, không ghi gì.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

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
