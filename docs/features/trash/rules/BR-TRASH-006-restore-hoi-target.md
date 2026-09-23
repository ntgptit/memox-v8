---
id: BR-TRASH-006
title: Restore hỏi target
status: active
summary: Restore hỏi target và không ghi gì trước khi người dùng xác nhận.
superseded_by:
---
## Rule

Restore MUST hỏi target và MUST NOT ghi gì trước khi người dùng xác nhận. Target của một card MUST là deck đang active, non-root, `content_type` là `card` hoặc `unset`, và cùng root với card đó (BR-CARD-010). Target của một **sub-deck** MUST thoả **đúng** bộ luật của move (BR-DECK-001 độ sâu, BR-DECK-009/BR-DECK-010 loại nội dung, BR-DECK-017/BR-SRS-006 scheduler và generation của root) — MUST NOT có bộ luật thứ hai dành riêng cho restore. Item root là một **root deck** MUST chỉ có đúng một target hợp lệ là **top level**, vì root không có cha (BR-DECK-002) và move không áp dụng cho root; target đó vẫn MUST được người dùng xác nhận, và MUST NOT được chấp nhận cho bất kỳ item nào khác. Target `unset` MUST được set sang loại tương ứng trong chính transaction restore. Restore vi phạm bất kỳ điều kiện nào MUST bị từ chối bằng lý do có kiểu và MUST NOT ghi một phần.

**Enforced by:** rule + store
**Liên quan:** BR-DECK-001, BR-DECK-002, BR-DECK-009, BR-DECK-010, BR-DECK-017, BR-SRS-006, BR-CARD-010

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
