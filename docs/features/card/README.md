---
feature: card
code: [lib/features/card/domain, lib/features/card/data, lib/features/card/di, lib/core/database/queries/card_queries.drift, lib/core/database/queries/card_row_queries.drift, lib/core/database/queries/card_list_queries.drift, lib/core/database/queries/live_row_queries.drift]
depends_on: [deck]
---
## Phạm vi

Nội dung card, cờ, di chuyển, thao tác hàng loạt và chi tiết card kèm lịch sử học (V8.0): quản lý card trong một deck loại `card` và màn chi tiết chỉ đọc.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Card đầu tiên của deck `unset` | Tạo ở UC-DECK-004, feature `deck` |
| Media trong card | Ngoài MVP; quy tắc reset (BR-SRS-021) đã đặt sẵn, và khi thêm sẽ lưu trong thư mục riêng của ứng dụng như mọi dữ liệu riêng tư khác, không phải bộ nhớ dùng chung |
| Quản lý tag | Feature `tags` |
