---
id: BR-SRS-006
title: Chặn di chuyển sang root không tương thích
status: active
summary: Di chuyển subtree sang root khác scheduler hoặc generation bị chặn hoặc yêu cầu reset tường minh.
superseded_by:
---
## Rule

Di chuyển subtree sang root có scheduler hoặc generation không tương thích MUST bị chặn, hoặc MUST yêu cầu người dùng reset tường minh.

Khoá scheduler (BR-SRS-003) MUST đi theo subtree: khi một subtree có thẻ đã hoàn tất chuỗi học được di chuyển, khôi phục từ Thùng rác hoặc hoàn tác xoá vào root tương thích mà chưa khoá, root đích MUST bị khoá trong cùng transaction với lần di chuyển đó (invariant Q30), để không thể đổi scheduler bên dưới thẻ đã học.

**Enforced by:** rule + store + invariant Q30

## Lý do

BR-SRS-006 là hệ quả trực tiếp của BR-SRS-005 khi cây có nhiều root. Một subtree kéo từ root
dùng `eight_box` sang root dùng `sm2` sẽ mang theo card có `current_box` mà
scheduler mới không hiểu.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Di chuyển subtree sang root khác scheduler | Chặn, đề nghị reset (BR-SRS-006) |
| Di chuyển, khôi phục hoặc hoàn tác xoá subtree có thẻ đã học vào root cùng scheduler chưa khoá | Cho phép; root đích bị khoá ngay, đổi scheduler ở đó bị chặn (BR-SRS-003) |
| Subtree không có thẻ đã học vào root chưa khoá | Cho phép; root đích không khoá |
