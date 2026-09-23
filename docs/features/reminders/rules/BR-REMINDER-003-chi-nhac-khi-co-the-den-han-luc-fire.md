---
id: BR-REMINDER-003
title: Chỉ nhắc khi có thẻ đến hạn lúc fire
status: active
summary: Notification chỉ hiện khi `overdue + due-today` > 0 đo lại tại thời điểm fire.
superseded_by:
---
## Rule

Notification MUST chỉ được hiện khi tổng `overdue + due-today` > 0 **đo lại tại thời điểm fire**, không phải tại thời điểm đặt lịch. Thẻ chưa học xong chuỗi learning (`learned_at IS NULL`) MUST NOT được tính và MUST NOT tự mình làm phát notification. Đến giờ mà tổng bằng 0 thì MUST bỏ hẳn lượt nhắc đó và MUST NOT hiện notification rỗng hay notification "không có gì để học".

**Enforced by:** rule
**Liên quan:** BR-STUDY-001, BR-STUDY-051

## Lý do

BR-REMINDER-003 nói "đo lại tại thời điểm fire" chứ không phải "đo lúc đặt lịch": một
notification đã nạp sẵn nội dung từ hôm qua vẫn hiện đúng giờ ngay cả khi người
dùng đã học hết, và nó hiện **số của hôm qua**.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Đến giờ nhắc nhưng người dùng vừa học hết | Bỏ lượt nhắc, không hiện notification nào (BR-REMINDER-003) |
| Chỉ còn thẻ chưa học, không có thẻ đến hạn | Không nhắc — thẻ mới không làm phát notification (BR-REMINDER-003) |
