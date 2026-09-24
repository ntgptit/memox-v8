---
id: UC-DECK-006
title: Sắp xếp lại Deck cùng cấp
status: ready
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-004, BR-SRS-007]
code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn Move up hoặc Move down trên một deck khi Library đang ở
Manual order.
**Preconditions:** Source và target là deck active cùng một level; danh sách
đang ở Manual order để thứ tự nhìn thấy chính là thứ tự persisted.

## Main flow

**Main flow:**
1. Hệ thống lấy sibling liền trước hoặc sau từ thứ tự Manual đã lưu và gửi
   operation `before`/`after`, không gửi một database index thô.
2. Hệ thống mở một transaction, đọc lại source và target active, xác nhận
   chúng còn cùng `parent_id`, rồi cập nhật thứ tự nhóm sibling.
3. Watch của level phát emission mới; danh sách đổi vị trí tại chỗ. Mọi parent,
   root pointer, scheduler, card, study state và subtree giữ nguyên.

## Alternative / Error flow

**Alternative flows:** Deck đầu không hiện Move up; deck cuối không hiện Move
down; level chỉ có một deck không hiện thao tác reorder. Khi đang dùng sort theo
tên, ngày, due hoặc tiến độ, thao tác bị ẩn để neighbour không bị suy ra từ một
view-only order.

**Error flows:** Source hoặc target đã stale, hoặc không còn sibling → transaction
từ chối và không ghi gì. Lỗi database ở bất kỳ update nào → toàn transaction
rollback, thứ tự cũ giữ nguyên.

## UI

**UI states:** Ở Manual order, action sheet hiện Move up khi có sibling trước
và Move down khi có sibling sau. Ở đầu/cuối hoặc level một phần tử, action
tương ứng bị ẩn. Ở mọi view-only sort khác, cả hai thao tác bị ẩn; lỗi giữ
nguyên danh sách hiện có.

## Local

**Postconditions:** Chỉ `sibling_position` (và timestamp audit của các sibling
được đánh số lại) đổi trong một transaction; sibling xuất hiện theo thứ tự mới
qua stream và toàn bộ tree pointer, subtree cùng study data giữ nguyên.

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
