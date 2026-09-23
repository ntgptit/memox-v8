---
id: ADR-005
title: Starter deck là template được sao chép
status: active
superseded_by:
---
Quyết định đã chốt ngày 2026-07-28 (`product/product.md`).

## Quyết định

**Nội dung: starter deck quản lý như template.** Người dùng chọn dùng thì app tạo
một **bản sao** vào dữ liệu cá nhân; bản sao là deck bình thường. Cập nhật
template ở bản app mới không ghi đè nội dung người dùng đã sửa. Xem UC-STARTER-001.
Nội dung starter hiện tại là fixture cho development/test (BR-STARTER-010).

Quyết định nội dung/bản sao ở trên vẫn là nghiệp vụ chốt cho M6 khi sub-project
thư viện starter triển khai; M6 nằm ngoài phạm vi V8.0 theo spec
`docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md` §2, không
phải must-have của V8.0.

| # | Feature | Done when |
|---|---|---|
| M6 | Thư viện starter deck với sao chép vào dữ liệu cá nhân | Sub-project sau (UC-STARTER-001, BR-STARTER-001…BR-STARTER-009, BR-STARTER-010): cài mới → mở app → chọn một starter deck → ôn được ngay. Sửa bản sao rồi cập nhật app lên version template mới thì nội dung đã sửa **không** bị ghi đè. Mở lại app **không** tạo deck trùng |

Luật: BR-STARTER-001…BR-STARTER-010; luồng UC-STARTER-001.
