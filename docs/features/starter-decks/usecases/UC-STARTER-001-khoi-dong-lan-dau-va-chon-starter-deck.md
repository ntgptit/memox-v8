---
id: UC-STARTER-001
title: Khởi động lần đầu và chọn starter deck
status: ready
rules: [BR-CARD-004, BR-DECK-002, BR-STARTER-001, BR-STARTER-002, BR-STARTER-003, BR-STARTER-004, BR-STARTER-005, BR-STARTER-006, BR-STARTER-007, BR-STARTER-008, BR-STARTER-009, BR-STARTER-010, BR-STUDY-077]
code: [lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart, lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Phạm vi:** Starter library, phần store (BE-B4, [spec](../../../superpowers/specs/2026-09-26-starter-decks-backend-design.md)). Màn 03
thuộc FE-B4.

**Actor:** Người dùng mới cài app
**Trigger:** Mở app lần đầu sau khi cài
**Preconditions:** Chưa có deck nào

## Main flow

**Main flow:**
1. Người dùng mở app.
2. Hệ thống khởi tạo database.
3. Người dùng thấy màn hình chưa có deck, kèm hai lối đi: **chọn từ thư viện
   starter** hoặc **tạo deck mới**.
4. Người dùng mở thư viện starter deck.
5. Hệ thống đọc manifest template và hiện danh sách: tên, số card, ngôn ngữ,
   nguồn nội dung. Nội dung starter được ghi rõ là **fixture cho development và
   test** (BR-STARTER-010).
6. Người dùng chọn một starter deck.
7. Hệ thống hỏi **chế độ ôn tập** cho bản sao, gợi ý sẵn `default_scheduler_type`
   của template (BR-STARTER-004).
8. Hệ thống **tạo bản sao** trong một transaction (BR-STARTER-009): root deck mới với
   `content_type = 'deck'`, `root_id = id`, `generation = 1`; toàn
   bộ cây deck con với `content_type` đúng theo template; toàn bộ card; và study
state theo scheduler đã chọn (BR-CARD-004, BR-STARTER-003).
9. Bản sao xuất hiện trong danh sách deck. Toàn bộ card là thẻ **chưa học**
   (`learned_at IS NULL`), nên badge của deck hiện số New chứ không phải số
   đến hạn (BR-STUDY-051, BR-STUDY-046).
10. Người dùng bấm Study và bắt đầu phiên **học mới** ngay.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Bỏ qua thư viện, tự tạo deck:** đi thẳng UC-DECK-001.
- **A2 — Đã có bản sao từ đúng template và version đó:** hỏi xác nhận, nêu rõ đã
  tồn tại (BR-STARTER-008). Đồng ý thì tạo bản sao thứ hai — lựa chọn có ý thức, khác hoàn
  toàn với việc app tự tạo trùng (BR-STARTER-007).
- **A3 — Cập nhật app có template mới hoặc version mới:** template mới xuất hiện
  trong thư viện. Bản sao đã có **không** bị đụng đến (BR-STARTER-006).
- **A4 — Người dùng đã xoá bản sao:** template vẫn còn trong thư viện, lấy lại
  được.

**Error flows:**
- **E1 — Không mở được database:** màn hình lỗi rõ ràng với hành động thử lại.
  Không được là màn hình trắng — trắng không phân biệt được với treo.
- **E2 — Manifest hỏng hoặc thiếu:** thư viện hiện empty state; app vẫn dùng bình
  thường với luồng tạo deck thủ công.
- **E3 — Một file template hỏng:** bỏ qua đúng template đó, các template khác vẫn
  hiện.
- **E4 — Sao chép thất bại giữa chừng:** transaction rollback (BR-STARTER-009). Không có
  cây deck nửa vời.

## UI

**UI states:** initial · loading · loaded · empty · submitting · error

## Local

**Postconditions:**
- Bản sao có `source_template_id`, `source_template_version`, `scheduler_type` đã
  chọn, `generation = 1`, `first_answered_at = NULL`.
- Mọi deck trong bản sao có `root_id` trỏ đúng root mới (BR-DECK-002).
- Mỗi card có đúng một study state khởi tạo theo scheduler đó.

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] **Given** thư viện starter có template "English → Vietnamese · Everyday" và chưa có bản sao nào của nó, **when** người dùng thêm nó với SM-2, **then** có một root deck mới mang tên template, `source_template_id` và `source_template_version` của nó, `generation = 1`, `first_answered_at` NULL; bốn sub-deck theo đúng thứ tự; 40 card chưa học, mỗi card đúng một study state SM-2 (BR-STARTER-003, BR-STARTER-004).
- [ ] **Given** đã có một bản sao của đúng template và version đó nằm ngoài Trash, **when** người dùng thêm lại mà không xác nhận, **then** không có gì được ghi và lý do là `alreadyInLibrary`; khi người dùng xác nhận thêm bản sao thứ hai, có một cây deck thứ hai độc lập (BR-STARTER-007, BR-STARTER-008, A2).
- [ ] **Given** bản sao duy nhất của một template nằm trong Trash, **when** người dùng thêm template đó, **then** một bản sao mới được tạo mà không hỏi (A4).
- [ ] **Given** bản app mới nâng version của một template đã có bản sao, **when** thư viện hiện, **then** template được coi là chưa có trong thư viện, và thêm nó không đụng bản sao của version cũ (BR-STARTER-006, A3).
- [ ] **Given** manifest thiếu hoặc hỏng, **when** mở thư viện, **then** thư viện rỗng; **given** một file template hỏng, **then** chỉ template đó bị bỏ qua (E2, E3).
- [ ] **Given** một lần ghi thất bại giữa chừng khi sao chép, **when** thêm template, **then** không có root, deck, card hay study state nào được ghi (BR-STARTER-009, E4).
