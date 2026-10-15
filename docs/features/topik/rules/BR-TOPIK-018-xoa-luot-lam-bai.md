---
id: BR-TOPIK-018
title: Xoá lượt làm bài
status: active
summary: Xoá một lượt, dở hay đã nộp, cần xác nhận và xoá cả đáp án trong cùng một transaction; xoá lượt đã nộp được đồng bộ.
superseded_by:
---
## Rule

Xoá một lượt MUST qua một xác nhận. Lượt và mọi đáp án của nó MUST bị xoá trong **cùng một transaction**. Xoá lượt đã nộp MUST được đồng bộ như một lần xoá cuối cùng (BR-TOPIK-026); lượt dở chưa bao giờ đồng bộ nên không có gì để gửi. Thống kê và số thứ tự lượt tính lại ngay (BR-TOPIK-021).

**Enforced by:** store + UI
**Liên quan:** BR-TOPIK-010, BR-TOPIK-021, BR-TOPIK-026

## Lý do

Xoá một nửa để lại đáp án mồ côi làm sai thống kê theo câu.

## Ví dụ

Xoá lượt #2 trong ba lượt: lượt #3 thành #2; Best và Average tính lại.

## Edge case

Xoá lượt đang mở ở màn khác: màn đó hiện trạng thái lượt không còn.
