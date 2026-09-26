---
feature: transfer
code: [lib/features/transfer/domain, lib/features/transfer/data, lib/features/transfer/di]
depends_on: [card, deck, tags]
---
## Phạm vi

**Phạm vi:** Card Transfer, phần store (BE-B3,
[spec gói 9a](../../superpowers/specs/2026-09-26-transfer-backend-design.md)): CSV, TSV và
văn bản dán ở gói 9a; XLSX ở gói 9b.

Import card hàng loạt vào một deck và export card của một deck ra file (Card Transfer).

Nửa import của N1 (UC-TRANSFER-001): thư viện starter giải quyết "app trống lúc mới
cài", nhưng không giải quyết "bộ thẻ của tôi đang nằm trong một file" — và
nhập tay từng card không phải câu trả lời cho một file nghìn dòng. Nửa export
(UC-TRANSFER-002): mang bộ thẻ ra khỏi app là điều kiện để "dữ liệu của tôi" không bị
khoá trong một cài đặt duy nhất — nhưng nó là export **nội dung**, không phải
backup, nên không thay thế được sync.

Import đọc nguồn trong bộ nhớ, trên một isolate khác (`ReadImportSourceUseCase`), rồi
xếp mỗi hàng dữ liệu vào một trạng thái bằng đúng các rule của card: sẵn sàng, trùng,
invalid hay trống (`PreviewImportUseCase`). Commit xếp lại trên deck như lúc ghi và ghi
tất cả hoặc không gì trong một transaction (`ImportCardsUseCase`); card nhập vào giữ thứ
tự của file khi học và khi export. Export đọc một snapshot và không ghi gì
(`ExportCardsUseCase`). Ô tags của cả hai chiều đi qua một codec duy nhất, `TagCell`
(BR-TRANSFER-009).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Card list của deck loại card — "Import cards" | UC-TRANSFER-001 |
| Card list — `Export cards` trong overflow menu | UC-TRANSFER-002 |

Nguồn: trigger của UC-TRANSFER-001 và UC-TRANSFER-002.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Backup/restore, sync, `.apkg` | Nice-to-have ngoài phạm vi export nội dung (trước migrate: `use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
| Màn import (màn 11), màn export (màn 12), chọn file, file tạm, share sheet | FE-B3 ([`wbs_FE.md`](../../wbs_FE.md)) |
| Chuẩn hoá Unicode của text nhập vào | Quyết định chung cho cả ứng dụng, BE-C5 ([`wbs_BE.md`](../../wbs_BE.md)); import giữ nguyên code point (spec gói 9a D17) |
