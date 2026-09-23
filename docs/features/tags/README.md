---
feature: tags
code: []
depends_on: [card]
---
## Phạm vi

**Phạm vi:** sub-project sau — Tags (spec §2).

Mô hình dữ liệu tag (BR-TAG-001, BR-TAG-002) và Tag Management v1: catalog, lọc theo tag, đổi tên/gộp, xoá.

Ngoại lệ: gắn/gỡ tag trên thẻ (BR-TAG-001, BR-TAG-002, UC-CARD-001 A8) thuộc V8.0 (chủ dự án chốt ngày 2026-09-23, [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md)); Tag Management vẫn là sub-project sau.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tag catalog (hành động `Tags` trên app bar của Library, hoặc `Manage tags`) | UC-TAG-001 |

Nguồn: trigger của UC-TAG-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Tag phân cấp, màu tag, taxonomy chia sẻ | Ngoài phạm vi Tag Management v1 — UC-TAG-001 chốt tag là nhãn phẳng, là định danh văn bản, không phải hệ thống deck thứ hai |
