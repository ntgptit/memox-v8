---
id: UC-TRANSFER-001
title: Import card hàng loạt vào một deck
status: ready
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TAG-001, BR-TAG-002, BR-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005, BR-TRANSFER-006, BR-TRANSFER-009]
code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/usecases/commit_import_use_case.dart, lib/features/transfer/presentation/controllers/card_import_controller.dart, lib/features/transfer/presentation/screens/card_import_screen.dart]
---
## Mục tiêu / Actor / Precondition

**Phạm vi:** backend BE-B3 và màn import FE-B3 đã xong ([spec card transfer](../../../superpowers/specs/2026-09-26-card-transfer-design.md), [màn 11](../../../shared/ui/screen-handoff/11-card-import.md)).

**Actor:** Người dùng
**Trigger:** Chọn "Import cards" từ card list của một deck loại card, từ empty
state của card list, hoặc từ lựa chọn tạo phần tử con của một deck `unset`
**Preconditions:** Deck đích tồn tại và là sub-deck `unset` hoặc `card` (BR-TRANSFER-001)

## Main flow

**Main flow:**
1. Người dùng mở màn import; hệ thống hiển thị deck đích, số card hiện có và
   bốn bước Source → Columns → Preview → Import (spec card transfer §8.1).
2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV.
3. Người dùng bấm Preview; hệ thống parse nguồn trong bộ nhớ (BR-TRANSFER-006) — không
   ghi gì vào database.
4. Hệ thống mặc định coi hàng đầu là header và tự map các cột trùng tên
   (front, back, example, hint, pronunciation, tags — không phân biệt hoa
   thường); người dùng chỉnh mapping nếu cần. `front` và `back` bắt buộc phải
   được map; một cột nguồn không map vào hai đích (BR-TRANSFER-002).
5. Hệ thống validate toàn bộ hàng bằng đúng các rule của card (BR-TRANSFER-002), đánh
   dấu trùng lặp theo BR-TRANSFER-003, và hiển thị: tổng số hàng, số sẵn sàng, số trùng,
   số invalid kèm lý do, số hàng trống đã bỏ qua, cùng các hàng đầu tiên.
6. Người dùng bấm Continue rồi xác nhận ở bước Import — màn xác nhận nêu deck
   đích, số card sẽ ghi, số trùng bị bỏ/ghi, số invalid bị loại.
7. Hệ thống ghi toàn bộ trong một transaction (BR-TRANSFER-004): card, study state mới
   cho từng card, tag, và `content_type` nếu deck đang `unset` (BR-TRANSFER-005).
8. Hệ thống hiện kết quả — số đã ghi, số trùng bỏ qua, số invalid bị loại — với
   hai lối ra: View cards về card list (danh sách tự cập nhật qua stream),
   hoặc Import another file giữ deck đích và làm lại từ bước Source.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Dán văn bản:** ở bước Source người dùng dán các hàng CSV/TSV vào ô
  nhập; parse chỉ chạy khi bấm Preview, và văn bản giữ nguyên khi parse lỗi.
- **A2 — XLSX nhiều sheet:** hệ thống mặc định chọn sheet không rỗng đầu tiên
  và cho người dùng đổi sheet; đổi sheet chạy lại bước 4–5.
- **A3 — Không có header:** người dùng tắt "First row contains headers"; các
  cột hiển thị tên vị trí ổn định (Column A, Column B, …) và hàng đầu được
  validate như dữ liệu.
- **A4 — Bao gồm trùng lặp:** người dùng bật "Include duplicates"; số sẵn sàng
  gồm cả các hàng trùng, và commit ghi chúng như card mới (BR-TRANSFER-003).
- **A5 — Đổi file:** người dùng thay file đã chọn; hủy hộp chọn file không
  phải lỗi và không xoá lựa chọn trước đó.

**Error flows:**
- **E1 — File không đọc được:** file hỏng, có mật khẩu, đuôi không hỗ trợ hoặc
  encoding không phải UTF-8/UTF-8 BOM (BR-TRANSFER-006) → lỗi có kiểu kèm hướng dẫn
  (export lại UTF-8); nguồn đã chọn trước đó giữ nguyên.
- **E2 — Nguồn rỗng:** file/sheet/văn bản không có hàng dữ liệu nào → thông báo
  rõ ở bước Preview; không đi tiếp được.
- **E3 — Không còn hàng hợp lệ:** sau validate và policy trùng lặp, số sẽ ghi
  bằng 0 → Continue bị khoá; không có mutation nào (BR-TRANSFER-004).
- **E4 — Deck đích không còn hợp lệ lúc ghi:** deck biến mất, thành root-level
  hoặc đã giữ deck con → transaction từ chối bằng lý do có kiểu (BR-TRANSFER-001), không
  ghi gì; preview và mapping giữ nguyên.
- **E5 — Commit thất bại giữa chừng:** một write lỗi → rollback toàn bộ
  (BR-TRANSFER-004); màn import giữ nguyên nguồn, mapping và preview, hiện Try again.
- **E6 — Mọi hàng đã thành trùng lúc ghi:** giữa Preview và Import, deck nhận
  các card trùng với mọi hàng sẽ ghi; kiểm tra trùng chạy lại trong transaction
  (BR-TRANSFER-003) nên không ghi card nào → màn kết quả "Nothing added", deck
  không đổi kể cả `content_type` (BR-TRANSFER-005); một lối về deck.

## UI

**UI states:** initial (Source trống) · source đã chọn · parsing · parse error ·
preview loaded (đủ valid/invalid/duplicate/blank) · preview empty (E2/E3) ·
confirm · submitting · commit error · result. Không có state "refreshing" —
nguồn chỉ parse lại khi người dùng đổi nguồn, sheet, header hoặc bấm lại
Preview.

## Local

**Postconditions:** Mọi card được ghi có đúng một study state mới theo scheduler
của root (BR-TRANSFER-004); card, tiến độ và history đã có từ trước không bị sửa;
`content_type` của deck đích phản ánh đúng nội dung sau import (BR-TRANSFER-005).

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] **Given** một sub-deck `unset` và một file CSV có header `front,back,tags`, **when** người dùng import, **then** mỗi hàng hợp lệ thành một card mới có đúng một study state mới và tag của nó, deck thành `card`, và không có review log nào (BR-TRANSFER-004, BR-TRANSFER-005).
- [ ] **Given** một hàng trùng `front`+`back` (sau fold) với card đã có trong deck và một hàng lặp lại trong file, **when** preview, **then** hai hàng đó được đánh dấu trùng và mặc định bị bỏ; bật Include duplicates thì cả hai được ghi thành card mới (BR-TRANSFER-003).
- [ ] **Given** một file UTF-16 hoặc Latin-1, **when** chọn file, **then** hệ thống từ chối bằng lý do encoding kèm hướng dẫn và không ghi gì (BR-TRANSFER-006).
- [ ] **Given** preview đã xong và deck vừa nhận deck con, **when** commit, **then** transaction từ chối bằng lý do có kiểu và không ghi gì (BR-TRANSFER-001, E4).
- [ ] **Given** một write lỗi giữa batch, **when** commit, **then** không card, study state, tag hay `content_type` nào đổi (BR-TRANSFER-004, E5).
