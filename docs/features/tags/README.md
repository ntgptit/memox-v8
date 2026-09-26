---
feature: tags
code: [lib/features/tags/domain, lib/features/tags/data, lib/features/tags/di]
depends_on: [card]
---
## Phạm vi

**Phạm vi:** Tag Management, phần store (BE-B2,
[spec](../../superpowers/specs/2026-09-26-tag-management-backend-design.md)).

Mô hình dữ liệu tag (BR-TAG-001, BR-TAG-002) và Tag Management v1: catalog, lọc theo tag, đổi tên/gộp, xoá.

Gắn/gỡ tag trên thẻ (BR-TAG-001, BR-TAG-002, UC-CARD-001 A8) thuộc V8.0 (chủ dự án chốt ngày 2026-09-23, [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md)); Tag Management là sub-project sau V8.0, phần store làm ở BE-B2.

Đổi tên được xem trước rồi mới ghi: `PlanTagRenameUseCase` nói trước lúc xác nhận là
giữ nguyên, đổi tên hay gộp vào tag nào, kèm số thẻ; `RenameTagUseCase` chỉ gộp vào
đúng tag người dùng đã xác nhận, còn lại từ chối `mergeNotConfirmed` và không ghi gì
(spec D5). Lọc card list theo tag là `CardListQuery.tagIds` của feature `card` (BE-C4).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tag catalog (hành động `Tags` trên app bar của Library, hoặc `Manage tags`) | UC-TAG-001 |

Nguồn: trigger của UC-TAG-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Tag phân cấp, màu tag, taxonomy chia sẻ | Ngoài phạm vi Tag Management v1 — UC-TAG-001 chốt tag là nhãn phẳng, là định danh văn bản, không phải hệ thống deck thứ hai |
| Màn catalog (màn 05), overlay lọc của card list, hành động `Tags` trên app bar của Library | FE-B2 ([`wbs_FE.md`](../../wbs_FE.md)) |
