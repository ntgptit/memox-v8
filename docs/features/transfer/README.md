---
feature: transfer
code: [lib/features/transfer/domain, lib/features/transfer/data, lib/features/transfer/di, lib/features/transfer/presentation]
depends_on: [card, deck, tags]
---
## Phạm vi

**Phạm vi:** Card Transfer: backend BE-B3 và giao diện FE-B3 xong — màn import (SCR-TRANSFER-001) và sheet export (SCR-TRANSFER-002). Thiết kế: [spec card transfer](../../superpowers/specs/2026-09-26-card-transfer-design.md).

Import card hàng loạt vào một deck và export card của một deck ra file (Card Transfer).

Nửa import của N1 (UC-TRANSFER-001): thư viện starter giải quyết "app trống lúc mới
cài", nhưng không giải quyết "bộ thẻ của tôi đang nằm trong một file" — và
nhập tay từng card không phải câu trả lời cho một file nghìn dòng. Nửa export
(UC-TRANSFER-002): mang bộ thẻ ra khỏi app là điều kiện để "dữ liệu của tôi" không bị
khoá trong một cài đặt duy nhất — nhưng nó là export **nội dung**, không phải
backup, nên không thay thế được sync.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Backup/restore, sync, `.apkg` | Nice-to-have ngoài phạm vi export nội dung (trước migrate: `use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
