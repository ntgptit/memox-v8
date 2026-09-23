---
id: ADR-006
title: Cây deck nhiều cấp, mỗi deck một loại nội dung
status: active
superseded_by:
---
Quyết định đã chốt ngày 2026-07-28 (trước migrate nằm ở `product/product.md`, mục "Quyết định đã chốt").

## Quyết định

**Cấu trúc deck: cây nhiều cấp, mỗi deck chỉ chứa một loại.** Root deck chỉ chứa
deck con. Deck con mới tạo chưa xác định loại; lần tạo phần tử con đầu tiên xác
lập nó thành "chứa card" hoặc "chứa deck con", và sau đó không trộn lẫn. Người
dùng không phải chọn loại lúc tạo deck — lúc đó họ chưa biết. Xem UC-DECK-004.

Luật: BR-DECK-001…BR-DECK-012, BR-DECK-015; luồng UC-DECK-004.
