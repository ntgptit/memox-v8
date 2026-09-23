---
id: BR-TRASH-001
title: Xoá là soft-delete
status: active
summary: Xoá card hoặc deck là soft-delete trong một transaction, tạo đúng một batch và một item root.
superseded_by:
---
## Rule

Xoá card hoặc deck MUST là soft-delete trong **một** transaction và MUST NOT xoá cứng bất cứ hàng nào, kể cả descendant. Thao tác MUST tạo đúng một batch mang `deleted_at` và một item root. UI MUST nói item đã được chuyển vào Trash, MUST NOT nói đã xoá vĩnh viễn, và với thao tác xoá **một** item MUST cung cấp Undo ngay tại chỗ. Xoá nhiều item cùng lúc MUST tạo một batch cho mỗi item root, MUST NOT gộp thành một batch chung — mỗi item root là một thứ người dùng khôi phục được riêng.

**Enforced by:** store + UI
**Liên quan:** BR-DECK-022, BR-DECK-023

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
