---
id: BR-SETTINGS-008
title: Reset to defaults
status: active
summary: `Reset to defaults` có xác nhận, đưa `app_settings` về mặc định, không đụng dữ liệu học.
superseded_by:
---
## Rule

`Reset to defaults` MUST là hành động tường minh có xác nhận, MUST đưa sáu giá trị người dùng chọn trong `app_settings` về mặc định trong một transaction — `card_limit`, `new_card_order`, `theme_mode`, `language`, `reminder_enabled`, `reminder_minute_of_day` — và MUST giữ nguyên hai giá trị chỉ của máy, không phải lựa chọn của người dùng: `reminder_last_delivered_at` (bookkeeping của nhắc học, BR-REMINDER-004) và `welcome_seen` (màn 29). Reset MUST NOT đụng `deck.study_config`, tiến độ học, `card_schedule`, `review_log`, session, scheduler hay nội dung card. Copy MUST nói rõ phạm vi đó trước khi thực hiện — MUST NOT dùng từ ngữ khiến hành động này bị hiểu là Reset learning progress (BR-SRS-022).

**Enforced by:** store + UI
**Liên quan:** BR-SRS-022, BR-SETTINGS-001, BR-SETTINGS-003

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Reset tắt nhắc học, nên alarm đang chờ phải đi theo: reset và hoà giải alarm chạy như **một** thao tác nhắc học qua gate của reminders (`ResetAppOptionsUseCase`), để một lần Bật đang chạy dở không thể chen vào giữa và để lại `reminder_enabled = 1` sau khi đã xác nhận reset (DEV-218).
