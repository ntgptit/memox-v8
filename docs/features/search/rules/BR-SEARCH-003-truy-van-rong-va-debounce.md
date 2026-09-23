---
id: BR-SEARCH-003
title: Truy vấn rỗng và debounce
status: active
summary: Truy vấn rỗng trả trạng thái ban đầu không chạm DB; truy vấn có nội dung debounce 250ms ở seam provider.
superseded_by:
---
## Rule

Câu truy vấn chuẩn hoá thành rỗng MUST trả về trạng thái ban đầu và MUST NOT phát sinh bất kỳ statement nào tới database. Truy vấn có nội dung MUST được debounce **250ms** ở seam provider/controller, MUST NOT debounce bên trong widget nhập liệu. Xoá trắng ô tìm kiếm MUST có hiệu lực ngay, không chờ hết cửa sổ debounce. Mỗi lần đọc MUST có định danh riêng; kết quả hoặc lỗi đến sau khi truy vấn đã đổi MUST bị bỏ. Rời màn hình MUST huỷ cửa sổ đang chờ.

**Enforced by:** UI

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
