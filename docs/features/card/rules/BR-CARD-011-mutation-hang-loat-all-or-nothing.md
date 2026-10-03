---
id: BR-CARD-011
title: Mutation hàng loạt all-or-nothing
status: active
summary: Mọi mutation hàng loạt trên thẻ chạy trong một transaction, giữ quy tắc của thao tác đơn lẻ; thẻ đã không còn bị bỏ qua.
superseded_by:
---
## Rule

Mọi mutation hàng loạt trên thẻ — di chuyển, xoá, đặt/bỏ cờ, gắn tag — MUST chạy trong **đúng một transaction** và giữ quy tắc của thao tác đơn lẻ: một thẻ vi phạm luật (đích di chuyển từ chối nó, tag chạm trần 10) làm cả lô rollback, và MUST NOT có partial success không được đặc tả. Một thẻ **không còn tồn tại** lúc ghi (đã bị xoá, đã vào Trash) không phải là vi phạm luật: lô bỏ qua thẻ đó trong cùng transaction, ghi các thẻ còn lại và trả `BulkOutcome(done, skipped)`; UI nêu số thẻ đã bỏ qua và dọn các id đó khỏi selection. Khi không còn thẻ nào tồn tại, lô bị từ chối `notFound` và không ghi gì. Gắn tag hàng loạt MUST giữ nguyên quy tắc đơn lẻ: dùng lại tag theo tên đã fold (BR-TAG-001), trần 10 tag mỗi thẻ (BR-TAG-002), và **idempotent** khi thẻ đã có tag đó. Chỉ cần một thẻ chạm trần là cả lô bị từ chối và không ghi gì; thông báo nêu số thẻ đã chạm trần. Đặt cờ hàng loạt MUST là lệnh tường minh `Set flagged` / `Remove flag`, MUST NOT là toggle suy ra từ thẻ đầu tiên. Xoá hàng loạt MUST cascade study state và history như xoá đơn lẻ, và MUST đưa deck về `unset` nếu đó là những thẻ cuối (BR-DECK-015).

**Enforced by:** store
**Liên quan:** BR-CARD-009, BR-TAG-001, BR-TAG-002, BR-DECK-015

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
