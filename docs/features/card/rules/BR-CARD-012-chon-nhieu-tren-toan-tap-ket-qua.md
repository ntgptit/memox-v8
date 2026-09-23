---
id: BR-CARD-012
title: Chọn nhiều trên toàn tập kết quả
status: active
summary: Chọn nhiều áp lên toàn bộ tập kết quả theo filter/search đang bật; đổi ngữ cảnh thì xoá selection.
superseded_by:
---
## Rule

Chọn nhiều thẻ MUST áp dụng lên **toàn bộ tập kết quả** của deck hiện tại theo đúng filter và search term đang bật, MUST NOT chỉ giới hạn trong cửa sổ phân trang đã tải. "Select all" MUST đọc danh sách id qua cùng vị từ mà danh sách và các pill đếm dùng, MUST NOT tải nội dung thẻ chỉ để lấy id. Khi filter, search term, sort hoặc deck đổi, selection MUST bị xoá — một selection không nhìn thấy được là một mutation người dùng không đồng ý. Sau mutation thành công MUST xoá selection; khi thất bại MUST giữ selection và nêu lỗi, MUST NOT báo thành công.

**Enforced by:** UI + store
**Liên quan:** BR-CARD-011

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
