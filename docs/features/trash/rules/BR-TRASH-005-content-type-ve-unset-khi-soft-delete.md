---
id: BR-TRASH-005
title: content_type về unset khi soft-delete
status: active
summary: Soft-delete lấy đi direct child active cuối cùng thì deck non-root về `unset` cùng transaction.
superseded_by:
---
## Rule

Khi soft-delete lấy đi direct child **đang active** cuối cùng của một deck non-root, deck đó MUST tự về `content_type = unset` trong cùng transaction. Root MUST giữ `deck` (BR-DECK-004). MUST NOT có thao tác reset thủ công. Tombstone còn nằm trong deck MUST NOT được tính là nội dung khi đo điều kiện này.

**Enforced by:** store
**Liên quan:** BR-DECK-015, BR-DECK-004

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
