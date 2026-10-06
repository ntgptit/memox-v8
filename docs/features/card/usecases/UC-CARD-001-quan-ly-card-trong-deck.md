---
id: UC-CARD-001
title: Quản lý card trong deck
status: ready
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-CARD-005, BR-CARD-006, BR-CARD-009, BR-CARD-010, BR-CARD-011, BR-CARD-012, BR-CARD-020, BR-DECK-009, BR-DECK-015, BR-DECK-022, BR-DECK-023, BR-TAG-001, BR-TAG-002, BR-TAG-004, BR-TRASH-001, BR-TRASH-004, BR-TRASH-005, BR-TRASH-008]
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
- **A1 — Sửa card:** nội dung và tag đổi; study state, history và cờ **không** đổi (BR-CARD-005, BR-CARD-009). Nút cờ trong editor là A7, ghi riêng sau khi nội dung được lưu.
- **A2 — Xoá card:** hỏi xác nhận; xác nhận thì card vào Trash trong một
  transaction, mỗi card là **một** batch của riêng nó, cùng một `deleted_at`
  (BR-TRASH-001). Nội dung, study state và history giữ nguyên tới khi purge
  (BR-TRASH-004); phiên `in_progress` có card trong hàng đợi hoặc dùng card làm
  lựa chọn của câu `guess` kết thúc với `content_deleted`. Xoá **một** card thì có
  Undo ngay tại chỗ (BR-TRASH-008); khôi phục về sau qua Trash (UC-TRASH-001).
  Nếu đó là card **cuối cùng** đang active,
  deck atomically trở về `content_type = unset` trong cùng transaction
  (BR-DECK-015, BR-TRASH-005); sau đó người dùng quay về màn hình deck và
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

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** một deck `unset` và một draft hợp lệ, **when** người dùng thêm card, **then** card và study state mới của nó (theo scheduler và generation của root) được ghi trong một transaction, và deck thành `content_type = card` (BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004).
- [ ] **Given** một card đã có study state và lịch sử, **when** người dùng sửa nội dung, **then** nội dung và tag đổi nhưng study state, `review_log` và cờ không đổi — kể cả khi cờ được bật trong lúc editor đang mở (BR-CARD-005, BR-CARD-009, A1).
- [ ] **Given** người dùng xoá đúng một card, **when** xác nhận, **then** card vào Trash, nội dung, study state và lịch sử giữ nguyên tới khi purge, và có Undo ngay tại chỗ (BR-TRASH-001, BR-TRASH-004, BR-TRASH-008, A2).
- [ ] **Given** người dùng xoá nhiều card, **when** xác nhận, **then** tất cả vào Trash cùng lúc và không có Undo (BR-TRASH-001, A2).
- [ ] **Given** card bị xoá là card active cuối cùng của deck, **when** xoá thành công, **then** deck về `content_type = unset` trong cùng transaction (BR-DECK-015, BR-TRASH-005, A2).
- [ ] **Given** deck còn card nhưng bộ lọc đang bật không khớp card nào, **when** danh sách hiện, **then** hệ thống hiện empty state của bộ lọc (khác empty state của deck) kèm lối hiện tất cả (A3).
- [ ] **Given** form thêm card, **when** Save ghi xong, **then** form vẫn mở, các ô được xoá trống và focus về ô mặt trước để thêm card kế tiếp (A4).
- [ ] **Given** người dùng di chuyển card sang deck khác cùng root, **when** xác nhận, **then** id, nội dung, study state, lịch sử, cờ và tag giữ nguyên, chỉ `deck_id` và `updated_at` đổi; deck nguồn rỗng thì về `unset`, deck đích `unset` thì thành `card` (BR-CARD-010, BR-DECK-015, A5).
- [ ] **Given** bộ lọc hoặc search đang áp và mới tải một phần kết quả, **when** người dùng bấm Select all, **then** mọi id khớp filter và search hiện tại được chọn, không chỉ các hàng đã tải (BR-CARD-012, A6).
- [ ] **Given** một hoặc nhiều card đã chọn, **when** áp Flag hoặc Remove flag, **then** `is_flagged` đúng giá trị trên mọi card, và card đã đúng giá trị không bị ghi lại (BR-CARD-009, BR-CARD-011, A7).
- [ ] **Given** một tên tag gắn cho nhiều card, **when** attach, **then** hệ thống dùng lại tag có cùng tên đã fold hoặc tạo tag mới, và gắn cho mọi card đã chọn; gỡ tag chỉ xoá liên kết, không xoá tag (BR-TAG-001, A8).
- [ ] **Given** card list ở chế độ thường, **when** chạm một hàng, **then** chi tiết chỉ đọc của đúng card đó mở ra; cùng cú chạm khi đang chọn nhiều chỉ đổi trạng thái chọn, không điều hướng (BR-CARD-020, A9).
- [ ] **Given** mặt trước hoặc mặt sau rỗng, hoặc vượt giới hạn độ dài, **when** người dùng gõ, **then** lỗi hiện ngay dưới ô đó và Save bị khoá (BR-CARD-001, BR-CARD-002, E1, E2).
- [ ] **Given** ghi card mới thất bại, **when** người dùng thấy lỗi, **then** nội dung form được giữ, lỗi kèm Retry, và không có card nào được tạo mà thiếu study state (BR-CARD-004, E3).
- [ ] **Given** deck đích không còn hợp lệ (mất, là root, giữ deck con, hoặc chính deck nguồn), **when** move chạy, **then** bị từ chối với lý do có kiểu và không ghi gì (BR-CARD-010, E5).
- [ ] **Given** một card trong lô vi phạm luật (ví dụ đã đủ 10 tag), **when** thao tác hàng loạt chạy, **then** cả lô không ghi gì, danh sách và lựa chọn giữ nguyên, lỗi nói rõ lý do (BR-CARD-011, E6, E7).
