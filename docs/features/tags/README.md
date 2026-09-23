---
feature: tags
code: []
depends_on: []
---
## Phạm vi

**Phạm vi:** sub-project sau — Tags (spec §2).

Mô hình dữ liệu tag (BR-TAG-001, BR-TAG-002) và Tag Management v1: catalog, lọc theo tag, đổi tên/gộp, xoá.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

> ⚠️ OPEN QUESTION: Tag là sub-project sau V8.0 (`superpowers/specs/2026-09-21-memox-v8-foundation-design.md` §2; mục Phạm vi ở trên), nhưng UC-CARD-001 (V8.0) có luồng A8 gắn tag và khai báo BR-TAG-001, BR-TAG-002. (Plan OQ-4)

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tag catalog (hành động `Tags` trên app bar của Library, hoặc `Manage tags`) | UC-TAG-001 |

Nguồn: trigger của UC-TAG-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Tag phân cấp, màu tag, taxonomy chia sẻ | Ngoài phạm vi Tag Management v1 — UC-TAG-001 chốt tag là nhãn phẳng, là định danh văn bản, không phải hệ thống deck thứ hai |
