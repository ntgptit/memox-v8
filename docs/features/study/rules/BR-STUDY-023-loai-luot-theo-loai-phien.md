---
id: BR-STUDY-023
title: Loại lượt theo loại phiên
status: active
summary: Học mới: mọi lượt là `learning`/`relearning`, không đổi lịch; ôn tập: lượt đầu `scheduled`, lượt lặp `relearning`.
superseded_by:
---
## Rule

Trong phiên **học mới**, mọi lượt MUST là `learning` hoặc `relearning` và MUST NOT đổi lịch (BR-STUDY-053). Trong phiên **ôn tập**, lượt đầu tiên của mỗi thẻ là `scheduled` và đổi lịch; mọi lượt lặp sau đó là `relearning`.

**Enforced by:** store
**Liên quan:** BR-SRS-016, BR-STUDY-059, BR-STUDY-053

## Lý do

**Một thẻ đi qua nhiều mode trong một phiên, và câu "lượt nào đổi lịch" có hai
câu trả lời khác nhau tùy loại phiên.**

Trong phiên `reviewing`, mỗi thẻ được hỏi bằng **một** mode, nên lượt đầu của nó
là `scheduled` và đổi lịch; các lượt lặp sau đó — round hoặc BR-STUDY-005 — là
`relearning` (BR-SRS-016, BR-STUDY-023).

Trong phiên `learning`, thẻ đi qua cả chuỗi và **không lượt nào đổi lịch**
(BR-STUDY-053). Lý do không phải là tiết kiệm: bốn mode chấm điểm đều lặp tới khi sạch
(BR-STUDY-069), nên mọi thẻ đều kết thúc chuỗi bằng một lần đúng — một `action` suy từ
đó sẽ luôn đọc là "nhớ được" và không phân biệt được thẻ nào. Lịch vì thế được
khởi tạo bởi **sự kiện hoàn tất**, ở mức thấp nhất, giống nhau cho mọi thẻ.

**Mô hình này thay một cách tiếp cận cũ, cho lượt đầu ở stage chấm điểm đầu
tiên quyết định lịch** — một hệ quả được chấp nhận chứ chưa được cân nhắc đủ:
sai ở Match rồi đúng ba stage sau
vẫn cho lịch của một lần sai. Câu hỏi đó không còn tồn tại — trong phiên học mới
không có lịch nào để đặt sai, và trong phiên ôn tập chỉ có một mode nên không có
gì để chọn giữa.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
