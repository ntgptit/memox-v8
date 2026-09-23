---
id: BR-SEARCH-007
title: Phân trang keyset
status: active
summary: Phân trang keyset với khoá bốn thành phần theo thứ tự sắp xếp.
superseded_by:
---
## Rule

Phân trang MUST là keyset. Khoá phân trang MUST gồm đúng bốn thành phần theo đúng thứ tự sắp xếp: bậc khớp, văn bản đã fold dùng để sắp, `created_at`, rồi `id` — nên thứ tự là toàn phần và không hai hàng nào bằng nhau. MUST NOT dùng `OFFSET`. Một lần ghi xen giữa hai trang MUST NOT làm lặp hàng hay bỏ sót hàng.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
