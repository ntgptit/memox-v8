---
feature: deck
code: [lib/features/deck/domain, lib/features/deck/data, lib/features/deck/di, lib/core/database/queries/deck_queries.drift]
depends_on: []
---
## Phạm vi

Cây deck, tên và xoá deck (V8.0): luồng tạo, sửa, xoá, di chuyển và sắp xếp lại
deck. Luật ở [`rules/`](rules/), luồng ở [`usecases/`](usecases/), điều hướng và
validation dùng chung ở [`ui.md`](ui.md), state machine `content_type` ở
[`data.md`](data.md).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Danh sách deck (màn gốc của tab Thư viện) | UC-DECK-003, UC-DECK-001, UC-DECK-006 |
| Một deck đang mở | UC-DECK-003 A3, UC-DECK-004, UC-DECK-002, UC-DECK-005 |

Nguồn: trigger của UC-DECK-001 ("màn hình danh sách deck"), UC-DECK-006
("Library đang ở Manual order"), UC-DECK-004 ("bên trong một deck"); sơ đồ điều
hướng ở [`ui.md`](ui.md) (điểm vào "Một deck đang mở").

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Đưa deck con lên thành root deck | Cần quyết định scheduler mới; là tính năng riêng, không phải phép di chuyển (UC-DECK-005 A2) |
| Nội dung card | Feature `card` |
| Scheduler | Feature `srs` |
