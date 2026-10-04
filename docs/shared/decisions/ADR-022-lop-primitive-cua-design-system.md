---
id: ADR-022
title: Lớp primitive nội bộ của design system
status: accepted
superseded_by:
---
## Bối cảnh

SP3a ([spec](../../superpowers/specs/2026-10-04-sp3a-design-system-foundation-design.md), D16)
dựng design system theo thứ tự token → theme → primitive → `Mx*`. Primitive là khối dựng mà
nhiều `Mx*` cùng dùng: bề mặt nhấn được (ink nằm trong decoration, lớp phủ khi nhấn, vòng
focus, vùng chạm 48 dp), vòng focus và vùng chạm. Cây thư mục của
[ADR-011](ADR-011-cau-truc-thu-muc-v8.md) chỉ ghi `shared/widgets/`. Một thư mục mới có
ranh giới import riêng là một quyết định, nên được ghi ở ADR này thay vì sửa ADR-011.

## Quyết định

- `lib/shared/primitives/` chứa primitive của design system. Tên class không có tiền tố
  `Mx`, vì primitive không phải API công khai.
- Chỉ `lib/shared/widgets/` và chính `lib/shared/primitives/` được import thư mục này.
  Feature, `app/` và màn hình không import nó; `core/` không import `shared/` (ADR-011).
- `primitiveViolations` trong `test/architecture/boundary_rules.dart` kiểm luật này trên
  `lib/` thật, qua `boundaries_test.dart`.

## Hệ quả

- ADR này bổ sung ADR-011, không thay thế nó. Các quyết định khác của ADR-011 giữ nguyên.
- Màn hình cần hành vi của một primitive thì dùng `Mx*` bọc primitive đó. Nếu chưa có
  `Mx*` phù hợp, component được thêm vào `DESIGN.md` trước (spec D7).
