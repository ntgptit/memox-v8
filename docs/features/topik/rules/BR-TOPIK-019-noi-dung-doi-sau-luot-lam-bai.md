---
id: BR-TOPIK-019
title: Nội dung đổi sau lượt làm bài
status: active
summary: Summary luôn hiện từ bản chốt của lượt; Review cần nội dung, báo khi nội dung đã đổi và báo không khả dụng khi nội dung không còn.
superseded_by:
---
## Rule

- Summary MUST hiện chỉ từ bản chốt của lượt (BR-TOPIK-013), kể cả khi đề đã đổi `contentVersion` hay không còn trong app.
- Review MUST dùng nội dung hiện tại. Khi `contentVersion` hiện tại khác của lượt, Review MUST hiện một thông báo "nội dung đã cập nhật sau lượt này". Khi đề không còn hoặc không hợp lệ, Review MUST báo không khả dụng và Summary vẫn dùng được.
- Tiếp tục một lượt dở khi đề không còn hợp lệ: app MUST không cho tiếp tục và đề nghị xoá lượt.

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-007, BR-TOPIK-013

## Lý do

Kết quả cũ phải đọc được mãi; nội dung bổ trợ có thể thiếu nhưng không được làm hỏng nó.

## Ví dụ

Lượt chấm trên `contentVersion 1`, app nay có bản 2: Summary giữ điểm cũ, Review hiện thông báo cập nhật.

## Edge case

Không áp dụng
