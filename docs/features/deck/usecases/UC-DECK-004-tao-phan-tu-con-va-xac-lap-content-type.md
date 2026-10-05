---
id: UC-DECK-004
title: Tạo phần tử con và xác lập `content_type`
status: ready
rules: [BR-CARD-004, BR-DECK-001, BR-DECK-002, BR-DECK-004, BR-DECK-005, BR-DECK-006, BR-DECK-007, BR-DECK-008, BR-DECK-009, BR-DECK-010, BR-DECK-011, BR-DECK-012, BR-DECK-015, BR-DECK-019, BR-DECK-025]
code: [lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/usecases/create_sub_deck_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Bấm Create bên trong một deck
**Preconditions:** Deck tồn tại

Đây là use case định hình toàn bộ cấu trúc cây, và là chỗ dễ cài sai nhất vì nút
Create có ba hành vi khác nhau tuỳ trạng thái deck.

## Main flow

**Main flow:**
1. Người dùng bấm Create trong một deck.
2. Hệ thống quyết định lựa chọn hiển thị:

   | Deck | Lựa chọn hiện ra |
   | root deck (`content_type = 'deck'`, bất biến) | **chỉ** Create deck (BR-DECK-005) |
   | deck con, `content_type = 'unset'` | Create card **và** Create deck (BR-DECK-007) |
   | deck con, `content_type = 'card'` | **chỉ** Create card (BR-DECK-012) |
   | deck con, `content_type = 'deck'` | **chỉ** Create deck (BR-DECK-012) |

3. Người dùng chọn một hành động và nhập nội dung.
4. Hệ thống thực hiện **trong một transaction** (BR-DECK-008):
   - nếu deck đang `unset`: đặt `content_type` theo hành động đã chọn;
   - tạo phần tử con: card (kèm study state, BR-CARD-004) hoặc deck con mới với
     `content_type = 'unset'`, `parent_id` = deck hiện tại,
     `root_id` = root của deck hiện tại (BR-DECK-002), và **không** có cột
     scheduler (BR-DECK-025).
5. Từ đây nút Create trong deck này chỉ hiện hành động tương ứng (BR-DECK-012).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Deck đã `card`:** không có lựa chọn tạo deck con, ở bất kỳ đâu trong UI
  (BR-DECK-009).
- **A2 — Deck đã `deck`:** không có lựa chọn tạo card (BR-DECK-010).
- **A3 — Phần tử con cuối cùng rời đi:** xoá card cuối, xoá deck con cuối hoặc
  di chuyển deck con cuối sang cha khác đều đưa `content_type` của sub-deck về
  `unset`, trong cùng transaction với mutation đó (BR-DECK-015). Không có thao tác
  reset thủ công nào, và không cần có.
- **A4 — Huỷ giữa chừng:** không tạo gì và **không** xác lập `content_type` —
  `content_type` chỉ đổi cùng với việc phần tử con thực sự được tạo (BR-DECK-008).

**Error flows:**
- **E1 — Validate thất bại** (tên deck rỗng, card thiếu mặt): lỗi inline; không
  tạo gì và không đổi `content_type`.
- **E2 — Ghi thất bại giữa chừng:** transaction rollback. Deck giữ nguyên
  `content_type` cũ và không có phần tử con nửa vời (BR-DECK-008) — chiều xoá cũng
  vậy: mutation và thay đổi type cùng sống hoặc cùng chết (BR-DECK-015).
- **E3 — Cố tạo card trong root deck:** không có đường nào tới được trạng thái
  này qua UI (BR-DECK-005). Nếu xảy ra qua deep link hoặc lỗi lập trình, từ chối và log
  — đây là vi phạm BR-DECK-004 và validation phải bắt được.
- **E4 — Deck cha đã ở cấp 10:** tạo deck con bị chặn trước khi ghi (BR-DECK-001).
  Không tạo gì và không đổi `content_type` của deck cha — kể cả khi nó đang
  `unset`. Tạo card không bị giới hạn này: card không thêm cấp cho cây.

## UI

**UI states:** initial · submitting · error

## Local

**Postconditions:**
- Deck có `content_type` khác `unset`, khớp với loại phần tử con vừa tạo.
- Deck không đồng thời chứa card và deck con (BR-DECK-011).
- Deck con mới có `root_id` đúng bằng root của cha (BR-DECK-002, BR-DECK-019).

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** một root deck, **when** bấm Create, **then** chỉ có Create deck (BR-DECK-004, BR-DECK-005).
- [ ] **Given** một deck con `content_type = 'unset'`, **when** bấm Create, **then** có cả Create card và Create deck (BR-DECK-007).
- [ ] **Given** một deck con `unset`, **when** tạo deck con đầu tiên, **then** nó thành `content_type = 'deck'` trong cùng transaction với việc tạo, và deck mới có `root_id` bằng root của cha (BR-DECK-002, BR-DECK-006, BR-DECK-008, BR-DECK-019).
- [ ] **Given** một deck con `unset`, **when** tạo card đầu tiên, **then** nó thành `content_type = 'card'`, và study state của card được tạo cùng transaction theo scheduler và `generation` của root (BR-CARD-004, BR-DECK-008).
- [ ] **Given** một deck `content_type = 'card'`, **when** mở lựa chọn tạo hoặc gọi tạo deck con, **then** không có lựa chọn tạo deck con và lời gọi bị từ chối (BR-DECK-009, A1).
- [ ] **Given** một deck `content_type = 'deck'`, **when** mở lựa chọn tạo hoặc gọi tạo card, **then** không có lựa chọn tạo card và lời gọi bị từ chối (BR-DECK-010, A2).
- [ ] **Given** một deck con chỉ còn một phần tử con active, **when** phần tử đó bị xoá hoặc di chuyển đi, **then** deck con về `unset` trong cùng transaction, không cần thao tác tay (BR-DECK-015, A3).
- [ ] **Given** dialog tạo deck con hoặc card đang mở, **when** người dùng huỷ, **then** không tạo gì và `content_type` của deck cha không đổi (BR-DECK-008, A4).
- [ ] **Given** tên deck con rỗng hoặc card thiếu một mặt, **when** xác nhận, **then** lỗi hiện ngay dưới ô nhập, không tạo gì và `content_type` không đổi (E1).
- [ ] **Given** ghi thất bại giữa chừng (ví dụ không ghi được study state), **when** tạo card, **then** không có card nào được ghi và `content_type` của deck cha không đổi (BR-DECK-008, E2).
- [ ] **Given** một root deck, **when** tạo card trực tiếp trong nó, **then** thao tác bị từ chối và không tạo gì (BR-DECK-004, E3).
- [ ] **Given** deck cha ở cấp 10, **when** tạo deck con, **then** bị chặn trước khi ghi và `content_type` của deck cha không đổi; tạo card ở cấp 10 vẫn được (BR-DECK-001, E4).
