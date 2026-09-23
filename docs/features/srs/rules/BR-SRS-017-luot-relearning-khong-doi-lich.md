---
id: BR-SRS-017
title: Lượt relearning không đổi lịch
status: active
summary: Thẻ quay lại sau `forgotten`/`again` là `relearning`: ghi study answers, không đổi lịch.
superseded_by:
---
## Rule

Card quay lại sau `forgotten`/`again` MUST là `relearning`. Lượt `relearning` MUST ghi study answers và cập nhật `last_answered_at`, nhưng MUST NOT thay đổi `current_box`, `ease_factor`, `interval_days` hay `due_at`.

**Enforced by:** store + invariant Q14

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
