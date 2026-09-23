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

> ⚠️ OPEN QUESTION: nguồn định nghĩa cùng khái niệm ở hai rule của hai section (Progress by Deck và Progress overview): card-day ở BR-PROGRESS-002 và BR-PROGRESS-011; phân hoạch Learning/Reviewing ở BR-PROGRESS-005 và BR-PROGRESS-014; chỉ-đọc ở BR-PROGRESS-007 và BR-PROGRESS-009. Chưa rõ rule nào là nguồn duy nhất. Nguồn: `business-rules/progress.md`. (Plan OQ-19)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
