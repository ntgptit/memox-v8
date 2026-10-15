---
id: BR-TOPIK-014
title: Nộp khi còn câu bỏ trống
status: active
summary: Nộp khi còn câu chưa trả lời cần xác nhận nêu số câu trống; câu trống được tính 0 điểm.
superseded_by:
---
## Rule

Khi người dùng nộp mà còn câu chưa trả lời, app MUST hiện xác nhận nêu số câu trống trước khi nộp. Huỷ xác nhận giữ lượt `in_progress`, không đổi gì. Câu trống được chấm `unanswered`, 0 điểm (BR-TOPIK-013). Nộp khi đã trả lời đủ không cần xác nhận.

Trong lúc nộp, chạm nộp lần nữa hay Back MUST không có tác dụng.

**Enforced by:** UI
**Liên quan:** BR-TOPIK-013

## Lý do

Nộp là không quay lại được (BR-TOPIK-010); một xác nhận rẻ hơn một lượt hỏng.

## Ví dụ

Còn 3 câu trống, chạm Nộp: hỏi "3 câu chưa trả lời. Nộp bài?"; xác nhận thì nộp, 3 câu đó 0 điểm.

## Edge case

Chạm Nộp hai lần liên tiếp: chỉ một lần nộp được ghi.
