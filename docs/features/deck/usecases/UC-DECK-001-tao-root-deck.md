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

- [ ] **Given** một tên hợp lệ và một chế độ ôn tập (`eight_box` hoặc `sm2`), **when** người dùng xác nhận tạo, **then** hệ thống tạo root deck với `parent_id = NULL`, `root_id = id`, `content_type = 'deck'`, `generation = 1` và chế độ đã chọn, và deck còn sau khi khởi động lại app (BR-DECK-002, BR-DECK-004, BR-SRS-001).
- [ ] **Given** một root deck vừa tạo, **when** người dùng bấm Create bên trong nó, **then** chỉ có lựa chọn Create deck, không có Create card (BR-DECK-004, BR-DECK-005).
- [ ] **Given** đã có một deck tên "Unit 5", **when** tạo thêm một root deck cũng tên "Unit 5", **then** hệ thống chấp nhận và không báo trùng tên (BR-DECK-021).
- [ ] **Given** tên rỗng hoặc chỉ có khoảng trắng, **when** xác nhận, **then** lỗi hiện ngay dưới ô nhập và không tạo gì (BR-DECK-020, E1).
- [ ] **Given** tên dài hơn 200 ký tự, **when** xác nhận, **then** lỗi hiện ngay dưới ô nhập và không tạo gì (BR-DECK-020, E2).
- [ ] **Given** ghi database thất bại, **when** xác nhận, **then** hệ thống báo lỗi, giữ nguyên form và dữ liệu đã nhập, và không tạo deck (E4).
- [ ] **Given** dialog tạo root deck đã có tên hoặc chế độ ôn, **when** người dùng bấm Cancel, Back hay chạm ra ngoài, **then** hệ thống hỏi "Discard this deck?"; Keep editing giữ nguyên dữ liệu, Discard đóng dialog và không tạo gì. Dialog còn trống thì đóng ngay (A1).
- [ ] **Given** dialog tạo root deck vừa mở, **when** người dùng chưa chọn chế độ ôn tập mà bấm Create, **then** không có chế độ nào được chọn sẵn, lỗi inline "Choose how the cards are reviewed." hiện dưới phần chọn chế độ và không có deck nào được tạo (BR-SRS-001, E3).
