---
id: BR-PROGRESS-014
title: Phân rã một ngày Learning/Reviewing (overview)
status: active
summary: Card-day là Learning khi có lượt `learning`, ngược lại là Reviewing; partition loại trừ nhau.
superseded_by:
---
## Rule

Phân rã của một ngày là một **partition loại trừ nhau**: một card-day là **Learning** khi có ít nhất một answer `kind = 'learning'` trong ngày đó; nếu không, và chỉ khi đó, nó là **Reviewing** khi có answer `scheduled` hoặc `relearning`. `learning + reviewing = total` MUST luôn đúng cho mọi ngày. Một card vừa `learning` vừa `scheduled` trong cùng ngày MUST đếm là Learning và MUST NOT đếm hai lần.

**Enforced by:** store (SQL)
**Liên quan:** BR-SRS-015, BR-PROGRESS-011

## Lý do

Cùng khái niệm phân hoạch Learning/Reviewing với BR-PROGRESS-005, rule tương ứng của Progress by Deck; hai rule áp cho hai màn và được giữ cả hai (chủ dự án chốt khi xử lý OQ-19 (2026-09-23)). Sửa một rule thì kiểm tra rule kia.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
