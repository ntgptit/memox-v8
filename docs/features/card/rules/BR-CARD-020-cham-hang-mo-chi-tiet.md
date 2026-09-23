---
id: BR-CARD-020
title: Chạm hàng card mở chi tiết
status: active
summary: Chạm hàng card ở chế độ thường mở chi tiết chỉ đọc; chế độ chọn nhiều chạm là chọn.
superseded_by:
---
## Rule

Chạm vào một hàng card trong danh sách đang ở chế độ thường MUST mở chi tiết chỉ-đọc của thẻ đó. Trong chế độ chọn nhiều (UC-CARD-001 A6), chạm MUST giữ nguyên nghĩa chọn/bỏ chọn và MUST NOT điều hướng. Sửa MUST là một action riêng, tường minh, dẫn tới editor sẵn có; nó MUST NOT là hành động mặc định của một lần chạm và MUST NOT nổi bật hơn phần nội dung đang đọc. Quay lại từ chi tiết MUST giữ nguyên ngữ cảnh của danh sách — filter, search term, sort, cửa sổ đã tải và selection.

**Enforced by:** UI
**Liên quan:** BR-CARD-012

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Chạm hàng card khi đang ở chế độ chọn nhiều | Toggle chọn; không mở chi tiết (BR-CARD-020) |
