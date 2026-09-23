---
id: BR-CARD-019
title: Thẻ không tồn tại có lý do có kiểu
status: active
summary: Thẻ không tồn tại hiện bằng lý do có kiểu, không màn trắng, không lộ chi tiết kỹ thuật.
superseded_by:
---
## Rule

Thẻ không tồn tại — chưa bao giờ có, hoặc bị xoá từ màn khác trong lúc màn chi tiết đang mở — MUST surface bằng một lý do **có kiểu** — cùng lý do mà editor đã dùng khi thẻ biến mất, không phải một lý do thứ hai — MUST NOT là màn trắng, MUST NOT là thông báo kỹ thuật và MUST NOT lộ id, đường dẫn hay SQL (BR-CORE-005). Route chi tiết của thẻ **đang hoạt động** MUST NOT hiển thị thẻ đã nằm trong Trash nếu tính năng đó tồn tại; Trash MAY dùng lại cùng read model qua một capability tường minh và MUST NOT nhân bản màn hình.

**Enforced by:** store + UI
**Liên quan:** BR-CORE-005, BR-CARD-011

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Thẻ bị xoá từ màn khác khi chi tiết đang mở | Not-found có kiểu, không màn trắng, không lộ id (BR-CARD-019) |
