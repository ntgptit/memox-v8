---
id: BR-TOPIK-021
title: Lượt gần đây và lịch sử
status: active
summary: Recent Attempts là năm lượt mới nhất; History là mọi lượt; số thứ tự lượt là hạng theo thời điểm bắt đầu trong các lượt còn lại.
superseded_by:
---
## Rule

- Recent Attempts MUST là năm lượt có `started_at` mới nhất, mới nhất trước; History MUST là mọi lượt, cùng thứ tự.
- Số thứ tự `#n` của một lượt MUST là hạng của nó trong các lượt hiện còn của đề theo `started_at` tăng dần; xoá một lượt làm các lượt sau đánh số lại.
- Lượt đã nộp hiện `score / max_score`, ngày giờ, thời lượng và `correct_count / question_count`, mở Summary hoặc Review.
- Lượt dở hiện "Đang làm" và mở lại lượt (Tiếp tục).

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-018, BR-TOPIK-020

## Lý do

Người học cần thấy nhanh vài lượt gần nhất, và đầy đủ khi muốn xoá hay so.

## Ví dụ

Bảy lượt: Recent hiện #7 đến #3.

## Edge case

Lượt đồng bộ từ máy khác có `started_at` cũ hơn chen vào đúng vị trí theo thời gian.
