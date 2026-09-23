---
id: BR-TRASH-009
title: Retention 30 ngày
status: active
summary: Retention là 30 × 24 giờ từ `deleted_at`; auto-purge chạy khi khởi động, resume và mở Trash.
superseded_by:
---
## Rule

Retention là **30 × 24 giờ** tính từ `deleted_at`. Một batch eligible để purge khi `now - deleted_at >= 30 ngày`; đúng biên 30 ngày MUST là eligible. Auto-purge MUST chạy khi app khởi động, khi resume và khi mở Trash, MUST idempotent, và MUST NOT phụ thuộc vào việc người dùng có mở Trash hay không. Thời điểm MUST đến từ clock được inject; mọi layer MUST NOT gọi `DateTime.now()`.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
