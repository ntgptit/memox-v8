---
id: BR-STUDY-004
title: Ghi đánh giá ngay
status: active
summary: Đánh giá được ghi ngay khi người dùng bấm, không chờ hết phiên.
superseded_by:
---
## Rule

Đánh giá MUST được ghi ngay khi người dùng bấm, không chờ hết phiên.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Thoát giữa phiên | Giữ toàn bộ lượt đã ghi (BR-STUDY-004, BR-STUDY-019); session → `abandoned`/`user_exit`. Phiên học mới bỏ dở **không để lại lịch nào** (BR-STUDY-053) |
