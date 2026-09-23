---
id: UC-DECK-002
title: Sửa và xoá deck
status: ready
rules: [BR-DECK-015, BR-DECK-020, BR-DECK-022, BR-DECK-023, BR-DECK-025, BR-SRS-002, BR-SRS-003, BR-SRS-004, BR-STUDY-016]
code: []
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn sửa hoặc xoá trên một deck
**Preconditions:** Deck tồn tại

## Main flow

**Main flow (sửa tên):**
1. Người dùng đổi tên deck.
2. Hệ thống validate (BR-DECK-020) và lưu.

**Main flow (đổi chế độ ôn tập — chỉ trên root deck, chỉ khi chưa có thẻ nào học xong chuỗi học mới):**
1. Hệ thống hiển thị phần chọn chế độ ở trạng thái **mở khoá**
   (`first_answered_at IS NULL`, BR-SRS-002).
2. Người dùng chọn chế độ khác.
3. Hệ thống cảnh báo study state của **toàn bộ card trong cây** sẽ được khởi tạo
   lại theo chế độ mới (BR-SRS-004), và phiên học đang mở sẽ bị đóng (BR-STUDY-016). Đây
   **không** phải Reset learning progress: không có generation nào bị tiêu, không
   có lịch sử nào bị bỏ, nên cảnh báo này MUST NOT dùng giọng phá huỷ của UC-SRS-001.
4. Người dùng xác nhận.
5. Hệ thống đổi scheduler, khởi tạo lại study state toàn cây, **và** đóng mọi
   phiên đang mở của cây — trong một transaction (BR-SRS-004, BR-STUDY-016).

**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số deck con và số card sẽ bị xoá vĩnh viễn
   (BR-DECK-023).
2. Người dùng xác nhận.
3. Hệ thống xoá cứng deck cùng toàn bộ descendant, card, study state, study
   answers và study session của nó, trong một transaction (BR-DECK-022). Khi
   sub-project Trash triển khai, bước này đổi thành soft-delete có Undo và
   khôi phục — xem UC-TRASH-001.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Root deck đã có thẻ học xong chuỗi học mới:** phần chọn chế độ hiển thị ở trạng thái **khoá**,
  kèm giải thích và lối đi tới Reset learning progress (UC-SRS-001). Không ẩn đi — ẩn
  khiến người dùng tưởng tính năng không tồn tại (BR-SRS-003).
- **A2 — Sửa deck con:** không có phần chọn chế độ (BR-DECK-025).
- **A3 — Huỷ xác nhận xoá:** không xảy ra gì.
- **A4 — Xác nhận đúng chế độ deck đang chạy:** thao tác được chấp nhận và không
  làm gì người dùng thấy được (BR-SRS-002). Không seed lại cây, không đóng phiên đang
  mở — mất một phiên đang học cho một thay đổi bằng không là cái giá không ai
  đồng ý trả.

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách với
  thông báo nhẹ nhàng.
- **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên
  scheduler cũ và study state cũ.
- **E3 — Xoá thất bại:** hiện lỗi; deck còn nguyên vẹn, và `content_type` của
  deck cha cũng không đổi — cả hai nằm trong một transaction (BR-DECK-015).
- **E4 — Scheduler bị khoá trong lúc bảng chọn đang mở:** người dùng học xong một
  thẻ ở màn khác giữa lúc bảng chọn mở. Hệ thống đọc lại `first_answered_at`
  **bên trong** transaction (BR-SRS-003) và từ chối; màn hình hiện lý do và lối đi tới
  Reset. Trạng thái vẽ trên màn hình MUST NOT là thứ quyết định thao tác có hợp lệ
  hay không.

## UI

**UI states:** loaded · submitting · error

## Local

**Postconditions:**
- Sau đổi chế độ: `scheduler_type` mới, mọi study state trong cây khởi tạo lại,
  `generation` **không đổi** (chưa có gì để reset), `first_answered_at`
  vẫn NULL, và không còn phiên `in_progress` nào của cây (BR-STUDY-016).
- Sau xoá: deck và mọi descendant của nó không còn tồn tại — cascade đã xoá
  cứng card, study state, study answers và study session của chúng (BR-DECK-022);
  không bề mặt active nào còn hiện chúng.
- Sau xoá một deck con: nếu deck cha là **sub-deck** và vừa mất phần tử con cuối
  cùng, `content_type` của nó tự về `unset` trong cùng transaction (BR-DECK-015).
  Deck cha là root thì giữ `deck` (BR-DECK-004).

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
