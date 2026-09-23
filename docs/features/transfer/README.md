---
feature: transfer
code: []
depends_on: [card, deck, tags]
---
## Phạm vi

**Phạm vi:** sub-project sau — Import (spec §2).

**Phạm vi:** sub-project sau — Export (spec §2).

Import card hàng loạt vào một deck và export card của một deck ra file (Card Transfer).

Nửa import của N1 (UC-TRANSFER-001): thư viện starter giải quyết "app trống lúc mới
cài", nhưng không giải quyết "bộ thẻ của tôi đang nằm trong một file" — và
nhập tay từng card không phải câu trả lời cho một file nghìn dòng. Nửa export
(UC-TRANSFER-002): mang bộ thẻ ra khỏi app là điều kiện để "dữ liệu của tôi" không bị
khoá trong một cài đặt duy nhất — nhưng nó là export **nội dung**, không phải
backup, nên không thay thế được sync.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

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
