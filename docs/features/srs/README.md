---
feature: srs
code: [lib/features/srs/domain, lib/features/srs/data, lib/features/srs/di]
depends_on: [card, deck]
---
## Phạm vi

Hai scheduler (`eight_box`, `sm2`), chọn và khoá/đổi scheduler, loại lượt ôn, reset learning progress và `generation` (V8.0).

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Scheduler thứ ba | Abstraction đã sẵn sàng; thêm khi có nhu cầu thật |
| Chọn scheduler lúc tạo và đổi khi chưa khoá | Luồng thuộc UC-DECK-001, UC-DECK-002 (feature `deck`); luật ở đây |
