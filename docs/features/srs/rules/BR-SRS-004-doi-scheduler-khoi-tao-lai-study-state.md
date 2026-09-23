---
id: BR-SRS-004
title: Đổi scheduler khởi tạo lại study state
status: active
summary: Đổi scheduler khi chưa khoá khởi tạo lại study state toàn cây trong một transaction.
superseded_by:
---
## Rule

Đổi scheduler khi chưa khoá MUST khởi tạo lại study state của toàn bộ card trong cây theo scheduler mới, trong một transaction.

**Enforced by:** store

## Lý do

BR-SRS-004 dễ bị bỏ sót vì "chưa có lượt học nên không có gì để mất". Nhưng study state
đã tồn tại từ lúc tạo card (BR-CARD-004), và state của 8-box không dùng được cho SM-2.
Bỏ bước này để lại card `sm2` với `current_box` và không có `ease_factor`.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Đổi scheduler khi chưa có lượt học | Cho phép, khởi tạo lại study state toàn cây (BR-SRS-004) |
