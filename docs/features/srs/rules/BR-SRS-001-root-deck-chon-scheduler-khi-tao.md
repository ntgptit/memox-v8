---
id: BR-SRS-001
title: Root deck chọn scheduler khi tạo
status: active
summary: Root deck chọn `eight_box` hoặc `sm2` khi tạo; không có mặc định ngầm.
superseded_by:
---
## Rule

Root deck MUST chọn một scheduler khi tạo: `eight_box` hoặc `sm2`. MUST NOT có mặc định ngầm bỏ qua bước chọn.

**Enforced by:** rule + invariant Q11

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Tạo root deck không chọn scheduler | Chặn, lỗi inline (BR-SRS-001) |
