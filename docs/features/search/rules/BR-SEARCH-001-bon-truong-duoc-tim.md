---
id: BR-SEARCH-001
title: Bốn trường được tìm
status: active
summary: Tìm kiếm bao phủ đúng bốn trường: tên deck, mặt trước, mặt sau và tên tag; không tìm dữ liệu đã xoá.
superseded_by:
---
## Rule

Tìm kiếm MUST bao phủ đúng bốn trường: tên deck, mặt trước card, mặt sau card và tên tag. MUST NOT tìm trong `example`, `hint`, `pronunciation`, dữ liệu scheduler, study state hay review history. Deck và card đã bị xoá MUST NOT xuất hiện; khi Trash tồn tại (feature riêng), nội dung soft-deleted MUST bị loại bằng cùng một predicate đặt ở một chỗ duy nhất.

**Enforced by:** rule + store
**Liên quan:** BR-TAG-001

## Lý do

Global Library Search (UC-SEARCH-001). Các rule dưới đây **không** phát biểu lại luật
nội dung card (BR-CARD-001, BR-CARD-002, BR-CARD-003), luật tag (BR-TAG-001) hay luật riêng tư chung
(BR-CORE-001…BR-CORE-004) — chúng chỉ nói phần mà việc tìm kiếm thêm vào.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
