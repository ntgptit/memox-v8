---
id: BR-CARD-011
title: Mutation hàng loạt all-or-nothing
status: active
summary: Mọi mutation hàng loạt trên thẻ là all-or-nothing trong một transaction, giữ quy tắc của thao tác đơn lẻ.
superseded_by:
---
## Rule

Mọi mutation hàng loạt trên thẻ — di chuyển, xoá, đặt/bỏ cờ, gắn tag — MUST là **all-or-nothing trong đúng một transaction**: một thẻ vi phạm làm cả lô rollback, và MUST NOT có partial success không được đặc tả. Gắn tag hàng loạt MUST giữ nguyên quy tắc đơn lẻ: dùng lại tag theo tên đã fold (BR-TAG-001), trần 10 tag mỗi thẻ (BR-TAG-002), và **idempotent** khi thẻ đã có tag đó. Chỉ cần một thẻ chạm trần là cả lô bị từ chối. Đặt cờ hàng loạt MUST là lệnh tường minh `Set flagged` / `Remove flag`, MUST NOT là toggle suy ra từ thẻ đầu tiên. Xoá hàng loạt MUST cascade study state và history như xoá đơn lẻ, và MUST đưa deck về `unset` nếu đó là những thẻ cuối (BR-DECK-015).

**Enforced by:** store
**Liên quan:** BR-CARD-009, BR-TAG-001, BR-TAG-002, BR-DECK-015

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
