---
id: BR-SRS-006
title: Chặn di chuyển sang root không tương thích
status: active
summary: Di chuyển subtree sang root khác scheduler hoặc generation bị chặn hoặc yêu cầu reset tường minh.
superseded_by:
---
## Rule

Di chuyển subtree sang root có scheduler hoặc generation không tương thích MUST bị chặn, hoặc MUST yêu cầu người dùng reset tường minh.

**Enforced by:** rule

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
