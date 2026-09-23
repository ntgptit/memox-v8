---
id: UC-DECK-004
title: Tạo phần tử con và xác lập `content_type`
status: ready
rules: [BR-CARD-004, BR-DECK-001, BR-DECK-002, BR-DECK-004, BR-DECK-005, BR-DECK-006, BR-DECK-007, BR-DECK-008, BR-DECK-009, BR-DECK-010, BR-DECK-011, BR-DECK-012, BR-DECK-015, BR-DECK-019]
code: []
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

Không áp dụng — ứng dụng local-only, không network ([quyết định nền tảng](../../../product/product.md#platform-decisions)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
