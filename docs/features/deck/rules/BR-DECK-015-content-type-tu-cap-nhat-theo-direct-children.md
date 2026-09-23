---
id: BR-DECK-015
title: content_type tự cập nhật theo direct children
status: active
summary: Hệ thống cập nhật `content_type` của sub-deck atomically cùng mutation direct children; không có reset thủ công.
superseded_by:
---
## Rule

Với mọi sub-deck, `content_type` MUST được hệ thống cập nhật **atomically trong cùng transaction với mutation direct children**: `unset` khi không còn direct child nào, `card` khi chứa direct card, `deck` khi chứa direct child deck. Root deck vẫn bất biến `deck` theo BR-DECK-004. Người dùng MUST NOT có thao tác reset `content_type` thủ công. Transaction thất bại MUST rollback cả mutation lẫn thay đổi `content_type`.

**Enforced by:** store + invariant Q29

## Lý do

**BR-DECK-013 và BR-DECK-014 bị BR-DECK-015 thay thế.** Lập luận cũ — "quay về `unset`
tự động khiến cấu trúc đổi âm thầm" — giả định `content_type` là một lựa chọn của
người dùng. Nó không phải: BR-DECK-006 cấm chọn lúc tạo và BR-DECK-008 xác lập nó tự động từ
phần tử con đầu tiên. Nó là **metadata hệ thống tự duy trì** để cưỡng chế "một deck
chỉ chứa một loại" (BR-DECK-011), nên hướng ngược lại cũng phải tự động: create đã
đổi type atomically, còn delete/move thì không — bất đối xứng đó để lại deck rỗng
nhưng vẫn `card`/`deck`, một trạng thái người dùng không thoát ra được nếu không
biết tới một nút reset chôn trong action sheet. Reset thủ công vì thế là thao tác
quản trị không mua được giá trị nghiệp vụ nào, và BR-DECK-015 xóa nó.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Xoá card cuối cùng của deck `content_type = card` | `content_type` về `unset` trong cùng transaction (BR-DECK-015) |
| Muốn đổi deck rỗng từ `card` sang chứa deck con | Rỗng là đã `unset`; tạo deck con luôn được (BR-DECK-015) |
