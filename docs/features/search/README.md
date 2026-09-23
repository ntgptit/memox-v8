---
feature: search
code: []
depends_on: []
---
## Phạm vi

Tìm kiếm toàn thư viện (Global Library Search): tên deck, hai mặt card và tên tag.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

> ⚠️ OPEN QUESTION: Search có thuộc V8.0 không: `business-rules/README.md` ghi "Tìm kiếm toàn thư viện (V8.0)", `product/product.md` xếp tìm kiếm là S1 should-have, còn `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` §2 không nhắc Search ở cả danh sách trong lẫn ngoài V8.0. (Plan OQ-2)

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tìm kiếm từ header của Library, ở mọi cấp | UC-SEARCH-001 |

Nguồn: trigger của UC-SEARCH-001 ("Bấm biểu tượng tìm kiếm ở header của Library, ở bất kỳ cấp nào").

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Fuzzy/semantic search, bỏ dấu, tìm trong `example`/`hint`/`pronunciation` | Ngoài phạm vi v1 (`use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
