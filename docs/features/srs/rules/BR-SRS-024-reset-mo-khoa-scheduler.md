---
id: BR-SRS-024
title: Reset mở khoá scheduler
status: active
summary: Sau reset `first_answered_at` về NULL, mở khoá scheduler.
superseded_by:
---
## Rule

Sau reset, `first_answered_at` MUST về NULL → scheduler mở khoá. Đây là cơ chế duy nhất để đổi scheduler sau lượt học đầu.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
