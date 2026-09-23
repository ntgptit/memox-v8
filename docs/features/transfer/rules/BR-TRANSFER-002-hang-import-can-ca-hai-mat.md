---
id: BR-TRANSFER-002
title: Hàng import cần cả hai mặt
status: active
summary: Mỗi hàng import cần `front` và `back` sau trim; hàng trống toàn bộ được bỏ qua.
superseded_by:
---
## Rule

Mỗi hàng import MUST có cả `front` và `back` sau khi trim; hàng chỉ có một trong hai là invalid, hàng trống toàn bộ được bỏ qua không tính là lỗi. Validation nội dung MUST tái sử dụng đúng các rule hiện có — BR-CARD-001/BR-CARD-002 cho hai mặt, BR-CARD-003 cho ba trường phụ, BR-TAG-001/BR-TAG-002 cho tag — MUST NOT có bộ validation thứ hai trong parser hoặc UI. Tag trong một ô MUST tách bằng dấu chấm phẩy `;`, MUST NOT dùng dấu phẩy vì nó là delimiter phổ biến của CSV. `front` MUST NOT bị từ chối chỉ vì không chứa Hangul — từ vay mượn, chữ số và ký hiệu vẫn hợp lệ.

**Enforced by:** rule
**Liên quan:** BR-CARD-001, BR-CARD-002, BR-TAG-001, BR-TAG-002, BR-CARD-003

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Hàng chỉ có `front`, thiếu `back` | Hàng invalid, hiện lý do; các hàng khác không bị ảnh hưởng (BR-TRANSFER-002) |
