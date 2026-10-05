---
id: UC-DECK-006
title: Sắp xếp lại Deck cùng cấp
status: ready
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-004, BR-DECK-027, BR-SRS-007]
code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn Reorder trong action sheet của một deck khi Library đang ở
Manual order, rồi kéo deck tới vị trí mới; với TalkBack, dùng action Move up
hoặc Move down trên hàng deck (quyết định của chủ dự án 2026-09-28, theo kit 01).
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

**Alternative flows:** Ở chế độ Reorder, deck đầu không có action Move up của
TalkBack và deck cuối không có Move down; level chỉ có một deck không hiện mục
Reorder. Khi đang dùng sort theo
tên, ngày, due hoặc tiến độ (BR-DECK-027), thao tác bị ẩn để neighbour không bị
suy ra từ một view-only order.

**Error flows:** Source hoặc target đã stale, hoặc không còn sibling → transaction
từ chối và không ghi gì. Lỗi database ở bất kỳ update nào → toàn transaction
rollback, thứ tự cũ giữ nguyên.

## UI

**UI states:** Ở Manual order, action sheet hiện mục Reorder khi level có từ hai
deck; chế độ Reorder cho kéo thả, và mỗi hàng có action Move up / Move down của
TalkBack khi có sibling trước / sau. Ở mọi view-only sort khác, Reorder bị ẩn;
lỗi giữ nguyên danh sách hiện có.

## Local

**Postconditions:** Chỉ `sibling_position` (và timestamp audit của các sibling
được đánh số lại) đổi trong một transaction; sibling xuất hiện theo thứ tự mới
qua stream và toàn bộ tree pointer, subtree cùng study data giữ nguyên.

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** hai deck cùng `parent_id` ở Manual order, **when** hệ thống gửi thao tác `before` hoặc `after` theo sibling liền kề, **then** chỉ `sibling_position` (và `updated_at` của các sibling đổi chỗ) thay đổi; `parent_id`, `root_id`, scheduler, card, study state và subtree giữ nguyên, trong một transaction (BR-SRS-007).
- [ ] **Given** nhiều root deck, **when** sắp xếp lại, **then** chúng đổi chỗ trong đúng nhóm sibling gốc (BR-SRS-007).
- [ ] **Given** level đang ở Manual order và chỉ có một deck, **when** mở action sheet của deck đó, **then** không có thao tác sắp xếp lại; có từ hai deck trở lên thì có.
- [ ] **Given** level đang dùng một sort chỉ để xem (tên, ngày, due hoặc tiến độ), **when** mở action sheet của một deck, **then** thao tác sắp xếp lại bị ẩn (BR-DECK-027).
- [ ] **Given** source và target không còn cùng `parent_id`, **when** sắp xếp lại, **then** transaction từ chối và không ghi gì.
- [ ] **Given** deck hoặc anchor không còn, **when** sắp xếp lại, **then** thao tác bị từ chối, không ghi gì và thứ tự cũ giữ nguyên.
- [ ] **Given** một update lỗi giữa lúc đánh số lại nhóm sibling, **when** transaction dừng, **then** toàn bộ rollback và thứ tự cũ giữ nguyên.
- [ ] **Given** level đang ở Manual order với từ hai deck, **when** người dùng chọn Reorder và kéo một deck, hoặc dùng Move up / Move down của TalkBack, **then** deck đổi chỗ với sibling kề đó và không có deck nào khác đổi thứ tự.
