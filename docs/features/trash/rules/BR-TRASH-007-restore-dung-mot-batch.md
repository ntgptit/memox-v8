---
id: BR-TRASH-007
title: Restore đúng một batch
status: active
summary: Restore một batch hồi sinh đúng các hàng của batch đó, giữ nguyên id, nội dung, lịch sử và tag.
superseded_by:
---
## Rule

Restore một batch MUST hồi sinh **đúng** những hàng mang batch đó và MUST NOT chạm hàng của batch khác. Id, nội dung, study state, history và tag MUST giữ nguyên. Vị trí cũ MUST NOT được chọn tự động; UI MAY preselect một target hợp lệ nhưng người dùng MUST xác nhận. Restore một deck MUST viết lại `root_id` cho **toàn bộ** subtree của nó, gồm cả tombstone nằm bên trong, để cây không có hàng nào trỏ sai root.

**Enforced by:** store
**Liên quan:** BR-DECK-018, BR-DECK-019

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
