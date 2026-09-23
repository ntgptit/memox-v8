---
id: BR-PROGRESS-008
title: Màn tiến độ theo deck cập nhật trực tiếp
status: active
summary: Màn tiến độ theo deck tự cập nhật khi có lượt mới, chuyển thẻ, xoá deck và qua nửa đêm.
superseded_by:
---
## Rule

Màn hình MUST cập nhật trực tiếp: ghi một lượt trả lời, chuyển thẻ hoặc subtree, xoá deck, và nửa đêm địa phương đi qua MUST đều làm số trên màn hình đổi mà người dùng không phải thao tác gì. Ba sự kiện đầu MUST đến từ stream invalidation của các bảng liên quan; sự kiện thứ tư không có write nào trong database nên MUST đến từ một lần hẹn giờ duy nhất, đặt theo thời điểm hết hạn mà chính snapshot mang theo (BR-PROGRESS-003).

**Enforced by:** store + UI
**Liên quan:** BR-PROGRESS-003

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
