---
feature: progress
code: [lib/features/progress/domain, lib/features/progress/data, lib/features/progress/di, lib/features/progress/presentation]
depends_on: [deck, srs, study]
---
## Phạm vi

Tiến độ theo deck và Progress overview (V8.0): đọc lại lịch sử học, không ghi gì.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Accuracy, longest streak, goal, XP, heatmap, lọc theo deck, chia sẻ, hiệu ứng ăn mừng | Cần định nghĩa nghiệp vụ riêng chưa được chốt (BR-PROGRESS-010) |
