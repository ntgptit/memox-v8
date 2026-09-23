---
feature: srs
code: []
depends_on: []
---
## Phạm vi

Hai scheduler (`eight_box`, `sm2`), chọn và khoá/đổi scheduler, loại lượt ôn, reset learning progress và `generation` (V8.0).

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Xác nhận "Đặt lại tiến độ học" trên một root deck | UC-SRS-001 |

Nguồn: trigger của UC-SRS-001 ("thường từ chỗ giải thích vì sao chế độ ôn tập đang bị khoá (UC-DECK-002 A1)"). Chọn và đổi scheduler là một phần của UC-DECK-001 và UC-DECK-002 (feature `deck`).

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Scheduler thứ ba | Abstraction đã sẵn sàng; thêm khi có nhu cầu thật |
| Chọn scheduler lúc tạo và đổi khi chưa khoá | Luồng thuộc UC-DECK-001, UC-DECK-002 (feature `deck`); luật ở đây |
