---
id: BR-MODE-003
title: Chuỗi stage cho học mới, một mode cho ôn tập
status: active
summary: Phiên học mới chạy chuỗi stage cố định; phiên ôn tập chạy đúng một mode người dùng chọn.
superseded_by:
---
## Rule

Phiên **học mới** MUST chạy một **chuỗi stage** theo thứ tự cố định do thuật toán khai báo; người dùng MUST NOT chọn stage. Phiên **ôn tập** MUST chạy đúng **một** mode do người dùng chọn (BR-STUDY-055).

**Enforced by:** rule
**Liên quan:** BR-MODE-004, BR-STUDY-051

## Lý do

**Không còn mục nào để trống.** Câu cuối cùng — lượt nào trong chuỗi stage đổi
lịch — được BR-STUDY-023 trả lời, và câu trả lời đã nằm sẵn trong cơ chế round.

**Vì sao BR-SRS-016 vẫn đúng dù nó được viết cho một phiên một cách hỏi.** BR-STUDY-069 bắt
mỗi stage lặp cho tới khi một round không còn thẻ sai, nên **lượt cuối của mọi
stage luôn là một lần đúng** — nó không mang tín hiệu nào về trí nhớ, chỉ nói rằng
vòng lặp đã kết thúc. Thứ duy nhất cho biết người học có thực sự nhớ hay không là
**lần thử đầu tiên**, khi chưa có stage nào nhắc bài. Lấy kết quả cuối chuỗi sẽ
cho mọi thẻ đều "nhớ được", và SRS mất sạch tín hiệu.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
