---
id: BR-PROGRESS-007
title: Đọc tiến độ là chỉ đọc
status: active
summary: Đọc tiến độ theo deck là chỉ đọc: không ghi, không mở hay đóng session.
superseded_by:
---
## Rule

Đọc tiến độ MUST là thao tác chỉ-đọc: mở, rời hay đổi khoảng trên màn hình MUST NOT ghi hay chạm tới nội dung card, timestamp, `content_type`, study state, review history, session hay quan hệ tag; MUST NOT mở hay đóng session nào. Một lần đọc thất bại vì thế MUST NOT làm hỏng dữ liệu, và copy lỗi MUST NOT gợi ý ngược lại.

**Enforced by:** store + UI
**Liên quan:** BR-TRANSFER-011

## Lý do

Cùng khái niệm tính chỉ-đọc với BR-PROGRESS-009, rule tương ứng của Progress overview; hai rule áp cho hai màn và được giữ cả hai (chủ dự án chốt khi xử lý OQ-19 (2026-09-23)). Sửa một rule thì kiểm tra rule kia.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
