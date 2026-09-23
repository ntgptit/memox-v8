---
id: BR-DECK-003
title: Xác định root qua root_id
status: active
summary: Root được xác định qua `root_id`, không bao giờ bằng `COALESCE(parent_id, id)`.
superseded_by:
---
## Rule

Xác định root MUST qua `root_id`. MUST NOT dùng `COALESCE(parent_id, id)`.

**Enforced by:** script

## Lý do

BR-DECK-003 cấm đúng một biểu thức đã từng xuất hiện trong tài liệu.
`COALESCE(parent_id, id)` cho ra "cha, hoặc chính nó nếu không có cha", nên
với deck ở cấp 3 nó trả về deck cấp 2 chứ không phải root.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
