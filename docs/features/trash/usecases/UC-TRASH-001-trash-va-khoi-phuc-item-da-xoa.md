---
id: UC-TRASH-001
title: Trash và khôi phục item đã xoá
status: ready
rules: [BR-CARD-010, BR-CARD-012, BR-DECK-001, BR-DECK-009, BR-DECK-010, BR-DECK-015, BR-DECK-017, BR-DECK-018, BR-SRS-006, BR-TRASH-001, BR-TRASH-002, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005, BR-TRASH-006, BR-TRASH-007, BR-TRASH-008, BR-TRASH-009, BR-TRASH-010, BR-TRASH-011, BR-TRASH-012]
code: []
---
## Mục tiêu / Actor / Precondition

**Phạm vi:** sub-project sau — Trash (spec §2).

**Actor:** Người dùng
**Trigger:** Xoá một card hoặc deck (vào Trash), hoặc mở `Trash` từ app bar của
Library
**Preconditions:** Không có. Trash mở được kể cả khi rỗng — đó là cách người
dùng biết nó tồn tại (BR-TRASH-002 chỉ nói cái gì bị ẩn khỏi *bề mặt active*)

## Main flow

**Main flow:**
1. Người dùng xoá một card hoặc một deck từ luồng đã có (UC-CARD-001, UC-DECK-004). Hệ thống
   chạy một transaction: tạo batch, đánh dấu item root cùng mọi descendant đang
   active, đưa parent về `unset` nếu nó vừa mất direct child cuối, và đóng phiên
   `in_progress` nào chạm tới item đó với lý do `content_deleted`
   (BR-TRASH-001, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005).
2. Màn đang đứng báo item đã chuyển vào Trash và hiện Undo trong một khoảng thời
   gian có hạn (BR-TRASH-001). Mọi bề mặt active cập nhật ngay — item biến mất khỏi
   danh sách, khỏi đếm, khỏi search và khỏi study (BR-TRASH-002).
3. Người dùng mở `Trash` từ app bar của Library. Hệ thống chạy auto-purge trước
   khi vẽ, rồi hiển thị các batch còn lại, tách theo loại: Cards và Decks
   (BR-TRASH-009, BR-TRASH-011).
4. Mỗi hàng nêu tên item, thời điểm đã xoá, đường dẫn gốc **như thông tin**, số
   ngày còn lại trước khi bị xoá vĩnh viễn, và — với deck — số deck/card đi kèm
   trong batch (BR-TRASH-012).
5. Người dùng chọn `Restore` trên một hàng. Hệ thống mở picker target dựng từ
   **đúng** eligibility của move: chỉ deck đang active thoả loại nội dung, độ
   sâu và scheduler/generation mới xuất hiện (BR-TRASH-006).
6. Người dùng chọn một target và xác nhận. Hệ thống chạy một transaction: gỡ
   tombstone của **đúng** batch đó, gắn item root vào target, viết lại
   `root_id` cho cả subtree kể cả tombstone bên trong, và set `content_type`
   của target nếu nó đang `unset` (BR-TRASH-006, BR-TRASH-007).
7. Trash bỏ hàng vừa khôi phục; Library hiện item ở vị trí mới với nguyên id,
   study state, history và tag (BR-TRASH-007).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Undo ngay sau khi xoá:** người dùng bấm Undo trên snackbar. Hệ thống
  đảo ngược đúng batch đó về **vị trí cũ**, không hỏi target (BR-TRASH-008).
- **A2 — Chọn nhiều:** người dùng bật chế độ chọn trong Trash. Thanh hành động
  hiện `Restore` và `Delete permanently` cho tập đang chọn. Chọn một card làm
  mọi hàng deck không chọn được và ngược lại; UI nói rõ vì sao (BR-TRASH-011).
- **A3 — Purge vĩnh viễn:** người dùng chọn `Delete permanently`. Hộp thoại nêu
  đúng số item, nói lịch sử học không khôi phục được, đặt focus mặc định ở hành
  động an toàn, và chỉ hành động phá huỷ mang vai trò màu destructive (BR-TRASH-011).
  Xác nhận chạy một transaction xoá cứng batch và cascade (BR-TRASH-010).
- **A4 — Batch hết hạn khi Trash đang mở:** auto-purge chạy lại khi màn được
  focus lại và bỏ các hàng đã hết hạn; danh sách cập nhật tại chỗ, không nhảy vị
  trí cuộn (BR-TRASH-009).
- **A5 — Deck có descendant đã ở Trash từ trước:** restore batch của deck cha
  chỉ hồi sinh hàng của batch đó; descendant kia vẫn nằm trong Trash như một
  hàng riêng (BR-TRASH-003).
- **A6 — Trash rỗng:** màn hiển thị trạng thái rỗng giải thích item đã xoá sẽ ở
  đây 30 ngày, không hiện thanh hành động và không hiện filter.

**Error flows:**
- **E1 — Không có target hợp lệ:** picker mở ra rỗng và giải thích vì sao (cây
  đã đầy 10 cấp, hoặc không còn deck nhận được loại nội dung này). Hệ thống
  MUST NOT hiện hàng bị vô hiệu hoá trông như chọn được (BR-TRASH-006).
- **E2 — Target hết hợp lệ giữa chừng:** cây đổi sau khi picker mở. Transaction
  từ chối bằng lý do có kiểu, không ghi gì, và picker tải lại danh sách (BR-TRASH-006).
- **E3 — Undo không còn dùng được:** vị trí cũ đã bị xoá, đã thành `card`, hoặc
  đã đầy. Undo báo lý do có kiểu và chỉ người dùng sang Trash; item vẫn nằm
  nguyên trong Trash (BR-TRASH-008).
- **E4 — Purge bị chặn:** một descendant của batch thuộc batch chưa tới hạn hoặc
  còn active. Batch đó bị bỏ qua, không purge một phần, và người dùng thấy lý do
  có kiểu (BR-TRASH-010).
- **E5 — Lỗi ghi:** bất kỳ bước nào của xoá, restore hay purge thất bại →
  transaction rollback toàn bộ, trạng thái cũ giữ nguyên, UI hiện error + Retry.
- **E6 — Item đã biến mất:** batch được chọn đã bị purge bởi một lần chạy khác.
  Thao tác báo not-found có kiểu và danh sách tự làm mới, không dừng ở hàng ma.

## UI

**UI states:** loading · empty · cards-only · decks-only · mixed · selection
(card) · selection (deck) · restoring · purging · target picker (rỗng / nhiều /
không hợp lệ) · validation conflict · expired-live-removal · error + Retry ·
undo snackbar. Không có state `refreshing` riêng — danh sách là một `watch()`
stream, nên auto-purge biểu hiện thành hàng biến mất chứ không thành spinner.

## Local

**Postconditions:** Sau bước 7, item nằm dưới target đã chọn với đúng id cũ, và
không hàng nào của batch khác bị chạm. Sau A3, các hàng của batch và mọi thứ
cascade từ chúng không còn trong database, và không batch nào khác mất hàng.

Ghi chú từ mục "Business rules" của nguồn:

BR-TRASH-001…BR-TRASH-012, và BR-DECK-001, BR-DECK-009, BR-DECK-010, BR-DECK-017, BR-DECK-018, BR-SRS-006,
BR-DECK-015, BR-CARD-010, BR-CARD-012 qua đường dùng lại eligibility của move.


## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
