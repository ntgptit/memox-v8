---
id: BR-STUDY-011
title: Năm giá trị end_reason
status: deprecated
summary: Đã thay bằng BR-STUDY-012. `end_reason` có năm giá trị.
superseded_by: BR-STUDY-012
---
## Rule

`study_session.end_reason` MUST có năm giá trị: `user_exit`, `scheduler_reset`, `stale_generation`, `persistence_error`, `interrupted`; NULL khi kết thúc bình thường hoặc chưa kết thúc.

**Enforced by:** db + invariant Q12

## Lý do

Bị thay thế bởi BR-STUDY-012 — xem `## Lý do` của BR-STUDY-012.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
