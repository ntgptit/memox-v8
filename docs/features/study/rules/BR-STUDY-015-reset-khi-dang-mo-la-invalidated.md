---
id: BR-STUDY-015
title: Reset khi phiên đang mở là invalidated
status: active
summary: Reset khi session đang mở cho `invalidated`, `end_reason = scheduler_reset`.
superseded_by:
---
## Rule

Reset xảy ra khi session đang mở MUST cho `invalidated`, `end_reason = scheduler_reset`.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Reset khi đang có phiên dở | Session → `invalidated`/`scheduler_reset` trong cùng transaction (BR-STUDY-015, BR-SRS-027) |
