---
id: UC-TRANSFER-001
title: Import card hàng loạt vào một deck
status: ready
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TAG-001, BR-TAG-002, BR-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005, BR-TRANSFER-006, BR-TRANSFER-009]
code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/usecases/import_cards_use_case.dart, lib/features/card/domain/repositories/card_repository.dart]
---
## Mục tiêu / Actor / Precondition

**Phạm vi:** Card Transfer, phần store (BE-B3): CSV, TSV và văn bản dán ở gói 9a, XLSX
ở gói 9b. Màn import (màn 11) thuộc FE-B3.

**Actor:** Người dùng
**Trigger:** Chọn "Import cards" từ card list của một deck loại card, từ empty
state của card list, hoặc từ lựa chọn tạo phần tử con của một deck `unset`
**Preconditions:** Deck đích tồn tại và là sub-deck `unset` hoặc `card` (BR-TRANSFER-001)

## Main flow

**Main flow:**
1. Người dùng mở màn import; hệ thống hiển thị deck đích, số card hiện có và
   ba bước Source → Preview → Import.
2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV. File CSV
   phân cách bằng `,` hoặc `;` (cách Excel lưu CSV ở locale dùng dấu phẩy thập phân). Tính
   phần nằm ngoài dấu nháy kép, hệ thống chọn dấu xuất hiện cùng số lần, ít nhất một, ở
   mọi hàng trong tối đa 20 hàng không trống đầu tiên; khi cả hai dấu hoặc không dấu nào
   như vậy, file phân cách bằng `;` nếu hàng không trống đầu tiên có `;` mà không có `,`,
   còn lại bằng `,`.
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
  nhập; parse chỉ chạy khi bấm Preview, và văn bản giữ nguyên khi parse lỗi. Văn bản là
  TSV khi hàng không trống đầu tiên có tab nằm ngoài dấu nháy kép; nếu không, nó được
  đọc như một file CSV, kể cả phân cách `;` của bước 2.
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

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
