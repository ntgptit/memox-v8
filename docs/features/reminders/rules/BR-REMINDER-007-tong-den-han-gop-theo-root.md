---
id: BR-REMINDER-007
title: Tổng đến hạn gộp theo root deck
status: active
summary: Tổng thẻ đến hạn gộp theo root qua `root_id`, mỗi thẻ đếm đúng một lần.
superseded_by:
---
## Rule

Tổng số thẻ đến hạn MUST gộp theo **root deck** qua `deck.root_id` (BR-DECK-003) và MUST đếm mỗi thẻ **đúng một lần**: một thẻ MUST NOT bị cộng thêm vì tổ tiên và hậu duệ của deck chứa nó cùng có mặt trong danh sách. `COALESCE(parent_id, id)` MUST NOT được dùng để tra root.

**Enforced by:** db + rule
**Liên quan:** BR-DECK-002, BR-DECK-003, BR-REMINDER-003

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
