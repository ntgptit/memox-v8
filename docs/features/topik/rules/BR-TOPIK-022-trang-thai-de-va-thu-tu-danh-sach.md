---
id: BR-TOPIK-022
title: Trạng thái đề và thứ tự danh sách
status: active
summary: Mỗi đề trong danh sách hiện trạng thái của người dùng (chưa làm, đang làm, điểm tốt nhất) và danh sách sắp theo kỳ hoặc theo hoạt động gần nhất.
superseded_by:
---
## Rule

Mỗi hàng đề MUST hiện số kỳ, tên tiếng Hàn, thẻ nội dung (BR-TOPIK-009) và trạng thái:

- **chưa làm** khi không có lượt nào;
- **đang làm** khi có lượt dở trên máy này;
- **điểm tốt nhất** kèm số lượt đã nộp khi có lượt đã nộp (một đề vừa có lượt dở vừa có lượt đã nộp hiện cả hai).

Thứ tự: kỳ giảm dần (mặc định), kỳ tăng dần, hoặc hoạt động gần nhất (đề chưa làm đứng cuối, rồi kỳ giảm dần).

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-009, BR-TOPIK-020

## Lý do

Danh sách là chỗ người học chọn đề tiếp theo; trạng thái cho biết đề nào đã làm mà không phải mở từng đề.

## Ví dụ

Kỳ 96 có lượt dở và hai lượt đã nộp (best 88): hàng hiện "đang làm" và "88 · 2 lượt".

## Edge case

Không áp dụng
