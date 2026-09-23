---
id: UC-CARD-001
title: Quản lý card trong deck
status: ready
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-CARD-005, BR-CARD-006, BR-CARD-009, BR-CARD-010, BR-CARD-011, BR-CARD-012, BR-CARD-020, BR-DECK-009, BR-DECK-015, BR-DECK-022, BR-DECK-023, BR-TAG-001, BR-TAG-002, BR-TAG-004]
code: [lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart, lib/features/card/domain/usecases/edit_card_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/move_cards_use_case.dart, lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart, lib/features/card/domain/usecases/set_cards_flagged_use_case.dart, lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart, lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Mở một deck có `content_type = 'card'`
**Preconditions:** Deck tồn tại và `content_type = 'card'` (BR-DECK-009)

## Main flow

**Main flow:**
1. Người dùng thấy danh sách card của deck.
2. Người dùng thêm card: nhập mặt trước và mặt sau, tuỳ chọn thêm ví dụ, gợi ý
   và phiên âm (BR-CARD-003).
3. Hệ thống validate (BR-CARD-001, BR-CARD-002, BR-CARD-003).
4. Hệ thống tạo card **và** study state của nó trong cùng transaction, theo
   scheduler của root deck (tra qua `root_id`) và generation hiện tại (BR-CARD-004).
5. Card xuất hiện; số card đến hạn của deck tăng.

Card đầu tiên của một deck `unset` được tạo qua UC-DECK-004, và chính nó xác lập
`content_type = 'card'`.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Sửa card:** nội dung đổi; study state và history **không** đổi (BR-CARD-005).
- **A2 — Xoá card:** hỏi xác nhận, nêu rõ nội dung sẽ mất (BR-DECK-023); xác nhận thì
  xoá cứng card cùng study state và history của nó, trong một transaction
  (BR-DECK-022). Khi sub-project Trash triển khai, thao tác này đổi thành soft-delete
  có Undo và khôi phục — xem UC-TRASH-001. Nếu đó là card **cuối cùng** đang active,
  deck atomically trở về `content_type = unset` trong cùng transaction
  (BR-DECK-015); sau đó người dùng quay về màn hình deck và
  lại chọn được tạo card hay tạo sub-deck. "Deck `card` rỗng" không còn là một
  trạng thái ổn định của hệ thống.
- **A3 — Deck còn card nhưng danh sách rỗng theo bộ lọc:** empty state của bộ
  lọc, không phải của deck.
- **A5 — Di chuyển thẻ sang deck khác:** chọn deck đích trong cùng root; thẻ giữ
  nguyên id, nội dung, study state, history, cờ và tag — chỉ đổi chỗ (BR-CARD-010).
  Deck nguồn mất thẻ cuối thì về `unset`, deck đích đang `unset` thì thành
  `card`, cùng transaction (BR-DECK-015).
- **A6 — Chọn nhiều thẻ:** long-press một thẻ hoặc dùng action **Select** trên
  app bar để vào chế độ chọn. Thanh hành động ngữ cảnh hiện số đã chọn và các
  thao tác hàng loạt: Move, Add tag, Flag, Remove flag, Delete. **Select all**
  chọn toàn bộ tập kết quả theo filter và search hiện tại, không chỉ phần đã
  tải (BR-CARD-012). Mỗi thao tác là all-or-nothing (BR-CARD-011).
- **A4 — Thêm liên tiếp nhiều card:** sau khi lưu, giữ form mở và xoá trống các ô.
- **A7 — Cờ:** người dùng bật hoặc bỏ cờ của một thẻ (BR-CARD-009).
- **A8 — Tag:** người dùng gắn tag theo tên — dùng lại tag trùng tên đã fold, tạo
  mới nếu chưa có — hoặc gỡ tag khỏi thẻ (BR-TAG-001, BR-TAG-002).
- **A9 — Mở chi tiết:** chạm một thẻ ở chế độ thường mở chi tiết chỉ đọc (UC-CARD-002);
  sửa là action riêng (BR-CARD-020).

**Error flows:**
- **E1 — Mặt trước hoặc mặt sau rỗng:** lỗi inline ở đúng ô đó.
- **E5 — Deck đích không hợp lệ:** picker chỉ liệt kê deck cùng root, không phải
  root, không phải loại `deck`, và không phải chính deck nguồn. Nếu một thao tác
  vẫn mang đích không hợp lệ tới trước khi ghi — deep link, hoặc cây đổi giữa
  lúc mở picker và lúc xác nhận — nó bị từ chối kèm lý do có kiểu và không ghi
  gì (BR-CARD-010).
- **E6 — Một thẻ trong lô vi phạm:** cả lô rollback; danh sách và selection giữ
  nguyên, lỗi nêu rõ vì sao (BR-CARD-011).
- **E2 — Vượt giới hạn độ dài** (BR-CARD-002, BR-CARD-003): lỗi inline ở đúng ô đó.
- **E3 — Ghi thất bại:** hiện lỗi, giữ nội dung; không tạo card không có study
state.
- **E7 — Tag không hợp lệ, hoặc thẻ đã đủ 10 tag:** lỗi có kiểu; tag của thẻ giữ
  nguyên (BR-TAG-001, BR-TAG-002).

## UI

**UI states:** loading · loaded · empty · submitting · error

## Local

**Postconditions:** Card tồn tại kèm đúng một study state, đúng scheduler và
đúng generation của root deck.

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
