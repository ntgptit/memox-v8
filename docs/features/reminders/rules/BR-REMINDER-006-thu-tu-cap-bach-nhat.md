---
id: BR-REMINDER-006
title: Thứ tự "cấp bách nhất"
status: active
summary: "Cấp bách nhất" là thứ tự toàn phần, tất định theo overdue, tuổi overdue, rồi tên và id.
superseded_by:
---
## Rule

"Cấp bách nhất" MUST là một thứ tự **toàn phần và tất định**: số thẻ overdue giảm dần, rồi tuổi overdue lớn nhất (số ranh giới ngày địa phương đã qua, BR-STUDY-067) giảm dần, rồi số thẻ due-today giảm dần, rồi tên deck tăng dần, rồi `deck.id` tăng dần. Không được có tie chưa phân giải: hai deck cùng mọi số liệu MUST xếp theo tên rồi id, không theo thứ tự database trả về.

**Enforced by:** rule
**Liên quan:** BR-STUDY-067

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Hai deck có số overdue và tuổi overdue bằng nhau | Xếp theo tên rồi `id`, không theo thứ tự database (BR-REMINDER-006) |
