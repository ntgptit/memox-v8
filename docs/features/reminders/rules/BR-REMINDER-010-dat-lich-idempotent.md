---
id: BR-REMINDER-010
title: Đặt lịch idempotent
status: active
summary: Hoà giải lịch với cùng settings và giờ địa phương cho đúng một lịch đang chờ.
superseded_by:
---
## Rule

Đặt lịch MUST **idempotent**: chạy lại việc hoà giải lịch với cùng settings và cùng giờ địa phương MUST cho đúng một lịch đang chờ, MUST NOT xếp chồng thêm lượt và MUST NOT nhân đôi notification.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Mở app nhiều lần trong ngày khi đang bật nhắc | Hoà giải lịch idempotent — vẫn đúng một lượt chờ (BR-REMINDER-010) |
