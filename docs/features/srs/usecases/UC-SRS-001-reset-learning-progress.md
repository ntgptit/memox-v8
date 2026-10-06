---
id: UC-SRS-001
title: Reset learning progress
status: ready
rules: [BR-CARD-004, BR-DECK-024, BR-SRS-020, BR-SRS-021, BR-SRS-022, BR-SRS-023, BR-SRS-024, BR-SRS-025, BR-SRS-026, BR-SRS-027, BR-SRS-028, BR-SRS-029, BR-SRS-030, BR-STUDY-015, BR-STUDY-017, BR-STUDY-050, BR-STUDY-051]
code: [lib/features/deck/domain/usecases/get_reset_learning_summary_use_case.dart, lib/features/deck/domain/usecases/reset_learning_progress_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn "Đặt lại tiến độ học" trên một **root deck** — thường từ chỗ
giải thích vì sao chế độ ôn tập đang bị khoá (UC-DECK-002 A1)
**Preconditions:** Root deck tồn tại

## Main flow

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

## Alternative / Error flow

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

## UI

**UI states:** loaded · submitting · error

## Local

**Postconditions:**
- `generation` tăng đúng 1.
- Mọi study state trong cây có generation mới, scheduler mới, `due_at = NULL`.
- `first_answered_at IS NULL`.
- Không còn session `in_progress` nào của cây.
- `review_log` cũ còn nguyên, mang generation cũ (BR-SRS-023).
- Cấu trúc cây và `content_type` không đổi (BR-SRS-021).
- Bất biến BR-SRS-028 và BR-SRS-029 giữ nguyên.

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** một root đã khoá scheduler và đã học, **when** người dùng xác nhận reset với một chế độ, **then** trong một transaction `generation` tăng đúng 1, `first_answered_at = NULL`, và mọi study state trong cây khởi tạo lại ở giá trị đầu của chế độ đó, cùng generation mới (BR-SRS-020, BR-SRS-022, BR-SRS-024).
- [ ] **Given** một reset vừa xong, **when** kiểm tra dữ liệu, **then** cây deck, card, tag và `content_type` không đổi (BR-SRS-021).
- [ ] **Given** một reset vừa xong, **when** kiểm tra `review_log`, **then** các dòng cũ còn nguyên và vẫn mang generation cũ (BR-SRS-023).
- [ ] **Given** nhiều cây deck độc lập, **when** một cây được reset, **then** các cây khác không đổi gì (BR-SRS-020, BR-SRS-029).
- [ ] **Given** reset giữ nguyên chế độ đang chạy, **when** người dùng xác nhận, **then** chế độ giữ nguyên nhưng `generation` vẫn tăng và study state vẫn khởi tạo lại (BR-SRS-020, A1).
- [ ] **Given** một root chưa từng học hoặc không có card, **when** hộp xác nhận hiện, **then** tóm tắt nói rõ không có gì để mất, và reset vẫn thực hiện được (BR-SRS-030, A2).
- [ ] **Given** hộp xác nhận reset đang mở, **when** người dùng bấm Huỷ, **then** không có gì thay đổi (A3).
- [ ] **Given** một deck con, **when** người dùng tìm thao tác đặt lại tiến độ học, **then** thao tác không có ở đó; chỉ root mới reset được (BR-DECK-024, A4).
- [ ] **Given** một ghi lỗi giữa transaction reset, **when** hệ thống xử lý, **then** toàn bộ rollback: root giữ `generation`, chế độ, study state và trạng thái phiên cũ (BR-SRS-027, E1).
- [ ] **Given** cây có một phiên `in_progress`, **when** reset được thực hiện, **then** phiên đó thành `invalidated` với `end_reason = scheduler_reset`, lượt trả lời kế tiếp của nó bị từ chối, và các lượt đã ghi trước reset vẫn giữ (BR-STUDY-015, E2).
- [ ] **Given** một root không tồn tại hoặc đang ở Trash, **when** yêu cầu reset hoặc xem tóm tắt, **then** thao tác bị từ chối, không có tóm tắt và không ghi gì.
