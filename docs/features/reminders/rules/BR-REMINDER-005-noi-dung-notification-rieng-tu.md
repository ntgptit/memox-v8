---
id: BR-REMINDER-005
title: Nội dung notification giữ riêng tư
status: active
summary: Notification có thể nêu tên root deck cấp bách nhất, tổng số thẻ đến hạn, số deck còn lại; không chứa nội dung thẻ.
superseded_by:
---
## Rule

Nội dung notification MAY nêu **tên root deck cấp bách nhất**, **tổng số thẻ đến hạn** và **số deck còn lại**. Nội dung MUST NOT chứa mặt trước/sau của thẻ, ví dụ, gợi ý, phiên âm, tag, lịch sử ôn hay bất kỳ dữ liệu học nào của từng thẻ, kể cả trên lock screen. Quy tắc riêng tư này áp cho nội dung notification. Log thì theo [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) (2026-09-29, thay vế "MUST NOT log nội dung thẻ, tên deck" cũ): log ghi mọi thứ, không che.

**Enforced by:** store + UI
**Liên quan:** BR-CORE-001, ADR-018

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
