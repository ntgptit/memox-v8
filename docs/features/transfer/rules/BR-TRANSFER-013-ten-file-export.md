---
id: BR-TRANSFER-013
title: Tên file export
status: active
summary: Tên file export dẫn xuất từ tên deck đã sanitize.
superseded_by:
---
## Rule

Tên file export MUST dẫn xuất từ tên deck đã sanitize — loại ký tự phân cách đường dẫn, ký tự điều khiển và ký tự không hợp lệ của hệ tệp, gộp khoảng trắng liên tiếp thành một, trim hai đầu — cộng một ngày lấy từ `clockProvider` và phần mở rộng theo format đã chọn. Sanitize ra chuỗi rỗng thì phần tên MUST fallback về `cards`. MUST NOT gọi `DateTime.now()` ở bất kỳ layer nào, và tên file MUST NOT xuất hiện trong log ở bất kỳ level nào (BR-TRANSFER-006).

**Enforced by:** rule
**Liên quan:** BR-TRANSFER-006

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Tên deck chỉ gồm ký tự bị loại khi sanitize | Tên file dùng `cards` + ngày + đuôi format (BR-TRANSFER-013) |
