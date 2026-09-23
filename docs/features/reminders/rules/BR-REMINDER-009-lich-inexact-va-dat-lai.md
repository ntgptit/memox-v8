---
id: BR-REMINDER-009
title: Lịch inexact và đặt lại lịch
status: active
summary: Đặt lịch dùng cơ chế inexact, không xin exact alarm; đặt lại khi các điều kiện liệt kê xảy ra.
superseded_by:
---
## Rule

Đặt lịch MUST dùng cơ chế **không chính xác** (inexact) của hệ điều hành; ứng dụng MUST NOT khai báo hay xin quyền exact alarm. Lịch MUST được đặt lại khi: bật nhắc, đổi giờ nhắc, offset địa phương đổi, và — nếu nền tảng yêu cầu — sau reboot hoặc app update. Tắt nhắc MUST huỷ lịch đang có.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
