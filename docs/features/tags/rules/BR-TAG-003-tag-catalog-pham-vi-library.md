---
id: BR-TAG-003
title: Tag catalog phạm vi library
status: active
summary: Tag catalog ở phạm vi library, mỗi hàng hiện tên canonical và số thẻ đang hoạt động.
superseded_by:
---
## Rule

Tag catalog MUST ở phạm vi **library** — mọi tag của owner hiện tại, không giới hạn theo deck đang mở (BR-TAG-001). Mỗi hàng MUST hiển thị tên canonical đúng như đã lưu và số thẻ **đang hoạt động** mang tag đó. Catalog MUST sắp theo `name_folded` tăng dần với tie-break `id` tăng dần — MUST NOT sắp theo tên chưa fold, vì hai cách fold khác nhau cho hai thứ tự khác nhau ở cùng một dữ liệu. Tìm kiếm trong catalog MUST dùng đúng phép fold của BR-TAG-001 cho cả chuỗi tìm lẫn cột được tìm; MUST NOT thêm bộ chuẩn hoá thứ hai. Tag không còn thẻ nào MUST vẫn xuất hiện với số đếm 0 — nó vẫn là một tag người dùng tạo ra và vẫn phải xoá được.

**Enforced by:** rule + store
**Liên quan:** BR-TAG-001

## Lý do

Tag Management v1 không đổi mô hình dữ liệu của BR-TAG-001/BR-TAG-002: nó chỉ thêm mặt
**quản lý** cho cùng những hàng đó — nhìn toàn bộ tag, lọc thẻ theo tag, đổi tên
(có thể dẫn tới gộp) và xoá tag. Các rule dưới đây **không** phát biểu lại
BR-TAG-001 (chuẩn hoá tên, duy nhất không phân biệt hoa thường) hay BR-TAG-002 (trần 10
tag mỗi thẻ); chúng chỉ nói phần mà mặt quản lý thêm vào.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
