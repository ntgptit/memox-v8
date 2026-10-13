---
id: UC-DECK-005
title: Di chuyển deck trong cây
status: ready
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-008, BR-DECK-010, BR-DECK-011, BR-DECK-015, BR-DECK-016, BR-DECK-017, BR-DECK-018, BR-DECK-019, BR-DECK-028, BR-SRS-005, BR-SRS-006, BR-SRS-028, BR-SRS-029]
code: [lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart, lib/features/deck/domain/usecases/move_deck_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn di chuyển một deck sang deck cha khác
**Preconditions:** Deck nguồn và deck đích tồn tại

## Main flow

**Main flow:**
1. Người dùng chọn deck nguồn và deck đích.
2. Hệ thống kiểm tra, theo thứ tự:
   - đích không phải chính deck nguồn hoặc descendant của nó (BR-DECK-017);
   - đích có `content_type = 'deck'` hoặc `'unset'` (BR-DECK-010) — không thể đưa deck
     vào một deck chỉ chứa card;
   - root của đích có cùng `scheduler_type` và `generation` với root
     của nguồn (BR-SRS-006);
   - độ sâu sau move không vượt giới hạn (BR-DECK-001): với `targetDepth` là cấp của
     deck đích (root là cấp 1) và `subtreeHeight` là chiều cao subtree nguồn
     (deck nguồn tính là 1), MUST có `targetDepth + subtreeHeight <= 10`.
3. Hệ thống thực hiện **trong một transaction** (BR-DECK-018):
   - đặt `parent_id` của deck nguồn thành deck đích;
   - cập nhật `root_id` và `depth` cho **toàn bộ subtree** của deck nguồn (BR-DECK-018);
   - nếu đích đang `unset`, đặt `content_type = 'deck'` (BR-DECK-008);
   - nếu deck cha **cũ** là sub-deck và vừa mất phần tử con cuối cùng, đặt
     `content_type` của nó về `unset` (BR-DECK-015); cha cũ là root thì giữ `deck`.
4. Cây được vẽ lại.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Di chuyển trong cùng một cây (cùng root):** `root_id` không đổi,
  nhưng vẫn phải chạy trong transaction cùng với việc đổi `parent_id`.
- **A2 — Di chuyển lên thành root deck:** ngoài phạm vi MVP — deck nguồn sẽ cần
  scheduler riêng, tức là một quyết định mới, không phải một phép di chuyển.

**Error flows:**
- **E1 — Đích là chính nó hoặc descendant:** chặn, lỗi rõ ràng "Không thể di
  chuyển deck vào chính nó" (BR-DECK-017). Đây là phép kiểm tra chống cycle (BR-DECK-016).
- **E2 — Đích có `content_type = 'card'`:** chặn, giải thích deck đích chỉ chứa
  card (BR-DECK-010).
- **E3 — Root đích khác scheduler hoặc generation:** **chặn**, và đề nghị đặt lại
  tiến độ học một cách tường minh (BR-SRS-006). Không im lặng chuyển đổi state — không
  có ánh xạ nào có cơ sở giữa box và ease factor (BR-SRS-005).
- **E4 — Thất bại giữa chừng:** transaction rollback (BR-DECK-018) — con trỏ cha, con
  trỏ root của cả subtree, `content_type` của đích **và** `content_type` của cha
  cũ cùng quay lại nguyên trạng (BR-DECK-015). Không có descendant nào trỏ sai root
  (BR-DECK-019).
- **E5 — Vượt độ sâu tối đa:** `targetDepth + subtreeHeight > 10` → chặn trước
  khi ghi (BR-DECK-001). Không đổi `parent_id`, `root_id`, `content_type`
  của đích hay bất kỳ timestamp nào.

## UI

**UI states:** loaded · submitting · error

## Local

**Postconditions:**
- Cây không có cycle (BR-DECK-016).
- Mọi deck trong subtree đã di chuyển có `root_id` đúng bằng root mới
  (BR-DECK-002, BR-DECK-019).
- Không deck nào đồng thời chứa card và deck con (BR-DECK-011).
- Deck đích `unset` nhận phần tử con đầu tiên thành `deck`; cha cũ là sub-deck
  mất phần tử con cuối thành `unset`; cha cũ còn sibling giữ `deck` (BR-DECK-015).
- Không có card study state nào lệch scheduler hoặc generation so với root
  (BR-SRS-028, BR-SRS-029).

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** deck nguồn và đích hợp lệ (đích không phải chính nó hay descendant, đích `deck` hoặc `unset`, cùng scheduler và generation, độ sâu sau khi di chuyển không quá 10), **when** di chuyển, **then** deck nguồn nhận `parent_id` mới và cả subtree có `root_id` và độ sâu đúng, trong một transaction (BR-DECK-002, BR-DECK-016, BR-DECK-018, BR-DECK-019).
- [ ] **Given** đích đang `unset` và deck cha cũ (không phải root) vừa mất phần tử con cuối cùng, **when** di chuyển xong, **then** đích thành `content_type = 'deck'` và cha cũ về `unset`, cùng transaction với việc di chuyển (BR-DECK-008, BR-DECK-015).
- [ ] **Given** nguồn và đích cùng một root, **when** di chuyển, **then** `root_id` không đổi và việc đổi `parent_id` vẫn chạy trong transaction (A1).
- [ ] **Given** deck nguồn là root, **when** di chuyển, **then** bị từ chối: đưa một deck lên hay xuống vị trí root nằm ngoài phạm vi (BR-DECK-028, A2).
- [ ] **Given** đích là đúng cha hiện tại của deck nguồn, **when** di chuyển, **then** bị từ chối và không có gì được ghi (BR-DECK-028).
- [ ] **Given** đích là chính deck nguồn hoặc một descendant của nó, **when** di chuyển, **then** bị chặn với lý do rõ ràng và `parent_id` không đổi (BR-DECK-016, BR-DECK-017, E1).
- [ ] **Given** đích có `content_type = 'card'`, **when** di chuyển, **then** bị chặn kèm giải thích và `parent_id` không đổi (BR-DECK-010, E2).
- [ ] **Given** root của đích khác `scheduler_type` hoặc `generation` với root của nguồn, **when** di chuyển, **then** bị chặn và không có chuyển đổi study state ngầm nào (BR-SRS-005, BR-SRS-006, E3).
- [ ] **Given** di chuyển thất bại giữa chừng, **when** transaction dừng, **then** con trỏ cha, `root_id` của cả subtree, `content_type` của đích và của cha cũ đều trở lại như trước (BR-DECK-015, BR-DECK-018, BR-DECK-019, E4).
- [ ] **Given** cấp của đích cộng chiều cao subtree vượt 10, **when** di chuyển, **then** bị chặn trước khi ghi, và không `parent_id`, `root_id`, `content_type` hay timestamp nào đổi (BR-DECK-001, E5).
