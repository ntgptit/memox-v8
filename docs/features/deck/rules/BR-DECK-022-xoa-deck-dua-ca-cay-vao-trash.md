---
id: BR-DECK-022
title: Xoá deck đưa cả cây vào Trash
status: active
summary: Xoá deck chuyển deck cùng mọi deck con và card còn active bên dưới vào Trash thành một batch; chỉ purge mới xoá hẳn, theo cascade.
superseded_by:
---
## Rule

Xoá deck MUST chuyển deck đó cùng mọi deck con và card còn active bên dưới vào Trash, thành **một** batch mà item root là chính deck đó (BR-TRASH-001, BR-TRASH-003), và MUST NOT xoá cứng hàng nào. Chỉ purge một batch (BR-TRASH-010) mới xoá hẳn: deck, card, study state, study answers và study session của batch đi theo cascade.

**Enforced by:** store + db
**Liên quan:** BR-TRASH-001, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005, BR-TRASH-010

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
