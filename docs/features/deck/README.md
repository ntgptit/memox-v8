---
feature: deck
code: [lib/features/deck/domain, lib/features/deck/data, lib/features/deck/di, lib/core/database/queries/deck_queries.drift]
depends_on: []
---
## Phạm vi

Cây deck, tên và xoá deck (V8.0): luồng tạo, sửa, xoá, di chuyển và sắp xếp lại
deck. Luật ở [`rules/`](rules/), luồng ở [`USE_CASES.md`](../../USE_CASES.md#deck), chức năng ở
[`functional-spec/deck.md`](../../functional-spec/deck.md), màn ở SCR-DECK-001, state machine
`content_type` ở [`data.md`](data.md).

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Đưa deck con lên thành root deck | Cần quyết định scheduler mới; là tính năng riêng, không phải phép di chuyển (UC-DECK-005 A2) |
| Nội dung card | Feature `card` |
| Scheduler | Feature `srs` |
