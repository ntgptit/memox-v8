# Use cases — SRS scheduler

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng SRS, dưới ID vĩnh viễn `UC-SRS-nnn` |
| **Scope** | Luồng reset learning progress. |
| **Source of truth for** | UC-SRS-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-SRS-001 · Reset learning progress

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn "Đặt lại tiến độ học" trên một **root deck** — thường từ chỗ
giải thích vì sao chế độ ôn tập đang bị khoá (UC-DECK-002 A1)
**Preconditions:** Root deck tồn tại

**Main flow:**
1. Người dùng chọn đặt lại tiến độ học.
2. Hệ thống hiện xác nhận nêu rõ hai danh sách (BR-SRS-030):
   - **Giữ nguyên:** deck, toàn bộ cây deck con, flashcard, media, tag, mọi nội
     dung, và lịch sử ôn tập cũ (để tham khảo).
   - **Mất:** lịch ôn hiện tại, ngày đến hạn, box / ease factor / interval, trạng
     thái thành thạo, phiên đang dở, và **dấu đã học xong lần đầu** — mọi thẻ
     trở lại tập Học mới và đi lại chuỗi stage (BR-STUDY-050, BR-STUDY-051).
3. Người dùng có thể chọn **chế độ ôn tập mới** ngay trong bước này — đây là mục
   đích chính của thao tác.
4. Người dùng xác nhận.
5. Hệ thống thực hiện, **trong một transaction duy nhất** (BR-SRS-027):
   - tăng `generation` của root deck (BR-SRS-020);
   - đặt `scheduler_type` / `version` / `config` mới nếu người dùng đã chọn;
   - đặt `first_answered_at = NULL` → scheduler mở khoá (BR-SRS-024);
   - khởi tạo lại study state của **toàn bộ** card trong cây (mọi cấp), theo
     scheduler mới và generation mới (BR-SRS-022, BR-CARD-004);
   - mọi study session `in_progress` của cây → `invalidated`,
     `end_reason = scheduler_reset`, `ended_at` được đặt (BR-STUDY-015);
   - **không** đụng tới `review_log` (BR-SRS-023), và **không** đụng tới
     `content_type` hay cấu trúc cây (BR-SRS-021).
6. Người dùng quay về deck; toàn bộ card đã trở lại trạng thái Học mới
   (`learned_at`/`due_at` về NULL) và chưa thuộc tập Due/Reviewing; scheduler
   được mở khoá lại, lịch sử trả lời cũ vẫn được giữ.

**Alternative flows:**
- **A1 — Reset mà không đổi chế độ:** hợp lệ. Dùng khi người dùng chỉ muốn học lại
  từ đầu.
- **A2 — Reset trên deck chưa có lượt học:** vẫn cho phép, nhưng nêu rõ là không có
  gì để mất.
- **A3 — Huỷ ở bước xác nhận:** không xảy ra gì.
- **A4 — Reset trên deck con:** không có thao tác này. Reset chỉ tồn tại ở root vì
  scheduler và generation thuộc root (BR-DECK-024).

**Error flows:**
- **E1 — Thất bại giữa chừng:** transaction rollback (BR-SRS-027). Root giữ nguyên
  generation cũ, scheduler cũ và toàn bộ state cũ. **Không** có trạng thái nửa vời
  với card thuộc hai generation.
- **E2 — Người dùng có phiên đang mở ở màn khác:** phiên đó đã bị chuyển
  `invalidated` ở bước 5. Lần bấm đánh giá tiếp theo trong phiên đó bị từ chối
  (UC-STUDY-001 E4, BR-STUDY-017).

**Postconditions:**
- `generation` tăng đúng 1.
- Mọi study state trong cây có generation mới, scheduler mới, `due_at = NULL`.
- `first_answered_at IS NULL`.
- Không còn session `in_progress` nào của cây.
- `review_log` cũ còn nguyên, mang generation cũ (BR-SRS-023).
- Cấu trúc cây và `content_type` không đổi (BR-SRS-021).
- Bất biến BR-SRS-028 và BR-SRS-029 giữ nguyên.

**Business rules:** BR-SRS-020…BR-SRS-030, BR-STUDY-015
**UI states:** loaded · submitting · error
