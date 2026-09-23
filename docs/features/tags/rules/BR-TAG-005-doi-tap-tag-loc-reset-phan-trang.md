---
id: BR-TAG-005
title: Đổi tập tag lọc reset phân trang
status: active
summary: Đổi tập tag đang lọc reset cửa sổ phân trang và xoá selection.
superseded_by:
---
## Rule

Đổi tập tag đang lọc MUST reset cửa sổ phân trang về trang đầu, cùng lý do với đổi filter/search/sort (BR-CARD-012): một cửa sổ mở trên tập kết quả cũ không mô tả tập kết quả mới. Selection đang mở MUST bị xoá khi tập tag đổi. Kết quả của một truy vấn đã cũ MUST bị bỏ qua, MUST NOT ghi đè kết quả của tập tag hiện tại.

**Enforced by:** UI + store
**Liên quan:** BR-CARD-012

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
