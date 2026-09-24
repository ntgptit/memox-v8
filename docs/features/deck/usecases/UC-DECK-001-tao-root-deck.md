---
id: UC-DECK-001
title: Tạo root deck
status: ready
rules: [BR-DECK-002, BR-DECK-004, BR-DECK-005, BR-DECK-020, BR-DECK-021, BR-SRS-001]
code: [lib/features/deck/domain/usecases/create_root_deck_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Bấm tạo deck ở màn hình danh sách deck
**Preconditions:** Không có

## Main flow

**Main flow:**
1. Người dùng nhập tên deck.
2. Người dùng **chọn chế độ ôn tập**: `eight_box` hoặc `sm2` (BR-SRS-001). Bắt buộc,
   không có mặc định ngầm bỏ qua bước này.
3. Hệ thống hiển thị mô tả ngắn cho từng chế độ, kèm lưu ý rằng chế độ sẽ bị khoá
   sau lượt ôn đầu tiên (BR-SRS-003).
4. Người dùng xác nhận.
5. Hệ thống validate tên (BR-DECK-020) và chế độ đã chọn.
6. Hệ thống tạo root deck với: `parent_id = NULL`, `root_id = id`,
   `content_type = 'deck'` (bất biến), `generation = 1`,
   `first_answered_at = NULL`.
7. Deck xuất hiện trong danh sách, rỗng.

**Root deck chỉ chứa deck con** (BR-DECK-004). Nút Create bên trong nó chỉ có một lựa
chọn: Create deck (BR-DECK-005). Việc tạo phần tử con nằm ở UC-DECK-004.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Người dùng huỷ:** không tạo gì; nếu đã nhập, hỏi xác nhận trước khi bỏ.

**Error flows:**
- **E1 — Tên rỗng:** lỗi inline dưới ô nhập, không phải snackbar.
- **E2 — Tên quá 200 ký tự:** lỗi inline; chặn nhập thêm thay vì cắt âm thầm.
- **E3 — Chưa chọn chế độ:** lỗi inline ở phần chọn chế độ; không tạo.
- **E4 — Ghi database thất bại:** hiện lỗi, giữ nguyên form và dữ liệu đã nhập.

## UI

**UI states:** initial · submitting · error

## Local

**Postconditions:** Root deck tồn tại với scheduler đã chọn, `content_type =
'deck'`, `root_id = id`, và còn sau khi khởi động lại app.

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
