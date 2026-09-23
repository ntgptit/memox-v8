---
id: BR-DECK-002
title: Mọi deck mang root_id
status: active
summary: Mỗi deck mang `root_id`; root có `root_id = id`, descendant mang `root_id` của root.
superseded_by:
---
## Rule

Mỗi deck MUST mang `root_id`. Root deck có `root_id = id`; mọi descendant mang đúng `root_id` của root.

**Enforced by:** db + invariant Q6, Q7

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Cây sâu 4–5 cấp | Hoạt động bình thường; root tra qua `root_id` (BR-DECK-002, BR-DECK-003) |
