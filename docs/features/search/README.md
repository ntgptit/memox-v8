---
feature: search
code: [lib/features/search/domain, lib/features/search/data, lib/features/search/di, lib/features/search/presentation]
depends_on: [card, deck, tags]
---
## Phạm vi

Tìm kiếm toàn thư viện (Global Library Search): tên deck, hai mặt card và tên tag. Thuộc V8.0 (chủ dự án chốt ngày 2026-09-23, [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md)).

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Fuzzy/semantic search, bỏ dấu, tìm trong `example`/`hint`/`pronunciation` | Ngoài phạm vi v1 (trước migrate: `use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
