---
id: BR-SETTINGS-008
title: Reset to defaults
status: active
summary: `Reset to defaults` có xác nhận, đưa `app_settings` về mặc định, không đụng dữ liệu học.
superseded_by:
---
## Rule

`Reset to defaults` MUST là hành động tường minh có xác nhận, MUST đưa toàn bộ giá trị của `app_settings` về mặc định trong một transaction, và MUST NOT đụng `deck.study_config`, tiến độ học, `card_schedule`, `review_log`, session, scheduler hay nội dung card. Copy MUST nói rõ phạm vi đó trước khi thực hiện — MUST NOT dùng từ ngữ khiến hành động này bị hiểu là Reset learning progress (BR-SRS-022).

**Enforced by:** store + UI
**Liên quan:** BR-SRS-022, BR-SETTINGS-001, BR-SETTINGS-003

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
