---
id: BR-PROGRESS-012
title: browse không tạo card-day
status: active
summary: `browse` không tạo card-day, không làm ngày active, không giữ streak.
superseded_by:
---
## Rule

Stage `browse` không ghi hàng `review_log` nào (BR-MODE-005), nên nó MUST NOT tạo card-day, MUST NOT làm một ngày trở thành active và MUST NOT giữ streak. Mở một phiên rồi chỉ lướt `browse` và thoát MUST để Progress y nguyên.

**Enforced by:** store (SQL)
**Liên quan:** BR-MODE-005

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
