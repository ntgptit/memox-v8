---
id: BR-SRS-016
title: Lượt đầu trong phiên reviewing là scheduled
status: active
summary: Trong phiên `reviewing`, lượt đầu của thẻ là `scheduled`; chỉ lượt `scheduled` được đổi lịch.
superseded_by:
---
## Rule

**Chỉ áp cho phiên `reviewing`.** Lượt đầu tiên của một thẻ trong phiên đó MUST là `scheduled`. Chỉ lượt `scheduled` MAY cập nhật `current_box`, `ease_factor`, `interval_days` và `due_at`. Phiên `learning` MUST NOT sinh lượt `scheduled` nào (BR-STUDY-053).

**Enforced by:** store
**Liên quan:** BR-STUDY-053

## Lý do

BR-SRS-016 là rule quan trọng nhất của mục này. Không có nó, một card trả lời
`forgotten` rồi `remembered` ngay trong phiên sẽ nhảy lên box 2 và biến mất khỏi
lịch ngày mai — người dùng vừa quên nó xong đã được cho nghỉ hai ngày.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
