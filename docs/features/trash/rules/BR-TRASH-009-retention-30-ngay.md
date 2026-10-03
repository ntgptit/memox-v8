---
id: BR-TRASH-009
title: Retention 30 ngày
status: active
summary: Retention là 30 × 24 giờ từ `deleted_at`; auto-purge chạy khi khởi động, resume và mở Trash, theo giờ không vượt quá giờ server thấy ở lần đồng bộ gần nhất.
superseded_by:
---
## Rule

Retention là **30 × 24 giờ** tính từ `deleted_at`. Một batch eligible để purge khi `now - deleted_at >= 30 ngày`; đúng biên 30 ngày MUST là eligible. Auto-purge MUST chạy khi app khởi động, khi resume và khi mở Trash, MUST idempotent, và MUST NOT phụ thuộc vào việc người dùng có mở Trash hay không. Thời điểm MUST đến từ clock được inject; mọi layer MUST NOT gọi `DateTime.now()`.

Auto-purge MUST tính hết hạn theo **giờ purge** = sớm hơn của giờ máy và giờ server thấy ở lần đồng bộ gần nhất (`sync_changes` trả `serverTime`). Nếu chưa từng đồng bộ thì chưa có giờ purge: auto-purge MUST NOT xoá gì cho đến lần chạy sau đồng bộ. Nhờ đó giờ máy chỉnh tới trước không bao giờ xoá sớm; giờ server cũ chỉ làm việc xoá chậm lại.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

- Giờ máy chỉnh tới trước 60 ngày khi offline → giờ purge vẫn là giờ server cuối; chỉ batch hết hạn theo giờ đó mới bị xoá, phần còn lại chờ lần đồng bộ kế.
- Chưa từng đồng bộ → auto-purge không xoá gì.
