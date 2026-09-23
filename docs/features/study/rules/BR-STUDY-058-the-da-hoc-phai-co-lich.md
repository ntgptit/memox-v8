---
id: BR-STUDY-058
title: Thẻ đã học phải có lịch
status: active
summary: Thẻ có `learned_at` có `due_at`; thẻ `learned_at IS NULL` không có lượt `scheduled`.
superseded_by:
---
## Rule

Thẻ có `learned_at` MUST có lịch (`due_at` không NULL); thẻ `learned_at IS NULL` MUST NOT có lượt `scheduled` nào.

**Enforced by:** db + invariant
**Liên quan:** BR-STUDY-053

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
